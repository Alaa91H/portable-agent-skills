---
description: "Use when a function handles structured input, invalid input, numeric edge cases, or serialization, or when example-based tests keep missing real bugs."
---


# Property based testing

## When examples are structurally insufficient

Example tests check the inputs you imagined. Property tests check a rule across
inputs you did not, which is the point when the input space is too large to
enumerate: parsers, serialisers, validators, anything arithmetic, anything with
structured input.

Reach for it when a bug report describes a class of input rather than one
reproduction:

> "It breaks when the string contains a trailing comma." — that is 10^4 cases,
> and you have tested one.

## State the property, not the case

A property is an invariant that holds for every valid input. Examples test
points; properties test the space.

```ts
import fc from 'fast-check'

// Property: encoding then decoding returns the original value
fc.assert(fc.property(fc.string(), s => {
  expect(decode(encode(s))).toBe(s)
}))

// Property: a percent-encoded string never contains a raw space
fc.assert(fc.property(fc.string(), s => {
  expect(encode(s)).not.toContain(' ')
}))

// Property: parse never throws
fc.assert(fc.property(fc.string(), s => {
  expect(() => parse(s)).not.toThrow()
}))
```

The third is the one that finds bugs: it turns "it crashed once on a weird
input" into "it crashes on a class of inputs you can now see".

## Use a generator that produces *valid* input

The most common mistake is testing against `fc.string()` when the function
requires structure. Random strings spend their entire budget on inputs rejected
by the first validation check, and find nothing.

Build inputs from the grammar the function accepts:

```ts
const token = fc.record({
  key: fc.stringOf(fc.constantFrom(...ALLOWED), { minLength: 1 }),
  value: fc.integer({ min: 0, max: 2 ** 31 }),
})
```

Good generators make every generated input meaningful. If your generator can
produce nonsense most of the time, the test is slow and shallow.

## Shrinking is the reason to bother

When a property fails, the framework minimises the input before reporting it.
That turns:

```
Failed after 4000 examples. Counterexample: [A;r;p;9;$c]xyzz
```

into

```
Failed after 63 examples. Counterexample: "a,"
```

Shrinking works because the framework keeps halving while the property still
fails. Use it deliberately: do not reject a small input inside the property,
or you have disabled the mechanism and will be handed the unreadable counterexample.

## Reproducibility

Every property test must be reproducible, or it will be reported as flaky and
eventually ignored.

```ts
fc.assert(prop, { seed: 1712345678, numRuns: 1000 })
```

Run with `fc.configureGlobal({ seed: Date.now(), endOnFailure: true })` for
finds while developing, and pin the seed in CI so a failure reproduces exactly.

Record the counterexample as a fixed example in the suite. That fixed case plus
the property is the permanent regression test; the search is the tool that found
it.

## What property testing does not prove

It proves a rule holds across a sampled space. It does not prove the rule is the
rule you meant, and it does not cover interaction with state, timing, or the
network. Keep the example tests for the cases that matter specifically; use
properties to cover the space you cannot enumerate.

The usual split: properties for parsers, codecs, arithmetic and pure functions;
example tests for business rules where the interesting cases are enumerable.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I will just add a few more examples." | If the space is large, examples sample it and miss the rest. |
| "Fast-check is a dependency I do not want." | It is a dev dependency, and the property is the part you keep. |
| "The property is obvious, I do not need to assert it." | Then the test documents intent for the next reader and catches your own later edits. |
| "Shrinking is slow." | It runs once, on failure, against a counterexample you would otherwise debug by hand. |
