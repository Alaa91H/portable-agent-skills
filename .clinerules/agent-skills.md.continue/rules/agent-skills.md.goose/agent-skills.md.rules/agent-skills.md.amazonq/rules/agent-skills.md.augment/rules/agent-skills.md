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

- **accessibility-audit** — Use when auditing a page or component for WCAG, screen-reader support, or keyboard operability.
- **api-contract-versioning** — Use when changing an API in a breaking way, or deciding on a versioning scheme.
- **caching-and-stampedes** — Use when adding or tuning a cache, or when a hot key overwhelms the database.
- **ci-pipeline-security** — Use when writing or reviewing CI workflow files, or assessing pipeline supply chain risk.
- **css-architecture** — Use when setting up design tokens, growing a stylesheet, or choosing between styling approaches.
- **database-migrations** — Use when writing or running schema migrations, backfills, or when a migration blocks queries.
- **date-time-handling** — Use when working with dates, time zones, timestamps, or calendar arithmetic.
- **dependency-supply-chain-review** — Use when adding or upgrading dependencies, or auditing a dependency tree or lockfile.
- **dispatching-parallel-agents** — Use when independent work items could run concurrently, or splitting a task across subagents.
- **docker-containerization** — Use when writing or reviewing a Dockerfile, or debugging image size, cache, or signals.
- **domain-modeling** — Use when identifying domain concepts, modelling business rules, or unclear code vocabulary.
- **environment-bootstrap** — Use when setting up a dev environment, installing dependencies, or getting a project running.
- **finishing-a-development-branch** — Use when a branch is ready to merge, hand off, or open a pull request.
- **frontend-design** — Use when building or restyling a user interface, component, or page.
- **graphql-api-security** — Use when exposing or reviewing a GraphQL API, or when it is slow or being abused.
- **http-security-headers** — Use when setting or reviewing security headers, CSP, or CORS policy.
- **improving-codebase-architecture** — Use when reviewing codebase structure, finding coupling or duplication, or prioritising refactors.
- **incident-response** — Use when responding to a production incident, outage, or alert.
- **infrastructure-as-code** — Use when writing Terraform or other infrastructure code, or diagnosing drift.
- **kubernetes-deployment** — Use when writing or reviewing Kubernetes manifests, probes, limits, or rollouts.
- **llm-application-development** — Use when building on language models: retrieval, prompts, evaluation, or tool calling.
- **localization-i18n** — Use when adding translations, handling plurals, or formatting dates and numbers.
- **message-queue-processing** — Use when writing or reviewing queue consumers, workers, retries, or dead letter queues.
- **oauth-authentication** — Use when implementing login, token handling, sessions, or OAuth flows.
- **observability-and-slos** — Use when defining SLOs, error budgets, or setting up metrics, logging, and tracing.
- **onboarding-unfamiliar-codebase** — Use when opening an unfamiliar repository, or when asked to orient in a codebase.
- **performance-profiling** — Use when a program is slow or memory grows, or when profiling CPU or allocations.
- **planning-before-implementation** — Use when a task needs a plan, spec, or breakdown before any code is written.
- **property-based-testing** — Use when testing structured or invalid input, or when examples keep missing bugs.
- **receiving-code-review** — Use when code-review comments arrive, especially when they conflict.
- **refactoring-without-breaking-behaviour** — Use when restructuring code where existing tests must keep passing.
- **requesting-code-review** — Use when finishing a feature or branch, before merging, to get it reviewed.
- **resolving-merge-conflicts** — Use when git reports a conflict, a rebase stops, or a merge leaves CONFLICT markers.
- **rest-api-design** — Use when designing or reviewing an HTTP API, its errors, pagination, or idempotency.
- **security-code-review** — Use when reviewing code that handles untrusted input, auth, secrets, or file access.
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
