---
name: dimensional-modeling
description: Use when designing a warehouse schema, or a slowly changing dimension.
---

# Dimensional modeling

## Surrogate keys come first

Facts store a generated integer key, not the source system's identifier. This is
step zero, not an optimisation, because everything else depends on it:

- It survives the source **renumbering** identifiers, which happens on merges and
  migrations and breaks joins permanently.
- It is fixed width, so indexes stay small.
- It is meaningless, which is exactly what makes it safe to let multiple source
  systems feed the same dimension.

```sql
-- generated, never the source id
row_number() over (order by source_system, source_id) as customer_key
```

Keep the natural key alongside it. The surrogate key is what facts join on; the
natural key is what you look up to find it.

## Grain is the most important decision, and it is made once

The grain is the level of detail a fact table holds: one row per order line, one
per order, one per customer per day.

State it in one sentence and put it in the model documentation. Then check every
column is at that grain. A measure that is not at the grain, such as an order
total on an order-line fact, invites aggregation that double-counts it, and the
error is invisible until a total exceeds revenue.

Two tables at different grains should not be joined without an explicit
aggregation, because that join is where fan-out errors come from.

## Slowly changing dimensions, chosen per attribute

The common misconception is that a dimension is Type 1 or Type 2 as a whole. It
is chosen **per attribute**, and one dimension routinely mixes them:

| Attribute | Example | Type |
| --- | --- | --- |
| Loyalty tier | Changes rarely, and history matters for reporting | **2** |
| Display name | Cosmetic, no one reports the old value | **1** |
| Region | Occasionally changes, and prior values are analysed | **3** |

| Type | Mechanism | Keeps history |
| --- | --- | --- |
| 1 | Overwrite in place | No |
| 2 | New row with a new surrogate key, expire the old | Full history |
| 3 | New column for the prior value | One prior value only |
| 7 | Both surrogate and natural key on the fact | Full, with the natural key |

Type 2 is the default for anything money touches, because a revenue figure
attributed to the current value of a changing attribute is not reproducible. The
cost is that the dimension grows, so set a retention policy deliberately rather
than letting it grow unexamined.

## Star schema: conformed dimensions

Fact tables hold foreign keys and measures. Dimension tables hold the descriptive
attributes, and they are **conformed** across facts so a single customer
definition serves every subject area.

The common failure is a separate copy of "customer" per subject area, each with
its own attributes and its own idea of who a customer is. Reports then cannot be
combined across subjects, and the discrepancy is discovered during reconciliation
rather than before it.

## Degenerate dimensions

Transaction identifiers, such as an order number, live on the fact without a
dimension table. They exist to be looked up on demand. Do not create a dimension
for one.

## Fact table types

| Type | Holds | Measures |
| --- | --- | --- |
| Transaction | One row per event | Additive |
| Periodic snapshot | One row per entity per period | Semi-additive; do not sum across periods |
| Accumulating snapshot | One row per entity, updated as it progresses | Mixed; recomputed milestones are non-additive |

Snapshot tables are where the aggregation mistakes live. A quantity measured at
the end of each month is **not** additive across months; summing it gives a
nonsense number. Balance and count measures are semi-additive for exactly this
reason, and no design change fixes it. Name them clearly so the consumer knows.

## Performance

- **Partition by the column most filters use**, usually the date. Partitioning by
  a high-cardinality key such as a customer identifier scatters each partition
  across files and removes the pruning benefit.
- **Cluster or sort by the next two filter columns**, which lets a query skip
  data within a partition.
- **Star schema beats a flat wide table** for the same reason a normalised
  relational schema does: the descriptive attributes are stored once rather than
  repeated per fact row.
- Pre-aggregate only for a measured slow query. Materialising every combination
  is its own maintenance burden.

## Model changes are breaking for consumers

Renaming a column or changing a measure's definition silently breaks every
dashboard built on it. Treat the warehouse model as a published contract:
add columns rather than renaming, and when a definition changes, record it and
tell the consumers.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We will use the source id as the key." | It changes on renumbering and breaks every historical join. |
| "The dimension is Type 2." | Per attribute. One dimension commonly mixes Type 1, 2 and 3. |
| "We can have our own customer dimension." | Then reports cannot combine across subject areas. |
| "We will sum the monthly snapshots." | They are semi-additive. Summing gives a meaningless number. |
| "The grain is obvious from the columns." | Write it in one sentence. Half of fact-table errors are grain violations. |
| "We will rename it later." | The dashboards built against the old name are the breakage. |
