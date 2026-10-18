---
trigger: model_decision
description: "Use when a branch is ready to merge, hand off, or open a pull request."
---


# Finishing a development branch

## The order matters

Run these in sequence. Skipping ahead is how branches arrive at main with a
failing test and a "should be fine".

**1. Working tree is clean and current.**

```sh
git status --short          # nothing uncommitted, nothing untracked that matters
git fetch origin
git log --oneline origin/main..HEAD
```

**2. The tests pass, on your branch, right now.**

```sh
npm ci && npm test
```

Run the install as well as the suite. A passing suite on a stale `node_modules`
is a common false positive after a dependency change.

**3. Re-read the whole diff.**

```sh
git diff main...HEAD
```

You have read this diff while writing it, when you knew what you meant. You
have not read it as a reviewer, which is the only reading that finds the
leftover `console.log`, the unrelated reformat, and the change you made in hour
one that hour six made irrelevant.

**4. Rebase onto the latest main.**

```sh
git fetch origin && git rebase origin/main
```

Rebase now, while the branch is yours alone, rather than at review time when
rewriting history touches someone else's work.

**5. Push and open the pull request.**

```sh
git push -u origin HEAD
gh pr create --title "..." --body-file /tmp/pr.md
```

**6. Watch CI rather than assuming it.**

```sh
gh pr checks --watch
```

## Choosing squash, merge, or rebase

| Strategy | Use when | Cost |
| --- | --- | --- |
| **Squash** | Feature branches, anything reviewed as a unit | Loses commit-level history; bisect suffers on short-lived branches |
| **Merge commit** | You want the branch boundary preserved | Noisy log on a high-traffic branch |
| **Rebase merge** | Default for shared long-lived branches | Linear history, but commit-level bisect of a fix is lost if squashed |

Default to squash for feature branches and rebase merge for everything else.
Whichever you pick, be consistent: an inconsistent history costs every future
reader who runs `git log`.

**Never force-push a shared branch.** Not to a branch someone else has, not to
`main`, not once. Use `--force-with-lease` rather than `--force` when you must
rewrite your own unpushed-elsewhere branch; it refuses if someone else has
pushed since you fetched.

## The pull request body

The same five sections every time, so reviewers know where to look:

```markdown
## What
The problem, then the change.

## Why this approach
The constraint that selected it; the alternative rejected.

## Not in scope
What you might expect and will not find.

## Verification
Exact commands run and their results.

## Risk
What breaks if this is wrong, and how a reader would notice.
```

## Handing off rather than merging

When someone else takes this branch, the writeup needs three more things: the
current state (what works, what is known broken), the next concrete step, and
the decisions you made that are not visible in the diff. The last one is the
expensive omission.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The suite passed earlier." | Earlier was before the last commit. Run it again. |
| "I will rebase after the review." | Then the rebase conflicts during review, with someone else waiting. |
| "It is a small branch, force-push is fine." | Small enough to finish properly, and it may not be. |
| "CI will catch it." | CI runs after the reviewer starts. Do not make them the first line of defence. |
| "I will write the PR description later." | Later means reconstructing it from a diff you no longer remember writing. |
