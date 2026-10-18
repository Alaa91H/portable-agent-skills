---
trigger: model_decision
description: "Use when reviewing codebase structure, finding coupling or duplication, or prioritising refactors."
---


# Improving codebase architecture

## Get evidence before proposing structure

An architectural opinion formed from reading three files is a guess. Gather
signal first; it is cheap and it reorders the work correctly:

```sh
# Where does complexity actually live?
git log --since=6.months --format= --name-only | sort | uniq -c | sort -rn | head -20

# Which files change together, repeatedly? These are the real module boundaries.
git log --since=1.year --name-only --format= | grep -v '^$' | sort | uniq -c | sort -rn | head -30

# Where does the churn concentrate?
git log --since=6.months --numstat --format= | awk '{add+=$1; del+=$2} END {}'
git shortlog -sn --since=6.months
```

High-churn files with many co-changing neighbours are the structural problem,
and they are usually not the files that look worst.

## Look for these four, specifically

**Cyclic dependencies.** Two modules that import each other cannot be tested,
reasoned about, or changed independently.

```sh
npx madge --circular --extensions ts src/
```

**Shotgun surgery.** One change touching twelve files means the concept has no
home. If a new field requires edits in twelve places, that is the finding.

**Leaky abstraction.** An abstraction whose callers must know which
implementation they got, or must call methods in a particular order. That is a
contract that was never stated, enforced only by convention.

**Duplication with variation.** Three copies differing in behaviour is a missing
type. Three copies differing only in literals is a missing constant. Three copies
that coincidentally look alike is not duplication and should be left alone.

## Separate structural findings from style findings

Say which is which, because they have different urgency and different fixes:

| Finding | Class | Fix |
| --- | --- | --- |
| Circular import between two modules | Structural | Break the cycle; usually invert one dependency |
| Every feature change touches the schema file | Structural | The schema is doing two jobs |
| Inconsistent naming across the directory | Style | Fix opportunistically, do not propose a branch |
| Function is 80 lines | Neither, on its own | Length is not a defect. Cyclomatic complexity is worth a look |

Do not present style findings as architectural ones. It makes the structural
findings harder to get approved, and often they get bundled and deferred together.

## Rank by risk against payoff

Refactor what is both frequently touched and expensive to change. Rank on
evidence:

1. **High churn, high cost to change** — do first. Every future change pays the
   interest.
2. **High churn, low cost** — leave it. It is fine.
3. **Low churn, high cost** — leave it, but fix the first change that touches it.
4. **Low churn, low cost** — do not touch.

Give each proposed change a rough size, and require each to be independently
mergeable and independently revertible. An architecture improvement delivered as
a 3000-line branch will not be merged, and the improvement is lost with it.

## Refuse the rewrite unless the evidence is overwhelming

A rewrite is the correct answer rarely, and the cases where it is correct are
enumerable:

- The domain is understood well enough that the current model is demonstrably
  wrong, and the old one cannot be wrapped.
- The dependency surface is the blocker, and the migration path is mechanical.
- Two attempts at incremental change have each failed the same way.

In the general case, an incremental replacement is the same work without a
period where neither system works. Say so plainly when the request is for a
rewrite and the evidence does not support it. A bad architecture is worth fixing
urgently; it is rarely worth breaking a working system to do it.

## Deliver the assessment as findings, not a wishlist

For each finding, give:

- What the evidence is, with the command that produced it.
- What it costs today, concretely: how many hours, how many mistakes.
- The smallest change that removes it.
- What it makes harder afterwards.

A review that produces a ranked list of concrete costs and small fixes gets
funded. A review that produces an ideal architecture does not, because it cannot
be scheduled.
