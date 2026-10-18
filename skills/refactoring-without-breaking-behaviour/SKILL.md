---
name: refactoring-without-breaking-behaviour
description: Use when restructuring existing code, reducing duplication, or modernising an interface, where existing tests must keep passing.
---

# Refactoring without breaking behaviour

## Pin the behaviour before you touch the structure

Refactoring changes how the code works while leaving what it does unchanged.
That is only safe if you can tell when it changed, which means you need a test
first.

```sh
npm test -- --coverage src/invoice     # what is pinned, and what is not?
```

Where coverage is absent, write a **characterisation test**: run the existing
code, record what it actually does, lock it in. It records current behaviour,
not intended behaviour, and that is correct here, because current behaviour is
what callers depend on today.

Where you cannot pin behaviour, narrow the refactor until you can. A structural
change to untested code is a behaviour change with extra steps.

## Small reversible steps

Each step should be one of: rename, extract, inline, move, or change a
signature. Not two at once, because when the suite goes red you then have two
suspects instead of one.

Run the suite after each step. If it takes ninety seconds, that is ninety seconds
per step, and it is the entire cost of knowing that your refactor is safe. Do
not batch.

Every step should be independently revertible with `git revert`. If reverting a
step would undo unrelated work, the steps are not independent and you should
split the change.

## Delete more often than you extract

Duplication is usually a symptom that something does not exist yet. Before
extracting a third copy of a block, ask whether there should be a type, a
config entry, or a strategy at all.

```ts
// Three call sites that differ only by a callback
const retry = makeRetry({ attempts: 3, backoff: 'exponential' })
```

If the three versions differ in *behaviour* rather than *data*, extract a
parameter. If they differ in *strategy*, extract an interface and inject it.
Pulling three near-identical blocks into one function with two boolean flags
produces a function with six branches that nobody will modify safely.

When the honest answer is that code should be deleted, delete it. Check first:

```sh
grep -rn "legacyExport" --include=*.ts src/
```

## Renames: know which kind you are doing

Safe to do in one step:

- A private function, variable, or local with no external reference.
- A file rename that the import graph update covers.

Requires compatibility steps:

- A public export. Add the new name, keep the old one as a re-export, find and
  migrate callers, then remove the old name in a separate change.
- Anything reflected on, serialised, or looked up by string at runtime.

## When the test suite is the thing that is wrong

Sometimes refactoring reveals that the tests are the obstacle. Before treating
them that way, confirm which it is:

| Symptom | Likely cause |
| --- | --- |
| One test fails after a structural change | The refactor changed behaviour. Usually the refactor is wrong. |
| Many unrelated tests fail | Shared setup or ordering. Fix the setup. |
| A test fails only in full-suite runs | Order dependence. That is a real bug in the suite. |

Do not "fix" a failing test by rewriting its assertion to match the new output.
That is the mechanism by which a refactor silently becomes a behaviour change.

## Know when to stop

Stop and report when the refactor requires changing behaviour, when the tests
are too weak to detect a regression, or when the payoff is a tidier file rather
than a structural improvement. Restructuring working code on request is the most
common way to introduce a defect into a system that did not have one.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I will just update the tests as I go." | Then you cannot tell a deliberate change from a regression. |
| "The tests are slow, I will run them at the end." | At the end you have one suspect and a large diff. |
| "This is only a rename." | Only if nothing outside the module can observe it. Check. |
| "I will extract this block, it is duplicated." | Check whether the copies differ in behaviour, not in naming. |
| "It is only cleanup." | Cleanup that fails a test is a behaviour change wearing a disguise. |