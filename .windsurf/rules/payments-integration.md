---
trigger: model_decision
description: "Use when integrating a payment provider, subscriptions or webhooks."
---


# Payments integration

## Idempotency is not optional

A network timeout is not proof the charge did not happen. Every mutating call
needs a key.

- Header `Idempotency-Key`, maximum 255 characters. Use a V4 UUID.
- **Never derive the key from an email or any personal identifier.** Keys land in
  logs.
- **Only POST needs one.** On GET and DELETE it has no effect, since those are
  idempotent by definition.
- If the parameters differ from the original request, the provider **errors**
  rather than replaying. That is correct: a silent replay under a changed body is
  how one customer gets charged for another's basket.
- Retries return the **saved response including 500s**. Caching only the
  successes means a retried failing request runs twice.

**The footgun: keys are pruned after 24 hours.** A retry scheduled for tomorrow
with today's key creates a brand-new charge. For anything with a delay longer
than a day, generate the key at send time, not at enqueue time.

## Verify webhooks on the raw body

Any re-serialisation changes bytes and breaks the signature.

```python
raw = request.get_data()                    # never request.json
event = stripe.Webhook.construct_event(
    raw, sig_header, endpoint_secret, tolerance=300)
```

- Default tolerance is **300 seconds**, which is the replay defence: an attacker
  who captured a valid payload cannot change the timestamp because it is part of
  the signed content.
- Compare in constant time, and check **every** `v1` value present, because
  secret rotation emits more than one.

## Do not trust the browser

The client-side success callback is an attacker. Confirm server-side against the
provider's API before fulfilling anything.

## Ordering is not guaranteed

A `subscription.updated` event for a cancellation can arrive **before** the
`invoice.paid` event for the preceding renewal. Two defences:

1. **Refetch the live object** and act on that, not on the event's embedded
   snapshot. The snapshot is a point in time and may already be stale.
2. When you must use the embedded object, prefer monotonic fields such as
   `current_period_end` and reject anything that appears to move backwards.

For local testing:

```sh
stripe listen --forward-to localhost:8000/webhook
stripe trigger invoice.payment_failed
```

## Subscription states, and what each requires

| Status | Meaning | Action |
| --- | --- | --- |
| `trialing` | Safe to provision | Auto-transitions to `active` on first payment |
| `incomplete` | First invoice unpaid, **23-hour window** | Return the user to payment within it |
| `incomplete_expired` | Window elapsed | **Create a new subscription**; the old one is dead |
| `active` | Healthy | Provision |
| `past_due` | Latest invoice failed | **Grace period. Do not revoke.** Dunning is running |
| `canceled` | Terminal | Revoke access |
| `unpaid` | Give-up state | Revoke access |

The three that cost real money:

- **`invoice.payment_failed` does not mean cancelled.** The provider is running
  dunning with smart retries. Read the resulting status rather than authoring the
  transition yourself.
- **`past_due` to `active` requires settling the most recent non-voided
  invoice.** Paying an older one does nothing.
- **Completing a late payment does not extend the original billing period start.**
  Less time remains in the first period than you would expect.

## PCI scope

You can qualify for the shortest self-assessment questionnaire, about 22
questions, when payment is **wholly outsourced**:

- A **redirect** to the provider's page or an email link, or
- An **embedded iframe or hosted field**, available from PCI DSS v4.0.1 onward
  **and only with an attestation that your site is not susceptible to
  script-based attacks**.

That iframe attestation is the change people miss, and it is a real requirement.
Moving from the full questionnaire to the short one via tokenisation is commonly
cited as roughly a 90 percent reduction in obligations, so it is worth
confirming your integration qualifies.

## Reconciliation

Webhook delivery is at-least-once and can be missed entirely. Reconcile
periodically against the provider's API rather than trusting the event stream to
be complete. Look for subscriptions you believe are active that the provider
does not, and the reverse.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The client said payment succeeded." | The client is the attacker. Confirm server-side. |
| "A day later we can reuse the key." | Keys are pruned after 24 hours, so that creates a second charge. |
| "Failed payment means cancelled." | Dunning is running. Read the resulting status. |
| "The webhook order matches our events." | It does not. Refetch, or use monotonic fields. |
| "We parse the JSON body." | Re-serialising changes bytes and the signature will not match. |
| "The iframe means we handle cards." | Only with the script-attack attestation, and from v4.0.1. |
