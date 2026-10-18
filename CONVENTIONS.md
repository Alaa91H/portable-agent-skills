# Agent Skills

This repository contains 59 validated Agent Skills.

If your agent supports the Agent Skills specification (`SKILL.md`), they are
already discoverable: they live under `.opencode/skills/` and are mirrored into
this repository's `skills/`, `.claude/skills/`, `.agents/skills/`, and
`.github/skills/` directories. Nothing further is needed.

If instead you are reading this as a flat instruction file, here is the index:

- **accessibility-audit** — Use when auditing a page or component for WCAG, screen-reader support, or keyboard operability.
- **api-contract-versioning** — Use when changing an API in a breaking way, or deciding on a versioning scheme.
- **caching-and-stampedes** — Use when adding or tuning a cache, or when a hot key overwhelms the database.
- **ci-pipeline-security** — Use when writing or reviewing CI workflow files, or assessing pipeline supply chain risk.
- **cloud-security-and-cost** — Use when reviewing cloud IAM, network exposure, or reducing cloud spend.
- **contract-and-load-testing** — Use when writing Pact contract tests, or load testing an API with k6 or JMeter.
- **css-architecture** — Use when setting up design tokens, growing a stylesheet, or choosing between styling approaches.
- **database-migrations** — Use when writing or running schema migrations, backfills, or when a migration blocks queries.
- **date-time-handling** — Use when working with dates, time zones, timestamps, or calendar arithmetic.
- **dbt-modeling** — Use when writing dbt models, incremental models, or fixing a broken build.
- **dependency-supply-chain-review** — Use when adding or upgrading dependencies, or auditing a dependency tree or lockfile.
- **dimensional-modeling** — Use when designing a warehouse schema, or choosing a slowly changing dimension type.
- **dispatching-parallel-agents** — Use when independent work items could run concurrently, or splitting a task across subagents.
- **docker-containerization** — Use when writing or reviewing a Dockerfile, or debugging image size, cache, or signals.
- **domain-modeling** — Use when identifying domain concepts, modelling business rules, or unclear code vocabulary.
- **email-deliverability** — Use when sending email, configuring SPF, DKIM or DMARC, or when mail is being filtered.
- **environment-bootstrap** — Use when setting up a dev environment, installing dependencies, or getting a project running.
- **feature-flag-and-secrets-lifecycle** — Use when adding or retiring a feature flag, or rotating secrets without downtime.
- **finishing-a-development-branch** — Use when a branch is ready to merge, hand off, or open a pull request.
- **frontend-design** — Use when building or restyling a user interface, component, or page.
- **graphql-api-security** — Use when exposing or reviewing a GraphQL API, or when it is slow or being abused.
- **http-security-headers** — Use when setting or reviewing security headers, CSP, or CORS policy.
- **improving-codebase-architecture** — Use when reviewing codebase structure, finding coupling or duplication, or prioritising refactors.
- **incident-response** — Use when responding to a production incident, outage, or alert.
- **infrastructure-as-code** — Use when writing Terraform or other infrastructure code, or diagnosing drift.
- **kubernetes-deployment** — Use when writing or reviewing Kubernetes manifests, probes, limits, or rollouts.
- **linux-ops-debugging** — Use when debugging a Linux host, a systemd unit, disk, permissions, or SSH.
- **llm-application-development** — Use when building on language models: retrieval, prompts, evaluation, or tool calling.
- **localization-i18n** — Use when adding translations, handling plurals, or formatting dates and numbers.
- **message-queue-processing** — Use when writing or reviewing queue consumers, workers, retries, or dead letter queues.
- **mobile-performance-and-release** — Use when a mobile app is slow to start, janky to scroll, or rejected by review.
- **oauth-authentication** — Use when implementing login, token handling, sessions, or OAuth flows.
- **observability-and-slos** — Use when defining SLOs, error budgets, or setting up metrics, logging, and tracing.
- **onboarding-unfamiliar-codebase** — Use when opening an unfamiliar repository, or when asked to orient in a codebase.
- **orchestration-dag-authoring** — Use when writing or debugging Airflow, Dagster or Prefect pipelines.
- **payments-integration** — Use when integrating a payment provider, or handling subscriptions or payment webhooks.
- **performance-profiling** — Use when a program is slow or memory grows, or when profiling CPU or allocations.
- **planning-before-implementation** — Use when a task needs a plan, spec, or breakdown before any code is written.
- **property-based-testing** — Use when testing structured or invalid input, or when examples keep missing bugs.
- **receiving-code-review** — Use when code-review comments arrive, especially when they conflict.
- **refactoring-without-breaking-behaviour** — Use when restructuring code where existing tests must keep passing.
- **requesting-code-review** — Use when finishing a feature or branch, before merging, to get it reviewed.
- **resolving-merge-conflicts** — Use when git reports a conflict, a rebase stops, or a merge leaves CONFLICT markers.
- **rest-api-design** — Use when designing or reviewing an HTTP API, its errors, pagination, or idempotency.
- **search-engineering** — Use when designing an Elasticsearch index, or tuning query relevance.
- **security-code-review** — Use when reviewing code that handles untrusted input, auth, secrets, or file access.
- **spark-performance** — Use when a Spark job is slow, data skew is suspected, or joins misbehave.
- **sql-query-performance** — Use when a query is slow, an index is missing, or querying a large table.
- **structured-logging-and-error-handling** — Use when adding logging, propagating errors, or redacting sensitive data.
- **systematic-debugging** — Use when a test or build fails and the cause is not yet known.
- **test-driven-development** — Use when adding or changing a feature or bugfix that needs tests.
- **using-git-worktrees** — Use when work should not disturb the current checkout, or branches run at once.
- **verification-before-completion** — Use when about to report work complete or fixed, or before committing or opening a pull request.
- **web-design-guidelines** — Use when reviewing UI code against interface, accessibility, or UX guidelines.
- **webapp-testing** — Use when verifying a web app in a real browser, or debugging a UI issue.
- **webhook-integration** — Use when sending or receiving webhooks, or verifying webhook signatures.
- **writing-acceptance-criteria** — Use when a requirement is ambiguous, or before tests, to pin down scope.
- **writing-agent-skills** — Use when authoring or debugging an agent skill, or when triggers are wrong.
- **writing-technical-docs** — Use when writing or updating README, architecture notes, or API reference.

Full instructions: `.opencode/skills/<id>/SKILL.md`.

Load a skill when its description matches the task. The description says when to
use it; the file says what to do. Do not work from the description alone.
