---
trigger: model_decision
description: "Use when writing concurrent code, or diagnosing races and deadlocks."
---


# Concurrency and async

## Know which kind of concurrency you have

They fail differently, and mixing them is where the interesting bugs live.

| Model | Where it runs | Failure mode |
| --- | --- | --- |
| Threads | OS threads, shared memory | Data races, deadlocks, starvation |
| Async / event loop | One thread, interleaved tasks | Blocking the loop, lost awaits |
| Processes | Separate memory | Communication cost, no shared state |
| GPU | Thousands of lanes | Occupancy, divergence between lanes |

"Slow" is usually one of these: the event loop is blocked, a lock is contended,
or the parallelism is real but the work is not parallelisable.

## Blocking the event loop

The single most common Node defect. **An `await` only yields if the awaited
thing is actually asynchronous.** A synchronous operation inside an async
function blocks every other task for its full duration.

```js
// blocks the entire process for the duration of the hash
const digest = crypto.createHash('sha256').update(hugeBuffer).digest('hex')

// blocks for the whole query
const rows = await someSyncDatabase.query(sql)
```

With one event loop, a five-second synchronous hash means every other request in
the process waits five seconds. That presents as "the API is randomly slow under
load" and never correlates with the request you are debugging.

Move it to a worker thread, a process pool, or a native async API.

## Blocking the async pool

In Java and other bounded-pool runtimes, the same mistake appears as
`BlockingQueue` inside an event loop, or a synchronous database call inside a
reactive chain. The pool is bounded, so the failure is not slowness but a
**deadlock**: every thread waiting for work that can never be submitted.

Rule: a synchronous call inside an async chain must be offloaded, not merely
wrapped.

## The await that is not awaited

```js
// the function returns before the write completes, and its rejection is unhandled
async function save(record) {
  db.write(record)      // missing await
}
```

Three concrete consequences: the caller proceeds before the write lands, an
error becomes an unhandled rejection that may be swallowed, and a test that
asserts on the written state fails intermittently.

The same applies to a promise stored and forgotten, and to a callback API called
inside a promise chain without promisifying it first.

**`Promise.all` rejects on the first failure and abandons the rest.** If the
remaining work must still happen, use `allSettled` and handle each outcome.

## Cancellation is a requirement, not a feature

Every concurrent operation needs a way to stop.

```js
const controller = new AbortController()
setTimeout(() => controller.abort(), 5000)
await fetch(url, { signal: controller.signal })
```

An operation that cannot be cancelled holds its slot until it completes, however
long that takes. With a bounded worker pool, enough uncancellable work starves
everything behind it, and the symptom is a gradual total freeze rather than an
error.

Propagate the signal through your own layers. A timeout at the outermost call
does nothing if the inner function ignores it.

## Locks and deadlocks

- **Always acquire multiple locks in a consistent global order.** This is the
  only reliable way to prevent deadlock; detection and retry are mitigation.
- **Never hold a lock across an `await`.** The lock may be held by the time the
  continuation runs, and the order is no longer the order you wrote.
- **Prefer a single lock over several.** A coarse lock has a longer critical
  section; many fine locks have a combinatorial deadlock surface.
- If you must detect, a deadlock detector that reports the wait graph beats a
  timeout, because a timeout does not tell you what is holding what.

```java
// retry on deadlock rather than assuming the first order is right
try {
  transfer(from, to, amount);
} catch (TransientTransactionException | DeadlockLoserDataAccessException e) {
  // retry with backoff
}
```

## Shared mutable state

- **Make the shared state immutable.** Then there is nothing to lock and nothing
  to race on. This is the highest-leverage fix and it is usually available.
- **Isolate per-task state.** A single module-level mutable accumulator shared
  across tasks is a race that only appears under concurrency.
- **Double-checked locking requires a volatile field**, or the second thread
  sees a partially constructed object.

```js
let cache = new Map()                       // safe: rebuilt on miss
let hits = 0                                // unsafe: shared mutation
```

- In Go, the data race detector is not optional tooling: `go test -race`. In
  JavaScript with worker threads, the same applies. In Rust, the compiler
  prevents the whole class.

## Rate limiting and backpressure

Unbounded concurrency converts a slow dependency into an outage. Every outbound
call needs a bound.

```js
// a queue with a fixed worker count, not Promise.all over an unbounded list
const limit = pLimit(20)
await Promise.all(items.map(item => limit(() => process(item))))
```

And every retry needs a budget. Retries with no cap against a struggling
dependency are a denial of service you are generating yourself: exponential backoff
with jitter, a total attempt count, and only on retryable errors.

## Testing concurrent code

**A test that passes once proves nothing here.** Run the failing scenario in a
loop, or with an artificially tight interleaving:

```sh
go test -race -count=100 ./...
```

Most races appear on a handful of runs. If a test is intermittent, the defect is
usually real and the test is simply not exercising the window that triggers it.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The hash is fast enough." | On one request, yes. Under concurrency it blocks every other task. |
| "It is await, so it yields." | Only if the awaited operation is genuinely async. A sync call inside does not yield. |
| "Promise.all is fine." | It abandons the rest on the first failure, and it launches everything at once. |
| "We can add the timeout at the entry point." | Only if every layer propagates the signal. |
| "The lock is released before the await." | Only if nothing between can re-enter it. |
| "It works on my machine." | Interleaving is timing-dependent. Run the loop, with a race detector. |
