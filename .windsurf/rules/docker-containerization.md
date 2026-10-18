---
trigger: model_decision
description: "Use when writing a Dockerfile, or debugging image size, cache or signals."
---


# Docker containerization

## Layer order is cache order

A layer is reused only if the instruction and every file it depends on are
unchanged. Copy the whole tree before installing dependencies and you invalidate
the install on every single source change.

```dockerfile
# Broken: any file change busts the install
COPY . .
RUN npm ci
RUN npm run build

# Correct: expensive and stable first, volatile last
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
```

Expensive, rarely-changing steps first; frequently-changing steps last. This is
the single highest-leverage Docker rule and it is wrong in most Dockerfiles.

### Cache mounts for package managers

Cache mounts persist the package cache *across* layer invalidation:

```dockerfile
RUN --mount=type=cache,target=/root/.npm npm ci
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build go build
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends gcc
```

`apt` needs `sharing=locked` (exclusive access); npm, pip and Go use the default
shared mode.

**Cache mounts are not included in `--cache-to` / `--cache-from` and start empty
on every fresh CI runner.** That is a widespread silent misconfiguration: the
build is fast locally and slow in CI, and the cause is not obvious.

## Multi-stage builds

```dockerfile
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim AS runtime
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./
RUN npm ci --omit=dev && groupadd -r app && useradd -r -g app app
USER app
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

Only the artefact crosses the boundary. The compiler, the source and the dev
dependencies never reach the final image.

Name your stages with `AS`, never `COPY --from=0`: integer indices break when
someone reorders the file. `--target build` builds only up to that stage, and
BuildKit skips stages the target does not depend on.

## The PID 1 problem

A process running as PID 1 without an init gets **no default signal handlers**.
Linux's default dispositions for `SIGTERM` apply to shell processes, not to
binaries, so your app never sees `docker stop` and is killed after the timeout.

PID 1 also does not reap orphaned children, so zombies accumulate for the life of
the container.

```dockerfile
ENTRYPOINT ["/app/server"]     # exec form: signals reach the process
CMD ["npm", "start"]            # shell form: /bin/sh -c is PID 1, app is a child
```

Always the JSON exec form. `CMD ["npm", "start"]` makes `npm` PID 1 and your app
its orphaned child, so the signal stops npm and leaves the server running.

Pair with a `STOPSIGNAL` if you need something other than `SIGTERM`, and with
Kubernetes `preStop` hooks plus a `terminationGracePeriodSeconds` (default 30s).

## Do not run as root

```dockerfile
RUN groupadd -r app && useradd -r -g app app
USER app
```

Runtime hardening, since `USER` alone does not restrict capabilities:

```bash
docker run --cap-drop all --cap-add CHOWN \
           --security-opt=no-new-privileges \
           --read-only --tmpfs /tmp \
           -p 127.0.0.1:8000:8000 image
```

- `-p 8000:8000` binds to **all interfaces** and bypasses host firewall rules,
  because Docker writes its iptables/nftables rules *before* your `DENY` rules.
  Bind to `127.0.0.1` explicitly.
- **Never mount `/var/run/docker.sock`.** Read-only is not a mitigation: a
  process that can connect to the socket can still create privileged containers.
- **Never pass secrets as `ARG` or `ENV`.** They persist in image history. Use
  build secrets, which are mounted at `0400` and not recorded:

```dockerfile
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```

## Other rules with specific consequences

- `.dockerignore` at the context root, at minimum: `node_modules`, `.git`,
  `dist`, `build`, `**/*.log`, `**/.env*`.
- **`apt-get update` and `apt-get install` in one `RUN`.** Separate layers cache a
  stale package index, which is the classic "works locally, stale in CI" bug.
- `ENV abc=hello` then `ENV abc=bye def=$abc` sets `def` to **`hello`**. Values
  referenced within the same instruction use the value from before that
  instruction.
- `COPY`, not `ADD`: `ADD` auto-extracts archives and fetches URLs, both of
  which surprise you.
- Pin base images **by digest**, not by a floating tag:
  `FROM node:22-slim@sha256:...`.
- Avoid `curl | sh` in any layer. Fetch, verify, then execute.

## Healthchecks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1
```

`--start-period` matters: failures during it do not count toward `--retries`,
which is the grace period for a slow boot.

In Kubernetes, probes **replace** the Docker healthcheck entirely. Do not
maintain both.

## Verify rather than assume

```sh
docker history --no-trunc <image>     # find secrets leaked into layers
docker image inspect <image> --format '{{.Config.User}}'   # should not be root or empty
```

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The build is fast enough." | It is slow on the first cold CI run, every time, and nobody notices until the cache expires. |
| "`CMD npm start` is simpler." | npm becomes PID 1, the signal goes to npm, and your server is killed rather than shut down. |
| "We can chown later at runtime." | Then the container runs as root, which is the thing you were avoiding. |
| "The build cache is disabled in CI." | Cache mounts survive that. They are not part of the layer cache. |
| "It is only internal." | `-p 8000:8000` is on every interface, not just localhost. |
