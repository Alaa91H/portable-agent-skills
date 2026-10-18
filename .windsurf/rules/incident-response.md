---
trigger: model_decision
description: "Use when responding to a production incident, outage, or alert, including triage, mitigation, communication, handoff, and writing a postmortem."
---


# Incident response

## Mitigate first, diagnose second

The instinct to understand before acting is wrong during an outage. Reverse the
order:

1. **Reduce impact.** Roll back, disable the feature flag, shed load, fail over.
2. Then diagnose.

A rollback is reversible and takes minutes. A fix deployed under pressure is
usually neither. **The fastest correct action is almost always the one that
undoes the most recent change**, because change is the top cause of outages and
the most recent change is the most likely cause.

```sh
kubectl rollout undo deployment/api
git revert <sha> && git push   # for an application change
```

## The first fifteen minutes

```
1. Acknowledge, declare, and start a clock. Write down the start time now.
2. Name an incident commander. One person coordinates; they do not debug.
3. Confirm the blast radius: who is affected, and how badly.
4. Check the most recent change: deploys, config, feature flags, dependency bumps.
5. Mitigate by rollback or failover if that is available.
6. Communicate: what is broken, who is affected, what is being tried, next update time.
```

Say **"next update in 20 minutes"** and honour it, even when the answer is no
change. Silent responders get assumed dead.

## Separate roles

| Role | Does | Does not |
| --- | --- | --- |
| Incident commander | Coordinates, assigns, times updates | Debug |
| Operations | Investigates and mitigates | Talk to stakeholders |
| Communications | Updates users and the team | Make technical decisions |

One person doing all three does each badly. If you are the only person available,
say so explicitly rather than silently multitasking.

## Diagnose from the outside in

Work down the stack, and stop at the first thing that explains the symptom:

```
edge / CDN -> DNS -> load balancer -> application -> dependencies -> data store
```

Use the error budget as your prior. If you are nearly out of budget, the response
is to stop shipping features, and that is a decision to make at declaration, not
after the investigation.

Check these first, because they are the usual answer:

- Deploys in the last hour. `kubectl rollout history`, the deploy log, the
  feature flag timeline.
- Resource exhaustion: memory, connection pools, disk, quota, rate limits.
- One dependency degraded while everything else is fine.
- Certificates, and anything that expires.

## Communicate with structure

Every update has four parts. Vagueness wastes the reader's time:

```markdown
**Status** investigating | identified | monitoring | resolved
**Impact** 40% of checkout requests failing, EU only, since 14:02 UTC
**Cause** (once known)
**Action** rolled back deploy a1b2c3d; watching error rate
**Next update** 14:40 UTC
```

State the impact in user terms ("checkout is failing"), not in internal terms
("the payments pod is unhealthy"). During an incident, several teams read your
updates and none of them share your context.

## When to declare an incident

Declare when the user-visible impact is real, not when you understand it. Early
declaration is cheap and brings in help; late declaration means you spent twenty
minutes alone with a problem that needed a team.

State plainly what you do **not** know. "Unknown, investigating the deploy
timeline" is a legitimate update; a confident wrong theory is actively harmful
because people act on it.

## Handoff

For anything longer than about an hour, or across time zones, write a handoff
before you stop:

- Current state, what is deployed, what is rolled back.
- Timeline with timestamps.
- Hypotheses ranked by likelihood, with what would confirm or refute each.
- Exact next commands to run.
- Things already tried that did **not** work, so nobody repeats them.

An oral handoff loses this, and the person picking it up restarts from zero.

## Postmortem

Blameless means blameless **for people**, and factual about **systems**. A
postmortem that finds a person at fault has found nothing, because that person
did the reasonable thing given the system they were in.

The useful structure:

1. **Impact**, quantified: duration, requests or users affected, error budget
   consumed. The SRE Workbook's own analysis found a single 72,000-error outage
   consumed 65% of a quarterly budget, which is exactly the kind of number that
   changes priorities.
2. **Timeline**, with timestamps, including how long each mitigation took.
3. **Trigger**, the specific change.
4. **Contributing factors**, plural. Most incidents have several, and finding one
   is not finding the cause.
5. **What made detection slow.** This is where the real fixes usually are, and it
   is the question teams skip.
6. **Actions**, each with an owner and a date. Unowned actions do not happen.

Write for someone who was not there, including the person who joins in six
months. Name the systems, not "the backend".

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Let me understand it before I touch anything." | Impact grows while you understand. Mitigate, then diagnose. |
| "It is not that bad yet." | Declaring early is cheap. Declaring late is the outage. |
| "I will handle communication later." | Then nobody else knows you are blocked. Update on a timer. |
| "The deploy is probably not it." | It probably is. Check it first, it takes two minutes. |
| "Postmortem will make it about the mistake." | Blameless for people, factual for systems. That is where the fixes are. |
