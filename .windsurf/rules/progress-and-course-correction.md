---
trigger: model_decision
description: "Use when work is in progress and drifting from its goal, or effort is being wasted."
---


# Progress and course correction

## Every other check runs at the edges

Validation happens before you start and verification happens after you finish.
Both are correct and both are blind to the thing that actually goes wrong most
often, which is the long middle where the work quietly stops being the work.

```
before ────────── during ────────── after
        plan                      verify
                    nobody is here
```

That middle is where drift is cheapest to fix — an hour of work redirected costs
an hour. The same hour discovered at the end costs the hour plus everything it
was spent on. Checking during is not a substitute for the edges. It is the only
place where correction is cheap.

## A monitor that costs more than the drift is not a monitor

This is the constraint everything else follows from. A check that consumes a
tenth of your effort budget to run at every step is a tax, and like every tax it
gets removed the first time it is inconvenient.

So the during-check is deliberately the cheapest thing that can work: **three
questions, no tools, no re-reading, no audit.**

```
1. Am I still doing the thing I was asked to do?
2. Is the step I am about to take on the path, or beside it?
3. What have I done that nobody asked for?
```

That is the whole monitor. If it cannot be answered from context in under a
minute, it is too expensive to be a monitor and belongs at the next edge
instead.

## When to check, and when not to

Continuous checking is as broken as never checking, because a check you run
constantly is a check you learn to wave through.

Check at **boundaries**, which are events, not intervals:

| Boundary | Why it is a boundary |
| --- | --- |
| A plan is agreed | The path is set; verify it is the right path |
| A component or phase completes | Cheap moment to notice the next one is wrong |
| You are about to do something hard to revert | Last cheap chance |
| Compaction or a context reset | The goal is most likely to have decayed |
| The next step needs a decision you were not expecting | Drift usually shows up here first |

If none of those has happened, do not check. Checking on a timer rather than at
an event is how a monitor becomes noise, and noise gets ignored.

## What being off course looks like

These are observable, and unlike "I feel like I am drifting" they can be
checked by someone else.

**The goal was restated recently.** If you cannot say what you were asked for
without reading your notes, the goal is gone and everything since is inference.

**The unrequested changes have outnumbered the requested ones.** A useful ratio:
how many files did the task name, versus how many you touched? Tasks that touch
three times that many usually went somewhere else.

**Each step is small and none is urgent.** A run of small, low-stakes steps is
usually avoidance of one large obvious step. That is not drift in the goal, it
is drift in the plan.

**You are producing instead of deciding.** Volume of output rising while the
number of decisions stays flat means you are filling rather than working.

**The same blocker is being solved for the third time.** Usually the approach is
wrong, and continuing is the expensive form of persistence.

**You cannot state what done would look like.** The goal became a feeling.

## What to do when the monitor fires

Naming the deviation is most of the work. Then choose one of four:

| Signal | Response |
| --- | --- |
| Still on goal, but the plan is worse than expected | Replan. Say so out loud |
| Off goal, cheaply reversible | Revert. The cost of reverting is the point of checking now |
| Off goal, expensively reversible | Stop and ask. A wrong hour is cheaper than a wrong afternoon |
| Off goal, and it is what the user actually wanted | Ask whether to continue or to hand back a smaller answer |

The fourth is the one people skip. Sometimes the work you are doing is better
than the work you were asked to do, and the right move is to stop and say so,
not to deliver the better thing unasked. That is drift with good intentions,
and it is still drift.

## The scope ledger

Keep one list, from the first step to the last: **things you changed that the
task did not name.** Two uses, and the second is why it exists:

1. At the next boundary you can see the total instead of the increment.
2. At the end you can hand it back — "here is what I did beyond the ask" —
   which is the difference between a surprise and a disclosure.

It should be empty or deliberately justified. It is never empty by accident.

## Do not confuse correcting with stopping

A monitor that fires constantly trains you to ignore it, and an ignored monitor
is worse than none because you believe you have one. If three checks in a row
fire, the plan is wrong rather than your attention. Rewrite the plan; do not
tighten the monitor.

The healthy pattern is a check that almost always passes, is cheap enough to
ignore when it does not need to run, and is impossible to wave through once.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I am keeping track already." | Tracking is not checking. Tracking has no moment it can fail. |
| "I will review it all at the end." | Then every correction costs full price. |
| "The check would take longer than the work." | Then check at fewer boundaries, not at none. |
| "This is what they wanted." | Did they say that, or is it a version you resolved silently? |
| "I am nearly done, no point checking." | The point is highest exactly when it is nearly done. |
| "The monitor fired, so I must stop." | It fired, so you must decide. Stopping is one of four responses. |
| "It is fine, just not how they asked." | That is the definition of drift, not a defence against it. |
