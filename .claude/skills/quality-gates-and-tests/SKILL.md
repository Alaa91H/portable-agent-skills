---
name: quality-gates-and-tests
description: Use when setting up CI gates, E2E tests, coverage targets, or judging test strength.
---

# Quality gates and tests

## Coverage is not the goal, and 100% is not the target

Coverage measures **which lines executed**. Correctness measures **whether
execution produced the right result**. These are different questions, and a suite
can score 100% on the first while scoring zero on the second:

```python
def test_discount():
    calculate_discount(order)          # executed
                                     # nothing asserted
```

That test passes on a function that returns `None` for every input. It raises
the coverage number and lowers the confidence. Driving coverage to 100% by
writing assertion-free tests is worse than leaving the gap visible, because it
converts a known weakness into a hidden one.

So: **coverage is a floor, not a target.** Its real job is to find code nobody
ever runs. Its value collapses the moment it becomes a number to optimise.

## What actually measures test strength

Mutation testing asks whether your tests would notice a defect, by breaking the
code on purpose and checking that something fails.

| Score | Meaning |
| --- | --- |
| mutation score high | The suite detects real defects. Coverage is incidental |
| mutation score low, coverage high | The suite executes code and ignores its output. This is the dangerous case |
| mutation score low, coverage low | Honest. Nothing is pretending |

A single mutant that survives is a specific, actionable finding: this test does
not check that value. It is worth more than the entire coverage dashboard, and
it takes less time to obtain.

Cheaper proxies, in order of usefulness per hour:

1. **Assert on the return value, not just the absence of an exception.** Most
   weak suites stop at "it did not crash".
2. **Add one test for the boundary.** Off-by-one lives at the edges and nowhere
   else.
3. **Delete a line and see if a test fails.** If nothing fails, you have found
   the real gap, in two minutes, with no tooling.

That third check is worth doing by hand regularly. It is the cheapest available
answer to "are my tests actually testing anything".

## A gate that cannot fail is worse than no gate

The most expensive failure in a quality gate is the one that has stopped working
and still reports agreement. This repository found three of them in a single
session: a CRLF detector whose regex could never match, a file list built with
colons and split on whitespace, and an equality test against a heading format
that never occurred.

Every gate needs, before it is trusted:

- **A planted failure.** Break something the gate checks, confirm it fails, undo
  the break. A gate never seen failing is an untested gate.
- **An exit code that is actually checked.** Not "ran", not "printed something".
  If the workflow does not inspect the status, the gate is decoration.
- **A failing case that is fast to trigger.** A gate you cannot test is a gate
  you cannot trust.

The pattern is worth generalising beyond CI: any check that only ever runs on
passing input is not a check, it is a ritual.

## Test at the level where the defect lives

| Defect type | Level that catches it |
| --- | --- |
| Wrong arithmetic in a function | Unit |
| Wrong interaction between two services | Integration, with real boundaries |
| The flow is unreachable from the UI | End-to-end |
| The request is malformed | Contract test against the real schema |
| Performance regression | Load test |

Unit tests alone give a fast, precise, honest signal about the parts. They say
nothing about whether those parts are wired together correctly, and that wiring
is where production incidents actually come from.

E2E tests earn their cost by exercising the paths that only exist once everything
is assembled. That means the real path a user takes, with real data, through the
real boundary. An E2E test that calls the handler directly is a unit test that
happens to be slow.

## Flaky tests destroy the signal

A gate with a 3% failure rate gets retried, then ignored, then removed. The suite
loses its meaning before any defect is found.

The only honest causes, and each needs a different fix:

| Cause | Fix |
| --- | --- |
| Real race condition in the code | Fix the code. The test found a defect |
| Timing assumption in the test | Wait for a condition, not for a duration |
| Order dependency | Isolate state between tests |
| Shared external service | Own the fixture, or test at a level below it |
| Genuinely intermittent defect | Quarantine it, file it, and do not pretend it passes |

A retried-then-passed test is not a pass. It is a measurement of how often your
suite is wrong, and that number is worth tracking.

## Where to put the bar

The number that matters is not a percentage, it is **what failure would reach a
user**. Set the bar where that answer is reachable:

- Trivial formatting and lint: warn, do not block
- Correctness and security: block, always, no exceptions
- Performance: block on a regression threshold, not on an absolute number,
  because machines differ
- Style preferences: never block. A blocking style gate produces a culture of
  disabling gates

And keep the fast tier fast. Full lint, unit, and build on every commit; E2E and
load on a schedule or on pre-merge. A suite that takes forty minutes gets run
once a week, which is worse than a suite that takes three minutes and gates every
commit.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Coverage is at 100%." | Lines executed. Try mutating one and see whether anything fails. |
| "Add an assertion to this test." | Assert the return value. Otherwise you tested that it did not crash. |
| "The gate passes, so it works." | A gate never seen failing is untested. Plant a failure. |
| "E2E is too slow to run." | Run it on a schedule, and keep the fast tier blocking. |
| "Just retry the flaky test." | A retried pass is a measurement of your suite's error rate, not a result. |
| "The test covers the happy path." | Then it does not cover the case that is broken in production. |
| "We will add tests later." | Later is after the incident that made them obvious. |
| "Set the threshold to 80%." | A number nobody can explain will be met by writing tests nobody reads. |