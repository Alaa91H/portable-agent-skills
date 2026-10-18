---
name: domain-modeling
description: Use when identifying domain concepts, modelling business rules, or unclear code vocabulary.
---

# Domain modelling

## Start from the vocabulary, not the schema

The database schema records storage. The domain model records meaning. They are
different things, and deriving one from the other produces code that names
things after the table they live in.

Collect the words first, from the people who do the work:

> What do you call this thing? What are its states? What can happen to it? What
> makes it invalid? What are the rules that surprise people?

Write the answers down verbatim, including disagreements. **A disagreement about
a word is a disagreement about the model**, and it is much cheaper to find now
than after three teams have implemented incompatible interpretations of "order
status".

Names that are worth arguing about:

- `order`, `booking`, `reservation`, `cart`, `quote` — genuinely different things.
- `customer`, `user`, `account`, `party`, `organisation` — usually conflated, and
  the conflation causes an authorisation bug.
- `active`, `valid`, `enabled`, `available` — these are not synonyms, and using
  one word for several ideas means nobody can be told what it means.

## Separate the states that are actually different

Most entity confusion is a state machine nobody wrote down.

```ts
type OrderState =
  | 'draft'           // editable, nothing reserved
  | 'placed'          // submitted, awaiting payment
  | 'paid'            // money captured
  | 'fulfilled'       // goods handed over
  | 'cancelled'       // terminal
  | 'refunded'        // terminal, after paid
```

Then decide which transitions are legal, and enforce that rather than scattering
conditionals:

```ts
const ALLOWED: Record<OrderState, OrderState[]> = {
  draft:     ['placed', 'cancelled'],
  placed:    ['paid', 'cancelled'],
  paid:      ['fulfilled', 'refunded'],
  fulfilled: ['refunded'],
  cancelled: [],
  refunded:  [],
}
```

Two states that are actually one (`cancelled` before payment versus after) become
one state, and `refunded` disappears. Two states that are actually different
(`cancelled` by the customer versus by the system, which have different refund
rules) become two.

**Enum values are a contract.** Adding one breaks clients that switch
exhaustively, as covered in `api-contract-versioning`.

## Push behaviour into the model

```ts
// Wrong: a service reaches into another entity's fields and decides
if (order.status === 'paid' && !order.refunded && order.total > 0) { ... }
```

Every caller re-implements the rule, and they drift. Put the decision where the
data lives:

```ts
order.canBeRefunded()          // the rule, written once
order.refund(amount)           // the transition, with its guard
```

The test is: could you delete one of the two implementations of the same rule
and have nothing break? If no, the rule is duplicated.

## Value objects for things with rules

Anything with validation, units, or normalisation is a value object, not a
primitive:

```ts
type Cents = bigint                      // never a float for money
type Email = string & { __brand: 'Email' }
```

A `Cents` type makes the whole class of "added a tax rate to the wrong column"
bugs unrepresentable, which is cheaper than any amount of review. Note that
money is integer minor units; a float for currency is a rounding bug waiting for
a large enough amount.

## Boundaries, not layers

Split a model where the **vocabulary changes**, not where the screens are or
where the technical layers are.

```
Sales speaks about quotes, discounts and commissions.
Support speaks about tickets, SLAs and escalation.
They share a database and should share almost no code.
```

A boundary where one team's vocabulary ends and another's begins is a place where
a change on one side stops being a surprise on the other. Contrast with splitting
by technical layer, which produces every team able to change every part and no
team able to change anything safely.

## Record the decisions

For each concept, write one line: what it is, what it is not, and what makes it
invalid. That is the part that is expensive to rediscover, and the part that
usually lives only in one person's head.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The schema already models it." | The schema models storage. It has no opinion about meaning. |
| "We will name things properly later." | Renaming a concept touches every file, and later is under deadline. |
| "It is only a status field." | Most domain bugs are an unmodelled state machine. Write the transitions down. |
| "The duplication is only three lines." | Three copies of a rule become three different rules within two quarters. |
| "We do not need a domain layer." | Then every caller decides when an order can be refunded, differently. |
