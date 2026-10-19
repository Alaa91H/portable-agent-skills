#!/usr/bin/env bash
#
# report-drift.sh - run the generation gates and, if any of them reports drift,
# open or update a single tracking issue that names the drifting files.
#
# A gate that fails only in a CI log is a gate whose failure most maintainers
# never see. Logs are per-run, unlinked, unsearchable and easy to ignore; an
# issue is durable, has history, and can be subscribed to. The first version of
# this repository shipped a marketplace manifest two releases out of date and a
# set of scripts without their executable bit, and the only signal was a red
# tick that nobody had a reason to click.
#
# The point is not the report. It is that "the checks failed" and "nobody knows
# which files failed" are different problems, and only one of them is fixable
# without a machine.
#
# Deduplicated on purpose: one open issue per distinct set of drifting files,
# with later runs commenting on it. A gate that opens a new issue on every push
# trains people to ignore issues, and muting is what removes a gate.
#
# Usage: scripts/report-drift.sh
# Env:   GH_TOKEN (required), GITHUB_REPOSITORY (owner/repo), DRY_RUN=1 to
#        print without publishing.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; BLD=''; RST=''
fi

DRY="${DRY_RUN:-0}"
REPO="${GITHUB_REPOSITORY:-}"
TITLE='Generated files are out of date on main'

# Each gate is run and its failure output collected. Only the gates that can
# drift from a hand edit are here; spec conformance and the regression suite fail
# for different reasons and are already visible as build status.
GATES='scripts/set-descriptions.sh --check
scripts/sync-agents.sh --check
scripts/sync-rules.sh --check
scripts/build-catalog-doc.sh --check'

report=""
failed=0

printf '%sdrift report%s\n' "$BLD" "$RST"
IFS_SAVE="$IFS"
IFS='
'
for gate in $GATES; do
  IFS="$IFS_SAVE"
  # The script and its flags must be separate arguments. Passing "$gate" quoted
  # hands bash one string containing a space, which it takes as a filename, and
  # the failure reads "No such file or directory" rather than mentioning
  # arguments at all. Read them apart explicitly instead of relying on word
  # splitting that the IFS juggling then undoes.
  gate_script="${gate%% *}"
  gate_flags="${gate#* }"
  [ "$gate_flags" = "$gate" ] && gate_flags=""
  out="$(bash "$gate_script" $gate_flags 2>&1)"
  rc=$?
  IFS='
'
  if [ "$rc" -ne 0 ]; then
    failed=$((failed + 1))
    # Keep the report short: the full output of a generator is long, and the
    # first few drift lines are what a reader acts on.
    detail="$(grep -v '^$' <<<"$out" | head -n 12)"
    report+="

### \`$gate\` (exit $rc)

\`\`\`
$detail
\`\`\`
"
    printf '  %sFAIL%s  %s\n' "$RED" "$RST" "$gate"
  else
    printf '  %sok%s    %s\n' "$GRN" "$RST" "$gate"
  fi
done
IFS="$IFS_SAVE"

if [ "$failed" -eq 0 ]; then
  printf '\n%sall generation gates pass%s\n' "$GRN" "$RST"
  exit 0
fi

printf '\n%s%d generation gate(s) report drift%s\n' "$RED" "$failed" "$RST"

body="$(cat <<EOF
Generated files in this repository do not match what the generators produce, so
the collection is inconsistent between commits. Nothing here is wrong in the
skills; the derived files are stale.

Fix by regenerating and committing:

\`\`\`sh
scripts/set-descriptions.sh
scripts/sync-agents.sh
scripts/sync-rules.sh
scripts/build-catalog-doc.sh
git commit -am 'Regenerate derived files'
\`\`\`

If a generator keeps reporting drift immediately after being run, the cause is
almost always an uncommitted artefact from an interrupted run rather than the
generator itself. Look for files matching \`*.tmp.*\`, which is what an
interrupted \$\$-suffixed write leaves behind.
$report
---
Reported by \`scripts/report-drift.sh\` on $(date -u +%Y-%m-%dT%H:%M:%SZ).
Run count is recorded in the issue comments; the first report is kept.
EOF
)"

if [ "$DRY" = "1" ] || [ -z "${GH_TOKEN:-}" ] || [ -z "$REPO" ]; then
  printf '\n%snot publishing%s (DRY_RUN=%s, token=%s, repo=%s)\n\n' "$YEL" "$RST" \
    "$DRY" "$([ -n "${GH_TOKEN:-}" ] && echo yes || echo no)" "${REPO:-none}"
  printf '%s\n' "$body"
  exit 1
fi

# One open issue per drifting file set. Re-running with the same drift adds a
# comment, which keeps the history without spamming the list.
fingerprint="$(printf '%s' "$report" | sha256sum | cut -c1-12)"
marker="drift-set: $fingerprint"

existing="$(gh issue list --repo "$REPO" --state open \
  --search "$TITLE in:title" --json number,body \
  --limit 20 2>/dev/null | grep -B2 -A20 "$marker" | grep '"number"' | head -n 1 \
  | tr -dc '0-9')"

if [ -n "$existing" ]; then
  printf 'updating issue #%s\n' "$existing"
  printf '%s\n\n%s\n' "$marker" "$body" | gh issue comment "$existing" \
    --repo "$REPO" --body-file - >/dev/null
else
  printf 'opening an issue\n'
  printf '%s\n\n%s\n' "$marker" "$body" | gh issue create \
    --repo "$REPO" --title "$TITLE" --body-file - >/dev/null
fi

exit 1