---
trigger: model_decision
description: "Use when handling personal data, deletion, or retention policy."
---


# Privacy and data retention

## Minimisation is the whole strategy

The most reliable privacy control is not having the data. It is decided at design
time and cannot be added later, because deletion has to work across backups,
analytics, logs, and every system that received a copy.

Ask two questions before adding a field:

1. **Do we need this to do the thing?** Most speculative fields are stored for a
   future that never arrives.
2. **Do we need it to be identifiable?** An aggregate is usually enough.

Every field you do not add is one fewer thing to encrypt, redact, delete,
discover in a breach, and defend in a subject access request.

## Retention is set at write time

A table with no retention policy is an archive that nobody chose:

```sql
-- rows expire by policy, not by a scheduled job someone forgets
created_at timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at)     -- drop the partition, do not DELETE the rows
```

**Partition and drop beats deleting rows.** A large `DELETE` generates enormous
write-ahead log volume, holds locks, and leaves bloat behind.

Logs are the usual exception: you cannot retroactively delete a log line, so
retention has to be a logging configuration:

```yaml
retention: 30d
```

## Deletion is a distributed problem

A user requests deletion. The record exists in the primary database, in backups,
in the analytics warehouse, in logs, in caches, in search indexes, and in any
third party that received it. **A delete on one system is not compliance.**

Make the inventory first. It is the only artefact that answers a regulator:

| System | Contains | Deletion mechanism |
| --- | --- | --- |
| Primary database | Full record | Hard delete or anonymise |
| Backups | Full record | Age out; cannot selectively edit |
| Warehouse | Columns, often derived | Drop or null the subject's rows |
| Logs | Emails, ids, sometimes payloads | Retention window |
| Search index | Denormalised copy | Reindex or delete by key |
| Third parties | Varies | Their API, or a contractual commitment |

Some copies genuinely cannot be deleted on request: encrypted backups age out,
and that is an acceptable answer when you can say so and when the window is
bounded. What is not acceptable is not knowing which copies exist.

**Decide what "deleted" means while the user is still an active case.** Erase
identifiers but keep the record for aggregates, or remove the row entirely? Both
are defensible. Discovering the answer during a request, under a deadline, is
not.

## Anonymisation has a failure mode

Hashing an email does not anonymise it. Email addresses have low entropy, the
whole space is enumerable, and a rainbow table defeats the hash in seconds.

```python
# not anonymisation
email_hash = sha256(email)

# a keyed digest with a secret the attacker does not have
email_pseudonym = hmac.new(PEPPER, email.lower().strip(), sha256).hexdigest()
```

Better still, replace the identifier with a random one and keep the mapping in a
separate system with tighter access. Salt and pepper live in different systems,
so compromising the data does not enable the attack.

Before calling a dataset anonymised, test it: attempt a re-identification with the
auxiliary data you realistically have. If you can re-link a row, you have not
anonymised it.

## Legal basis is a product decision

Different processing needs different grounds: consent, contract, legitimate
interest, legal obligation. Consent is the one with engineering consequences,
because it must be **withdrawable as easily as it was given**.

That means:

- The withdrawal path must not be harder than the signup path.
- Consent state lives in your database, not only in a banner the user dismissed.
- A change to the purposes is a **new** consent, not a reinterpretation of the
  old one.
- The record of what was consented to, and when, is itself retained.

## Consent and tracking

- Consent state is per purpose, not one global flag. Analytics consent does not
  imply marketing consent.
- Honour the signal in the tag manager and in the server, because a server-side
  event bypasses browser consent tooling entirely.
- Withdrawing consent must stop collection going forward. It does not and cannot
  undo what was already collected; say so plainly rather than implying otherwise.

## Rights requests are an engineering feature

Access, export and deletion all need a data map and a query. Build them before
you need them, and measure them.

An export that times out on a large account, or a deletion that misses one of
eleven subsystems, is a defect with a deadline. Both are found by running them
against real data during normal development, not during a request.

## Data subject scope

An account is not a person. One person may have several accounts, may appear in
another person's records as a counterparty, and may be identified by an address
or a card rather than an email. Searching for a subject by their own identifier
misses all of it.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We will delete the row." | There are eleven copies. The row is the easiest one. |
| "We hashed the email, so it is anonymous." | Email is low entropy and enumerable. Use a keyed digest or a surrogate. |
| "Retention can be a cleanup job later." | Logs cannot be selectively deleted. Set it at write time. |
| "Consent is the banner." | Consent is data in your database, withdrawable. |
| "We only need it in case." | Every field you do not add is one fewer breach surface. |
| "Backups are encrypted so they are fine." | They age out, which is acceptable. Say so, with the window. |
