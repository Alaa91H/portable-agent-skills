---
trigger: model_decision
description: "Use when writing or reviewing CI workflows, or assessing supply chain risk."
---


# CI pipeline security

## Pin actions to a SHA, and verify the SHA is real

```yaml
# Never. A tag is mutable: whoever owns the repo can repoint it at any commit.
uses: some/action@v4

# Pin to a full commit SHA
uses: some/action@8f4b7f84864484a7bf31766abe9204da3cbe65b3 # v4.1.0
```

Dependabot or Renovate keeps the SHA current, so pinning does not mean falling
behind.

**SHA pinning alone is not sufficient**, and this is the part almost every team
misses. GitHub resolves a commit SHA, finds a matching object, and runs it
**regardless of which fork it came from**. An attacker who can get a commit into
a repository you have ever interacted with can therefore land an impostor commit
that satisfies your pin.

Verify the SHA belongs to the claimed repository, and automate that check:

```sh
npx zizmor --pedantic .github/workflows/
```

## Dangerous triggers

| Trigger | Why |
| --- | --- |
| `pull_request_target` | Runs in the **base** repository with a write-scoped token and all secrets. Checking out PR code here is remote code execution with production credentials. |
| `workflow_run` | Enables privilege escalation: an attacker edits the *triggering* workflow by pull request to invoke the privileged one. |
| `issue_comment` | Time-of-check-to-time-of-use. An attacker edits the pull request between the approval comment and execution. |

```yaml
# Never check out untrusted code under pull_request_target
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha }}   # attacker-controlled
```

Prefer `pull_request`, `workflow_call`, and explicit permissions.

For `issue_comment` deployments, bind the command to an immutable SHA and check
the actor:

```text
/ok-to-deploy 9f2c1ab...        # verify it matches the current HEAD, and that
                                 # the commenter can write to the repository
```

## Default to no permissions

```yaml
permissions: {}          # workflow level: nothing by default

jobs:
  build:
    permissions:
      contents: read      # grant per job
```

Never default to `write`. A job that needs more should say so.

Two more that leak credentials:

- `actions/checkout` with `persist-credentials: false` unless the job really
  needs git writes. Otherwise the token is written into `.git/config` and any
  later step can exfiltrate it.
- **Never `secrets: inherit`** in a reusable workflow; it forwards everything.
  Pass an explicit map.

Sanitise `run:` interpolation through environment variables:

```yaml
# Wrong: shell injection via a PR title
- run: echo "Building ${{ github.event.pull_request.title }}"

# Right
- env: { PR_TITLE: ${{ github.event.pull_request.title }} }
  run: echo "Building $PR_TITLE"
```

## Disable caching in release workflows

GitHub Actions cache poisoning lets content injected into a cache execute inside a
privileged release context and steal production secrets. A workflow that publishes
a release or deploys to production should have caching turned off entirely.

Where caching is appropriate, segment keys by trust level so one workflow cannot
read another's cache:

```yaml
key: ${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
restore-keys: ${{ runner.os }}-
```

## Require approval, and know the known bypass

Require approval for all external contributors, not just first-timers.
"Require approval for first-time contributors" is bypassed by landing one benign
typo fix to gain trust, then following up with the real payload.

Prefer OIDC or workload identity federation over any long-lived cloud credential
stored in CI.

## Quarantining flaky tests is a ledger, not a fix

Quarantine is legitimate and it must be a debt ledger:

- A hard expiry date and a named owner.
- The test still runs and still reports.
- It **blocks the release** once the deadline passes.

A quarantine without an expiry becomes permanent, the suite becomes a lie, and
real regressions hide behind it.

## Deployment strategies

| Strategy | Rollback | Cost | Fits |
| --- | --- | --- | --- |
| Rolling | Slow, requires forward-compatible schema | Low | Default, schema-compatible changes |
| Blue/green | Instant | 2× capacity | Small services, reversible changes |
| Canary | Instant, shift weight back | Metrics needed | Tail latency, gradual risk |

Canaries catch tail-latency regressions that a blue/green smoke test misses, and
rollback is seconds. Use a progression like 1% → 5% → 25% → 50% → 100%, and
promote on SLO metrics rather than on "no errors appeared".

**Never canary a change that is invisible until 100%**: authentication flows,
cache warm-up, connection-pool sizing, large backfills. The canary has to observe
a metric that actually moves early, or it approves a change that was never tested.

## Verify your own pipeline

```sh
npx zizmor --pedantic .github/workflows/   # supply chain and trigger issues
actionlint .github/workflows/*.yml          # syntax and expression errors
```

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We pin to v4, that is enough." | Tags are mutable, and a SHA alone admits impostor commits. |
| "pull_request_target is needed for fork PRs." | It runs with your secrets. Restructure the job instead. |
| "It is an internal repo." | A compromised or careless dependency reaches CI either way. |
| "Caching speeds up our releases a lot." | It also lets cache content execute in a privileged context. |
| "The flaky test is quarantined." | For how long, and who owns it? No expiry means never fixed. |
