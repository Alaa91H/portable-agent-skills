---
trigger: model_decision
description: "Use when a feature or branch is ready, before merging, to get it reviewed."
---


# Requesting code review

## Make the review possible first

Review fails on more than code. It fails on missing context, and the most common
reason a review is slow is that the reviewer has to reconstruct the intent.

Before asking anyone to look, be able to state in three sentences:

1. What problem this solves, and who felt it.
2. The approach chosen, and the alternative rejected.
3. What is deliberately not in scope.

If you cannot write those three sentences, that is the work still outstanding,
not the review's problem.

## Review your own diff first

The reviewer should find design problems, not typos. Run this pass before
submitting:

```sh
git diff main...HEAD --stat     # size and spread
git diff main...HEAD            # read it whole
git log --oneline main..HEAD    # does the history tell the story?
```

Check four things in that output:

- **Debug leftovers.** `console.log`, commented-out code, `.only` on a test,
  a hardcoded credential, a `TODO` with no issue.
- **Unrelated changes.** A drive-by reformat in a diff is noise the reviewer
  pays for and does not see.
- **The migration.** Schema change, lockfile, generated file: confirm each is
  intended and in the right order.
- **The commit history.** If it reads "fix", "fix2", "actually", the reviewer
  will reconstruct intent from the code instead.

## Size decides whether review is possible

Roughly: under 400 changed lines a review is thorough. Beyond about 800, reviewers
switch to skimming and approve the shape rather than the logic. This is why a
large change is better as a sequence of small ones, each independently mergeable
and individually reviewable.

If the change cannot be split, say so in the description and point the reviewer
at the specific decisions you most want challenged. Unreviewed-by-default is a
real risk and it belongs in the writeup.

## What the description must contain

Write it for someone who did not follow the work:

```markdown
## What
One paragraph. The problem, then the change.

## Why this approach
The constraint that selected it, and the alternative rejected.

## Not in scope
What a reader might expect but will not find.

## How it was verified
The exact commands run, with results. Not "tests pass" but the command and its
outcome.

## Risk
What breaks if this is wrong, and how to tell.
```

## When the review says something you disagree with

Verify before conceding, and concede before arguing. A comment is a claim about
the code, and you have more information about it than the reviewer does.

Say which, and be specific:

- "Correct, fixed in `<commit>`." Then fix it.
- "Correct, and I want to do it differently because `<reason>`." Then either
  change your mind on the reason being weak, or make the case on the reason.
- "I disagree, because `<specific consequence>`." A concrete consequence, not a
  preference.

Every comment ends in one of three states: addressed, declined with a reason, or
open with a follow-up. A comment silently ignored is indistinguishable from a
comment missed, and the reviewer cannot tell you which it is.
