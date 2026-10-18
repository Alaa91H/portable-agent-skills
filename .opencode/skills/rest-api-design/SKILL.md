---
name: rest-api-design
description: Use when designing or reviewing an HTTP API: errors, pages, idempotency.
---

# REST API design

## Error bodies are RFC 9457 Problem Details

Media type `application/problem+json`. Not a bespoke envelope.

```json
{
  "type": "https://example.com/probs/out-of-credit",
  "title": "You do not have enough credit.",
  "detail": "Your current balance is 30, but that costs 50.",
  "instance": "/account/12345/msgs/abc",
  "balance": 30
}
```

Four rules models break most often:

- **`status` is advisory.** The real HTTP status must match it. Proxies, caches
  and WAFs never read the body. Returning `200` with `"status": 500` inside is a
  spec violation, not a flexible design.
- **`title` must not vary between occurrences.** Interpolating a user value into
  `title` is wrong; that is what `detail` is for. `title` is a stable, localisable
  label.
- **`detail` is not machine-readable.** The spec says clients SHOULD NOT parse
  it. Anything a client must branch on belongs in an extension member.
- **`type` and `instance` must be absolute URIs.** A relative `type` resolves
  against the document's own base, so `"out-of-credit"` under `/account/12345`
  and `/widget/456` resolve to two different resources.

Omit `type` for generic conditions rather than inventing one; absence means
`about:blank`, "no semantics beyond the status code."

For validation errors, use the sanctioned `errors` array with RFC 6901 JSON
Pointers, since clients need the exact field:

```json
{
  "type": "https://example.com/probs/validation",
  "title": "Validation failed",
  "errors": [
    { "pointer": "#/age", "message": "must be a non-negative integer" },
    { "pointer": "#/email", "message": "must be a valid address" }
  ]
}
```

## Status codes are a contract

| Code | Meaning | The distinction that matters |
| --- | --- | --- |
| `400` | Malformed or unparseable | A schema validator could have caught it |
| `401` | Not authenticated | Must include `WWW-Authenticate` |
| `403` | Authenticated, not permitted | |
| `404` | Not found, or hidden | Return 404 for a resource the caller may not know exists |
| `409` | Conflict with current state | A username already taken |
| `422` | Understood, rules rejected it | End date before start date |
| `429` | Rate limited | Include `Retry-After` |

The `409` versus `422` split decides whether a client should retry later: a 422
request can never succeed as written, a 409 might succeed after a re-read. Get
this backwards and clients retry forever.

**Never return `200` with `{"success": false}`.** It is the single most common
defect an assistant introduces into a REST API.

## Pagination: choose cursor before you have a problem

Offset pagination has two failure modes, and the second is invisible until
production:

- **Cost.** `OFFSET 99980` does not jump to row 99,981. The database scans,
  processes and discards 99,980 rows. Page 1 is instant; page 5,000 is unusable.
- **Shifting data.** While the user is on page 5, three rows are inserted. The
  offset advances *and* the data advances, so rows are duplicated and others
  silently skipped. Deletions leave permanent gaps.

Cursor pagination tracks records rather than positions, so it is immune. Rules
that make a cursor correct:

- The cursor must contain **every column in the `ORDER BY`**. Sorting by
  `view_count DESC, id ASC` and encoding only `id` is ambiguous.
- Make it opaque base64 with a version tag, so you can evolve it.
- Hard-cap `limit`, typically 100.

The real cost of picking wrong is that cursor pagination cannot be retrofitted.
You lose random page access ("jump to page 500"), and by the time it matters,
clients are integrated. Decide before launch.

```json
{ "data": [...], "next_cursor": "eyJ2I6NDAwLCJpZCI6MTIzfQ", "has_more": true }
```

## Idempotency for retried writes

A network timeout is not proof the server did not act. Idempotency keys make the
retry safe.

- Key on `POST` only. `GET` and `DELETE` are idempotent by definition and the
  key has no effect.
- Use a V4 UUID, maximum 255 characters.
- **Never derive the key from sensitive data.** It lands in logs.
- **Bind the key to a payload hash.** If the same key arrives with a different
  body, that is an error, not a replay. Silently replaying is how a client bug
  becomes data loss.
- Save the response only once the endpoint begins executing. Requests that fail
  validation or conflict with an in-flight request must not be recorded, so the
  client can correct and retry.
- **Cache the failure too.** Retries must replay the original 500. Only caching
  successes means a retried failing request executes twice.

## Query parameters

Allowlist the fields. This is both hygiene and a security boundary:

```
/orders?status=open&created_after=2026-01-01&sort=-created_at&limit=50
```

Never interpolate a user-supplied `sort` or `filter` name into SQL. Map it
through an allowlist:

```ts
const SORTABLE = { created_at: 'created_at', total: 'total_cents' } as const
const sort = SORTABLE[req.query.sort as keyof typeof SORTABLE] ?? 'created_at'
```

Cap `limit` server-side. A client asking for 100,000 rows is a denial of service
even when it is authenticated.

## Other things that are easy to get wrong

- `PUT` replaces the resource and is idempotent; `PATCH` is partial and should
  still be idempotent. `POST` is neither.
- Return `Location` on `201 Created`, and support it in the `Link` header for
  pagination (RFC 8288).
- `GET`, `HEAD`, `PUT`, `DELETE`, `OPTIONS` and `TRACE` must be side-effect free.
- Do not put secrets in a redirect URL. The `Referer` header leaks them.
- Timestamps in UTC with an explicit offset. See `api-contract-versioning` for
  when breaking changes are allowed.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Our error envelope is better." | Better than what? Clients already parse a standard shape, and RFC 9457 is that shape. |
| "200 with a body is fine for errors." | Proxies, caches and monitoring will all report success. |
| "Offset is simpler." | It is simpler until page 5,000, or the first concurrent insert. |
| "Nobody retries POSTs." | Mobile clients do, on timeouts, which are indistinguishable from failure. |
| "We can add pagination later." | Cursor pagination cannot be added without a breaking change. |
