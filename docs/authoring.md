# Authoring skills

This is the contract every skill in `.opencode/skills/` follows. It exists so
that skills authored by different people, or by agents working in parallel, look
and behave like one collection.

`scripts/validate-skills.sh` enforces the mechanical parts. The judgement calls
are written down here because a validator cannot check them.

---

## 1. The hard contract

### Layout

```text
.opencode/skills/<skill-id>/
├── SKILL.md          # required
├── references/       # optional, loaded on demand
├── scripts/          # optional, executed
└── assets/           # optional, templates and data
```

`<skill-id>` is lowercase kebab-case: `^[a-z0-9]+(-[a-z0-9]+)*$`, 1–64 characters.

### Frontmatter

Exactly six keys are permitted. Anything else is a hard error.

```yaml
---
name: test-driven-development          # must equal the directory name
description: <routing sentence>        # required, 1-1024 chars
license: Apache-2.0                    # optional
compatibility: Requires a POSIX shell # optional, max 500 chars
metadata:                              # optional, flat string -> string map
  author: your-handle
  version: "1.0"
allowed-tools: Bash(git:*) Read        # optional, experimental
---
```

- `name` **must** match the directory. The portable spec requires it, and
  OpenCode derives the skill ID from the same path, so keeping them equal
  satisfies both.
- `metadata` is a flat map. A key with no value introduces a nested object and
  is rejected. Use a reference file instead.
- Do not use Claude Code-only keys such as `disable-model-invocation`,
  `argument-hint` or `when_to_use`. They hard-error when a skill is uploaded or
  packaged. If you need to hide a skill from auto-discovery, put
  `opencode/autoinvoke: "false"` inside `metadata`, which is still a valid
  string-to-string map.
- Line 1 of the file must be `---`. No BOM, no blank line, no prose before it.
- Files are UTF-8 without BOM and LF line endings. Run `scripts/normalize.sh`.

### Budgets

| Thing | Limit |
| --- | --- |
| `description` | 1024 chars hard; aim for 150–400 |
| `SKILL.md` body | under 500 lines, under 5000 tokens |
| Frequently loaded skills | under 200 words |
| Reference files | keep each focused; add a TOC past 100 lines |
| Reference depth | exactly one level from `SKILL.md` |

If a skill needs more room, that is the signal to move material into
`references/`, not to grow the body.

---

## 2. Writing the description

This is the highest-leverage line in the file. Only the ID, name and description
are in context at every model step; the body is not read unless the agent decides
to load the skill. A weak description makes the whole skill unreachable.

There are two schools of guidance and they genuinely conflict.

- **Anthropic's official guidance**: describe *what the skill does* and *when to
  use it*, in the third person, and be deliberately "pushy" so the agent does
  not under-trigger it.
- **The `superpowers` field guide**: describe *when to use* the skill and never
  summarise the workflow, because an agent that already knows the plan from the
  description will follow that shortcut and never read the body.

**The rule this collection uses**: the description describes the **trigger
surface**, never the **workflow**. You may name the domain so the agent can
recognise the territory; you may not prescribe the steps.

| Bad — summarises the workflow | Good — describes the trigger surface |
| --- | --- |
| `Use when running tests - dispatch a subagent per test file and review between batches` | `Use when adding or changing a feature or bugfix that needs tests, or when a test-first workflow is requested.` |
| `Handles flaky tests by rewriting them with retry loops and timeouts.` | `Use when tests fail intermittently, pass in isolation but fail in the suite, or depend on timing and ordering.` |
| `Use for React - follow the component and hook conventions in this file.` | `Use when writing or reviewing React components, hooks, or Server Components, or when a hook rule or dependency-array bug is suspected.` |

Add these three things whenever they apply:

1. **Symptom and error strings.** Agents match on the text they are actually
   seeing. Include the literal error, e.g. `"Hook timed out"`, `"ENOTEMPTY"`,
   `"cannot update unmounted component"`.
2. **An anti-trigger.** When a neighbouring skill exists, say what this one is
   *not* for. Anthropic's own document skills do this:
   `"Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks."`
   It measurably reduces mis-triggering between neighbours.
3. **Third person, present tense.** `"Debugs failing builds"`, never `"I can
   help you debug"` or `"You can use this to debug"`.

Do not pad with "Use this skill to..." boilerplate or vague nouns like
"Helps with documents".

---

## 3. Match the form to the failure

A skill should prescribe the shape of guidance that actually fixes the problem
it targets. Choosing wrongly makes things worse.

| The observed failure | Correct form | Wrong form |
| --- | --- | --- |
| A rule gets skipped under pressure | A prohibition plus a table of the rationalisations the agent will reach for | Soft guidance ("prefer to...", "try to...") |
| Output has the wrong shape | A positive contract: state what the output *is*, its parts in order | A list of things not to do |
| A required element is omitted | Put it in the template the agent fills in | Prose reminders |
| Behaviour depends on a condition | A conditional keyed to an observable predicate | An unconditional rule plus exemptions |

Head-to-head wording tests found that prohibitions produced *more* unwanted
content than an equivalent positive recipe for shape problems, and trended
worse than giving no guidance at all. Pick the form from the table, not from
habit.

Two further notes:

- **Exemption clauses do not scope.** Appending one "unless it matters" clause
  to a recipe that works turns it from consistent into noisy.
- **Explain why, not just what.** A short reason survives; a bare `ALWAYS` does
  not. Heavy-handed all-caps rules are a warning sign that the reasoning was
  skipped.

---

## 4. Progressive disclosure

Three levels, and the point is to keep each one as small as it can be:

1. **Metadata** — `name` and `description`. In context at every step. Keep tight.
2. **Instructions** — the `SKILL.md` body. Read once when the skill triggers. It
   stays in the conversation afterwards, so it is not re-read later.
3. **Resources** — `references/`, `scripts/`, `assets/`. Cost nothing until
   touched, which is why the amount of context a skill can bundle is effectively
   unbounded.

Rules that follow from this:

- Keep references **one level deep**. An agent reading `a.md`, which points at
  `b.md`, may preview `b.md` with `head -100` instead of reading it, and act on
  a partial file.
- For a reference file that is long, put a table of contents at the top so the
  agent can target a section.
- Split mutually exclusive paths. "If Postgres, read `references/postgres.md`;
  if SQLite, read `references/sqlite.md`" beats one file covering both.
- **Say whether to run a script or read it.** `"Run scripts/verify.sh to
  confirm"` is different from `"Read scripts/verify.sh for the verification
  algorithm"`. Bundled scripts are usually better than agent-generated code:
  deterministic, token-cheap, and consistent between runs.
- Invoke scripts through their interpreter, `bash scripts/x.sh`, never as a bare
  path, because packaging can strip the executable bit.

### How much freedom a script gets

| Freedom | Use when | Form |
| --- | --- | --- |
| High | Several approaches are valid and the right one depends on context | Numbered instructions |
| Medium | One pattern is preferred but variation is fine | Parameterised script or template function |
| Low | Fragile, error-prone, or the order is critical | `Run exactly this command. Do not modify it.` |

A database migration is low freedom. A design review is high freedom.

If you do ship a script, it must handle its own errors rather than punting them
back at the agent, and every constant in it must be justified by a comment.

---

## 5. Style

- Direct address and active voice: `Read the changelog`, not `One should read`.
- Be specific. `Prefer meaningful identifiers` is advice; `rename `amt` to
  `amountUsd`` is a change.
- Explain the reason for a rule in one clause. Agents follow reasons.
- Consistent terminology. Pick `endpoint` or `route`, not both.
- One excellent concrete example beats several mediocre ones. Do not
  multi-language a single example.
- Keep time-sensitive facts out of skills. Put superseded advice in a
  `<details>` block labelled with its era rather than deleting it.
- Give a default and an escape hatch rather than a menu of five equal options.

---

## 6. Do not write a skill for

- A one-off problem.
- A standard practice that is already well documented somewhere authoritative.
- A convention that belongs in the project's `AGENTS.md`, not in a skill.
- **A constraint a script could enforce.** If it is checkable by a linter, a
  regex, or a validator, automate it. Documentation is for judgement calls.

That last one is the most common mistake in skill collections. A skill that
restates something mechanically checkable is pure token cost.

---

## 7. Before you commit

```sh
scripts/normalize.sh        # strip BOM, force LF
scripts/validate-skills.sh  # spec conformance
tests/run-tests.sh          # the validator still works
```

The validator catches structural defects: bad ids, missing or malformed
frontmatter, disallowed keys, `name` disagreeing with its directory, empty
bodies, references to files that do not exist, and nested metadata.

It cannot tell you whether the skill is *good*. For that, apply the harder
standard from Anthropic's own guide: **run an agent on a representative task
without the skill, record what it does wrong, and confirm the skill changes that
behaviour.** A skill written from intuition is a hypothesis, not a fix.