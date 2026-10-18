# Agent Skills

This repository contains 74 validated Agent Skills.

If your agent supports the Agent Skills specification (`SKILL.md`), they are
already discoverable: they live under `.opencode/skills/` and are mirrored into
this repository's `skills/`, `.claude/skills/`, `.agents/skills/`, and
`.github/skills/` directories. Nothing further is needed.

If instead you are reading this as a flat instruction file, here is the index:

- **accessibility-audit** — Use when auditing a page or component for WCAG, screen readers, or keyboards.
- **api-contract-versioning** — Use when changing an API in a breaking way, or deciding on a versioning scheme.
- **background-jobs-and-scheduling** — Use when adding cron or a job queue, or when jobs overlap, drift, or run twice.
- **backup-and-disaster-recovery** — Use when designing backups, recovery objectives, or planning for data loss.
- **caching-and-stampedes** — Use when adding or tuning a cache, or when a hot key overwhelms the database.
- **ci-pipeline-security** — Use when writing or reviewing CI workflows, or assessing supply chain risk.
- **cloud-security-and-cost** — Use when reviewing cloud IAM, network exposure, or reducing cloud spend.
- **codebase-decomposition** — Use when a file has grown large, or deciding where behaviour belongs.
- **concurrency-and-async** — Use when writing concurrent code, or diagnosing races and deadlocks.
- **context-window-management** — Use when work must survive compaction, or a long task loses coherence.
- **contract-and-load-testing** — Use when writing Pact contract tests, or load testing an API.
- **css-architecture** — Use when setting up design tokens, growing a stylesheet or choosing styling.
- **database-migrations** — Use when running schema migrations or backfills that block queries.
- **date-time-handling** — Use when working with dates, time zones, timestamps, or calendar arithmetic.
- **dbt-modeling** — Use when writing dbt models, incremental models, or fixing a broken build.
- **dependency-supply-chain-review** — Use when adding or upgrading dependencies, or auditing a lockfile.
- **dimensional-modeling** — Use when designing a warehouse schema, or a slowly changing dimension.
- **dispatching-parallel-agents** — Use when independent work could run concurrently, or split across subagents.
- **docker-containerization** — Use when writing a Dockerfile, or debugging image size, cache, or signals.
- **domain-modeling** — Use when identifying domain concepts, business rules, or unclear vocabulary.
- **email-deliverability** — Use when sending email, or configuring SPF, DKIM, or DMARC records.
- **environment-bootstrap** — Use when setting up a dev environment, installing dependencies or running it.
- **feature-flag-and-secrets-lifecycle** — Use when adding or retiring a feature flag, or rotating secrets.
- **finishing-a-development-branch** — Use when a branch is ready to merge, hand off, or open a PR.
- **frontend-design** — Use when building or restyling an interface, component or page.
- **git-internals** — Use when recovering lost work, bisecting, or managing submodules.
- **graphql-api-security** — Use when exposing or reviewing a GraphQL API, or when it is abused.
- **hallucination-defense** — Use when an agent may invent facts, drift from the request, or output must be grounded.
- **http-security-headers** — Use when setting or reviewing security headers, CSP or CORS.
- **improving-codebase-architecture** — Use when reviewing codebase structure, duplication or refactor priority.
- **incident-response** — Use when responding to a production incident, outage or alert.
- **infrastructure-as-code** — Use when writing Terraform or infrastructure code, or diagnosing drift.
- **kubernetes-deployment** — Use when writing or reviewing Kubernetes manifests or probes.
- **linux-ops-debugging** — Use when debugging a Linux host, systemd unit, disk, or SSH.
- **llm-application-development** — Use when building on language models: retrieval, prompts, evaluation.
- **localization-i18n** — Use when adding translations, plurals, or date and number formats.
- **mcp-server-authoring** — Use when building an MCP server or tool, or agent capabilities.
- **message-queue-processing** — Use when writing queue consumers, workers, retries or dead letters.
- **mobile-performance-and-release** — Use when a mobile app is slow to start, janky to scroll, or rejected.
- **oauth-authentication** — Use when implementing login, tokens, sessions, or OAuth flows.
- **observability-and-slos** — Use when defining SLOs, error budgets, or metrics, logging and tracing.
- **onboarding-unfamiliar-codebase** — Use when opening an unfamiliar repository, or orienting in one.
- **orchestration-dag-authoring** — Use when writing or debugging Airflow, Dagster or Prefect DAGs.
- **payments-integration** — Use when integrating a payment provider, subscriptions or webhooks.
- **performance-profiling** — Use when a program is slow or memory grows, or when profiling CPU.
- **planning-before-implementation** — Use when a task needs a plan or breakdown before code is written.
- **privacy-and-data-retention** — Use when handling personal data, deletion or retention rules.
- **prompt-injection-defense** — Use when an LLM reads untrusted content or acts on model output.
- **property-based-testing** — Use when testing structured or invalid input, or examples miss bugs.
- **receiving-code-review** — Use when code-review comments arrive, or conflict with your work.
- **refactoring-without-breaking-behaviour** — Use when restructuring code where the existing tests must pass.
- **release-engineering** — Use when cutting a release, writing a changelog, or a rollback plan.
- **requesting-code-review** — Use when a feature or branch is ready, before merging, to get it reviewed.
- **resolving-merge-conflicts** — Use when git reports a conflict, a rebase stops, or markers remain.
- **rest-api-design** — Use when designing or reviewing an HTTP API: errors, pagination, idempotency.
- **search-engineering** — Use when designing an Elasticsearch index or tuning relevance.
- **security-code-review** — Use when reviewing code handling untrusted input, auth or secrets.
- **shell-and-text-tooling** — Use when writing shell scripts, grep/sed/awk, or file-scanning tooling.
- **spark-performance** — Use when a Spark job is slow, data skew is suspected, or joins break.
- **sql-query-performance** — Use when a query is slow, an index is missing, or a table is large.
- **structured-logging-and-error-handling** — Use when adding logging, propagating errors, or redacting secrets.
- **systematic-debugging** — Use when a test or build fails and the cause is not yet known.
- **test-driven-development** — Use when adding or changing a feature or bugfix that needs tests.
- **token-and-context-budget** — Use when a task is large, or when deciding what to read, delegate or write.
- **trustworthy-checks** — Use when writing a validator, gate, or CI check, or when a check passes and you doubt it.
- **up-to-date-tooling** — Use when choosing a library or API, recalling a version, or adopting newer tooling.
- **using-git-worktrees** — Use when work should not disturb the checkout, or run branches at once.
- **verification-before-completion** — Use when about to report work complete, or before committing.
- **web-design-guidelines** — Use when reviewing UI code against interface, accessibility or UX.
- **webapp-testing** — Use when verifying a web app in a browser, or debugging a UI issue.
- **webhook-integration** — Use when sending or receiving webhooks, or verifying signatures.
- **writing-acceptance-criteria** — Use when a requirement is ambiguous, or before tests, to fix scope.
- **writing-agent-skills** — Use when authoring or debugging an agent skill, or fixing triggers.
- **writing-technical-docs** — Use when updating a README, architecture notes or API reference.

Full instructions: `.opencode/skills/<id>/SKILL.md`.

Load a skill when its description matches the task. The description says when to
use it; the file says what to do. Do not work from the description alone.
