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
- **dependency-supply-chain-review** — Use when adding or upgrading dependencies, auditing an existing dependency tree, or assessing the risk of a package, lockfile, or build pipeline.
- **dispatching-parallel-agents** — Use when independent work items could run concurrently, or when a large task is being split across subagents without coordination.
- **finishing-a-development-branch** — Use when a branch is ready to merge, open a pull request for, or hand off, and the remaining steps need to be done in order.
- **frontend-design** — Use when building or restyling a user interface, component, or page, including when the request mentions a design or visual change.
- **improving-codebase-architecture** — Use when asked to review, assess, or improve the structure of a codebase, find coupling or duplication, or decide what to refactor first.
- **planning-before-implementation** — Use when a task needs more than a trivial edit and no agreed approach exists yet, or when asked to plan, spec, or break down work before implementing.
- **property-based-testing** — Use when a function handles structured input, invalid input, numeric edge cases, or serialization, or when example-based tests keep missing real bugs.
- **receiving-code-review** — Use when code-review comments have arrived, especially when they conflict with each other or with the implementation.
- **refactoring-without-breaking-behaviour** — Use when restructuring existing code, reducing duplication, or modernising an interface, where existing tests must keep passing.
- **requesting-code-review** — Use when finishing a feature, a branch, or a substantial change, before merging, to get the work checked against the stated requirements.
- **resolving-merge-conflicts** — Use when git reports a conflict, when a rebase stops, or when a merge produces CONFLICT markers in a file.
- **security-code-review** — Use when reviewing code that handles untrusted input, authentication, authorisation, secrets, file or network access, or when a security review is requested.
- **sql-query-performance** — Use when a database query is slow, when an index is missing or unused, or when writing queries against a large table.
- **systematic-debugging** — Use when a test fails, a build breaks, or behaviour is unexpected, and the cause is not yet known, before any fix is proposed.
- **test-driven-development** — Use when adding or changing any feature or bugfix that needs tests, or when a test-first workflow is requested.
- **using-git-worktrees** — Use when starting work that should not disturb the current checkout, or when several branches need to be worked on at once.
- **verification-before-completion** — Use when about to report that work is complete, fixed, passing, or done, before committing, pushing, or opening a pull request.
- **web-design-guidelines** — Use when reviewing UI code against interface guidelines, or when a question involves accessibility, layout, interaction, or UX quality.
- **webapp-testing** — Use when verifying a web application in a real browser, debugging a UI issue, or writing end-to-end tests against a running app.
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
