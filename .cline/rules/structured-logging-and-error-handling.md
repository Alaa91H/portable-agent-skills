---
description: "Use when adding logging, propagating errors, or redacting secrets."
---


# Structured logging and error handling

## Log JSON, and never parse it with a regular expression

```json
{
  "timestamp": "2026-03-04T11:22:33.481Z",
  "level": "error",
  "service": "orders",
  "version": "2.14.3",
  "environment": "production",
  "trace_id": "8f3a1c2b9d4e7f06",
  "span_id": "a19b2c3d",
  "request_id": "req_01HQ8...",
  "user_id": "u_4821",
  "event": "payment_authorization_failed",
  "error": { "type": "GatewayTimeout", "code": "upstream_timeout" },
  "duration_ms": 3002,
  "attempt": 3
}
```

The fields that matter are the ones that make a log queryable: `event` as a
stable machine-readable name, `level`, and the identifiers.

**Correlation IDs beat timestamps.** Every line carries `trace_id` and
`service`/`version`/`environment`, so one request can be reconstructed across
services. A wall-clock timestamp tells you when, not which request.

Never write an ad-hoc message string as the primary payload. `log.error("failed
to process " + id)` is unaggregatable; a stable `event` field is.

## Levels mean specific things

| Level | Means | Not |
| --- | --- | --- |
| `error` | An operator must look at this | A handled 4xx from a user |
| `warn` | Degraded but working; investigate if it clusters | Expected control flow |
| `info` | A significant business event | Per-request noise |
| `debug` | Diagnostic detail, off in production | Anything required to operate the system |

Logging a client validation failure at `error` trains everyone to ignore the
error level, which is how a real outage gets missed.

## Never log secrets or personal data

- Access and refresh tokens, session cookies, `Authorization` headers.
- Passwords, reset tokens, one-time codes.
- Full card numbers; log the last four at most.
- Personal data you do not need for the incident.

Redact at the serialisation layer so you cannot forget at a call site:

```ts
const logger = pino({
  redact: {
    paths: ['req.headers.authorization', 'req.headers.cookie', '*.password',
            '*.cardNumber', '*.ssn'],
    censor: '[redacted]',
  },
})
```

Central redaction means a new call site is safe by default, which per-call-site
thinking does not.

## Errors: preserve the cause, expose the message you control

Two audiences, two shapes. The user gets a message that is safe and useful; the
operator gets the stack.

```ts
class OrderError extends Error {
  constructor(public code: string, message: string, options?: ErrorOptions) {
    super(message, options)      // the cause is preserved, not flattened
    this.name = 'OrderError'
  }
}

throw new OrderError('payment_timeout', 'Payment provider did not respond', { cause: err })
```

- **Always pass the `cause`.** Without it the original stack is lost and the
  investigation starts from zero.
- Never leak internals to the user. A stack trace in an API response is a map of
  your modules, versions and database driver.
- Never swallow an error silently. An empty `catch` block converts a crash into
  a mystery.
- Re-throw with context rather than catching and logging and continuing, unless
  continuing is genuinely correct.

```ts
try {
  await charge(order)
} catch (err) {
  logger.error({ err, event: 'payment_failed', orderId: order.id }, 'charge failed')
  throw new OrderError('payment_failed', 'Payment could not be completed', { cause: err })
}
```

## Error boundaries and partial failure

At an application boundary, convert rather than propagate:

- **HTTP handler**: the error code decides the status and the safe message, per
  `rest-api-design`.
- **Queue consumer**: log with full context, do not throw a bare error, and make
  the effect idempotent so a retry is safe.
- **UI**: an error boundary catches render failures so one broken component does
  not blank the page. Show something recoverable, not a blank screen.
- **Background job**: record the failure against the job so it can be retried or
  reported, rather than only appearing in a log.

## What to log when something fails

Enough to answer, without a second deployment:

```json
{
  "event": "payment_authorization_failed",
  "order_id": "o_7721",
  "provider": "acquirer-a",
  "attempt": 3,
  "duration_ms": 3002,
  "error": { "type": "GatewayTimeout", "message": "...", "stack": "..." },
  "trace_id": "8f3a1c2b9d4e7f06"
}
```

What was being attempted, which identifier, how many times, how long it took, and
the correlation identifier. Without those you cannot tell one customer's failure
from a provider-wide one.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We log strings, it is easier to read." | It cannot be queried or grouped, which is the only reason to log. |
| "We need the stack trace in the response." | It is a map of your internals. Log it, return a message. |
| "This is expected, so no log." | Then the cluster is invisible. Log at the right level. |
| "Redact at the call sites we know about." | The one you forget is the breach. Redact in the serialiser. |
| "Empty catch is fine here, it is expected." | If it is expected, say why in a comment. Otherwise it hides the bug. |
