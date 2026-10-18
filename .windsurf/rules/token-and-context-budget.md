---
trigger: model_decision
description: "Use when a task is large, or when deciding what to read, delegate or write."
---


# Token and context budget

## The expensive resource is attention, not tokens

Tokens are priced. Attention is not, and it is what actually limits you. A
context window holding 40,000 tokens is not 40,000 tokens of usable reasoning —
past a few thousand, relevance per token collapses, and the material in the
middle is the material you get wrong.

So the question is never "how do I fit this". It is **"what is the smallest set of
context that makes this decision correct?"** Everything else is cost paid for
nothing.

## Read narrowly, cite exactly

The most expensive habit in agentic work is pasting a file to reference one
function. It costs a thousand tokens and dilutes everything around it.

```bash
# costs a thousand tokens of context
cat src/auth/session.py

# costs forty, and is more useful, because it is checkable
sed -n '120,148p' src/auth/session.py
```

The second form is strictly better in three ways: it is cheaper, it leaves room
for the surrounding reasoning, and **it is verifiable** — the reader can open
those exact lines.

**Cite `path:line` instead of reproducing content.** Reproduction goes stale and
costs tokens at read time and at every subsequent re-read. A reference costs four
tokens and never needs refreshing.

Reserve full-file reads for the cases that genuinely need them: the file you are
about to edit, and the file whose shape you are about to change.

## Delegate when the work will not fit

A subagent starts with an empty context. That is the whole point: it is the only
mechanism that lets you work on more than one window's worth of material, because
what it consumes never enters yours.

| Delegate when | Keep it yourself when |
| --- | --- |
| The investigation would fill your window | The decision depends on everything you know |
| The result is a **finding** | The result is an **edit** you must verify |
| Many independent searches | A chain where each step needs the last |
| Reading a large unfamiliar area | Something you already have partial context on |

The economics turn on what comes back. A subagent's entire value is its summary,
so a summary that omits the one thing you needed makes the delegation a loss
however cheap it was. **Specify the return shape**: not "look into the caching"
but "which functions populate this cache, their file and line, and whether the
invalidation is TTL-based or event-based".

## Read for a decision, not for coverage

Before opening anything, name the decision. Then read the minimum that resolves
it, and stop.

```
Decision:  can this migration run without downtime?
Minimum:   the migration runner's transaction handling, and whether it takes a lock
Not needed: the schema, the connection config, the test fixtures
```

Reading for coverage is how a 20-line change turns into a 200,000-token session.
It feels thorough and produces no better an answer.

## Keep a scratch file, not scratch context

Notes held in context are lost to compaction. Notes held in a file are not, and
the file is also readable by the next session, by a reviewer, and by a subagent.

```
## decided
- events are written synchronously; the queue is for retries only  (why: at-least-once)
- the migration lock is advisory, so the runner must be the only writer

## open
- does the CDC consumer tolerate out-of-order events? UNANSWERED

## rejected
- retry inside the transaction — doubles the lock hold time
```

The rejected list is the highest-value part. Without it, a later session
re-derives an option you already spent twenty minutes eliminating, and you cannot
tell the difference between "not considered" and "considered and wrong".

## Write the answer, not the narration

Output length is context you spend before the answer arrives.

| Instead of | Write |
| --- | --- |
| "I examined X, Y and Z and concluded…" | the conclusion, with `path:line` for each claim |
| "First I'll read the file, then analyze it, then…" | the result of reading it |
| Restating the problem back | the answer, assuming the problem was stated |
| A summary of every file touched | the diff, which says it exactly |

A diff is the most information-dense output format available, because it is
lossless and it is the thing you were asked for.

## Cost is not the only thing that scales badly

Retries, re-reads and re-runs are token costs with a latency multiplier, and they
dominate a long session.

- **Do not re-read a file you already read.** If you need it again, cite the
  lines you noted rather than re-reading the whole thing.
- **Do not re-run a suite that passed.** Run the narrowest test that could change
  the answer.
- **Fix the cause once.** Five edits to work around a root cause costs five
  times the context of the fix.

## Measure the ratio, not the total

The number worth watching is **context consumed per decision made**. A session
that reads 200,000 tokens and makes three decisions is a problem; one that reads
12,000 and makes twenty is a good session, whatever the model charged.

If the ratio climbs, the cause is almost always one of three: reading whole files
to change a line, investigating rather than asking, or re-reading instead of
writing a note.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I need the whole file to understand it." | Then cite the region you need and let the reader open more. |
| "Context is cheap." | The limit is attention, and it degrades long before the token cap. |
| "Delegating loses too much." | It loses what you did not specify. Name the return shape. |
| "The summary is only for me." | It is the entire value delivered. Make it checkable. |
| "I will remember the decision." | Compaction will not preserve it. Write it down. |
| "Reading more cannot hurt." | Irrelevant context displaces relevant context. |
| "It is a small change." | Small changes consume most context when you read for coverage. |
