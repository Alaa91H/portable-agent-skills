---
name: environment-bootstrap
description: Use when setting up a dev environment, installing dependencies or running it.
---

# Environment bootstrap

## Read the lockfile before installing anything

The lockfile is the build instruction; the manifest is the wish. Always install
from the lockfile:

```sh
npm ci                 # never npm install for a team project
pnpm install --frozen-lockfile
yarn install --immutable
pip install -r requirements.lock
```

`npm ci` deletes `node_modules` and installs exactly the lockfile. `npm install`
may resolve differently, which means your local build differs from everyone
else's and from CI, and you will debug the wrong thing.

## Check the toolchain before installing dependencies

A project that requires Node 22 and a Postgres 16 will not be fixed by
`npm ci`. Find the declared versions first:

```sh
grep -A8 '"engines"' package.json
cat .nvmrc .node-version .tool-versions 2>/dev/null
cat .python-version 2>/dev/null; grep -E 'python_requires|requires-python' pyproject.toml
grep '^FROM' Dockerfile | head -3        # the image often pins it
```

Match the runtime version exactly, not approximately. Native modules compiled
against one version fail at load time under another.

## Bring up dependencies, then verify each one

```sh
docker compose up -d postgres redis
docker compose ps
```

Check each service is actually healthy, not merely started:

```sh
docker compose exec postgres pg_isready -U postgres
redis-cli ping                                   # PONG
```

A container that is up but not accepting connections produces the same error as
one that is not running, and guessing between them wastes the afternoon.

## Run the test suite before writing any code

This is the step that proves the environment works, and it is the one people
skip:

```sh
npm test
```

If the suite fails **before you have changed anything**, the problem is the
environment, and now is the cheapest possible time to know that. Get it green
first, record the command, and treat it as the definition of a working setup.

## Rebuild from scratch when things get strange

The escalation ladder, cheapest first:

```sh
rm -rf node_modules .next dist build && npm ci    # 1: dependency state
rm -rf ~/.cache                                # 2: tool caches
docker compose down -v && docker compose up -d   # 3: volumes, destroys local data
git clean -xfd                                  # 4: nuclear, removes all ignored files
```

Step 3 destroys local database data, so stop and warn before running it.

## Common causes, in the order they are actually the cause

| Symptom | Usual cause |
| --- | --- |
| Module not found, after a clean install | Workspace not linked, or a missing `postinstall` |
| Native module fails to load | Wrong runtime version, or built for a different platform |
| Tests pass alone, fail together | Order dependence, or a shared port or database |
| Cannot connect to a local service | Compose up, but not healthy; or the port is taken |
| Everything worked yesterday | A lockfile change, or an expired credential |

Check for a port conflict before concluding the database is broken:

```sh
lsof -i :5432      # or: netstat -ano | findstr :5432
```

## Record what worked

The output of a successful bootstrap is the highest-value artefact a
contributor produces, and it belongs in the repository:

```sh
npm ci
docker compose up -d
npm test
```

in a README, in order, copy-pasteable, with no implied knowledge. If the setup
needs a step only you know, the setup is not finished.

## When you cannot get it running

Say so specifically rather than proceeding against an unknown environment:

> `npm ci` succeeds and `npm test` runs, but 4 integration tests fail because
> Postgres is not reachable on 5432. Everything else passes. I have not changed
> any code.

That sentence tells the next person exactly where the boundary is. "The
environment is broken" tells them nothing.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "npm install is fine." | It may resolve differently from the lockfile, so your build is not CI's build. |
| "It works on my machine." | That is the claim to falsify, not to state. |
| "I will skip the tests for now." | They are how you know the environment works, before your changes confuse the signal. |
| "Docker fixes everything." | It fixes dependency versions and services. It does not fix a port conflict or a missing env var. |
| "compose down -v will help." | It also deletes the database. Warn first. |
