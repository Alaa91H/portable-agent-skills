---
description: "Use when finishing work and something may be missed, or auditing scope."
---


# Completeness and detail

## Enumerate before you act

The miss is almost never a hard thing. It is a boring adjacent thing: the second
call site, the empty list, the config default, the doc line that now says the old
number.

So the method is to produce the **full inventory first**, and only then choose
what to do. An inventory you did not write down is an inventory you did not
have.

```
change: add a required field to the create request

surfaces touched
  api        handler, validation, schema, error case
  data       migration, backfill, default for existing rows
  clients    every caller, including ones in other services
  ops        config, feature flag, runbook, monitoring
  docs       reference, examples, changelog
  tests      the new path, and every test that constructs the type
```

Five lines before writing any code. It takes a minute and it is the difference
between a change and a finished change.

## Trace the lifecycle, not the function

A unit of behaviour is not tested or changed in one place; it exists at every
stage of its own life. Missing a stage is the common failure, because the stage
you are working on is the one you can see.

```
create   read   update   delete
  list    search   serialize   deserialize
  import   export   migrate   backfill
  display in the UI   print   log   report
  validate   authorise   rate-limit   audit
```

Walk that row for every entity you touched. `read` gets attention because the
work was about reading; `delete` and `export` and `audit` are where the surprise
lives, because nobody was looking at them.

## The boundary states are the work

The happy path is the easy part and it is usually the one already covered. The
states that are missed are all the same family:

| State | Why it gets missed |
| --- | --- |
| empty | Looks like a crash, feels like an edge nobody has |
| one element | Singular/plural bugs live here |
| maximum | Overflow, truncation, pagination, timeouts |
| zero, negative, NaN | Silent nonsense instead of an error |
| missing key | `undefined` is not an error in three languages |
| concurrent | Correct in isolation, wrong in a sequence |
| partial failure | Two calls, one succeeded |
| unicode | Length, truncation, collation, RTL |
| very long | Log lines, titles, paths |
| duplicate | Idempotency, or a double-submit |

## A closure checklist per artifact type

The specific misses are predictable once you know the artifact. For each kind of
change, the things that must be touched with it:

**New function** — every caller, the error path, the empty input, the test that
fails without it, the docstring.

**New configuration** — the default, the validation of the value, the
documentation, the example, the override for every environment that needs one,
and what happens when it is absent.

**New endpoint** — auth, rate limit, validation, the error format, the docs, the
client, the monitoring, and the idempotency story.

**Schema change** — the migration, the backfill for existing rows, the default
for new ones, the rollback, the code that reads it, and every place that
constructs the type.

**Dependency added** — the lockfile, the licence, the version pin, the size, the
build, the vulnerability surface, and what it can be replaced with.

**Behaviour changed** — the tests that assert the old behaviour, the docs that
describe it, the callers that depended on it, and the migration for anyone
outside the team.

## Grep for what you replaced

The single highest-yield command in this skill:

```sh
git diff --name-only | while read -r f; do
  git diff -U0 "$f" | grep '^-' | grep -v '^---' | grep -oE '[a-zA-Z_][a-zA-Z0-9_]{3,}'
done | sort -u > /tmp/removed-symbols
xargs -a /tmp/removed-symbols -r grep -rn . --include='*.ts' --include='*.md' -l
```

Every identifier and literal you deleted is a thing that used to be true
somewhere. Find the remaining references. This finds callers no amount of reading
the changed file would reveal, because they live in files you never opened.

## Ask what breaks, then look

For each thing you changed, the honest questions are:

- what was relying on the old behaviour?
- what reads this file, this field, this key?
- what happens if this is absent rather than empty?
- what happens if it is run twice?
- what does the operator see when it fails?
- what does the next person assume without asking?

Each question has a concrete search behind it. A question with no search behind
it is a feeling, and the feeling is what makes someone say "that is finished".

## Know where completeness stops

This matters as much as the rest, because completeness without a boundary is
unfinishable work.

Completeness means **the surface area you can enumerate is covered**, not that
every possible interaction is. Write down what you enumerated, so the boundary
is visible:

```
covered    api, migration, backfill, 6 of 6 callers, docs, tests
not covered  the legacy /v1 endpoint, which the new code does not serve
out of scope  rate limiting, unchanged by this diff
```

An unstated boundary reads as an oversight when someone finds it later. A stated
one reads as a decision, and it is checkable.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The tests cover it." | They cover the path you thought of, not the states you did not. |
| "It is a small change." | Small changes still touch six surfaces; small is about lines, not scope. |
| "There is only one caller." | Then the grep for the old symbol will confirm it in one command. |
| "The docs are obviously fine." | The docs contain the old field name until someone changes it. |
| "Empty input will never happen." | It happens when a filter returns nothing, which is most days. |
| "Nobody uses that endpoint." | Then it should have been deleted, and that is a finding. |
| "I would remember." | You would remember the part you worked on. |
| "Being thorough means finishing everything." | It means enumerating, covering the enumeration, and stating where it stops. |
