# Catalog

23 skills, grouped by cluster. The routing sentence is the skill's exact
`description`; changing it changes when the agent reaches for the skill, so
treat it as reviewed surface rather than incidental wording.

Read `authoring.md` before adding or changing any of these.

---

## Craft and process

The highest-leverage cluster in every public collection, and the one with the
widest measured effect on output quality.

| Skill | Routes when |
| --- | --- |
| `planning-before-implementation` | Use when a task needs more than a trivial edit and no agreed approach exists yet, or when asked to plan, spec, or break down work before implementing. |
| `writing-acceptance-criteria` | Use when a requirement is ambiguous, when defining done, or before writing tests, so that scope and edge cases are pinned down first. |
| `test-driven-development` | Use when adding or changing any feature or bugfix that needs tests, or when a test-first workflow is requested. |
| `systematic-debugging` | Use when a test fails, a build breaks, or behaviour is unexpected, and the cause is not yet known, before any fix is proposed. |
| `verification-before-completion` | Use when about to report that work is complete, fixed, passing, or done, before committing, pushing, or opening a pull request. |

## Review and quality

| Skill | Routes when |
| --- | --- |
| `requesting-code-review` | Use when finishing a feature, a branch, or a substantial change, before merging, to get the work checked against the stated requirements. |
| `receiving-code-review` | Use when code-review comments have arrived, especially when they conflict with each other or with the implementation. |
| `property-based-testing` | Use when a function handles structured input, invalid input, numeric edge cases, or serialization, or when example-based tests keep missing real bugs. |
| `webapp-testing` | Use when verifying a web application in a real browser, debugging a UI issue, or writing end-to-end tests against a running app. |
| `refactoring-without-breaking-behaviour` | Use when restructuring existing code, reducing duplication, or modernising an interface, where existing tests must keep passing. |

## Version control and architecture

| Skill | Routes when |
| --- | --- |
| `using-git-worktrees` | Use when starting work that should not disturb the current checkout, or when several branches need to be worked on at once. |
| `finishing-a-development-branch` | Use when a branch is ready to merge, open a pull request for, or hand off, and the remaining steps need to be done in order. |
| `resolving-merge-conflicts` | Use when git reports a conflict, when a rebase stops, or when a merge produces CONFLICT markers in a file. |
| `improving-codebase-architecture` | Use when asked to review, assess, or improve the structure of a codebase, find coupling or duplication, or decide what to refactor first. |
| `writing-technical-docs` | Use when writing or updating README, architecture notes, API reference, onboarding guides, or any doc aimed at another developer. |

## Interface and security

| Skill | Routes when |
| --- | --- |
| `frontend-design` | Use when building or restyling a user interface, component, or page, including when the request mentions a design or visual change. |
| `web-design-guidelines` | Use when reviewing UI code against interface guidelines, or when a question involves accessibility, layout, interaction, or UX quality. |
| `accessibility-audit` | Use when auditing a page or component for WCAG conformance, screen-reader support, or keyboard operability, or when accessibility is named as a requirement. |
| `security-code-review` | Use when reviewing code that handles untrusted input, authentication, authorisation, secrets, file or network access, or when a security review is requested. |
| `dependency-supply-chain-review` | Use when adding or upgrading dependencies, auditing an existing dependency tree, or assessing the risk of a package, lockfile, or build pipeline. |

## Agent operation

| Skill | Routes when |
| --- | --- |
| `writing-agent-skills` | Use when authoring, reviewing, or debugging an agent skill, and when a skill is not triggering when it should or triggers when it should not. |
| `dispatching-parallel-agents` | Use when independent work items could run concurrently, or when a large task is being split across subagents without coordination. |
| `sql-query-performance` | Use when a database query is slow, when an index is missing or unused, or when writing queries against a large table. |

---

## Provenance

Each skill was written from the published guidance below rather than invented.
The document skills and the engineering post are Anthropic's; `superpowers` and
`skill-creator` are the most-installed community collections and supplied the
description and token-budget findings.

- Open Agent Skills specification — <https://agentskills.io/specification>
- OpenCode V2 skills — <https://opencode.ai/v2/docs/skills>
- Anthropic, *Equipping agents for the real world with Agent Skills* —
  <https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills>
- Anthropic official skills — <https://github.com/anthropics/skills>
- `obra/superpowers` — <https://github.com/obra/superpowers>
- Agent Skills platform documentation —
  <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>
- `trailofbits/skills` — <https://github.com/trailofbits/skills>
- `vercel-labs/agent-skills` — <https://github.com/vercel-labs/agent-skills>

Names here deliberately avoid `helper`, `utils` and `tools`. Those describe a
role rather than a situation, so they never tell an agent when to load the
skill.