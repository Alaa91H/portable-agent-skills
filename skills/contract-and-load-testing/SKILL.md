---
name: contract-and-load-testing
description: Use when writing Pact contract tests, or load testing an API with k6 or JMeter.
---

# Contract and load testing

## Contract testing with Pact

Unit tests assert against the implementation. Contract tests assert against the
**consumer's actual expectation**, which is the thing that breaks in production.

```bash
# consumer publishes the pact
pact-broker publish ./pacts \
  --consumer-app-version=${GIT_SHA} \
  --branch=main \
  --broker-base-url=https://broker.example.com \
  --broker-token=${PACT_BROKER_TOKEN}

# ask whether it is safe to deploy
pact-broker can-i-deploy \
  --pacticipant user-service --version ${GIT_SHA} \
  --to-environment production
```

The output is a matrix showing whether every consumer's contract has been
verified against this provider version. Gate the deployment on it.

**Write the loosest pact that still catches a breaking change.** A contract
asserting exact values makes the provider's tests fail for a rename that broke
nobody:

```ts
// brittle: any field change fails
expect(body[0]).toEqual([{ id: '123', name: 'Product 1' }])

// correct: shape is required, values are not
expect(body[0]).toEqual([
  { id: expect.stringMatching(/^\d+$/), name: expect.any(String) },
])
```

**Consumer writes the contract, provider verifies it.** The asymmetry is the
point: only the consumer knows what it actually depends on. A provider guessing
at a consumer's expectations will get it wrong.

Run provider verification in a **separate CI build**, triggered by the broker's
"contract content changed" webhook. In the same build as the provider's own
tests, one team's change breaks another team's pipeline.

Never verify against a deployed environment. It destroys fast feedback, serialises
your pipeline, and the webhook-per-version model breaks.

The scoping question before writing a case: *if I do not include this scenario,
what bug in my consumer, or what misunderstanding about the provider, might I
miss?* If nothing, leave it out.

## Load testing with k6

Thresholds decide pass or fail, so their syntax has to be right:

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },    // ramp up
    { duration: '5m', target: 1000 },   // steady state
    { duration: '2m', target: 0 },      // ramp down
  ],
  thresholds: {
    http_req_failed:   ['rate<0.01'],   // under 1% errors
    http_req_duration: ['p(95)<200'],   // 95th percentile under 200ms
    checkout_latency: [
      { threshold: 'p(99)<400', abortOnFail: true, delayAbortEval: '10s' },
    ],
  },
}
```

The aggregation method has to match the metric type, and getting this wrong is
the single most common k6 error:

| Metric type | Valid methods |
| --- | --- |
| Counter | `count`, `rate` |
| Gauge | `value` |
| Rate | `rate` |
| Trend | `avg`, `min`, `max`, `med`, `p(N)` |

A percentile outside 0 to 100 fails to parse and the test stops before running,
which looks like a silent pass with no results.

**Run for 30 to 60 minutes, not five.** Short runs miss memory leaks and gradual
resource exhaustion entirely; a process that leaks 1MB a minute looks healthy for
ten minutes. Use think time rather than hammering continuously, and model real
user behaviour including data variation, not a uniform loop.

## Comparing results across tools

Numbers will not match, and that is not a bug:

- JMeter's response time is connect plus send plus wait plus receive.
- k6 breaks the same span into `blocked`, `dns`, `connect`, `tls`, `sending`,
  `waiting`, `receiving`.
- Gatling starts its clock when it attempts to send.

Compare like with like or do not compare at all. Read the phase breakdown when
latency rises: a `waiting` spike is the server, a `connect` spike is the network
or the pool.

## Test against realistic data

Five rows in a fixture hides every N+1 in existence. Load tests with realistic
cardinality, or they prove less than no test: they certify a performance that
only exists at five rows.

Watch for connection exhaustion under load specifically. It presents as rising
latency and timeouts rather than as an error, and the workers holding those
connections are what turns it into a spiral. See `performance-profiling`.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Our integration tests cover the API." | They test against your provider, not against what the consumer expects. |
| "A strict pact is better." | A strict pact fails on renames that broke nobody, and gets ignored. |
| "Verify against staging." | It destroys fast feedback and serialises the pipeline. |
| "A short load test is enough." | Five minutes cannot see a leak that takes an hour. |
| "k6 and JMeter numbers differ, one is wrong." | They measure different spans. Compare phases, not totals. |
| "Five rows is fine for load testing." | That is the environment where N+1 is invisible. |
