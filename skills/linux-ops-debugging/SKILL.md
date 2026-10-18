---
name: linux-ops-debugging
description: Use when debugging a Linux host, systemd unit, disk, or SSH.
---

# Linux operations and debugging

## Disk fills up: check inodes before space

The order matters. `df -h` showing free space does not mean you can create a
file, because **inodes run out first** with many small files.

```sh
df -h                       # which partition is full
df -i                       # inode usage; if this is 100%, that is the answer
du -sh /var/log /var/cache 2>/dev/null
du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10
```

The case that wastes the most time: a deleted file whose descriptor is still
open. It consumes space, does not appear in `du`, and disappears from `ls`. Find
it with:

```sh
lsof +L1                     # deleted files still held open
```

Then restart or signal the process holding it. Deleting more files will not help.

Inode offenders:

```sh
find / -xdev -printf '%hn' 2>/dev/null | sort | uniq -c | sort -rn | head -20
```

## systemd units fail for specific, non-obvious reasons

- **`ExecCondition=` exit codes are asymmetric.** Exit `255`, a timeout, or death
  by signal marks the unit **FAILED**. Exit `1` skips the remaining commands but
  leaves the unit **not failed**. Getting this wrong makes a unit look healthy
  while having done nothing.
- If any `ExecStartPre=`, `ExecStart=` or `ExecStartPost=` fails and is not
  prefixed with `-`, the rest are skipped and the unit is marked failed. Prefix
  with `-` to ignore the exit code.
- **`TimeoutStartSec=` also applies to reloads.** A reload that exceeds it fails.
- **`StartLimitIntervalSec` must exceed `RestartSec` x `StartLimitBurst`.**
  Otherwise the limits never engage and the service restarts forever.
- **If the main PID cannot be determined, failure detection and automatic
  restart do not work reliably.** Use `Type=notify` with sd_notify, or an
  explicit `PIDFile=`.

Check what systemd thinks without reading the unit:

```sh
systemctl status <unit>
journalctl -u <unit> -n 100 --no-pager
systemd-analyze verify /etc/systemd/system/<unit>.service
systemd-analyze security <unit>    # exposure score
```

Hardening that scores well and costs nothing:

```ini
[Service]
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictSUIDSGID=true
PrivateDevices=true
```

Then `systemctl daemon-reload && systemctl restart <unit>`. When a unit still
behaves wrongly, `SystemCallLog=` records seccomp denials to the audit log, so
you can see which syscall the service is actually blocked from.

## Shell scripting: the traps that cause real bugs

```bash
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
```

`pipefail` is the one people omit. Without it, `some_cmd | true` reports success
no matter what `some_cmd` did, and a failure is silently swallowed.

**`"$@"` is right almost always; `$*` is wrong almost always.** `$*` word-splits
into one string, so an argument containing a space is destroyed:

```bash
set -- 1 "2 two" "3 three"
set -- "$*"; echo "$#"   # 1, one mangled argument
set -- "$@"; echo "$#"   # 3, each argument intact
```

Never expand an array as `"${ARR[@]:-}"`; that invents an empty element.
Use `"${ARR[@]}"` and check length first.

Under `nounset`, use `${VAR-}` rather than `${VAR}` when the variable may
legitimately be unset.

Diagnostics belong on stderr, and a trap keeps cleanup honest:

```bash
err() { echo "[$(date +%FT%T%z)] $*" >&2; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
```

Use `#!/bin/sh` only for genuinely portable POSIX. On RHEL and macOS `/bin/sh`
is bash, so it hides your bugs until they run on Debian.

## SSH hardening

```sh
# /etc/ssh/sshd_config.d/99-hardening.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
HostbasedAuthentication no
AllowUsers deploy monitoring
MaxAuthTries 3
MaxStartups 10:30:100
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 3
X11Forwarding no
```

`MaxStartups 10:30:100` means: begin dropping unauthenticated connections at 30,
refuse entirely at 100. `ClientAliveInterval` with `MaxAuthTries 3` is the
combination that shuts out brute force without breaking real sessions.

Then `systemctl reload sshd` and **keep your current session open** until you
have confirmed a second one works.

## Network diagnosis

```sh
ss -tulnp                     # listening sockets and owning processes
resolvectl query example.com  # or dig +short
curl -v https://example.com   # TLS handshake chain and timings
```

For TLS specifically, the failure you will actually hit is a certificate, and
`curl -v` names the exact error. `openssl s_client -connect host:443` shows the
chain, which distinguishes an expired leaf from a missing intermediate.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "df shows free space." | Inodes may be exhausted, which looks identical from the outside. |
| "I deleted the logs." | If `lsof +L1` shows it held open, the space is still used. |
| "ExecStart ran, so the unit started." | `ExecStartPre` failing skips everything after it and still fails the unit. |
| "set -e is enough." | Without `pipefail`, a failing command in a pipeline is invisible. |
| "Restart sshd, it is fine." | You will lock yourself out. Verify from a second session first. |
