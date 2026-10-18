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
arabic-news-briefing|Use when writing an Arabic news briefing, daily digest, or round-up.
accessibility-audit|Use when auditing a page or component for WCAG, reader or keyboard use.
api-contract-versioning|Use when changing an API in a breaking way, or picking a version scheme.
backup-and-disaster-recovery|Use when designing backups, recovery objectives, or planning for loss.
background-jobs-and-scheduling|Use when adding cron or a job queue, or when jobs overlap or repeat.
codebase-decomposition|Use when a file has grown large, or deciding where behaviour belongs.
completeness-and-detail|Use when finishing work and something may be missed, or auditing scope.
caching-and-stampedes|Use when adding or tuning a cache, or when a hot key overwhelms the DB.
ci-pipeline-security|Use when writing or reviewing CI workflows, or supply chain risk.
cloud-security-and-cost|Use when reviewing cloud IAM, network exposure, or cloud spend.
concurrency-and-async|Use when writing concurrent code, or diagnosing races and deadlocks.
contract-and-load-testing|Use when writing Pact contract tests, or load testing an API.
css-architecture|Use when setting up design tokens, growing a stylesheet, or picking styles.
database-migrations|Use when running schema migrations or backfills that block queries.
date-time-handling|Use when working with dates, time zones, timestamps, or calendar maths.
dbt-modeling|Use when writing dbt models, incremental models, or fixing a build.
dependency-supply-chain-review|Use when adding or upgrading dependencies, or auditing a lockfile.
dimensional-modeling|Use when designing a warehouse schema, or a slowly changing dimension.
dispatching-parallel-agents|Use when independent work could run concurrently, or across subagents.
docker-containerization|Use when writing a Dockerfile, or debugging image size, cache or signals.
self-critique-and-polish|Use when reviewing your own output before delivery, or polishing work.
deep-research|Use when researching a topic or sources, or needing depth and saturation.
dense-code-and-signal|Use when reviewing code for padding, dead code, or comments that restate the code.
quality-gates-and-tests|Use when setting up CI gates, E2E tests, coverage targets, or judging test strength.
domain-modeling|Use when identifying domain concepts, business rules, or unclear terms.
evidence-first-writing|Use when an answer states a fact, figure, link, or claim about others.
email-deliverability|Use when sending email, or configuring SPF, DKIM or DMARC records.
environment-bootstrap|Use when setting up a dev environment, or installing dependencies.
feature-flag-and-secrets-lifecycle|Use when adding or retiring a feature flag, or rotating secrets.
finishing-a-development-branch|Use when a branch is ready to merge, hand off, or open a PR.
frontend-design|Use when building or restyling an interface, component or page.
git-internals|Use when recovering lost work, bisecting, or managing submodules.
hallucination-defense|Use when an agent may invent facts, drift from the request, or output is ungrounded.
graphql-api-security|Use when exposing or reviewing a GraphQL API, or when it is abused.
http-security-headers|Use when setting or reviewing security headers, CSP or CORS.
improving-codebase-architecture|Use when reviewing codebase structure, duplication or refactor priority.
honest-technical-reporting|Use when describing work done, a result, or a status someone will act on.
incident-response|Use when responding to a production incident, outage or alert.
infrastructure-as-code|Use when writing Terraform or infrastructure code, or diagnosing drift.
kubernetes-deployment|Use when writing or reviewing Kubernetes manifests, probes or rollouts.
llm-application-development|Use when building on language models: retrieval, prompts, evaluation.
long-form-integrity|Use when finishing a long generated answer, report, digest or write-up.
linux-ops-debugging|Use when debugging a Linux host, systemd unit, disk, or SSH.
localization-i18n|Use when adding translations, plurals, or date and number formats.
mcp-server-authoring|Use when building an MCP server or tool, or exposing agent capabilities.
message-queue-processing|Use when writing queue consumers, workers, retries or dead letters.
mobile-performance-and-release|Use when a mobile app is slow to start, janky to scroll, or rejected.
oauth-authentication|Use when implementing login, tokens, sessions, or OAuth flows.
observability-and-slos|Use when defining SLOs, error budgets, or metrics, logging and tracing.
onboarding-unfamiliar-codebase|Use when opening an unfamiliar repository, or orienting in one.
orchestration-dag-authoring|Use when writing or debugging Airflow, Dagster or Prefect DAGs.
payments-integration|Use when integrating a payment provider, subscriptions or webhooks.
performance-profiling|Use when a program is slow or memory grows, or when profiling CPU.
planning-before-implementation|Use when a task needs a plan or breakdown before code is written.
privacy-and-data-retention|Use when handling personal data, deletion or retention rules.
progress-and-course-correction|Use when work is in progress and drifting from its goal, or effort is being wasted.
property-based-testing|Use when testing structured or invalid input, or examples miss bugs.
prompt-injection-defense|Use when an LLM reads untrusted content or acts on model output.
receiving-code-review|Use when code-review comments arrive, or conflict with your work.
refactoring-without-breaking-behaviour|Use when restructuring code where the existing tests must pass.
release-engineering|Use when cutting a release, writing a changelog, or a rollback plan.
requesting-code-review|Use when a feature or branch is ready, before merging, for review.
resolving-merge-conflicts|Use when git reports a conflict, a rebase stops, or markers remain.
rest-api-design|Use when designing or reviewing an HTTP API: errors, pages, idempotency.
search-engineering|Use when designing an Elasticsearch index or tuning relevance.
security-code-review|Use when reviewing code handling untrusted input, auth or secrets.
shell-and-text-tooling|Use when writing shell scripts, grep/sed/awk, or file-scanning tools.
spark-performance|Use when a Spark job is slow, data skew is suspected, or joins break.
sql-query-performance|Use when a query is slow, an index is missing, or a table is large.
structured-logging-and-error-handling|Use when adding logging, propagating errors, or redacting secrets.
systematic-debugging|Use when a test or build fails and the cause is not yet known.
context-window-management|Use when work must survive compaction, or a task loses coherence.
token-and-context-budget|Use when a task is large, or when deciding what to read, delegate or write.
test-driven-development|Use when adding or changing a feature or bugfix that needs tests.
trustworthy-checks|Use when writing a validator, gate, or CI check, or one passes suspiciously.
up-to-date-tooling|Use when choosing a library or API, recalling a version, or new tooling.
using-git-worktrees|Use when work should not disturb the checkout, or run branches at once.
verification-before-completion|Use when about to report work complete, or before committing.
webapp-testing|Use when verifying a web app in a browser, or debugging a UI issue.
web-design-guidelines|Use when reviewing UI code against interface, accessibility or UX.
webhook-integration|Use when sending or receiving webhooks, or verifying signatures.
writing-acceptance-criteria|Use when a requirement is ambiguous, or before tests, to fix scope.
writing-agent-skills|Use when authoring or debugging an agent skill, or fixing triggers.
writing-technical-docs|Use when updating a README, architecture notes or API reference.
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
