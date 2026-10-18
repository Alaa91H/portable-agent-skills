---
trigger: model_decision
description: "Use when an agent may invent facts, drift from the request, or output is ungrounded."
---


# Hallucination defense

## Scope

This covers **how the error is prevented**: why an unverified claim produces the
same feeling as a verified one, the order in which to resolve a
version-specific fact, and the structural habits that make an ungrounded claim
hard to state in the first place. It is written for engineering work, where the
failure is code written against an API that was renamed two majors ago.

For the **delivery** discipline — the Read/Stated/Inferred classification of what
you write, link and number handling, and confidence wording in research output —
see `evidence-first-writing`.

## Three failures, one confusion

They get treated as one problem and they are not, because the defences differ.

| Failure | What happened | Defence |
| --- | --- | --- |
| **Hallucination** | Invented a fact that does not exist | Ground every claim in a source you opened |
| **Confabulation** | Invented a plausible citation, API or path | Verify before asserting, never after |
| **Drift** | Answered a nearby question instead of the one asked | Restate the request, then check the answer against it |

Drift is the one people miss, because the output is usually *correct* — just
about the wrong thing. Correctness does not make it an answer.

## The root cause is not carelessness, it is unearned confidence

Nothing in your situation signals uncertainty. A name you half remember and a
name you know completely feel identical while producing them. So **"let me be
more careful" cannot work**, because there is no internal state to be more
careful from.

What works is structural: make the unverified claim **impossible to state**, or
impossible to leave behind.

## Ground every claim or mark it

The rule that does the work: **a claim is either sourced or labelled**. No third
state.

```
Grounded    `retry` takes 3 arguments as of 4.2  (src: node_modules/retry/index.d.ts:31)
Marked      I believe `retry` is 3-argument in current versions — UNVERIFIED, check before use
Open        Whether the CDC consumer tolerates out-of-order events — not answered
```

The second and third lines are as valuable as the first. An agent that labels its
uncertainty honestly is usable; one that does not is dangerous, because nothing
in the output distinguishes the two and the reader has to check everything.

**Never delete a marker to make output tidier.** An honest "unverified" costs one
line. A removed one costs a debugging session.

## Verify against the version you have, not the version you remember

The highest-risk content in any technical output is exactly the part that feels
most fluent: API names, parameter counts, flag spellings, error types, config
keys. This is where memory is worst and where it feels best.

Resolution order, and it is not negotiable:

1. **The lockfile** — the version actually pinned
2. **The installed package** — read its types or exports, not its documentation
3. **The documentation for that version** — not the latest version's page
4. **The changelog** — for anything released recently
5. **Your prior** — last, and labelled as such

```bash
# what version is actually here
node -p "require('./node_modules/express/package.json').version"
# does this symbol actually exist, with this signature
grep -rn "declare function retry" node_modules/retry/ --include=*.d.ts
```

Reading the installed package beats the documentation because the documentation
describes the version you are reading about, not the version you have. See
`up-to-date-tooling` for the discipline around this.

## Read before you write

The specific failure this prevents: editing a file you have not opened, or
opening it and writing from a model of what it probably contains.

**Open the file. Quote the lines you are changing.** Then edit. The quote is the
evidence that you read it, and it makes the diff reviewable against a source
rather than against a guess.

```
# before
<the current three lines, quoted>

# after
<the change>
```

When you cannot produce the "before" quote, you have not read it, and the edit is
a hallucination with a diff attached.

## Drift: check the answer against the request

Drift does not happen because you stopped listening. It happens because you
resolved an ambiguity silently and then answered your own version.

Two steps, both cheap:

1. **Restate the request in one line before answering.** Not to the user — to
   yourself, at the point where you would start answering.
2. **Check each part of your answer against that line**, and delete anything that
   is not asked for.

```
Asked:      "why is the migration slow?"
My version: "here are nine ways to speed up migrations"      <- drift
My version: "the lock is held for the whole copy"            <- the question
```

The most common drift is answering the general version of a specific question. A
specific question has a specific answer; the general one has a list, and a list
feels productive.

## Drift accumulates, and every step of it looks fine

The version above is drift inside one answer, which is visible because you can
hold both ends in view at once. The severe version is drift *across* a long
task, and it is invisible for exactly that reason:

```
Goal:     fix the failing test
Step 3:   reasonable, and while here the typo in that string
Step 9:   reasonable, and this helper really should be generic
Step 20:  reasonable, and now the module boundaries are clearer
Result:   a refactor nobody asked for, and the test still fails
```

Each step was locally faithful to the step before it. That is what makes it
dangerous — the chain has no moment where anyone can point and say *that*, and
the goal is gone long before anyone notices it is gone.

Three things catch it, and only the first is obvious:

1. **Restate the goal at every boundary**, not once at the start. A task long
   enough to drift is long enough to outlive the sentence you started with.
   Boundaries are: after a plan is agreed, after a phase completes, after
   compaction, and before any change you cannot cheaply revert.
2. **The restatement test.** After N steps, state the original goal in one
   sentence *without reading your notes*. If you need the notes, the goal is
   already gone and the notes are now the only copy.
3. **The unrequested-change ledger.** Keep the list of things you changed that
   nobody asked for. It should be empty or deliberately justified. It is never
   empty by accident, and it is the only artefact that shows the total scope at
   the end rather than at each step where it looked small.

## The confident-plausible trap

Some output is wrong in a way that reads as correct, because it is composed of
true facts arranged into a false claim:

- a file path that does not exist
- a test that "passed" and was never run
- a stack trace reconstructed rather than copied
- a benchmark number with no provenance
- a citation to a document that says something adjacent
- a changelog entry quoted from memory of a different release

Each individual element is checkable. **If a claim cannot be checked by the reader
with what you told them, it is not a claim, it is a decoration.**

## Numbers, identifiers and names are the highest risk

Language is forgiving. These are not, and they are where silent errors cost the
most:

- versions and version ranges
- file paths, function names, field names
- port numbers, URLs, hostnames
- error codes and their meanings
- measurements

For each of these, prefer a mechanical source over recall: read it, grep it, run
it. A model that says "approximately 12" when the file says `11.97` has
introduced a defect that will be copied.

## Separate finding from inference

Present them differently, because they have different reliability:

```
Found       `retry` is exported from `index.ts:8` with signature (options, fn).
Inferred    The retry policy is therefore configurable per call site.
```

Marking inference as inference lets a reader accept it without verifying it, which
is the right default. Unmarked inference gets verified or discarded along with
everything else, and the reader cannot tell which they are looking at.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I am confident about this API." | That is the failure mode, not a defence against it. Read it. |
| "Being careful is enough." | Careful and ungrounded look identical from the inside. Use structure. |
| "The marker makes the output look unsure." | It makes it usable. An unlabelled claim is worse. |
| "I remember this signature." | You remember some version of it, not the one installed. |
| "The docs cover it." | The docs cover the version they describe, not the one you have. |
| "It answers what they probably meant." | Drift is answering what you meant. Answer what was asked. |
| "The number is close enough." | Close enough to be copied into a config and debugged next week. |
| "It is a well-known library." | Familiarity is exactly how version-specific facts feel certain and wrong. |
| "Every step was reasonable." | Reasonable steps in a chain lead nowhere in particular. Judge the chain. |
| "I restated the goal at the start." | A task long enough to drift is long enough to outlive that sentence. |
| "It is just a small cleanup." | That is the sentence drift is built from. Nine of them is a rewrite. |
