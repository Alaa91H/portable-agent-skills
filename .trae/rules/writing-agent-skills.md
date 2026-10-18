---
description: "Use when authoring or debugging an agent skill, or when triggers are wrong."
---


# Writing agent skills

## Three levels of disclosure

A skill is read in three stages, and the design problem is keeping each one as
small as it can be:

1. **Metadata** — `name` and `description`. In context at *every* model step for
   *every* installed skill. This is what makes 200 skills affordable.
2. **Instructions** — the `SKILL.md` body. Read once, when the skill triggers. It
   stays in the conversation afterwards, so it is never re-read.
3. **Resources** — `references/`, `scripts/`, `assets/`. Cost nothing until
   touched.

The consequence is that bundled context is effectively unbounded while your
context window is not. Anything you can move to level 3 should be moved.

## Start from a failure, not from a topic

The most reliable way to produce a useful skill is to watch an agent get
something wrong without it:

1. Pick a representative task.
2. Run it with no skill present.
3. Record exactly what went wrong. Not "the output was not great" — which step
   was skipped, which instruction was ignored, which shape was wrong.
4. Write the minimum that changes that behaviour.
5. Re-run and confirm the failure is gone and nothing else regressed.

A skill written from a list of topics is a hypothesis. A skill written against a
recorded failure is a fix. If you cannot describe the failure, you do not yet
have a skill; you have a documentation page.

## The description decides everything

Only metadata is always in context, so the description alone determines whether
a skill is ever loaded. Two rules, and the second one is counter-intuitive.

**Include the routing signal.** Concrete trigger keywords, file types, tool
names, and the literal error text an agent will actually see. If users hit
`ENOTEMPTY`, the description should contain `ENOTEMPTY`.

**Never summarise the workflow.** This is the trap. When a description describes
the *procedure*, the agent has a usable plan before opening the file, and takes
it. The body then becomes documentation nobody reads. Describe the trigger
surface, never the steps.

There is a fuller treatment with worked before-and-after examples in
`references/description-craft.md`. Read it when writing or fixing a description,
and when a skill triggers at the wrong times.

## Match the form to the failure

The same guidance helps or hurts depending on what went wrong. Pick the form
from the failure, not from habit.

| Observed failure | Correct form | Wrong form |
| --- | --- | --- |
| A rule gets skipped under pressure | A prohibition, plus a table of the rationalisations that will be reached for | "Prefer to..." |
| Output has the wrong shape | A positive contract: what the output *is*, its parts in order | A list of things not to do |
| A required element is omitted | A required slot in the template being filled in | Prose reminders |
| Behaviour depends on a condition | A conditional keyed to an observable predicate | An unconditional rule plus exemptions |

Prohibitions measurably backfire for output-shape problems: head-to-head tests
found they produced *more* unwanted content than an equivalent recipe, worse than
giving no guidance at all. Use them where a rule is genuinely being rationalised
away, and recipes everywhere else.

Two related findings: exemption clauses do not scope anything, and appending one
"unless it matters" clause to a working recipe makes it noisy. Explain the reason
for a rule in one clause instead; a bare all-caps `ALWAYS` does not survive
contact with a hard task.

## Choose how much freedom the instructions get

| Freedom | When | Form |
| --- | --- | --- |
| High | Several approaches valid, context decides | Numbered instructions |
| Medium | One pattern preferred, variation fine | Parameterised script |
| Low | Fragile, error-prone, order-critical | "Run exactly this. Do not modify it." |

A database migration is low freedom. A design review is high freedom.

For anything deterministic, ship a script. A bundled script is cheaper than
generated code, consistent between runs, and does not consume context. Then say
explicitly whether to **run** it (`Run <your-script>.sh to confirm`) or **read**
it (`Read <your-parser>.py for the algorithm`). Ambiguity here causes the agent
to read a script it should have executed.

## Do not write a skill for

- A one-off problem.
- A practice already documented authoritatively somewhere.
- A convention belonging in the project's `AGENTS.md`.
- **Anything mechanically checkable.** If a linter, a regex, or a validator can
  enforce it, enforce it. Documentation is for judgement calls.

That last one is the dominant failure mode of large collections: skills that
restate what CI already guarantees, spending context to be ignored.

## Reference files

Keep them **one level deep**. An agent reading `a.md`, which points at `b.md`,
may preview `b.md` with `head -100` and act on a partial file. Flatten it.

Split mutually exclusive paths, and give any reference past 100 lines a table of
contents so the agent can target a section.

## Verify

Mechanical conformance is enforced for you:

```sh
scripts/validate-skills.sh
```

It checks ids, frontmatter, allowed keys, `name` matching its directory, length
limits, flat metadata, and reference existence and depth.

It cannot tell you whether the skill is *good*. For that, run the failure-first
protocol. `references/eval-protocol.md` has the full procedure, including how to
build a trigger test set with near-miss negatives, which is the part most skill
authors skip and the part that catches mis-triggering between neighbouring
skills.
