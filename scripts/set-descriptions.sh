#!/usr/bin/env bash
#
# set-descriptions.sh - apply the canonical description for each skill.
#
# Codex gives the skill list only 8,000 characters and drops whatever does not
# fit, shortening the longest descriptions first and omitting skills entirely
# with a warning. A long description therefore costs other skills their
# existence. This script keeps every routing sentence in one auditable place
# instead of scattered across 47 files.
#
# Usage: scripts/set-descriptions.sh [--check]

set -uo pipefail

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SRC=".opencode/skills"

# id | description. Keep these near 80-110 characters: the routing signal has to
# survive, and every character here is one a sibling skill does not get to use.
DESCRIPTIONS='
accessibility-audit|Use when auditing a page or component for WCAG, screen readers, or keyboard operability.
api-contract-versioning|Use when changing an API in a breaking way, or deciding on a versioning scheme.
backup-and-disaster-recovery|Use when designing backups, recovery objectives, or planning for data loss.
background-jobs-and-scheduling|Use when adding cron or a job queue, or when jobs overlap, drift, or run twice.
caching-and-stampedes|Use when adding or tuning a cache, or when a hot key overwhelms the database.
ci-pipeline-security|Use when writing or reviewing CI workflows, or assessing supply chain risk.
cloud-security-and-cost|Use when reviewing cloud IAM, network exposure, or reducing cloud spend.
concurrency-and-async|Use when writing concurrent or async code, or diagnosing races, deadlocks, or blocking.
contract-and-load-testing|Use when writing Pact contract tests, or load testing an API.
css-architecture|Use when setting up design tokens, growing a stylesheet, or choosing a styling approach.
database-migrations|Use when running schema migrations or backfills, or when a migration blocks queries.
date-time-handling|Use when working with dates, time zones, timestamps, or calendar arithmetic.
dbt-modeling|Use when writing dbt models, incremental models, or fixing a broken build.
dependency-supply-chain-review|Use when adding or upgrading dependencies, or auditing a lockfile.
dimensional-modeling|Use when designing a warehouse schema, or choosing a slowly changing dimension type.
dispatching-parallel-agents|Use when independent work could run concurrently, or splitting work across subagents.
docker-containerization|Use when writing a Dockerfile, or debugging image size, cache, or signals.
domain-modeling|Use when identifying domain concepts, business rules, or unclear code vocabulary.
email-deliverability|Use when sending email, configuring SPF, DKIM or DMARC, or when mail is being filtered.
environment-bootstrap|Use when setting up a dev environment, installing dependencies, or running a project.
feature-flag-and-secrets-lifecycle|Use when adding or retiring a feature flag, or rotating secrets.
finishing-a-development-branch|Use when a branch is ready to merge, hand off, or open a pull request.
frontend-design|Use when building or restyling a user interface, component, or page.
git-internals|Use when recovering lost work, bisecting a regression, or managing hooks and submodules.
graphql-api-security|Use when exposing or reviewing a GraphQL API, or when it is slow or being abused.
http-security-headers|Use when setting or reviewing security headers, CSP, or CORS policy.
improving-codebase-architecture|Use when reviewing codebase structure, duplication, or prioritising refactors.
incident-response|Use when responding to a production incident, outage, or alert.
infrastructure-as-code|Use when writing Terraform or other infrastructure code, or diagnosing drift.
kubernetes-deployment|Use when writing or reviewing Kubernetes manifests, probes, limits, or rollouts.
llm-application-development|Use when building on language models: retrieval, prompts, evaluation, tool calls.
linux-ops-debugging|Use when debugging a Linux host, a systemd unit, disk, permissions, or SSH.
localization-i18n|Use when adding translations, handling plurals, or formatting dates and numbers.
mcp-server-authoring|Use when building an MCP server or tool, or exposing capabilities to an agent.
message-queue-processing|Use when writing or reviewing queue consumers, workers, or retries.
mobile-performance-and-release|Use when a mobile app is slow to start, janky to scroll, or rejected by review.
oauth-authentication|Use when implementing login, token handling, sessions, or OAuth flows.
observability-and-slos|Use when defining SLOs, error budgets, or setting up metrics, logging, and tracing.
onboarding-unfamiliar-codebase|Use when opening an unfamiliar repository, or orienting in a codebase.
orchestration-dag-authoring|Use when writing or debugging Airflow, Dagster or Prefect pipelines.
payments-integration|Use when integrating a payment provider, or handling subscriptions or payment webhooks.
performance-profiling|Use when a program is slow or memory grows, or when profiling CPU or allocations.
planning-before-implementation|Use when a task needs a plan, spec, or breakdown before any code is written.
privacy-and-data-retention|Use when handling personal data, deletion, or retention policy.
property-based-testing|Use when testing structured or invalid input, or when examples keep missing bugs.
prompt-injection-defense|Use when an LLM reads untrusted content, or an agent acts on model decisions.
receiving-code-review|Use when code-review comments arrive, especially when they conflict.
refactoring-without-breaking-behaviour|Use when restructuring code where existing tests must keep passing.
release-engineering|Use when cutting a release, writing a changelog, or planning a rollback.
requesting-code-review|Use when finishing a feature or branch, before merging, to get it reviewed.
resolving-merge-conflicts|Use when git reports a conflict, a rebase stops, or CONFLICT markers remain.
rest-api-design|Use when designing or reviewing an HTTP API, its errors, pagination, or idempotency.
search-engineering|Use when designing an Elasticsearch index, or tuning query relevance.
security-code-review|Use when reviewing code that handles untrusted input, auth, secrets, or file access.
shell-and-text-tooling|Use when writing shell scripts, grep/sed/awk pipelines, or tooling that scans files.
spark-performance|Use when a Spark job is slow, data skew is suspected, or joins misbehave.
sql-query-performance|Use when a query is slow, an index is missing, or querying a large table.
structured-logging-and-error-handling|Use when adding logging, propagating errors, or redacting sensitive data.
systematic-debugging|Use when a test or build fails and the cause is not yet known.
test-driven-development|Use when adding or changing a feature or bugfix that needs tests.
trustworthy-checks|Use when writing a validator, gate, lint rule, or CI check, or when a check passes and you doubt it.
using-git-worktrees|Use when work should not disturb the current checkout, or branches run at once.
verification-before-completion|Use when about to report work complete or fixed, or before committing.
webapp-testing|Use when verifying a web app in a real browser, or debugging a UI issue.
web-design-guidelines|Use when reviewing UI code against interface, accessibility, or UX guidelines.
webhook-integration|Use when sending or receiving webhooks, or verifying webhook signatures.
writing-acceptance-criteria|Use when a requirement is ambiguous, or before tests, to pin down scope.
writing-agent-skills|Use when authoring or debugging an agent skill, or when triggers are wrong.
writing-technical-docs|Use when writing or updating README, architecture notes, or API reference.
'

if [ -t 1 ]; then RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'; else RED=''; GRN=''; RST=''; fi

changed=0
drift=0
seen=""

while IFS='|' read -r id desc; do
  id="${id// /}"
  [ -n "$id" ] || continue
  seen="$seen $id"

  f="$SRC/$id/SKILL.md"
  if [ ! -f "$f" ]; then
    printf '%sskip%s %s (no such skill)\n' "$RED" "$RST" "$id"
    drift=$((drift + 1))
    continue
  fi

  current="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -n 1)"
  if [ "$current" = "$desc" ]; then
    continue
  fi

  if [ "$CHECK" -eq 1 ]; then
    printf '%sdrift%s %s\n' "$RED" "$RST" "$id"
    drift=$((drift + 1))
    continue
  fi

  # Only the description line is replaced; the body is never touched.
  awk -v d="$desc" '
    BEGIN { done = 0 }
    !done && /^description:[[:space:]]*/ { print "description: " d; done = 1; next }
    { print }
  ' "$f" > "$f.tmp.$$" && mv "$f.tmp.$$" "$f"

  printf '%sset%s   %s\n' "$GRN" "$RST" "$id"
  changed=$((changed + 1))
done <<EOF
$DESCRIPTIONS
EOF

# A skill with no entry here would keep whatever description it has, which is
# how the catalog budget creeps up unnoticed.
for d in "$SRC"/*/; do
  d="${d%/}"
  id="${d##*/}"
  [ -f "$d/SKILL.md" ] || continue
  case " $seen " in
    *" $id "*) ;;
    *)
      if [ "$CHECK" -eq 1 ]; then
        printf '%sunmanaged%s %s has no canonical description\n' "$RED" "$RST" "$id"
        drift=$((drift + 1))
      else
        printf '%sunmanaged%s %s (add it to scripts/set-descriptions.sh)\n' "$RED" "$RST" "$id"
      fi
      ;;
  esac
done

printf '\n'
if [ "$CHECK" -eq 1 ]; then
  [ "$drift" -eq 0 ] && { printf '%sall descriptions match the canonical set%s\n' "$GRN" "$RST"; exit 0; }
  printf '%s%d description(s) differ%s - run scripts/set-descriptions.sh\n' "$RED" "$drift" "$RST"
  exit 1
fi
printf '%s%d description(s) updated%s\n' "$GRN" "$changed" "$RST"
exit 0
