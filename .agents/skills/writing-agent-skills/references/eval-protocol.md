# Evaluation protocol

A skill written from intuition is a hypothesis. This is how you test it.

- [ 1. Find the failure ](#1-find-the-failure)
- [ 2. Write the trigger set ](#2-write-the-trigger-set)
- [ 3. Test the wording ](#3-test-the-wording)
- [ 4. Write the minimum ](#4-write-the-minimum)
- [ 5. Verify no regression ](#5-verify-no-regression)

## 1. Find the failure

Run a representative task with **no skill present**. Record what the agent does
wrong specifically: which step was skipped, which instruction was ignored,
which part of the output was the wrong shape.

If nothing goes wrong, you do not have a skill to write. Delete the idea.

Build three scenarios at minimum, one per distinct failure mode you observed.
Vary the task, not the wording of one task.

## 2. Write the trigger set

Generate roughly 20 queries: 8 to 10 that should trigger, and 8 to 10 that
should not.

**The negatives are where the value is.** They must be near-misses that share
keywords with the skill but need something different:

```yaml
# For a PDF skill
should_trigger:  "extract the table from report.pdf"
should_not:      "write a python function that generates a pdf"   # shares "pdf", needs the other half
should_not:      "read this csv into pandas"                       # shares "extract", different format
```

A negative that shares no keywords tests nothing, because it would never have
triggered regardless of description quality.

Queries must be substantive. "Read file X" is a poor test case: an agent handles
that without consulting any skill, so it tells you nothing about the description.

## 3. Test the wording

Run each query with a single-shot call or a fresh subagent, several times per
variant. A single sample is not a measurement, and a skill that triggers 60% of
the time feels fine until you depend on it.

Include a **no-guidance control**: the same query with no skill at all. If the
control does not exhibit the failure, the scenario is wrong and must be replaced.

Read every flagged match by hand. A template echoing its own example text
counts as a hit and will distort your result if you let it.

Watch the variance: five different interpretations across five runs means the
wording is not binding.

## 4. Write the minimum

Write the least that changes the recorded failure. Resist adding rules for
adjacent situations you have not observed failing; that is how a skill grows
into a page of generic advice nobody follows.

If the agent writes the same helper script independently in all three
scenarios, that is a strong signal the skill should ship that script rather than
describe it.

## 5. Verify no regression

- Re-run the full trigger set, not only the positive cases. A description that
  was widened to fix under-triggering frequently over-triggers elsewhere.
- Confirm the fix holds on the original failing scenario.
- Check that adjacent skills did not start or stop firing.

## On frequency

Measure the skill's trigger rate across the set. A well-scoped skill sits high on
its positives and near zero on its near-miss negatives. A skill that scores well
on both halves of the positive set is usually describing a category rather than
a situation.

Split the tuning set from the held-out set, and choose between candidate
descriptions on the held-out score. Selecting on the same data you tuned against
produces a description that fits your examples rather than the task.

## Budget

Keep this proportionate. A small behavioural nudge does not need twenty
scenarios. The protocol matters most for skills that will be loaded constantly,
and for descriptions that sit next to several similar skills and will compete
with them.