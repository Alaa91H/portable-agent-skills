---
description: "Use when adding or changing a feature or bugfix that needs tests."
---


# Test driven development

## The rule

No production code is written before a test exists that fails without it.

The failing test is not a formality to be written alongside the code. It is what
proves the test measures the behaviour rather than restating the implementation.
Write it, run it, and read the failure before writing the fix.

## The loop

**Red.** Write one test for one behaviour. Run the suite. Confirm it fails, and
confirm it fails *for the reason you expect*:

```sh
npm test -- retry.test.js
# Expected: AssertionError: expected 2 attempts, received 0
# If it fails with a TypeError or a missing import, the test is wrong, not the code.
```

A test that fails for the wrong reason has not tested anything yet.

**Green.** Write the minimum that makes it pass. Minimum means minimum: no
defensive branches for cases you have not specified, no parameters for future
use. Resist it explicitly, because it is the most reliable form of scope creep
and it is invisible in review.

**Refactor.** Now improve the structure with the safety net in place. Remove the
duplication the test let you notice. Change no behaviour. Re-run the suite after
each step, not at the end.

Repeat. One behaviour at a time.

## A test that is hard to write is telling you something

Stop and treat this as a design signal, not a testing inconvenience:

- Five mocks needed to test one function means it is reaching for five things it
  does not need.
- A test needs `sleep` to pass means behaviour depends on timing that is not
  part of the contract.
- You cannot name the test without naming three internal functions means there
  is no unit here; you are testing through a seam that does not exist yet.

In each case the fix is in the production code. Test-first is not a discipline
imposed on good design; it is the technique that surfaces this pressure early.

## Tests that do not earn their place

- **Testing the framework.** Asserting that `Array.prototype.map` maps.
- **Asserting on mocks.** Asserting that the code called a mock you configured
  tests your own setup, not behaviour.
- **Snapshot everything.** A snapshot with no reviewer is a change-detector that
  approves whatever it is shown.
- **Order-dependent tests.** If test B fails when A runs first, the second test
  is the broken one.

## When the test comes first

For a bug, the failing test is the reproduction, and it is non-negotiable: write
the test that fails on the current code first, confirm the failure, then fix.
A fix applied before the reproduction exists is a guess, and a guess that
happens to make the symptom disappear has left the cause in place.

## Legacy code with no tests

Do not start by writing a full suite. Start with a **characterisation test**: run
the existing code, record what it actually does, and lock that in. It documents
current behaviour rather than intended behaviour, which is the point, because
right now the behaviour is what users depend on.

Then change one thing at a time with that net under you. Coverage is a side
effect of this process, not a target to chase.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I will add tests after, it is faster." | Tests written after encode the implementation you happened to write, bugs included. |
| "This is too trivial to test." | Trivial code still breaks. The cost is a name and an assertion. |
| "The test is basically done, just needs the code." | If it passes without the code, it asserts nothing. |
| "I am out of time." | Untested code ships a defect that costs more to find than the test would have. |
| "I will mock it to keep the test simple." | Every mock is a claim about a dependency being correct. Check the claim or do not make it. |
| "Coverage is too low." | Coverage measures which lines ran, not whether anything was verified. |
