---
description: "Use when cutting a release, writing a changelog, or planning a rollback."
---


# Release engineering

## Version numbers are a contract

Semantic versioning is a promise about **compatibility**, not about magnitude.

| Change | Bump |
| --- | --- |
| Anything a consumer could notice: a removed field, a changed default, a fixed bug | **PATCH** or **MINOR** |
| New functionality that is backward compatible | **MINOR** |
| Anything that breaks a consumer | **MAJOR** |

The judgement is about the consumer, not the diff. Renaming an internal helper is
a patch. Changing a default value that alters behaviour is a minor or major,
because every consumer's behaviour changed without their code changing.

Pre-release suffixes (`2.0.0-rc.1`) make the version sort before the release,
which is what you want: a client depending on `^2.0.0` does not silently adopt
the release candidate.

## The changelog is written for the person deciding whether to upgrade

Group by **what changed for the user**, not by commit type. A reader wants to know
what will break and what is worth adopting.

```markdown
## 3.2.0

### Breaking
- `createOrder` now requires `customerId`. The optional path was deprecated in 3.1.

### Added
- Partial refunds via `refundOrder(orderId, { amountCents })`.

### Fixed
- Webhook signature verification failed for payloads over 64KB.

### Deprecated
- `legacyExport` — removed in 4.0. See the migration guide.
```

Three things this format does that a generated one does not:

- **Breaking changes are unmissable**, in their own section, not filed under
  "changed".
- **Deprecations are announced with the version that removes them**, so the
  warning is actionable.
- **Entries name the API**, so a reader can find theirs.

Write it for the reader, not from the commit log. `git log` is an input, not an
output.

## Ship small and often

The cost of a release is roughly proportional to how much it changes. That makes
the trade explicit:

- Small releases mean small blast radius and a fast rollback.
- Long-lived branches mean a rebase conflict at the worst moment, which is the
  subject of `finishing-a-development-branch`.

A release train where everything waits for the next window turns every change
into a conflict, and every conflict into a delay.

## The artifact is immutable

The thing that shipped is not the branch. It is a specific, identified, immutable
artifact.

```sh
git tag -a v3.2.0 -m "3.2.0"
docker push registry.example.com/api:3.2.0
# pin by digest for anything you must be able to reproduce
docker push registry.example.com/api@sha256:...
```

Never rebuild an old version from a branch and assume it is the same artifact.
Compilers, dependency resolution and build environments all drift, so a rebuild
is a new build with a familiar name.

Tag the commit the release came from, and deploy **the tag**, not a branch. A
deployment that says which artifact is running is answerable during an incident.

## Rollback is a design property

Decide the rollback path **before** shipping, and check it exists. It is the
single question to ask when a release goes wrong.

The three cases, and they have different answers:

| Situation | Roll back? | Notes |
| --- | --- | --- |
| Bad code, no data change | Yes, quickly | The good outcome |
| Bad code **with** a schema change | Only if the change is backward compatible | See `database-migrations` |
| Bad data, correct code | No | Roll the data back, not the code |

The middle row is the one that catches people. A deploy that drops a column and
rolls the code back leaves old pods querying a column that no longer exists, and
rolling the code forward does not restore the data. **The schema change must be
the last thing to happen and the last thing to be rolled back.**

For the data case, have a rehearsed answer before you need it: a restore, a
compensating script, or a forward fix. Deciding during the incident is deciding
under pressure.

## Pre-release verification

Before tagging, verify what will actually ship:

```sh
git tag --list 'v*' --sort=-v:refname | head -5   # what already exists
git log --oneline v3.1.0..HEAD                    # what is in this release
git diff --stat v3.1.0..HEAD                      # how big it is
```

Then run the checks in the order that fails fastest: build, types, unit tests,
integration tests, and only then the slow end-to-end suite. A release that fails
after twenty minutes of end-to-end runs taught you nothing you would not have
learned in thirty seconds.

Check the version you are about to tag does not already exist. A duplicate tag
that points at a different commit is one of the harder things to unpick.

## Deprecation has a shape

Announce, then remove, with a date in between.

1. Mark it deprecated in the documentation and in the code.
2. Return a **machine-readable signal** so consumers can find every call site.
3. Announce the version that removes it.
4. Remove it only after usage is zero, and say so when you announce the addition.

Removing first and apologising later converts a migration into an outage for
whoever you did not reach. See `api-contract-versioning` for the versioning
mechanics.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "It is only an internal refactor." | A changed default alters every consumer's behaviour. |
| "The changelog comes from the commits." | Commits are an input. The reader needs breaking changes and deprecations surfaced. |
| "We will tag after the deploy." | Then the tag and the running artifact can disagree. |
| "We can rebuild the old version if needed." | A rebuild is a new build. Pin by digest. |
| "Rollback works for this one." | Only if no schema change is involved, and that is the case to check. |
| "The release train is easier to manage." | It concentrates every conflict at the worst moment. |
