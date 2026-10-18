---
trigger: model_decision
description: "Use when a test fails, a build breaks, or behaviour is unexpected, and the cause is not yet known, before any fix is proposed."
---


# Systematic debugging

## The rule

Do not change code until you have a hypothesis you can disprove.

Editing to "see what happens" is not debugging. It produces changes you cannot
evaluate, and if one of them accidentally fixes the symptom you have destroyed
your evidence while keeping the defect.

## 1. Reproduce it deterministically

A bug you cannot trigger on demand cannot be diagnosed, and neither can its fix
be verified.

```sh
npm test -- --runInBand -t "retries three times"
```

If it reproduces only sometimes, capture the frequency before moving on. A
flaky symptom whose rate you know is a different investigation from one you do
not, and "flaky" is not a cause.

Reduce to the smallest input or command that still fails. Everything you remove
is a variable you no longer have to hold in your head.

## 2. Read the actual failure

Read the whole output, not the last line. Stack traces name the frames that
were executing; the top frame is frequently a caller you already suspect, and
the interesting frame is often deeper.

Distinguish these three, because they point at different places:

| What you see | What it means |
| --- | --- |
| `Error: ECONNREFUSED` | The connection was attempted and refused. A dependency is down or the port is wrong. |
| `Error: connect ETIMEDOUT` | Packets went nowhere. Firewalls, DNS, or an unreachable host. |
| `Error: getaddrinfo ENOTFOUND` | Name resolution failed. The host does not exist. |

An error you have seen before still fails for a new reason. Confirm the cause
rather than pattern-matching on the message.

## 3. Bisect the hypothesis space

Rank candidate causes by evidence, then eliminate rather than confirm. Ask what
would have to be true for a cause to be responsible, then look for that.

Two techniques that pay for themselves quickly:

- **Bisect.** `git bisect start`, mark current `bad`, an older revision `good`.
  Git walks you to the first bad commit in about log2(n) steps.
- **Widen the blast radius.** If the failure only happens with two callers,
  reproduce it by calling both. If it only happens in production, the difference
  is in the environment, and the environment is the suspect list.

## 4. One hypothesis at a time, stated in falsifiable form

Bad: "Something is wrong with the cache."

Good: "The cache is not being invalidated because the write path updates
Postgres but never calls the invalidation hook, which `grep` can confirm."

A falsifiable hypothesis names the observation that would disprove it. If you
cannot describe what you expect to see when you are wrong, you cannot tell
success from coincidence.

## 5. Fix the cause, not the symptom

The symptom is what you observed. The cause is what produces it. A fix aimed at
the symptom is a coincidence that will recur with different inputs.

The check: after the fix, can you explain why the symptom followed from the
defect? If not, you have suppressed it, not fixed it.

## When to stop and ask

Stop investigating and bring in a human when:

- You have two or more hypotheses and no observation that separates them.
- The reproduction needs production data or credentials you do not have.
- The fix would change behaviour someone depends on and you cannot verify it.
- Three consecutive fixes have each moved the symptom without explaining it.

These are not failures. An accurate report of "the failure occurs when X, and
here is what I ruled out" is more useful than an hour of silent changes.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Let me just try changing this." | A change you cannot explain is a change you cannot evaluate. |
| "It must be a caching issue." | Caching is a guess with good odds. Confirm it before building on it. |
| "The error is unrelated, probably flaky." | If it is flaky, it is a defect with a rate. Find the rate. |
| "I will fix it and see if it stops." | Then you will not know what fixed it. |
| "Adding a retry will get us moving." | Retries convert a fast failure into a slow one and hide the cause. |
| "The test was wrong." | Possible, and worth checking deliberately, not assumed to avoid the work. |
