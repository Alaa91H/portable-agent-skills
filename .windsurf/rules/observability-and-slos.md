---
trigger: model_decision
description: "Use when defining SLOs, error budgets, or metrics, logging and tracing."
---


# Observability and SLOs

## Start from the error budget, not from a metric

An SLI is always a ratio of good events to total events. Keeping it that way
makes the error budget arithmetic trivial:

```
error budget = 100% - SLO
```

The budget is the decision tool. A number with no pre-agreed consequence is a
dashboard, not a control. Agree with product and engineering in advance what
happens when it is spent: reliability work becomes the top priority, a feature
freeze, or a production freeze.

## 100% reliability is the wrong target

It is unachievable, because correlated failures exist at any scale, and the
marginal cost of each additional nine rises while the marginal value to users
approaches zero.

The decisive reason is simpler: **the number one source of outages is change.** A
100% SLO means you can never ship, which guarantees the 100% you already failed
to have.

Use a four-week rolling window. Google found that a good general-purpose
interval, and defining it as an integral number of weeks keeps the number of
weekends constant, so the SLO does not shift for uninteresting reasons. A 30-day
window sometimes contains four weekends and sometimes five.

### Worked example

97% availability over four weeks, 3,663,253 requests:

```
error budget = 3% x 3,663,253 = 109,897 failures
a single outage of 72,000 errors = 65% of the quarterly budget
```

That arithmetic is how you prioritise. In Google's own analysis it proved bad
releases cost more than twice what a year of database failures cost.

## Set more than one threshold per SLI

```
90% of requests < 100ms
99% of requests < 400ms
```

A single p99 hides the slow tail that makes users unhappy. Set the common
convention for status codes explicitly too, for example that 5xx counts against
the SLO and everything else is success.

Pick at most five SLI types. Availability and latency cover most services;
freshness, durability, correctness and coverage cover data systems.

Do not set the first SLO from current performance and freeze it there. Users come
to expect the measured baseline, so a regression from it matters and a target
below it invites permanent disappointment.

## Cardinality is the cost, and it is silent

Every unique label-value combination is a separate time series.

```
http_request_duration_seconds{method="GET", route="/users/:id", status="200"}
```

Keep the **route template**, not the raw path. `/users/4821` and `/users/4822`
are different series; `/users/:id` is one. A user ID or request ID as a label is
worse, because it is unbounded by construction.

Sizing, concretely: roughly **1 to 3 KiB of RAM per active series** in the head
block. A 16 GB Prometheus handles 2 to 3 million active series; budget 3 to 4 GB
per million plus headroom for queries. Managed backends bind much earlier:
Grafana Cloud alerts above about 1.5 million active series, and Mimir tenants
commonly cap near 150,000.

Practical heuristic: keep distinct values per label below 10; above 100,
redesign the metric.

Alert on growth, not only on the ceiling:

```promql
delta(prometheus_tsdb_head_series[10m]) > 1000
topk(5, count by (__name__) ({__name__=~".+"})) > 500000
```

The usual fixes in order of effort: normalise dynamic values, pre-aggregate with
recording rules, apply `sample_limit` per scrape config, then shard.

## OpenTelemetry conventions

`http.server.request.duration` is a histogram in **seconds** with explicit
buckets:

```
0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10
```

`http.route` **must be low cardinality**, with static path segments present and
dynamic segments replaced by placeholders such as `/users/:userID`. Do not
substitute the raw URI path for it: that is the single most common way to blow up
a metrics bill.

`server.address` and `server.port` are opt-in and carry a cardinality warning
precisely because they come from request headers.

## Metric naming

- **Base units**: seconds not milliseconds, bytes not megabytes, celsius not
  kelvin, a 0-to-1 ratio not a percentage.
- **Put the unit and type in the name**: `process_cpu_seconds_total`. Even though
  OpenTelemetry carries the unit elsewhere, reading a raw PromQL expression in a
  plain YAML file during an incident and knowing what it means is worth the
  redundancy.
- Do not put label names in the metric name; they aggregate away and confuse.
- Test that summing or averaging a metric across all of its dimensions is
  meaningful. If it is not, you have two metrics.

## Structured logging

- JSON, never a format you have to parse with a regular expression.
- **Correlation IDs beat timestamps.** Every line carries `trace_id`,
  `span_id`, `service`, `version`, `environment`.
- High-cardinality detail belongs in logs and traces, not in metric labels.
- Log stack traces server-side and return a masked message. A production stack
  trace is a map of your internals.
- Never log tokens, credentials, personal data, or whole request bodies that may
  contain them.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "We want 99.99%." | At 100% you cannot ship, and change is the top cause of outages. |
| "The SLO is in the dashboard." | A number with no agreed consequence is not a control. |
| "We log the full URL for debugging." | That is unbounded cardinality in a metric label. Use the route template. |
| "p99 is fine on its own." | It hides the 1% that abandons. Set two thresholds. |
| "We will add an error budget policy later." | Later is after you have spent it twice without noticing. |
