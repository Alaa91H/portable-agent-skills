---
description: "Use when designing backups, recovery objectives, or planning for loss."
---


# Backup and disaster recovery

## A backup that has not been restored is a hypothesis

The only question that matters is whether a restore has ever been performed, on
schedule, by someone who had not written the backup script. Everything else is
configuration optimism.

```sh
# monthly, automated, into a clean environment
# the run is not the deliverable; the successful restore is
```

Test three failures separately, because they have different causes and different
fixes:

| Failure | What proves it works |
| --- | --- |
| The database host is destroyed | Restore to a new instance |
| The region is unavailable | Restore in another region |
| Someone deleted data an hour ago | Point-in-time restore to a timestamp |

## Recovery objectives decide everything

Define them before choosing a technology, because they are what you are buying.

- **RPO**, recovery point objective: how much data loss you accept. Sixty
  minutes means your backups must be at most sixty minutes apart.
- **RTO**, recovery time objective: how long you accept being down. Fifteen
  minutes means a full restore of a large database is probably not viable, and
  you need replication rather than backup.

The common design error is picking a backup cadence and calling it an RPO. A
nightly backup has an RPO of twenty-four hours, and if that is unacceptable, the
cadence is wrong regardless of what the documentation says.

**Test against the largest dataset you have, not the average one.** Restore time
grows with volume, and the hourly database that restores in four minutes becomes
the one that takes four hours.

## Three things to keep, and why

| Copy | Survives | Cost |
| --- | --- | --- |
| Backups | Logical corruption, bad deploys, accidental deletion | Low |
| Point-in-time logs | Accidental deletion, with recovery to the minute | Low |
| Replicas | Region loss, and it shortens RTO | High |

Replicas are **not backups**. A `DROP TABLE` propagates to every replica within
seconds, and so does the mistaken `DELETE`. A replica protects you from
infrastructure failure, and from nothing else.

This is the single most common and most expensive misunderstanding in this
domain.

## The 3-2-1 rule, and what it actually means

Three copies, on two different media, one of them off-site.

On-site copies are a bet against one correlated failure. Fire, flood, a stolen
rack and a ransomware actor with domain administrator all take every local copy
together. The off-site copy is the one that survives the correlated event, which
is the only event worth insuring against.

**Immutable or offline storage is the part people skip.** A backup the
authenticated attacker can delete is not a backup. Object-lock or
write-once retention, or storage the production credentials cannot reach.

## Encryption and keys

Encrypt backups with a key the backup system cannot retrieve. If the key lives
in the same account and region as the backups, an attacker who compromises that
account can decrypt everything, and a restore test in a clean environment is
impossible without the key.

Key loss is indistinguishable from data loss, so store the key separately and
test that you can find it during a restore.

## Verify, do not assume

```sh
# does the most recent backup exist, and is it the size you expect
aws s3api list-objects-v2 --bucket my-backups --prefix daily/ --query 'last_key'
```

Two checks that catch real problems:

- **Size trend.** A backup that silently shrinks to almost nothing usually means
  it captured an empty or partial database. Alert on the change, not the
  presence.
- **Restorability, on a schedule.** Automate a monthly restore into a scratch
  environment and alert on failure. This is the check that distinguishes a
  working backup from a backup job that reports success.

Verify the restore reaches the point where the application queries it. A restored
dump that the application cannot connect to, because of a missing extension or
role, is not a restore.

## Restore drills

Rehearse the runbook with someone who did not write it. The failure mode is
always the same: the runbook says "restore from backup", and the actual answer is
"restore from which backup, into which instance, with which credentials, and
then how do we point the application at it".

Three artefacts make a restore survivable:

1. **The exact command sequence**, not a description of it.
2. **Where the credentials come from**, and who can obtain them at 3am.
3. **How the application is repointed**, and the order to do it in.

The order matters. Restoring a database while the application is still writing
to the old one produces a database that is wrong again by the time you finish.

## Multi-region

Cross-region replication shortens RTO and survives a regional failure. It does
not replace backups, for the same reason replicas do not: deletion propagates.

Failover is a code path, and like every code path it is never exercised until it
is needed. Test the failover, not just the replication. A replicated system whose
failover needs a manual DNS change and a credential nobody holds is not a
disaster recovery plan.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We have a replica." | A deleted table propagates to it in seconds. It is not a backup. |
| "The backup job reported success." | It reports that it ran, not that the result is restorable. |
| "The nightly backup is enough." | Then your RPO is twenty-four hours. Say so, or change the cadence. |
| "We tested the restore once." | A year ago, by the person who wrote it. Rehearse with someone else. |
| "Replication covers the region." | Replication is not a backup, and failover is untested code. |
| "The encryption key is in our secret store." | If the attacker reaches that account, they can decrypt the backups too. |
