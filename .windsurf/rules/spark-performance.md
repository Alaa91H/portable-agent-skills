---
trigger: model_decision
description: "Use when a Spark job is slow, data skew is suspected, or joins break."
---


# Spark performance

## Adaptive Query Execution is already on

Since Spark 3.2, AQE is enabled by default. If you are configuring it, you are
usually working from a stale blog post rather than a measured problem.

The failure it introduces is worse than the problem it solves. AQE coalesces
small partitions at the end of a shuffle, which **breaks the `cache` and
`persist` reuse path** that worked before. Cached data is not reused, the job
gets slower after enabling caching, and AQE is blamed.

## Skew needs two conditions, not one

A partition is only considered skewed when **both** hold:

| Condition | Default |
| --- | --- |
| Size exceeds `median x skewedPartitionFactor` | **5.0** |
| Size exceeds `skewedPartitionThresholdInBytes` | **256 MB** |

```sh
--spark.sql.adaptive.advisoryPartitionSizeInBytes=134217728
--spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes=268435456
```

**The trap**: a partition of 250 MB with a 50 MB median is five times the median,
but it does not exceed the 256 MB absolute threshold, so it is **not** treated as
skewed. Both conditions must hold. Lowering the threshold is often the fix that
works, and raising the factor is usually the wrong lever.

## Skew optimisation does not apply to every join

| Join | Left side optimised | Right side optimised |
| --- | --- | --- |
| INNER, CROSS | Yes | Yes |
| LEFT OUTER | Yes | **No** |
| RIGHT OUTER | **No** | Yes |
| LEFT SEMI, LEFT ANTI | Yes | **No** |
| **FULL OUTER** | **No** | **No** |

And it **does not apply to broadcast joins at all**. If you converted a skew
problem to a broadcast join to escape it, you may have traded one problem for
another: broadcast hashes the whole side into every executor, which costs memory
proportional to that side.

## Diagnosing skew

In the Spark UI, look at **Shuffle Read Size by Task**. One towering bar among
many small ones is skew, unambiguously.

In the plan, a sort-merge join node flagged with skew.

The usual cause is a key with a Zipfian distribution: a popular product, a
country, a status value that is 90 percent one thing. The fixes, in order of
preference:

1. **Broadcast the small side.** Right for a genuinely small dimension.
2. **Salt the key.** Add a random or bucketed suffix so the hot rows spread
   across partitions, then de-aggregate afterwards.
3. **Pre-aggregate the hot key separately** when it is hot enough to justify it.

## Shuffles are the thing to remove

Every shuffle writes to disk and reads back. The levers that remove one entirely:

- **Broadcast join** for a small dimension. Watch the memory: it is collected
  per executor.
- **Bucket joins**, which pre-partition both sides by the join key so the shuffle
  is a metadata operation.
- **Partitioning to match an existing layout**, so a downstream stage does not
  reshuffle.

## Serialization and file formats

- Use a columnar format (Parquet or ORC) rather than JSON for anything repeated.
  JSON parsing dominates runtime on wide records.
- Filter and select the columns you need **before** the write, since a shuffle
  moves whole rows.
- ORC snappy or parquet snappy are the usual defaults. Compression affects IO and
  CPU in opposite directions, so measure rather than assume.

## Small files ruin performance

A thousand small files means a thousand task launches, each with fixed
overhead, and the executor spends its time scheduling rather than computing.

```sql
-- a compact file source avoids a separate shuffle
CREATE TABLE t USING parquet PARTITIONED BY (dt) LOCATION 's3://bucket/t'
TBLPROPERTIES ('parquet.mergeSchema' = 'true');
```

Coalesce small files on write, and check the input for the small-file problem
before blaming the engine.

## Caching

Cache only when the same dataset is genuinely used more than once, and prefer
`persist` over `cache` so you choose the storage level. An in-memory cache that
does not fit spills to disk, which is a shuffle wearing a disguise.

Remember the AQE interaction above: if caching appears to do nothing, test with
AQE disabled before concluding the cache is useless.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "A partition five times the median is skewed." | It also has to exceed the absolute threshold. Both conditions must hold. |
| "Skew optimisation fixed my join." | It does not apply to broadcast joins or the right side of a left outer join. |
| "Cache the input." | AQE coalescing can break cache reuse entirely. Test with it off. |
| "Fewer tasks means less overhead." | Only past the point where a task has useful work. Too few means no parallelism. |
| "Parquet is always faster." | It wins on IO and column pruning, and loses on write cost for one-shot writes. |
| "We need more executors." | More executors on skewed data adds tasks that wait on the hot partition. |
