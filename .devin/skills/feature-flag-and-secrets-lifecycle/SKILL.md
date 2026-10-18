---
name: feature-flag-and-secrets-lifecycle
description: Use when adding or retiring a feature flag, or rotating secrets.
---

# Feature flags and secrets lifecycle

## Every flag is a combinatorial liability

Ten active flags is **1,024 possible code paths**. Nobody has tested them, and
the combination that breaks is the one nobody remembers adding.

That arithmetic is the argument for a retirement rule at creation time, not an
argument against flags:

```yaml
owner: payments-team
created: 2026-03-04
expires: 2026-06-01
```

A flag with no expiry is a permanent branch, and permanent branches are how
systems become unexplainable.

## The retirement rule that matters

**A flag is not retired until the code that implements it is also removed.**
Removing it from the flagging system first deletes your visibility into its
carrying cost: the code branch remains, permanently unexercised and permanently
unsafe, and nobody is left watching it.

That order is counterintuitive because the flag looks like the leftover. It is
the code that is the leftover.

Mark it fully rolled out, then:

1. Remove the branching code.
2. Remove the flag definition.
3. Remove the flag default and the config key.

Stale detection: **fully rolled out, zero code references, no downstream
dependents**. All three, not one.

## Some flags should never expire

Kill switches, access gates, entitlement checks and regional rollouts are the
product working as intended. Expiring them on a schedule removes a capability
that is required to exist.

These need no retirement date, and blanket-expiring them is its own bug.

## What a flag is not for

Not for configuration. A feature toggle changes **behaviour visible to users**;
an environment variable or config entry changes **how the system runs**. Mixing
them produces a flag that some environments cannot turn on, discovered during an
incident.

## Flag safety in review

A managed flag service lets you change production behaviour **without a
deployment**, which is genuinely useful and also a genuine risk: the code in
production is not the code that was tested. Require that a flag change is
reversible, that its blast radius is known, and that it is visible in the same
place as deployments.

## Secrets: rotation without downtime

Rotation exists to stop working the moment you start it, so the mechanism has to
survive the switchover.

The standard pattern uses staged labels rather than overwriting in place:

| Label | Meaning |
| --- | --- |
| **current** | In use. Applications read this. |
| **pending** | Written, not yet validated. |
| **previous** | Retained briefly so an in-flight consumer can still complete. |

Rotation proceeds in four steps: **create** the new value, **set** the live
secret to it, **test** it, then **finish** by promoting pending to current. The
staging labels are the whole zero-downtime mechanism, because an application
reading `current` keeps working throughout validation.

The failure mode to guard: after `set`, the new value is live, so the `test`
step is not optional. If it fails, you still have `previous`.

```sh
aws secretsmanager rotate-secret --secret-id "prod/db/master" \
  --rotation-lambda-arn arn:aws:lambda:... \
  --rotation-rules '{"AutomaticallyAfterDays": 30}'
```

Two constraints that catch people:

- **Rotation intervals cannot be shorter than one day.** For faster rotation,
  drive it from a scheduler instead.
- **Applying a rotation to every instance at once is the outage.** A database
  credential that changes everywhere at the same time is a full outage, and the
  rotation mechanism above is what avoids it.

Verify after rotating that the **current** version is the one actually in use.
A rotation that appears to succeed while the old version is still live, or while
an intermediate version is current, produces an intermittent authentication
failure that is very hard to see.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We can clean up flags later." | Ten flags means 1,024 untested paths, and later is when nobody remembers why. |
| "Remove the flag, keep the code." | The code is the leftover. Removing the flag first hides it. |
| "Kill switches are flags, expire them too." | They are required to exist. Expiring them removes a capability. |
| "We will rotate manually, carefully." | A manual rotation applied everywhere at once is the outage. Use staged labels. |
| "Hourly rotation would be better." | Intervals under a day are not supported. Drive it from a scheduler. |
| "The flag is set to 100 percent, so it is safe." | Fully rolled out is one of three conditions. Check code references too. |
