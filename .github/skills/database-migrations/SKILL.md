---
name: database-migrations
description: Use when running schema migrations or backfills, or when a migration blocks queries.
---

# Database migrations

## Know what each statement locks

PostgreSQL's lock table is the core of this skill. Only one lock blocks a
`SELECT`, and it is the one almost every migration takes:

| Operation | Lock | Blocks |
| --- | --- | --- |
| `SELECT` | ACCESS SHARE | only ACCESS EXCLUSIVE |
| `INSERT`/`UPDATE`/`DELETE` | ROW EXCLUSIVE | ACCESS EXCLUSIVE |
| `CREATE INDEX CONCURRENTLY`, `VACUUM`, `ANALYZE` | SHARE UPDATE EXCLUSIVE | writers' heavy locks |
| **`CREATE INDEX`** (plain) | **SHARE** | **all writers** |
| `ADD FOREIGN KEY` (validated) | SHARE ROW EXCLUSIVE | writers |
| **`ALTER TABLE`, `DROP TABLE`, `TRUNCATE`, `REINDEX`** | **ACCESS EXCLUSIVE** | **everything, including reads** |

`ALTER TABLE` takes `ACCESS EXCLUSIVE`. That is why the naive migration takes an
application offline, even when the change looks trivial.

## Always set a lock timeout

```sql
SET lock_timeout = '5s';
SET statement_timeout = '60s';
```

If the lock is not available within five seconds, **fail fast and retry later**.
Without a timeout the migration queues behind a long-running transaction and
holds the queue, blocking the entire application while nothing appears to be
happening.

Retrying later is correct. A migration that eventually succeeds is fine; one that
blocked production for nine minutes is not.

## Expand and contract

Split one breaking change into several reversible deploys:

1. **Expand.** Add the new column, nullable, no constraint. Old code is unaffected.
2. **Backfill.** In batches, not one giant `UPDATE`.
3. **Dual write.** New code writes both, reads the old. Or use a database trigger
   to populate the new column.
4. **Switch reads.** Deploy code reading the new column.
5. **Contract.** Stop writing the old one, verify zero readers, then drop it.

A rename is **three production deployments**, not one.

| Safe in a single deploy | Needs expand/contract |
| --- | --- |
| Add a nullable column | Rename a column |
| Add a table | Change a column type |
| Add an index, concurrently | Make a nullable column required |
| Add a FK as `NOT VALID` | Drop a column |

**Why dropping a column in one deploy breaks rollback:** old pods are still
serving and still select or insert that column. Drop it and every one of those
requests fails with "column does not exist". A two-second window is harmless; a
deploy that takes four minutes is not, and rolling back the *code* does not help
because the *schema* is already destructive.

The schema change must be the last thing that happens, and the last thing that is
rolled back.

## Type changes are not uniform

- `varchar(50)` to `varchar(100)` is instant, metadata only.
- `integer` to `bigint` **rewrites the entire table** under `ACCESS EXCLUSIVE`.

Use expand/contract for anything that rewrites.

## Building indexes on a live table

```sql
CREATE INDEX CONCURRENTLY idx_orders_customer ON orders (customer_id);
```

No write-blocking lock, with three costs:

- It **cannot run inside a transaction block**. Your migration tool must be told.
- It does two table scans and waits for older transactions, so it is
  significantly slower.
- **On failure it leaves an INVALID index behind.** `\d` shows `INVALID`; drop
  and retry, or use `REINDEX INDEX CONCURRENTLY`. A failed concurrent unique
  build still enforces its constraint afterwards, so a retry must account for
  that.

Only one concurrent index build per table at a time, and it is not supported on
partitioned tables; build per partition, then add the parent index as
metadata-only.

## Adding a constraint to a large table

```sql
ALTER TABLE orders ADD CONSTRAINT fk_customer
  FOREIGN KEY (customer_id) REFERENCES customers(id) NOT VALID;
ALTER TABLE orders VALIDATE CONSTRAINT fk_customer;
```

The `NOT VALID` add skips the scan. The validate takes `SHARE UPDATE EXCLUSIVE`,
which blocks neither readers nor writers. Adding `NOT NULL` directly scans the
whole table under a heavy lock; this is the correct way to avoid that.

## Backfilling without starving the database

Use a keyset cursor in batches, each batch a short transaction:

```sql
UPDATE orders SET customer_id = $1
WHERE id > $2
ORDER BY id
LIMIT 5000;
```

Sleep between batches. One transaction over ten million rows holds locks for
minutes and generates a WAL volume that fills the disk.

## Other rules with teeth

- **Never hold a transaction open while waiting for user input.** A transaction
  seeking a table or row lock waits indefinitely for conflicting locks to be
  released, which is a deadlock with extra steps.
- **Avoid deadlocks by always acquiring locks on multiple objects in a
  consistent order.** You cannot predict which transaction a deadlock detector
  will abort, so **retry** aborted transactions.
- Advisory locks have a footgun: `SELECT pg_advisory_lock(id) FROM t WHERE id > x
  LIMIT 100` may leave dangling locks, because the `LIMIT` is not guaranteed to
  be applied before the locking function runs. Subquery first.
- Check for `NOT NULL` and FK constraints in `pg_constraint` as well as the
  table; they may live in a parent partition.

## Verify

```sh
psql -c "SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE NOT granted;"
```

If a migration is blocked, this shows what is blocking it. `granted = false` is
the queue you are about to join.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The table is small, we do not need a lock timeout." | Small today. The timeout is one line and protects the migration that follows. |
| "We can drop the column in the same deploy." | Old pods still use it. Every in-flight request fails. |
| "`CREATE INDEX` is faster." | Plain `CREATE INDEX` takes SHARE and blocks every writer. Use `CONCURRENTLY`. |
| "The backfill will be quick." | One transaction over ten million rows holds locks and generates enormous WAL. |
| "A deadlock means something is wrong." | It means two transactions disagreed on lock order. Fix the order, and retry. |
