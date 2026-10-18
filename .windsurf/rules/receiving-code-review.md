---
trigger: model_decision
description: "Use when code-review comments have arrived, especially when they conflict with each other or with the implementation."
---


# Receiving code review

## Sort every comment before acting on any

Comments arrive mixed. Acting on them in arrival order means a naming preference
gets the same attention as a data-loss defect. Classify first:

| Class | Test | Response |
| --- | --- | --- |
| **Correctness** | Can this input or state break something? | Fix now, regardless of effort |
| **Contract** | Does this break something outside this change? | Fix now |
| **Maintainability** | Will this be harder to change correctly later? | Fix, or trade explicitly |
| **Preference** | Would a reasonable reviewer have said otherwise? | Decline briefly, or accept if it is cheap |

Preferences are not worthless. They are not urgent, and treating them as urgent
is how a review turns into an argument.

## Verify before you concede

You know more about this code than the reviewer does, and comments are often
right about the code and wrong about the context.

```sh
grep -rn "processPayment" --include=*.ts src/
npm test -- payment.test.ts
```

If a comment claims a caller is missing, look for the caller before changing the
signature. A confident comment with a wrong premise still produces a wrong fix.

## Conflicting comments

When two reviewers disagree, do not pick the one you prefer or the one that
arrived first. Surface the conflict with the specific question:

> Reviewer A wants the validation in the handler, B in the repository. The
> difference matters when the call comes from the worker. I have put it in the
> repository so both entry points get it. Does that resolve your concern?

That question is answerable. Choosing unilaterally is how a review decision ends
up owned by nobody.

## Every comment closes

Before you consider the review handled, each comment is in exactly one state:

- **Addressed**, with the commit.
- **Declined**, with the reason, in one line.
- **Deferred**, with an issue that says so.

"Unaddressed" is not a state. It reads identically to "missed", and the reviewer
has to spend a second round to find out which.

## Pushing back well

Concede the valid part, state the disagreement, and give the consequence you are
reasoning from. Not:

> I don't think this is a problem because the code works.

Instead:

> The current shape is deliberate: the cache is per-request, not per-process.
> Sharing it would need invalidation on every write, which is the bug this
> change fixes elsewhere. If you think the cross-request case is worth that,
> I will change it.

That gives the reviewer something to decide rather than something to repeat.

## What not to do

- Do not fix everything without reading. Unreviewed mechanical fixes in a large
  diff hide real regressions.
- Do not revert a change you cannot explain to keep a reviewer quiet.
- Do not answer a correctness comment with a test you added but did not run.
- Do not treat agreement as closure. If you agree and do not change anything,
  say why in the thread.
