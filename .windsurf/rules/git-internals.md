---
trigger: model_decision
description: "Use when recovering lost work, bisecting, or managing submodules."
---


# Git internals

## The reflog is your undo

Every `HEAD` movement is recorded, including ones that seem to destroy work.
This is how work is recovered after a bad reset, a rebase, or an accidental
branch delete.

```sh
git reflog                                   # everything HEAD has pointed at
git reset --hard HEAD@{5}                    # go back to where you were
git switch -c recovered-branch HEAD@{12}     # rescue it onto a branch first
```

`git reset --hard` looks absolute and is not: the commit is still in the object
database, and the reflog says where. **Rescue to a branch before anything else**,
because a later `git gc` can prune unreferenced objects.

For the case where the commit is truly gone, `git fsck --lost-found` finds
unreachable objects and `git show <sha>` inspects them.

## Bisect properly

```sh
git bisect start
git bisect bad                  # current commit is broken
git bisect good v3.1.0          # this one was fine
# git bisect runs the midpoint and waits for you to judge it
git bisect good     # or: git bisect bad
git bisect reset
```

It needs a judgement at each step, so **automate that judgement** whenever the
test is automatable, which is the whole point:

```sh
git bisect run npm test
git bisect run ./smoke.sh
```

Without automation you are the loop, and you stop after ten steps. With it, a
thousand-commit range resolves in about ten runs and no attention.

A bisect across a **merge commit** needs care: `git bisect` picks a first-parent
lineage by default, so mark the merge itself as bad explicitly if that is where
it broke.

## Hooks

```sh
# .git/hooks/pre-commit  — must be executable
#!/usr/bin/env bash
set -euo pipefail
npm run lint -- --fix
if ! git diff --quiet; then
  echo "hook modified files; stage them and retry"
  exit 1
fi
git diff --cached --quiet || git commit    # re-commit without recursion
```

Two traps:

- **The hook must not be recursive.** A hook that calls `git commit` re-enters
  itself; guard with the environment variable `git commit` sets.
- **Hooks do not travel.** They are not in the repository by default. Share them
  by committing them and installing, or with a framework:

```sh
git config core.hooksPath .githooks        # then commit .githooks/pre-commit
```

Server-side enforcement is what actually holds; a local hook is a fast
convenience, not a guarantee.

## Submodules and the trap in them

A submodule is a **commit pointer**, not a copy of the files. Fresh clones get
an empty directory until you initialise them, which is the source of most
confusion.

```sh
git clone --recurse-submodules <url>
git submodule update --init --recursive
```

The recurring problem is a change inside the submodule that the parent does not
record:

```sh
cd sub/
git commit -am "..."        # change is committed there
cd ..                        # parent shows the submodule as modified, but the
                             # pointer has not moved
git add sub && git commit   # this is the step everyone forgets
```

A build that is green locally and broken in CI is almost always a submodule
pointer that was never staged.

If the dependency is a plain library rather than something you need to patch in
place, a package manager is a better answer: it records the version, not a
nested repository.

## Objects, and why that matters

Git stores four kinds, and only one is the file you are editing:

| Object | Content | Immutable |
| --- | --- | --- |
| blob | File content | Yes |
| tree | Directory listing | Yes |
| commit | Tree, parents, message, author | Yes |
| tag | Points at a commit | Yes |

Immutability is why git is safe: a commit cannot be edited, only replaced. It is
also why rewriting history works, because the old objects stay until they are
unreachable and pruned.

`git cat-file -p <sha>` shows the raw object. `git count-objects -vH` shows the
store size, and a repository with a huge pack file usually accumulated a large
binary in history:

```sh
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | awk '$1=="blob" {print $3, $4}' | sort -rn | head -20
```

Large files belong in storage, not in history. Once committed they stay in every
clone, so removing them from the working tree does nothing.

## Index and staging

The index is a **proposed snapshot**, which is what makes partial commits
possible:

```sh
git add -p file            # choose hunks
git add --intent-to-add f  # record that it is tracked, without staging content
git commit --only file     # commit that path, bypassing the index
```

`git stash` saves the index as well as the working tree, so a stash pop can
conflict on staged changes the same way a merge can.

## Configuration that travels badly

```sh
# line endings: the setting most likely to differ between machines
git config --global core.autocrlf input    # Windows: normalise to LF in the repo
git config --global core.eol lf
```

If a repository mixes line endings, symptoms appear only on one platform, in
files that look correct in the editor. `.gitattributes` fixes it for everyone;
local config fixes it for one person, which is why `.gitattributes` is the one
that matters.

```sh
git config --global --list --show-origin     # where a setting actually came from
```

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "reset --hard destroyed my work." | The commit is in the reflog. Rescue it to a branch first. |
| "Bisect is too manual." | `git bisect run <test>` does the judging. |
| "The hook will run for the team." | Hooks are local. Use core.hooksPath, and enforce server-side. |
| "The submodule is committed." | A pointer is. Stage the submodule path in the parent. |
| "The file is huge, so I will delete it." | History keeps it in every clone. |
| "The line endings are fine here." | They differ by machine. Fix it in `.gitattributes`. |
