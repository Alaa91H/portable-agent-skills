---
name: using-git-worktrees
description: Use when starting work that should not disturb the current checkout, or when several branches need to be worked on at once.
---

# Using git worktrees

## What a worktree is for

A worktree is a second working directory on the same repository, each with its
own branch and its own files. Use one when:

- You need to work on branch B while branch A is checked out and you want the
  running dev server for A to keep working.
- You are reviewing a diff, or running the test suite against two revisions, at
  the same time.
- Several tasks need to be in flight at once and switching branches would
  thrash uncommitted work.

Do not use one for a single linear task. It is real overhead for a benefit that
only appears when two lines of work are concurrent.

## Create, list, remove

```sh
git worktree add ../repo-feature -b feature/short-description
git worktree add ../repo-hotfix hotfix/urgent        # existing branch
git worktree list
git worktree remove ../repo-feature
git worktree prune                                  # clear records of removed dirs
```

`git worktree add <path> -b <branch>` creates the branch. Without `-b` it checks
out an existing one. The path is a normal directory anywhere on disk.

## The trap that costs people an afternoon

A worktree shares `.git` with the main checkout but has its own working files,
which means it has **no dependencies of its own**:

```sh
cd ../repo-feature
npm ci          # or: pnpm install, cargo build, mix deps.get
```

A worktree with no `node_modules` produces module-resolution errors that look
like broken code. Every worktree needs its own install. Conversely, do not put a
worktree inside the main checkout's ignored directories.

Compiled caches behave the same way. Two worktrees sharing a `target/` or `.next`
directory will corrupt each other's build output. Keep them separate.

## Use them to compare revisions

This is the least obvious and most valuable use:

```sh
git worktree add ../repo-before v1.4.0
git worktree add ../repo-after  v1.5.0
```

Two checkouts, two terminals, same repository. Run the suite in both, or diff
their generated output, without stashing or committing anything. Bisecting a
regression by hand in one checkout means stashing repeatedly; here it means
running in both directories at once.

## Cleaning up

Worktrees accumulate silently:

```sh
git worktree list
git worktree prune          # forget directories that no longer exist
git branch --merged         # branches whose worktree has gone
```

Prune after deleting a directory by hand, or `git worktree list` will keep
listing a path that is not there and commands that take a worktree will fail
confusingly.

## When not to use one

- A single task, one branch: just work in the checkout.
- Uncommitted changes you intend to bring across: commit, branch, then add the
  worktree. A worktree does not carry uncommitted work.
- Untracked files: same. They belong to the directory they are in.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I will just stash and switch." | Stash conflicts and forgotten stashes cost more than a worktree. |
| "It is only a small task." | Then the worktree is overhead; work in place. |
| "The worktree works without installing." | It does not, and the error message will not say so. |
| "I will delete the folder, that is enough." | Git keeps the record. Run `git worktree prune`. |
| "I can move uncommitted changes over." | You can copy them, and you can also lose them. Commit instead. |