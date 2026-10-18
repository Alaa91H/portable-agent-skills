---
name: caching-and-stampedes
description: Use when adding or tuning a cache, or when a hot key overwhelms the database.
---

# Caching and stampedes

## Know the failure before you choose the defence

A thundering herd has a number, and it is worth computing:

```
2,000 requests/second hit one key
the query takes 400ms
miss window = 400ms
herd size = 2,000 x 0.4 = 800 concurrent identical queries
```

Without a lock that is 115,200 database queries a day for one key. With a
singleflight lock, 144.

Note the framing: **Redis is usually not the cause.** It amplifies a traffic
spike when the caching strategy is misconfigured, and copes with it fine. The
database behind it does not cope.

## Four defences, in order of effort

**1. Singleflight / lock.** One caller goes to the database; the rest wait
briefly and re-read the cache.

```go
// golang.org/x/sync/singleflight
v, err, _ := group.Do(key, func() (any, error) { return db.Query(key) })
```

```bash
SET cache:key <value> NX EX 30
```

The lock **must have its own expiry**. Without one, a crashed holder blocks every
other replica permanently, which is a worse outage than the herd.

**2. Probabilistic early expiration.** Recompute when
`now - delta x rand() > (timeToExpiry x beta)`, so refreshes happen *before*
expiry and no request ever blocks waiting.

**3. Stale-while-revalidate.** Serve the stale value, refresh in the background.
The cost is an answer up to N seconds old.

```http
Cache-Control: max-age=3600, stale-while-revalidate=600, stale-if-error=86400
```

`stale-if-error` is your **origin-outage safety net**: stale content is served
on 5xx or an unreachable origin.

**4. CDN edge coalescing.** The edge collapses concurrent misses into one origin
fetch, shielding the origin completely.

## Jitter is mandatory

Fixed TTLs mean every key created by the same deploy expires at the same moment.
A per-key lock cannot fix that, because the keys were created together.

```
ttl = base_ttl +/- random(0, 300s)
```

Without jitter you have replaced a distributed stampede with a synchronised one,
which is easier to see and just as damaging.

## Directive semantics people get wrong

| Directive | Actual meaning |
| --- | --- |
| `no-store` | Do not store it at all. Use for anything credential-bearing. |
| `no-cache` | You may store it, but revalidate before reuse. **It does not prevent caching.** |
| `private` | Per-user cacheable, not shared-cacheable |
| `must-revalidate` | Once stale, refetch or fail; never serve stale |

The `no-cache` confusion is a real data leak: a response marked `no-cache` is
still written to disk, and the requirement is only that it be revalidated.

## Key design

- Include a **schema version** in the key, so a deploy that changes the value
  shape cannot serve old-shaped data out of the cache. This is the most common
  cause of a bug that appears only right after a release.
- Include every dimension that changes the result: tenant, locale, feature flag.
- **Negative-cache misses with a short TTL.** Without it, a 404 flood hits the
  origin every time.

## Eviction policy

`allkeys-lru` versus `allkeys-lfu`. LFU is better for scan-resistant workloads,
which is exactly what a hot-key workload is: a key requested once and never again
should occupy no space, and LRU still holds it.

## Verify rather than assume

```sh
redis-cli --hotkeys                  # sample the top keys by access
redis-cli info stats | grep keyspace_hit
```

`keyspace_misses` divided by `keyspace_hits` tells you the hit rate. If it is
low, the cache is paying its cost without delivering.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The cache will handle the hot key." | Redis serves one value to 800 waiters. The database still takes 800 queries. |
| "We need a distributed lock, not singleflight." | In-process deduplication is free and usually sufficient. Add the lock when one process is not enough. |
| "A lock without a TTL is simpler." | It is a permanent outage waiting for the holder to crash. |
| "Fixed TTLs are easier to reason about." | They synchronise every key created by the same deploy. Add jitter. |
| "`no-cache` means do not cache." | It means revalidate. Use `no-store` for secrets. |
