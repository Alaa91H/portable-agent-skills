---
trigger: model_decision
description: "Use when exposing or reviewing a GraphQL API, or when it is slow or being abused."
---


# GraphQL API security and performance

## N+1 is the default failure mode

A nested selection issues one query per node:

```graphql
query { posts { author { posts { author { name } } } } }
```

Without batching this is dozens of round trips per request. OWASP ranks it the
primary denial-of-service vector against GraphQL, and it is invisible in
development because there are five posts and not fifty thousand.

**Batch by request scope**, not per node. Per-node memoization does not collapse
the queries; it only avoids repeating them within one node's own resolution.
DataLoader-style batching per request is what reduces N queries to a constant
number of `WHERE id IN (...)`.

Detect it before it ships:

```ts
server.use(CountQueryPerRequest)
app.use((req, res, next) => {
  res.on('finish', () => {
    if (req.queryCount > 50) log.warn({ queryCount: req.queryCount }, 'possible N+1')
  })
  next()
})
```

Alert on the query count per request. It moves before latency does.

## Enforce limits yourself: nothing is built in

GraphQL has no native depth or amount limiting. You must add both, because they
are two different attacks.

```ts
import depthLimit from 'graphql-depth-limit'
import { createComplexityLimitRule } from 'graphql-validation-complexity'

const server = new ApolloServer({
  validationRules: [
    depthLimit(7),
    createComplexityLimitRule(500, { scalarCost: 1, objectCost: 2 }),
  ],
})
```

- **Depth bomb**: `album { songs { album { songs { ... } } } }`, nested arbitrarily.
  Close it with a depth limit.
- **Amount bomb**: `posts(first: 99999999) { title }`. Depth 2, catastrophic.
  Close it with a complexity or cost analysis, which a depth limit does not catch.

Add pagination to every list field. It is the cheapest structural mitigation and
it makes both attacks less effective by default.

Apollo's own advice is to skip the analysis until you have confirmed you need it:
try to crash or slow down staging with a nasty query and see how far you get.

## Batching attacks are invisible to your edge

A single HTTP request can carry many aliased operations:

```graphql
{ d1: droid(id:"1"){name} d2: droid(id:"2"){name} d3: droid(id:"3"){name} }
```

That enumerates the whole table in one request. The same technique brute-forces
passwords and OTPs.

- **Rate limits based on HTTP request counts are bypassed.** One HTTP request is
  one request, however many operations it contains.
- **WAFs, RASP, IDS and SIEMs generally do not detect it**, because it looks like
  a single legitimate request.
- The mitigation must be in code: count operations per request, not requests per
  second. Disable batching for sensitive objects such as username availability,
  OTP verification and session tokens, and cap concurrent operations.

## Persisted queries: performance tool, not a security control

This distinction is the one models get wrong.

- **Automatic Persisted Queries (APQ)** let any client *register* a new query.
  That shrinks payloads from kilobytes of text to a hash. It is a performance
  feature with no security benefit, because registering is open to anyone who
  can reach the endpoint.
- **Static persisted queries** are the security control. The allowlist is
  maintained at deploy time, so an attacker can only run operations you chose.

Use APQ for performance. Use a safelist for security. In production, turn off
dynamic registration.

## Authorise on nodes, not only on edges

The canonical vulnerability (HackerOne #489146): authorization was checked on
every edge but not on the node objects themselves, so a field resolved directly
returned data the requester should not see.

Every resolver must confirm the requester may read the object it returns, not
only that they may follow the edge. A query like `{ user(id: "someone-else") { email } }`
bypasses a parent-scoped check entirely.

Look for a global `node(id: ID!)` field, which enables this by design:

```sh
curl -s localhost:4000/graphql -d '{"query":"{__schema{types{name}}}"}' | jq '.data.__schema.types[].name'
```

If introspection works in production, an attacker learns your entire schema.
Disable introspection and GraphiQL, **and disable the "Did you mean ...?" field
suggestion feature**, because schema discovery still works by brute force with
introspection disabled.

## Configuration errors that leak

```ts
new ApolloServer({
  // explicitly false in production; log the trace server-side instead
  includeStacktraceInErrorResponses: false,
  introspection: process.env.NODE_ENV === 'production' ? false : true,
})
```

A stack trace in a production GraphQL response is a map of your internal
modules, versions and database driver. Never let it escape.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Our query is shallow." | The client sends the query. Depth limits protect you from the client. |
| "DataLoader fixes it." | DataLoader batches per request. You still need limits on the shape of the query. |
| "The WAF will rate limit us." | One HTTP request bypasses request-count limits entirely. |
| "APQ blocks unknown queries." | It does not. APQ lets anyone register. Use a safelist for that. |
| "Introspection is already disabled." | Fields can still be brute-forced. Disable suggestions too. |
