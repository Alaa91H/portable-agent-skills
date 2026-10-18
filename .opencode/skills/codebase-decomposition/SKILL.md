---
name: codebase-decomposition
description: Use when a file has grown large, or deciding where behaviour belongs.
---

# Codebase decomposition

## Size is a symptom; the disease is unrelated reasons to change

A large file is not a problem because of its length. It is a problem because it
has accumulated **several unrelated reasons for you to open it**, and those reasons
change at different times, by different people, for different reasons.

That is the real test, and it is measurable:

> Count the distinct reasons to edit this file in the last year. If more than one,
> it is not cohesive, regardless of its line count.

A 900-line file with one reason to change is fine. A 200-line file that must be
edited for three unrelated reasons is worse, because every one of those edits risks
a conflict with the others.

```sh
# the diagnostic, before any judgement about length
git log --format='%s' --since='1 year ago' -- src/payments.ts \
  | sed 's/^[a-z]*(//;s/):.*//' \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head
```

If the top of that list is one dominant reason, leave it alone.

## Split by change axis, not by noun

The most common mistake is grouping by what things **are** — `models/`,
`services/`, `handlers/` — which produces a structure where any one feature is
scattered across six directories and every change touches all of them.

Split by **what changes together**:

```
# scattered: one feature, six folders
src/models/payment.ts
src/services/payment.ts
src/handlers/payment.ts
src/utils/payment-helpers.ts
src/validators/payment.ts
src/events/payment.ts

# cohesive: one feature, one place, one reason to change
src/payments/
  model.ts
  service.ts
  http.ts
  schema.ts
  events.ts
  index.ts        # the only public surface
```

The test is the diff. In the second layout a payment change is one directory. In
the first it is a commit that touches six unrelated-looking paths, and merge
conflicts scale with the number of paths touched.

This is usually called vertical slices. It inverts the more familiar layering, and
the reason it wins is simple: **files change together, so they belong together.**

## Depth beats breadth

A module should be narrow to enter and deep to use. That means an `index.ts` with
few exports and real implementations behind it, not a barrel that re-exports
everything.

```ts
// wide and shallow: the caller must know the internals to use this
export { PaymentService } from './service'
export { PaymentSchema } from './schema'
export { validatePayment } from './validate'
export { PaymentRepository } from './repo'

// narrow and deep: the caller needs one name
export { createPayment, refundPayment } from './public'
```

The second is better because it is **changeable**. Everything behind `index.ts`
can be reorganised without touching a single caller. A wide barrel is a contract
you cannot revise without a breaking change, which is the opposite of what a
boundary is for.

## The `utils` dumping ground

A shared file attracts code that has no other home, which makes it shared by
accident rather than by design.

```
utils/helpers.ts   1,200 lines
  formatDate()          used by 3 modules, belongs in time
  validateEmail()       used by 1 module, belongs beside it
  retry()               used by 2 modules, belongs in networking
  legacyThing()         used by nobody, delete it
```

Shared is not a reason. Ask *which module owns this concept* — the answer is
almost always a real module that should expose it. `utils` should be nearly empty
by the time you are done, and its existence should be a question rather than a
destination.

If something genuinely resists having an owner, be honest about it: it is
probably a data structure with no behaviour, and it belongs next to the thing
that constructs it.

## Do not split what is already cohesive

Refactoring for its own sake is not free. Every seam you introduce is a place
where behaviour can leak, and it is a thing a reader must now understand.

```
400 lines, one feature, changed weekly by one team   ->  leave it
400 lines, three features, changed by three teams    ->  split it
180 lines, three features, rarely changes            ->  splitting it is churn
```

The commonest bad refactor is the one done to satisfy a line-count rule. It
produces three cohesive-looking files that share a mutable helper, which is worse
than the original because it now looks finished.

## Make the seam explicit

When two things talk across a boundary, say so. Implicit coupling is what makes
a codebase resist change, because nothing records the dependency.

- **One direction of dependency.** Modules point at the leaf, never at each other.
- **Pass data, not reach-through.** A helper that imports four modules to save a
  parameter is not a helper.
- **Name the contract, not the implementation.** If a caller needs a specific
  method, depend on that; if it needs to know the storage shape, the boundary is
  in the wrong place.

```
Before   order.ts  ->  database.ts ->  utils.ts ->  payments/service.ts
After    order.ts  ->  payments/service.ts   (one edge)
```

Dependencies that fan out are where coupling hides, because no single file looks
entangled.

## Extract to a named concept, not a verb-shaped helper

When you pull something out, the name is the design decision.

```
bad      doThing(), handleStuff(), process(), helper2()
good     resolvePaymentIntent(), assertRetryable(), SessionCache
```

A vague name means the boundary has not been thought through yet — you moved code
without deciding what it is. If you cannot name it, do not extract it; the
placement question is still open.

## Sequences, not arbitrary sizes

A file's natural units are usually not equal, and forcing them to be is a
false economy.

```
Good:  model.ts  (300)  service.ts (450)  http.ts (120)  index.ts (30)
       sizes differ because the concepts differ

Bad:   part1.ts (300)  part2.ts (300)  part3.ts (299)
       equal sizes, and none of them is a concept
```

`part1` is a file that must be read to know whether it contains what you need. It
converts "this file is too long" into "I do not know which file has the code",
which is strictly worse for a reader, and slightly better for nobody.

## Test the seams, not just the parts

After splitting, the behaviour should be identical and the tests should still
pass without modification. If a test needed editing, the split moved a decision,
not just code — which is fine, but it must be a decision you can name.

```sh
# the strongest signal that a split was behaviour-preserving
git diff --stat -- '*test*'    # should be empty
```

An empty test diff is the evidence. Without it you have refactored and re-tested,
which is two different claims, and only one of them was verified.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "It is over 500 lines, so split it." | Length is a symptom. Count the reasons to change instead. |
| "Grouping by type keeps things tidy." | It scatters one feature across six folders and maximises conflicts. |
| "Shared code belongs in utils." | Shared is not an owner. Ask which module owns the concept. |
| "The barrel export makes it convenient." | It is a contract you can never revise. Expose a narrow surface. |
| "Extracting the function was the refactor." | Then you moved code without deciding what it was. Name it. |
| "Equal-sized files are tidy." | They are not concepts, so nobody can guess which one to open. |
| "Splitting now is cheap." | Every seam is a place behaviour leaks. Split for a reason, not a number. |
