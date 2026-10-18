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

- **accessibility-audit** — Use when auditing a page or component for WCAG conformance, screen-reader support, or keyboard operability, or when accessibility is named as a requirement.
- **api-contract-versioning** — Use when changing an existing API in a breaking way, deciding on a versioning scheme, or handling backward compatibility for clients you do not control.
- **caching-and-stampedes** — Use when adding or tuning a cache, when requests overwhelm a database on a hot key, or when diagnosing cache misses, stale reads, and thundering herd problems.
- **ci-pipeline-security** — Use when writing or reviewing CI workflow files, GitHub Actions configurations, build pipelines, or when evaluating a pipeline for supply chain risk.
- **css-architecture** — Use when setting up design tokens, managing a growing stylesheet, choosing between CSS-in-JS and utility classes, or when a codebase's styles have become hard to change safely.
- **database-migrations** — Use when writing or running database migrations, schema changes, backfills, or when a migration is blocking queries, locking a table, or needs to be rolled back safely.
- **date-time-handling** — Use when working with dates, times, time zones, timestamps, scheduling, or calendar arithmetic, and when diagnosing off-by-one-day or ambiguous timestamp bugs.
- **dependency-supply-chain-review** — Use when adding or upgrading dependencies, auditing an existing dependency tree, or assessing the risk of a package, lockfile, or build pipeline.
- **dispatching-parallel-agents** — Use when independent work items could run concurrently, or when a large task is being split across subagents without coordination.
- **docker-containerization** — Use when writing or reviewing a Dockerfile, composing services, or debugging image size, build cache, container signals, or container runtime permissions.
- **domain-modeling** — Use when identifying domain concepts, naming things in a codebase, modelling business rules, or when the code has unclear boundaries and unclear vocabulary.
- **environment-bootstrap** — Use when setting up a development environment, installing dependencies, getting a project to build or run locally, or diagnosing a broken local setup.
- **finishing-a-development-branch** — Use when a branch is ready to merge, open a pull request for, or hand off, and the remaining steps need to be done in order.
- **frontend-design** — Use when building or restyling a user interface, component, or page, including when the request mentions a design or visual change.
- **graphql-api-security** — Use when exposing or reviewing a GraphQL API, or when a GraphQL endpoint is slow, is being abused, or leaks data it should not.
- **http-security-headers** — Use when setting security response headers, a Content-Security-Policy or CORS policy, or when reviewing an application for header hardening.
- **improving-codebase-architecture** — Use when asked to review, assess, or improve the structure of a codebase, find coupling or duplication, or decide what to refactor first.
- **incident-response** — Use when responding to a production incident, outage, or alert, including triage, mitigation, communication, handoff, and writing a postmortem.
- **infrastructure-as-code** — Use when writing Terraform or other infrastructure code, managing cloud resources declaratively, or diagnosing drift between code and a live environment.
- **kubernetes-deployment** — Use when writing or reviewing Kubernetes manifests, probes, resource limits, rollout configuration, or when diagnosing pods that crashloop or never become ready.
- **llm-application-development** — Use when building applications on language models, including retrieval pipelines, prompt and context design, evaluation harnesses, or agent and tool-calling patterns.
- **localization-i18n** — Use when adding translations, supporting multiple languages or locales, handling pluralisation, or formatting dates, numbers, and currency for international users.
- **message-queue-processing** — Use when adding or reviewing message queue consumers, producers, webhooks, or background workers, including retries, idempotency, ordering, and dead letter queues.
- **oauth-authentication** — Use when implementing login, token handling, sessions, or OAuth flows, and when choosing between JWT and server-side sessions or storing tokens safely.
- **observability-and-slos** — Use when defining reliability targets, error budgets, SLIs and SLOs, or when setting up metrics, logging, tracing, or dashboards and alerts.
- **onboarding-unfamiliar-codebase** — Use when opening an unfamiliar repository for the first time, or when asked to orient, explore, or understand what a codebase does and where things live.
- **performance-profiling** — Use when a program is slow or memory grows, when profiling CPU or allocations, when a flame graph is needed, or when requests are slow under load.
- **planning-before-implementation** — Use when a task needs more than a trivial edit and no agreed approach exists yet, or when asked to plan, spec, or break down work before implementing.
- **property-based-testing** — Use when a function handles structured input, invalid input, numeric edge cases, or serialization, or when example-based tests keep missing real bugs.
- **receiving-code-review** — Use when code-review comments have arrived, especially when they conflict with each other or with the implementation.
- **refactoring-without-breaking-behaviour** — Use when restructuring existing code, reducing duplication, or modernising an interface, where existing tests must keep passing.
- **requesting-code-review** — Use when finishing a feature, a branch, or a substantial change, before merging, to get the work checked against the stated requirements.
- **resolving-merge-conflicts** — Use when git reports a conflict, when a rebase stops, or when a merge produces CONFLICT markers in a file.
- **rest-api-design** — Use when designing or reviewing an HTTP API, including status code choices, error response bodies, pagination, or idempotency for retried writes.
- **security-code-review** — Use when reviewing code that handles untrusted input, authentication, authorisation, secrets, file or network access, or when a security review is requested.
- **sql-query-performance** — Use when a database query is slow, when an index is missing or unused, or when writing queries against a large table.
- **structured-logging-and-error-handling** — Use when adding logging, structuring log output, handling or propagating errors, setting error boundaries, or redacting sensitive data from logs.
- **systematic-debugging** — Use when a test fails, a build breaks, or behaviour is unexpected, and the cause is not yet known, before any fix is proposed.
- **test-driven-development** — Use when adding or changing any feature or bugfix that needs tests, or when a test-first workflow is requested.
- **using-git-worktrees** — Use when starting work that should not disturb the current checkout, or when several branches need to be worked on at once.
- **verification-before-completion** — Use when about to report that work is complete, fixed, passing, or done, before committing, pushing, or opening a pull request.
- **web-design-guidelines** — Use when reviewing UI code against interface guidelines, or when a question involves accessibility, layout, interaction, or UX quality.
- **webapp-testing** — Use when verifying a web application in a real browser, debugging a UI issue, or writing end-to-end tests against a running app.
- **webhook-integration** — Use when sending or receiving webhooks, verifying webhook signatures, integrating third-party payment or notification APIs, or handling delivery retries.
- **writing-acceptance-criteria** — Use when a requirement is ambiguous, when defining done, or before writing tests, so that scope and edge cases are pinned down first.
- **writing-agent-skills** — Use when authoring, reviewing, or debugging an agent skill, and when a skill is not triggering when it should or triggers when it should not.
- **writing-technical-docs** — Use when writing or updating README, architecture notes, API reference, onboarding guides, or any doc aimed at another developer.

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
