---
name: deep-research
description: Use when researching a topic or sources, or needing depth and saturation.
---

# Deep research

## Breadth and depth are separate passes

Doing them in one sweep produces neither. You skim ten sources and remember the
headlines; you then read one source properly and know more about it than anyone
else, while missing that three others contradicted it.

```
Pass 1 (breadth)   map the territory — what are the sub-questions, who is
                   credible, where does the literature disagree
Pass 2 (depth)     go deep only where pass 1 showed it matters
Pass 3 (saturation) search again, expecting to find nothing new
```

Pass 1 should be fast and wide. The failure mode is falling in love with a
promising source during pass 1 and reading it ten times.

## Source hierarchy

Not all sources are equal, and the difference is not reputation, it is
proximity to the thing being claimed.

| Tier | Source | Use it for |
| --- | --- | --- |
| 1 | Primary: the specification, the source code, the filing, the dataset | What is actually true |
| 2 | Maintainer docs, changelogs, official announcements | What is intended |
| 3 | Conference talks, engineering write-ups by practitioners | Why it is the way it is |
| 4 | Forums, issues, mailing lists, Stack Overflow | Edge cases, failure reports, what people actually hit |
| 5 | Blog aggregations, tutorials, summaries | Vocabulary and search terms only |
| 6 | Generated summaries of the above | Nothing. Verify elsewhere. |

Tier 4 is where the real value often is, and tier 5 is where confident errors
come from. A tutorial written against version 1 of a library will state, with
complete confidence, something that stopped being true in version 2.

The habit worth building: **when a claim comes from tier 5, go find tier 1 or 2
before repeating it.** Not because the claim is wrong, but because you cannot
tell whether it is wrong, and the cost of being wrong here is someone else's
debugging session.

## Reading forums properly

A forum thread is not evidence, it is a distribution of experiences. Extract the
signal:

**Raise confidence when**

- independent sources, with no shared origin, report the same thing
- the reporter gives specifics — versions, error text, a reproduction
- the report survives without a follow-up correction
- people who work on the software confirm it

**Lower confidence when**

- the only source is one highly-upvoted answer
- the claim is general where the reports were specific
- the version, platform, or configuration is not stated
- the answer explains what is convenient rather than what is true

**The single most useful signal** is disagreement. A community split on a
question usually means the answer is conditional — "it depends on X". Look for
the X. A question with universal agreement after twenty comments is more likely
to have a boring answer, or to have not been tested.

## Saturation: knowing when to stop

You cannot research forever, and you cannot know you are finished unless you
define finished. Saturation is a **measurement**, not a feeling.

```
You have saturated on a sub-question when, in two consecutive passes
across independent sources, you find nothing that changes the answer.
```

That gives a concrete stop rule: run a deliberate second sweep whose purpose is
to *disprove* your current answer. If the sweep is empty, you are done. If it is
not, the sweep was worth more than another round of confirmation.

Three failure modes at the stopping point:

- **Stopping at the first answer.** The first plausible source is usually the
  most popular one, not the most correct one.
- **Stopping at confirmation.** Every additional source agreed, so you feel done.
  Agreement without a deliberate adversarial pass is not evidence.
- **Stopping at comfort.** The question got hard and you moved to a part you
  already knew. Saturation on the easy part is easy to mistake for completeness.

The last one is the most common. Check whether your coverage is uniform or
lopsided: several paragraphs on the part you understood before you started, one
sentence on the part that was actually hard.

## Resolve conflicts explicitly

Sources will disagree. Choose deliberately rather than averaging:

1. **Newer beats older**, when the change is real and not a regression you have
   not heard about yet.
2. **Primary beats secondary**, always.
3. **A source that reports the failure beats a source that reports the success.**
   The happy path is documented by the person who wrote the code; the broken path
   is documented by the person who suffered.
4. **If the disagreement is conditional, find the condition.** "It does not work"
   and "it works" are usually both true.
5. **If it remains unresolved, say so.** A research answer that hides an unresolved
   conflict is worse than one that names it, because the reader cannot tell which
   part to trust.

## Record the search, not just the answer

A search log is what makes research auditable, and it is what stops the next
session repeating work already done.

```
Question:      <the question as actually asked>
Sub-questions: <what had to be resolved to answer it>
Searched:      <queries and sources, with dates>
Saturation:    <what pass 3 found, even if it found nothing>
Unresolved:    <what is still in conflict, and who would settle it>
Confidence:    <what would change this answer>
```

The last field is the one people skip and the one that matters most. If you
cannot state what would change your answer, you have not concluded, you have
stopped.

## Distinguish understood from read about

Having processed a lot of text is not the same as understanding the subject, and
the difference shows in what you can do afterwards.

You understand when you can:

- predict what happens in a case not covered by any source you read
- explain the mechanism, not just the recommendation
- say which parts of the guidance are load-bearing and which are incidental
- tell a plausible story that is wrong, and say why it is wrong

If you cannot do the first one, you have a summary. Say it is a summary. A
summary presented as understanding is the most common failure of research-shaped
work, and it is invisible from the outside because it reads fluently.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I found a good source." | One source is a data point, not a conclusion. Find the disagreement. |
| "The forum says it is fixed." | Ask what changed. "Fixed" often means "changed again". |
| "I covered both sides." | Did you, or did you read one side of a source that mentioned two? |
| "Nothing new came up, so it is complete." | That is one sweep. Saturation needs two consecutive empty ones. |
| "This source is authoritative." | Authority is not proximity. Check the tier. |
| "I will look at the edge case later." | Edge cases are usually the actual question. |
| "The summary is enough." | Then say it is a summary. Do not present it as understanding. |