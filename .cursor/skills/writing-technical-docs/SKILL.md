---
name: writing-technical-docs
description: Use when writing or updating README, architecture notes, or API reference.
---

# Writing technical docs

## Three genres, three structures

Pick the genre before writing. Mixing them produces a document that serves nobody:

| Genre | Question it answers | Structure |
| --- | --- | --- |
| **Tutorial** | "Teach me by doing" | Steps in order, each runnable, no explanation of why the internals work |
| **How-to** | "Help me do this specific thing" | Goal first, then steps, then the cases where it goes wrong |
| **Reference** | "Tell me exactly what this is" | Exhaustive, alphabetical or grouped by concern, no narrative |

The most common failure is a README that is three of them at once. A tutorial
that stops to explain every parameter stops being followable; a reference that
walks through a story stops being complete.

## Write for someone with none of your context

The reader knows the language and does not know this system. That means:

- Expand every acronym on first use. Do not assume the reader knows the internal
  name of your own service.
- Give a runnable command before explaining it. `npm test` teaches more than a
  sentence about the suite.
- State the prerequisites explicitly, including the version. "Node 20 or later"
  beats "Node".
- Link to the code rather than restating it. A link stays true; a copy does not.

## Document the decision, not the code

Code is already in the repository and already readable. What the code cannot say
is why it is like that, and that is the only thing documentation is actually
for:

```markdown
We cap batch size at 500 because the upstream API rejects 501 with a 400 that
does not say which field is wrong. Raising it looked free; it cost an afternoon.
```

Every entry answers *why now*, and "we tried the alternative" is the sentence
that saves the next person the experiment.

## Prefer executable documentation

Anything mechanically derivable should be generated, not written, because written
documentation is wrong the moment the code moves:

| Instead of writing | Generate or check |
| --- | --- |
| The list of CLI flags | `--help` output, or a test asserting the flags exist |
| The API surface | Types, or an OpenAPI diff in CI |
| The directory layout | A test that fails if it changes unexpectedly |
| The setup steps | A setup script that the doc runs |

This is the same rule the rest of this collection follows: if it can be checked
mechanically, automate it and reserve prose for judgement.

## Anti-patterns that make docs rot

- **The changelog as documentation.** A feature described only in release notes
  is invisible to the person searching the docs.
- **Doc that contradicts the code.** Worse than no doc, because it is trusted.
  Where a doc must not drift, fail CI when it does.
- **Screenshot as instruction.** They break silently and are not searchable.
- **Time-sensitive claims** ("as of 2024 the API supports X"). Date them or move
  them to a changelog.
- **Marketing language in a reference.** "Simply", "just", "obviously", and
  "easy" are all signals that the author has forgotten what it is like not to
  know the thing.

## Length

Match the doc to the reader's need. A README that answers installation, the five
common tasks, and how to get help is complete at two screens. The completeness
belongs in reference material that is linked, not in the front page.

If a document must exceed a few pages, put a table of contents at the top. The
reader is looking for one section, and they will not scroll to find it.

## Verify before publishing

```sh
# Every command in the docs actually runs?
grep -oE '```(bash|sh|console)' -A2 README.md | sed -n '2,$p'

# Do the paths referenced exist?
grep -oE '\]\(\.?/?[a-zA-Z0-9_./-]+\)' README.md | tr -d '](' | grep -v '^http'
```

Commands in documentation are the highest-value thing to check, because the
first one that fails teaches the reader that the rest cannot be trusted.
