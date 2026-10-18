---
name: self-critique-and-polish
description: Use when reviewing your own output before delivery, or polishing work.
---

# Self-critique and polish

## Criticism has to be adversarial or it is theatre

The most dangerous version of this is the one where you re-read your own work,
find it agreeable, and describe the process as review. That is not review, it is
reading with an opinion already formed, and it produces nothing.

Self-criticism is real only when it has **an attempt to break the work**. Read it
as the reviewer who wants to reject it, not as the author who wants to sign it.

Three questions that reliably find defects, because each attacks a different way
the work is wrong:

| Question | What it catches |
| --- | --- |
| What input makes this wrong? | The case you did not consider |
| What did I claim, and where is the evidence? | Overstatement and unverified assumption |
| If I wrote this, what would I object to? | The parts that read as padding |

The third is the useful one. It is the discomfort signal, and the parts of a piece
of work you would hesitate to defend are usually the parts that are weakest.

## Review the artifact, not the intention

Self-review fails most often by reviewing what you *meant* rather than what is
there. The file on disk is the artifact. Open it, read it, and evaluate that.

```
Intention:  "handle empty input in the parser"
Artifact:   if (input) { return parse(input) }    // parse('') throws
Review of the intention:  looks fine
Review of the artifact:   the empty case is not handled
```

## Polishing has a order, and most of it is deletion

Polishing is usually imagined as addition. It is mostly removal, and the removals
come in a specific order because each one makes the next one visible:

1. **Delete what is not executed.** Dead code, unreachable branches, unused
   imports, commented-out blocks, debug logging left in.
2. **Delete what restates the code.** A comment explaining what the next line does
   is a maintenance cost with no informational return.
3. **Delete the abstraction that wraps nothing.** A helper called once, for one
   line, that names nothing the caller did not already know.
4. **Merge the duplicated branch.** Two paths doing the same thing, differing
   only in a constant.
5. **Then, and only then, add.** The one place a comment earns its place is a
   decision the code cannot express.

Doing them in the other order wastes effort: polishing prose around dead code
produces beautifully written dead code.

## The self-repair loop

Continuous improvement is not "polish again", it is a loop with an exit
condition. Without one it either runs forever or stops arbitrarily.

```
deliver → read the result as a hostile reviewer → name defects → fix the
         worst one → repeat until no named defect remains → stop
```

Two properties make it work rather than spin:

- **Name the defect before fixing it.** A loop that "improves" without naming what
  was wrong cannot tell whether it helped, and will happily undo itself next pass.
- **Stop when the named defects run out**, not when the text looks good. Good
  looking is not a signal.

## A study has a shape; a mood does not

"Find everything that could be better" is a mood with a schedule attached. It
produces activity, no list, and no order, which is why it never converges.

A study is the same work done as a procedure, and it fits on one page:

```
1. enumerate across fixed axes     -- coverage comes from the axes, not recall
2. write each finding on one line  -- name the defect, not the feeling
3. attach evidence to each         -- file and line, or the failing case
4. rank by payoff against cost     -- cheapest real fix first
5. fix in rank order, one at a time
6. re-enumerate, and repeat from 1
```

The axes are the part that matters, and they should be written down **before** the
first pass:

| Axis | The question it answers |
| --- | --- |
| Correctness | Does it do the right thing? |
| Completeness | What was asked for and is missing? |
| Clarity | Could a competent stranger act on this? |
| Consistency | Does it match what surrounds it? |
| Cost | What does it cost to run, read, and change? |
| Safety | What breaks when it is wrong, or under load? |
| Fitness | Was this the right approach at all? |

Enumerating the axes beats brainstorming on one specific ground: brainstorming
finds what you expected to find. The axes are fixed in advance, so the axis you
forgot to worry about still gets asked about. Most missed findings live on an
axis nobody brought up.

Two rules keep the list usable. Every finding names a specific defect — not "the
error handling could be better", but "line 88 catches and returns null, so the
caller cannot distinguish empty from failed". And **a finding with no evidence
is not a finding**, it is a worry; drop it or go and get the evidence.

## "Improve until nothing more can be added" cannot be finished

This goal is worth taking seriously enough to say what is wrong with it, because
it sounds like rigour and is actually the absence of an exit.

A goal you cannot recognise as finished cannot be finished. Work under such a goal
does not converge, it churns: each pass finds something, the something is small,
and no pass is ever permitted to end because nobody defined the end. The tell is
that the list regenerates rather than shrinks. After four passes a real
improvement study has almost nothing left. A process still finding high-value
work after four passes is not working well, it is producing work.

The reachable version of the same ambition:

> Improve until the ranked list is empty. Re-enumerate once more. Stop if it
> comes back empty. If it comes back with one trivial item, that is not
> convergence — it is a treadmill, and the item is what you are paying to learn
> that.

Re-enumeration is the only honest test available, because it is the only one that
asks the question in the other direction: not "can I find more?" but "does this
still find things when I stop looking?"

And good enough is a decision, not a feeling. Name the axes you are **not**
going to push on, and why. Time is one. Readability for a reader who does not
exist yet is another. Both are legitimate stopping points, and writing them down
is what separates a decision from an excuse.

The difference between these two goals is the difference between a review and a
ratchet. The first ends with a list that is empty and a stopping point you can
state. The second ends when you run out of energy, having spent it on changes
nobody asked for.

## Distinguish polish from correctness

They get confused, and polishing something broken is wasted effort that delays the
fix while making the bug more convincing.

```
Correctness:  does it do the right thing?
Polish:       is it written the clearest way it can be?
```

Fix correctness first, always. A clean, well-named, beautifully formatted
implementation of the wrong behaviour is harder to spot and harder to replace
than a rough one, because the polish reads as reassurance.

## Know when to stop

Polish has a cost, and the cost is paid by the next person who has to change the
code. Every extra abstraction, every defensive branch for a case that cannot
happen, every named intermediate variable is a thing they must read past.

The stopping condition is not "it looks finished". It is:

- no named defects remain from an adversarial read
- anything a future maintainer would need to know is written down
- nothing remains that a reader must work around rather than through

Past that point, further polishing is preference, and preference has a budget.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Let me re-read it." | Re-reading is not criticism unless you are trying to break it. |
| "The comments explain things." | Restating the code is a cost with no return. Explain the decision. |
| "This is defensive programming." | A branch for an impossible case is a branch nobody can test. |
| "The helper makes it readable." | A helper used once that names nothing adds an indirection. |
| "It needs more polish." | Say which line, and what wrong about it. Otherwise it is taste. |
| "I will keep improving it." | Without a named defect you cannot tell improvement from churn. |
| "It is readable, so it is correct." | Readability is not a property of correctness. |
| "Keep improving until nothing more can be found." | You cannot recognise that goal as finished, so it churns. |
| "The list is always full of small things." | A list that regenerates instead of shrinking is a treadmill. |
| "I will brainstorm improvements." | Brainstorming finds what you expected. Enumerate fixed axes instead. |