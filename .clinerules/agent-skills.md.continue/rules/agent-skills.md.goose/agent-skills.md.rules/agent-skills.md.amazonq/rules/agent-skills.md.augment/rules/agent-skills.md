# Agent Skills

This repository provides a collection of validated Agent Skills. They are
SKILL.md files under `.opencode/skills/`, which several agents load directly.
If your agent reads flat rule files instead, the same guidance is available as
one rule per skill.

## When to load a skill

Only the name and description of each skill are listed here. Load a skill's full
instructions when its description matches the task in front of you. Do not
attempt to follow a skill from its description alone; the description states when
to use it, not what to do.

## The collection

- **accessibility-audit** — Use when auditing a page or component for WCAG, screen readers, or keyboard operability.
- **api-contract-versioning** — Use when changing an API in a breaking way, or deciding on a versioning scheme.
- **background-jobs-and-scheduling** — Use when adding cron or a job queue, or when jobs overlap, drift, or run twice.
- **backup-and-disaster-recovery** — Use when designing backups, setting recovery objectives, or planning for data loss.
- **caching-and-stampedes** — Use when adding or tuning a cache, or when a hot key overwhelms the database.
- **ci-pipeline-security** — Use when writing or reviewing CI workflow files, or assessing pipeline supply chain risk.
- **cloud-security-and-cost** — Use when reviewing cloud IAM, network exposure, or reducing cloud spend.
- **concurrency-and-async** — Use when writing concurrent or async code, or diagnosing races, deadlocks, or blocking.
- **contract-and-load-testing** — Use when writing Pact contract tests, or load testing an API with k6 or JMeter.
- **css-architecture** — Use when setting up design tokens, growing a stylesheet, or choosing a styling approach.
- **database-migrations** — Use when running schema migrations or backfills, or when a migration blocks queries.
- **date-time-handling** — Use when working with dates, time zones, timestamps, or calendar arithmetic.
- **dbt-modeling** — Use when writing dbt models, incremental models, or fixing a broken build.
- **dependency-supply-chain-review** — Use when adding or upgrading dependencies, or auditing a dependency tree or lockfile.
- **dimensional-modeling** — Use when designing a warehouse schema, or choosing a slowly changing dimension type.
- **dispatching-parallel-agents** — Use when independent work items could run concurrently, or splitting work across subagents.
- **docker-containerization** — Use when writing or reviewing a Dockerfile, or debugging image size, cache, or signals.
- **domain-modeling** — Use when identifying domain concepts, business rules, or unclear code vocabulary.
- **email-deliverability** — Use when sending email, configuring SPF, DKIM or DMARC, or when mail is being filtered.
- **environment-bootstrap** — Use when setting up a dev environment, installing dependencies, or running a project.
- **feature-flag-and-secrets-lifecycle** — Use when adding or retiring a feature flag, or rotating secrets without downtime.
- **finishing-a-development-branch** — Use when a branch is ready to merge, hand off, or open a pull request.
- **frontend-design** — Use when building or restyling a user interface, component, or page.
- **git-internals** — Use when recovering lost work, bisecting a regression, or managing hooks and submodules.
- **graphql-api-security** — Use when exposing or reviewing a GraphQL API, or when it is slow or being abused.
- **http-security-headers** — Use when setting or reviewing security headers, CSP, or CORS policy.
- **improving-codebase-architecture** — Use when reviewing codebase structure, finding duplication, or prioritising refactors.
- **incident-response** — Use when responding to a production incident, outage, or alert.
- **infrastructure-as-code** — Use when writing Terraform or other infrastructure code, or diagnosing drift.
- **kubernetes-deployment** — Use when writing or reviewing Kubernetes manifests, probes, limits, or rollouts.
- **linux-ops-debugging** — Use when debugging a Linux host, a systemd unit, disk, permissions, or SSH.
- **llm-application-development** — Use when building on language models: retrieval, prompts, evaluation, or tool calling.
- **localization-i18n** — Use when adding translations, handling plurals, or formatting dates and numbers.
- **mcp-server-authoring** — Use when building an MCP server or tool, or exposing capabilities to an agent.
- **message-queue-processing** — Use when writing or reviewing queue consumers, workers, retries, or dead letter queues.
- **mobile-performance-and-release** — Use when a mobile app is slow to start, janky to scroll, or rejected by review.
- **oauth-authentication** — Use when implementing login, token handling, sessions, or OAuth flows.
- **observability-and-slos** — Use when defining SLOs, error budgets, or setting up metrics, logging, and tracing.
- **onboarding-unfamiliar-codebase** — Use when opening an unfamiliar repository, or when asked to orient in a codebase.
- **orchestration-dag-authoring** — Use when writing or debugging Airflow, Dagster or Prefect pipelines.
- **payments-integration** — Use when integrating a payment provider, or handling subscriptions or payment webhooks.
- **performance-profiling** — Use when a program is slow or memory grows, or when profiling CPU or allocations.
- **planning-before-implementation** — Use when a task needs a plan, spec, or breakdown before any code is written.
- **privacy-and-data-retention** — Use when handling personal data, implementing deletion, or setting retention policy.
- **prompt-injection-defense** — Use when an LLM reads untrusted content, or an agent acts on model decisions.
- **property-based-testing** — Use when testing structured or invalid input, or when examples keep missing bugs.
- **receiving-code-review** — Use when code-review comments arrive, especially when they conflict.
- **refactoring-without-breaking-behaviour** — Use when restructuring code where existing tests must keep passing.
- **release-engineering** — Use when cutting a release, writing a changelog, choosing a version, or planning rollback.
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
- **verification-before-completion** — Use when about to report work complete or fixed, or before committing.
- **web-design-guidelines** — Use when reviewing UI code against interface, accessibility, or UX guidelines.
- **webapp-testing** — Use when verifying a web app in a real browser, or debugging a UI issue.
- **webhook-integration** — Use when sending or receiving webhooks, or verifying webhook signatures.
- **writing-acceptance-criteria** — Use when a requirement is ambiguous, or before tests, to pin down scope.
- **writing-agent-skills** — Use when authoring or debugging an agent skill, or when triggers are wrong.
- **writing-technical-docs** — Use when writing or updating README, architecture notes, or API reference.

## Using them

If your agent supports the Agent Skills specification, the skills are already
available and you will see them offered by name. Otherwise, read the relevant
file directly:

- OpenCode, Claude Code, Copilot, and other spec clients: `.opencode/skills/<id>/SKILL.md`
- This rule set: one Markdown file per skill, in the rules directory beside this file

## Rules

- Load a skill before starting work that matches it, not after.
- Do not load several skills that overlap; pick the closest match.
- If a skill contradicts the immediate instructions you were given, follow the
  immediate instructions and say so.
