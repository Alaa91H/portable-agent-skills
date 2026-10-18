---
name: writing-acceptance-criteria
description: Use when a requirement is ambiguous, when defining done, or before writing tests, so that scope and edge cases are pinned down first.
---

# Writing acceptance criteria

## The shape

Acceptance criteria exist to answer one question: how would two people who disagree about this feature decide who is right? If both would accept the same evidence, the criteria are done.

Write each one as a concrete statement with an observable outcome:

```markdown
- When a webhook is delivered twice with the same event id, the second delivery
  is discarded and no downstream side effect occurs twice.
```

That is checkable. "Webhooks should be idempotent" is a wish, not a criterion.

## Given / when / then, with the unhappy path included

Use the shape, then cover the cases that actually generate disagreement:

- **The happy path.** The case the request describes.
- **Empty.** No input, no list, first run ever.
- **Boundary.** Zero, one, the maximum, one past the maximum.
- **Malformed.** The input the parser should reject.
- **Duplicate and concurrent.** The same thing arriving twice, or two callers at once.
- **Partial failure.** Step three of four fails. What is the state? What is visible?

Most real disagreements are about the last three, which is why they are listed.

## Name the non-goals

Write what this change deliberately does not do. This is the highest-value line in the document and the one most often omitted:

```markdown
Not in scope: bulk import, CSV export, and changing the existing list ordering.
```

Without it, the reasonable reading of "add filtering" includes all three, and the work is judged against a scope nobody agreed to.

## Ask one question, not five

Ambiguity has a cost. Resolve it by asking about the decision that changes the most work, and state your assumption for the rest.

> Filter applies to the current page only, or to the whole result set? Assuming current page unless you say otherwise.

That is a question and a default, so the user can answer one word or say nothing. Five open questions, none with a default, converts your uncertainty into their workload.

Prefer this ordering:

1. State the assumption you will proceed under.
2. Ask the question that would invalidate the most work.
3. Note the rest, and proceed.

## Decide before implementing, not after

Criteria written after the code exists are a description of what happened, and reviewing them produces only confirmation. The value of the document comes entirely from being written while the implementation is still hypothetical.

If you notice yourself writing criteria after the first line of production code, stop. The remaining code is now unverified against anything.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The user already knows what they want." | They know the goal. The boundary cases are where the work lives. |
| "This is obvious, I will not write it down." | Obvious to you, unstated to everyone reviewing it in three weeks. |
| "I will write them after, faster." | After is too late to change the work they describe. |
| "More criteria is always safer." | Unbounded criteria are indistinguishable from no decision. Cover what changes the design. |
| "Testing is the same as acceptance criteria." | Tests check what you implemented. Criteria decide what should exist. |