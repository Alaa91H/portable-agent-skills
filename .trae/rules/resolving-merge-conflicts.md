---
description: "Use when git reports a conflict, a rebase stops, or markers remain."
---


# Resolving merge conflicts

## Start by understanding what you are merging

A conflict is not damage. It is git telling you it cannot decide whether two
changes are compatible. The three-way view is what makes it tractable:

```sh
git status                    # which files, unmerged
git diff --name-only --diff-filter=U
git log --merge -p            # commits on both sides since the merge base
```

In a conflict block, each marker is a different version:

```text
<<<<<<< HEAD
the change from your branch
=======
the change from the branch being merged
>>>>>>> feature/other
```

`HEAD` is *yours*, the other side is *theirs*. That mapping is the single most
common thing to get backwards.

To see the ancestor version too, which is usually the missing piece:

```sh
git checkout --conflict=diff3 -- <file>
```

This rewrites the markers to include the base, and the base is what tells you
which side actually changed.

## Resolve intent, not text

Read all three versions before choosing. The correct result is frequently neither
side: both branches changed the same region for different reasons, and the
answer is both changes.

If one side refactored a function that the other side called, taking either side
whole breaks a caller in one direction or the other. Find the caller:

```sh
grep -rn "functionName" --include=*.ts src/
```

Then write the result that satisfies both intents, and confirm the callers still
typecheck.

## Files you must not resolve by hand

| File | What to do instead |
| --- | --- |
| `package-lock.json`, `yarn.lock`, `Cargo.lock` | Abort, run the package manager to regenerate, redo the merge |
| `*.pb.go`, generated clients, `dist/` | Regenerate from the merged source |
| `.min.js`, sourcemaps | Regenerate |
| Schema migrations, both sides adding one | Write a third migration that does both, in the right order |

Hand-merging a lockfile produces an install that resolves differently on every
machine. Abort and redo:

```sh
git merge --abort
```

For a rebase, `git rebase --abort`. Then take one side cleanly and apply the
other deliberately.

## During a rebase, the commit is not yours yet

In a rebase conflict, `HEAD` is the commit you are replaying *onto*, not your
original branch tip. The semantics invert relative to a merge, which is why
rebase conflicts feel more confusing than merge conflicts.

```sh
git status                   # "You are currently rebasing on <sha>"
git rebase --show-current-patch    # read the commit you are replaying
git rebase --continue
git rebase --skip            # drop this commit entirely, deliberately
```

Squashing during a rebase means `git add` then `git rebase --continue`; adding
alone repeats the commit.

## Verify the resolution

A resolved conflict that compiles is not necessarily correct. Run:

```sh
npm test
npm run build
```

and then read the file one more time looking for the two things the markers
cannot detect: a duplicated block that merged cleanly from both sides, and a
logic path that only existed in the commit you were replaying.

Search for what should not survive:

```sh
grep -rn "^<<<<<<<\|^=======$\|^>>>>>>>" .
```

Leftover markers produce a file that parses in some languages and fails at
runtime in others. The grep is cheap and it is the last thing worth doing.

## When to abandon and restart

Aborting is cheaper than finishing a bad resolution:

- More than a handful of files conflict with substantive changes on both sides.
- The conflict is in generated files across the board, so the merge was never
  going to be clean.
- You are resolving in a file you have never read.
- Three attempts have each produced a result you are not confident in.

```sh
git merge --abort
git rebase --abort
```

Then rebase one branch onto the other deliberately, in smaller commits.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Take theirs, that is what we want." | You may be discarding the change you spent a day on. Diff first. |
| "It is only whitespace." | Whitespace conflicts usually mean a reformat, which is why the rebase should not have been mixed with the feature. |
| "I will edit the lockfile to match." | Hand-edited lockfiles resolve differently per machine. Regenerate. |
| "The file looks fine now." | Read it once more for blocks that merged cleanly from both sides. |
| "I will resolve it and check later." | The check is the resolution. `git rebase --continue` is the commit. |
