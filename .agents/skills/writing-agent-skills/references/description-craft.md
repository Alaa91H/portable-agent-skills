# Description craft

The description is the only part of a skill that is in context at every model
step. It decides whether the skill is ever loaded. Getting it wrong makes the
rest of the file unreachable.

## What to include

**The trigger condition, stated as a situation.** Not a summary of the skill.

**Concrete keywords.** File extensions, tool names, library names, error
strings, and the words a user actually types. Agents match on literal text.

**Symptom strings.** If users report `ENOTEMPTY`, `Hook timed out`, or
`cannot update unmounted component`, put that exact string in the description.
The error is the text the agent has in front of it.

**An anti-trigger, when a neighbour exists.** Say what this is not for. The
official document skills do this, and it is the most effective defence against
mis-triggering between two related skills.

```yaml
description: Use this skill any time a spreadsheet file is the primary input or
  output. Trigger especially when the user references a spreadsheet by name or
  path. Do NOT trigger when the deliverable is a Word document, HTML report,
  or a database pipeline, even if tabular data is involved.
```

## What never to include

**The workflow.** This is the important one.

```yaml
# Wrong - describes the procedure
description: Use when running tests - dispatch a subagent per test file and
  review the results between batches

# Right - describes the situation
description: Use when adding or changing a feature or bugfix that needs tests,
  or when a test-first workflow is requested.
```

The wrong version hands the agent a plan. The agent follows the plan, never
opens the file, and the carefully written body is dead text. This is not
hypothetical: a description mentioning "code review between tasks" produced an
agent doing exactly one review, while the body clearly specified two.

**First and second person.**

```yaml
# Wrong
description: I can help you with async tests when they are flaky
description: You can use this to process spreadsheets
```

**Vague nouns.** "Helps with documents", "Processes data", "Does stuff with
files". These match nothing a user would say.

**Boilerplate.** "Use this skill to..." consumes characters and carries no
routing information.

## Naming

Active voice, verb-first, gerund where it reads naturally:

- `testing-strategies`, `writing-documentation`, `reviewing-changes`
- `condition-based-waiting` over `async-test-helpers`, because it names the
  condition rather than the mechanism
- `flatten-with-flags` over `data-structure-refactoring`

Never `helper`, `utils`, `tools`, or `common`. Those name a role, not a
situation, so they never tell an agent when to load anything.

## Length

Under 1024 characters is a hard limit. Aim for 150 to 400.

Under about 50 characters, a description cannot carry both a trigger condition
and concrete keywords, and it will under-trigger. If you are out of room, cut
the prose, not the keywords.

## Third person, present tense

`Debugs failing builds.` not `This skill will help you debug failing builds.`

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The description is fine, the agent will find it." | If it were, you would not be writing the skill. |
| "I will mention the whole workflow so it is useful." | It is useful as a summary and fatal as a description. The body is where the workflow goes. |
| "I will add more keywords to be safe." | Extra keywords attract wrong triggers. Near-miss keywords are worse than none. |
| "The name is enough to identify it." | Names are not read at routing time. Descriptions are. |
| "Being pushy helps triggering." | Pushiness is fine. Breadth is not. Narrow the trigger, do not widen it. |

## A checklist

Before shipping a description:

- Does it name a situation rather than describe a procedure?
- Does it contain the literal error text or symptom a user would report?
- Does it exclude its nearest neighbour, if one exists?
- Is it third person?
- Can you construct a query that *should not* trigger it, and confirm the
  description gives you a reason to skip it? If not, it will over-trigger.
