---
name: performance-profiling
description: Use when a program is slow or memory grows, or when profiling CPU.
---

# Performance profiling

## Profile before changing anything

An intuition-led optimisation is a guess that costs a refactor. A profile is
twenty minutes and tells you which change is worth making.

## Reading a flame graph

- **Width is time spent**, inclusive of children. **Height is stack depth.**
- **A wide plateau at the top is where the work is.** That is where you optimise.
- Bar colour is random and carries **no meaning** by default.
- **Compare two profiles against each other** rather than reading an absolute
  one. A differential flame graph shows what a change made worse far faster than
  staring at a single profile.

Go ships the flame graph view in its own web interface, so no third-party tool is
needed:

```go
import _ "net/http/pprof"
go http.ListenAndServe("localhost:6060", nil)
```

```sh
go tool pprof -http=:8080 'localhost:6060/debug/pprof/profile?seconds=30'
go tool pprof -top -focus='json'  localhost:6060/debug/pprof/profile
go tool pprof -list=parseRequest server.out   # annotated source, fastest way to find the hot line
```

Capture **about 30 seconds under real load**, not in a microbenchmark. The
benchmark is not what your users experience.

## CPU profiling only sees on-CPU time

If the program is *waiting*, CPU profiles will look fine and the problem will
still be there. Waiting means I/O, lock contention, and downstream latency, and
it needs **off-CPU analysis** rather than a faster CPU.

That distinction explains most "the profiler says the app is idle but users say
it is slow" reports: the threads are blocked, not computing.

Prefer **allocation profiles** over page-fault sampling. Allocation happens
millions of times per second and is cheap to sample; page faults are rare.

## Memory leaks

Compare **allocation rate over time**, not just total heap. The leak signature is
`inuse_space` climbing while `alloc_rate` stays high.

In Go, always set `GOMEMLIMIT`. Without it the garbage collector thrashes near the
hard limit and you get an OOM kill instead of a slower, correct collection.

The usual causes:

- Unbounded maps, caches, or slices that only grow.
- Goroutine leaks; each one holds its stack and its captured variables.
- `defer` inside a long loop, which accumulates until the function returns.
- Closures capturing a parent frame that then cannot be collected.
- String concatenation in a loop, which is quadratic in allocation volume.

## Find the N+1 first

**ORM lazy loading is the default generator of N+1 queries**, and it is invisible
in development: five rows locally, fifty thousand in production.

```sql
-- EXPLAIN (ANALYZE, BUFFERS) shows the signature
Nested Loop  (actual rows=50000 loops=50000)
```

Look for a `Nested Loop` with a high `loops=` count. That is N+1 expressed in the
plan.

Detect it mechanically rather than by inspection:

```sh
grep -c "SELECT" app.log        # query count per request
```

Log the query count per request and alert above a threshold. It moves before
latency does, which gives you warning rather than a dashboard.

In many ORMs a single include/prefetch setting removes most of them.

## Connection pool exhaustion fails as a hang

The failure mode is a queue, not an error. When the pool is exhausted, requests
**block waiting for a connection** until the timeout. Latency climbs, then
requests time out, often **while still holding the connections** whose work never
finished. That is a death spiral.

The arithmetic that gets people woken up:

```
replicas x pool_size + admin headroom <= max_connections
```

Ten replicas at twenty connections each is 200, against a PostgreSQL default of
`max_connections` of 100. That is "too many clients already" at two in the
morning.

- Always set a **pool timeout**, so exhaustion surfaces as a fast error rather
  than an unbounded hang.
- Acquiring a connection must be **inside the request budget**. Holding one
  while making a thirty-second call to a third party is the most common root
  cause; acquire the connection, fetch, release, then call out.
- Watch for leaked connections on error paths that skip the release.
- PgBouncer in transaction pooling mode decouples this, but it breaks
  session-level features: `SET` outside a transaction, prepared-statement
  assumptions, and session-scoped advisory locks.

## Check complexity before micro-optimisation

A profile full of your own code inside `json.Marshal`, a regular expression, or a
sort usually means the wrong algorithm, not a slow CPU.

The classic O(n²) patterns in application code:

- Nested loops over database results.
- `in` or `includes` against a **list** instead of a **set**.
- Repeated string concatenation in a loop.
- `WHERE id IN (...)` chunked badly so it becomes many round trips.
- A deep copy inside a request handler.

Sorting ten thousand items to take the top ten is `O(n log k)` with a heap or a
partial selection, not a full sort.

## Verify the fix

Re-profile after the change and compare. A change that made the profile wider did
not help, even if the microbenchmark improved. And benchmark with realistic
cardinality: five rows in a fixture hides every N+1 in existence.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "It is obviously the database." | Take a profile. It is often the code that made the queries. |
| "The CPU profile looks fine." | Then the program is waiting, not computing. Use off-CPU analysis. |
| "We already tuned the query." | A Nested Loop with 50,000 loops is an N+1, not a tuning problem. |
| "We need a bigger pool." | Check replicas times pool size against max_connections first. |
| "The benchmark improved." | Benchmark with realistic cardinality, and re-profile the real path. |
