---
description: "Use when changing an API in a breaking way, or choosing a versioning scheme."
---


# API contract versioning

## Find out whether you can break it first

Before choosing a strategy, establish what you actually control:

```sh
grep -rn "api/v[0-9]\|/v[0-9]/" --include='*.ts' --include='*.py' . | head
```

- **Internal clients you deploy together?** Version nothing. Deploy the change
  and the callers together. A version header is pure overhead.
- **Public or externally consumed clients?** You cannot force a deploy, so you
  need compatibility to exist in time.
- **Unknown consumers, including scripts someone wrote once?** Assume public.

The answer decides the strategy, and guessing wrong is expensive in both
directions: versioning an internal API costs forever, and not versioning a
public one costs your users.

## The compatibility checklist

A change is **breaking** if it does any of these:

| Change | Breaking? |
| --- | --- |
| Removes or renames a field | Yes |
| Adds a required request field | Yes |
| Changes a field's type | Yes |
| Narrows an enum, even to add a value | Yes, for exhaustive clients |
| Tightens validation on existing input | Yes |
| Changes a status code for an existing case | Yes |
| Changes default sort order or pagination size | Yes |
| Adds an optional response field | No, unless clients are strict |
| Loosens validation | No |

**Adding a value to an enum is breaking** even though it looks additive. A
client that switches exhaustively will fall through.

**Adding an optional request field** is breaking for clients with strict
validation, which includes most generated ones.

## Strategies, and when each is right

**Additive only.** The safest and most common. Add fields, never remove or
change; keep the old field populated and deprecated. Works for years because
almost nothing is truly breaking.

**Explicit versioning in the path.** `/v1/orders` and `/v2/orders`. Obvious,
works, and every version is permanent maintenance. Prefer it over header
versioning when there is any doubt: a URL version is visible in logs, caches and
support conversations, and a header version is silently ignored by caches.

**Header versioning.** `Accept: application/vnd.acme.v2+json`. Clean URLs,
worse operability. Do not choose it for aesthetic reasons.

**Date-based.** `2024-01-01`. Fine for event streams, unnecessary for request APIs.

## Tolerant reader, strict writer

The property that makes additive change safe:

- **Clients must ignore unknown fields.** Never validate that a response has
  exactly the fields you expect.
- **Servers must ignore unknown request fields**, for the same reason, or every
  client becomes a breaking change.
- **Never change a field's meaning in place.** A field that means something else
  now is a new field with a new name.

Generated clients are where this fails: strict parsing of an unknown response
field breaks the client even though the server is being additive.

## Deprecation with a real path

A deprecation nobody can act on is not a deprecation:

1. Mark it deprecated in the API documentation and in the response schema.
2. **Return a machine-readable signal**, so a client can find every call site:
   - a `Deprecation` or `Sunset` response header
   - a `Link` with `rel="deprecation"` pointing at the migration guide
   - a warning field in the response body
3. Announce a **date**, not "eventually".
4. Instrument usage per client, so you know who is still calling it and can
   contact them.

The `Sunset` header carries an HTTP date, which is the standard place for this.

## When you must break

Sometimes additive is impossible: a security fix, or a semantic change that
cannot be represented alongside the old meaning.

Then do all of it, in order:

1. Ship the new version alongside the old. Both served.
2. Instrument usage of the old version, and contact the remaining callers.
3. Return a sunset date and the migration path in every response.
4. Remove the old version **only after usage is zero**, and announce the removal
   date when you announce the addition.

Removing first and apologising later is the failure mode here. It converts a
migration into an outage for whoever you did not reach.

## Schema changes are contract changes

If you publish a schema, changing it is breaking regardless of the HTTP
compatibility rules:

- Adding a required property to a request schema is breaking.
- Adding an enum value is breaking for exhaustive clients.
- Changing nullability is breaking.
- Removing anything is breaking.

Publish the schema, version it, and generate clients from it so the contract is
enforced mechanically rather than by documentation. See
`dependency-supply-chain-review` for pinning generated artifacts.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "It is internal, no need to version." | Then remove fields freely, but check for scripts and one-off consumers. |
| "Adding a field is always safe." | It breaks strict clients, and adding an enum value breaks exhaustive ones. |
| "We will announce the removal later." | By then someone has integrated. Announce the addition. |
| "Nobody uses the deprecated endpoint." | You can instrument that, rather than believe it. |
| "Header versioning keeps URLs clean." | Caches and logs lose it. Use the path unless there is a real reason. |
