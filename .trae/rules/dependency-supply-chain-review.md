---
description: "Use when adding or upgrading dependencies, auditing an existing dependency tree, or assessing the risk of a package, lockfile, or build pipeline."
---


# Dependency and supply chain review

## Before you add

Most of the damage is prevented here, because adding is where the decision is
still cheap.

**Is the package needed?** Check what it pulls in. A 200-byte helper is not worth
a 4,000-transitive-dependency tree that installs a postinstall script.

```sh
npm view <pkg> dependencies peerDependencies maintainers license dist.unpackedSize time.modified repository.url
npm install --dry-run <pkg>          # see the full tree before committing to it
```

**Is it the real package?** Typosquatting works on names people reach for.
Compare against what the README expects:

| Official | Typosquat |
| --- | --- |
| `crossenv` | `cross-env` (dash) |
| `lodash` | `lodashs` |
| `react` | `reactt` |
| `uuid` | `uuid-js` |

If the name does not match exactly what the documentation told you to install,
stop. That is the whole attack.

**Is it maintained?** Check last publish date, open issue count versus closed,
number of maintainers, and whether the repository has the history it claims. A
package with 40 million weekly downloads and no commits in two years has
transferred ownership.

```sh
npm view <pkg> time.modified maintainers
```

## Install scripts are the sharpest edge

A dependency can execute arbitrary code on install, on your machine, with your
credentials and in CI.

```sh
# Find every dependency that runs code at install time
npm ls --all --json | jq -r 'to_entries[] | select(.value.hasInstallScript) | .key'

# In a lockfile
grep -c '"hasInstallScript": true' package-lock.json
grep -B5 '"hasInstallScript": true' package-lock.json | grep '"resolved"'
```

Treat any new package with an install script as a manual review item. Legitimate
cases exist, such as native modules that must compile, and they are identifiable:
the script compiles or downloads a platform binary. A script that curls an
unspecified URL, or pipes to a shell, is not legitimate.

Reduce exposure where you can:

```sh
npm ci --ignore-scripts    # in CI, if the tree does not need native builds
```

## Auditing an existing tree

```sh
npm audit --production              # known advisories in what ships
npm audit fix                        # see what it would change first
npx osv-scanner --lockfile=package-lock.json
pip-audit                            # python
npm ls <pkg>                        # duplicates and shadowed versions
```

Then check what an advisory list cannot:

- **Abandoned packages.** No release in a year or more, with consumers who
  cannot migrate. Not a vulnerability, but an unmaintained attack surface.
- **Duplicated versions.** Two copies of the same package means two copies of
  its transitive tree, and one of them is probably stale and unpatched.
- **Packages you do not use directly** that entered through a transitive edge.
  These are the ones nobody reviewed when they were added.
- **Install scripts already present** in the committed lockfile.

Fix in the order: remove what is unused first, upgrade second, pin the rest.

## Lockfile integrity

The lockfile is a security control, so treat it like one.

- **Commit it.** An uncommitted lockfile means every install resolves fresh, and
  the attacker's window is every build.
- **Never use floating ranges in CI.** `^1.2.3` at install time resolves to
  whatever is newest, which is whatever an attacker published.
- **Treat a lockfile diff like any other review diff.** A package changing
  version silently in a lockfile update is the vector:

```sh
git diff package-lock.json | grep -E '^\+\s+"(version|resolved)"' | head -20
```

- **Use an integrity-checked registry** when available, and do not disable
  integrity verification to work around a registry error.

## CI pipeline

The build pipeline is usually the higher-value target, because it has the
secrets.

```sh
grep -rn "uses:" .github/workflows/        # unpinned actions
```

- **Pin actions to a commit SHA**, not a tag. Tags are mutable, and a tag is
  whatever the owner pushes next.
- **Never run `pull_request_target` with a checkout of the fork's code.** It runs
  with repository secrets against attacker-controlled input.
- **Scope secrets** to what each job needs; do not expose them to pull requests
  from forks at all.
- **Keep the token read-only by default** and elevate only in the job that needs
  write access.

## Record the decision

For anything non-trivial, note in the dependency PR: why the package, what it
transitively pulls in, whether it has an install script, and what happens if it
becomes unmaintained. That note is what makes the next review a five-second job
instead of an investigation.
