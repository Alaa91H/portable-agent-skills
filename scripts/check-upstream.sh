#!/usr/bin/env bash
#
# check-upstream.sh - detect drift in the Agent Skills specification this
# collection validates against.
#
# A skill collection is only as conformant as the specification it was written
# to, and that specification can change underneath it. Finding out months later
# from a failing validator is the worst way to find out: every skill in the
# collection may already be non-conformant at the same moment.
#
# The check is a fingerprint comparison, so it is cheap, has no dependencies, and
# cannot produce a false positive from formatting.
#
# Usage:
#   scripts/check-upstream.sh            # report drift, change nothing
#   scripts/check-upstream.sh --accept   # record the current fingerprint
#   scripts/check-upstream.sh --status   # print the recorded fingerprint and date

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SPEC_URL="https://agentskills.io/specification"
LOCK="spec/upstream.sha256"
CHECKED="spec/upstream.checked"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; BLD=''; RST=''
fi

say() { printf '%s\n' "$*"; }
note() { printf '  %s%s%s\n' "$DIM" "$*" "$RST"; }

recorded() { [ -f "$LOCK" ] && tr -d '[:space:]' < "$LOCK" || printf ''; }

fetch_fingerprint() {
  # Hash the body, not the headers: a CDN rotation or a changed ETag is not a
  # specification change, and reporting one would make the check noise.
  curl -fsSL --retry 3 --max-time 30 "$SPEC_URL" 2>/dev/null \
    | sha256sum 2>/dev/null \
    | cut -d' ' -f1
}

ACCEPT=0
STATUS=0
for a in "$@"; do
  case "$a" in
    --accept) ACCEPT=1 ;;
    --status) STATUS=1 ;;
    -*) printf 'unknown option: %s\n' "$a" >&2; exit 2 ;;
    *)  printf 'unknown argument: %s\n' "$a" >&2; exit 2 ;;
  esac
done

if [ "$STATUS" -eq 1 ]; then
  if [ -n "$(recorded)" ]; then
    say "$(recorded)"
    [ -f "$CHECKED" ] && say "recorded $(tr -d '[:space:]' < "$CHECKED")"
    exit 0
  fi
  say "no fingerprint recorded"
  exit 0
fi

say "fetching $SPEC_URL"
new="$(fetch_fingerprint)"
if [ -z "$new" ]; then
  say "${YEL}could not reach the specification${RST}"
  note "This is a network problem, not a specification change."
  note "Exit status 0: an unreachable upstream must not fail a build."
  exit 0
fi

old="$(recorded)"

if [ "$ACCEPT" -eq 1 ]; then
  mkdir -p spec
  printf '%s\n' "$new" > "$LOCK"
  date -u +%Y-%m-%dT%H:%M:%SZ > "$CHECKED"
  say "${GRN}recorded${RST} $new"
  if [ "$old" != "$new" ] && [ -n "$old" ]; then
    say "${YEL}note${RST} this differs from the previous fingerprint ($old)"
    note "Read the specification diff before committing this."
  fi
  exit 0
fi

say "current   $new"
if [ -z "$old" ]; then
  say "recorded  ${YEL}(none)${RST}"
  say ""
  say "No fingerprint on record, so there is nothing to compare against."
  say "Read the specification, then run: scripts/check-upstream.sh --accept"
  exit 0
fi

say "recorded  $old"
say ""

if [ "$old" = "$new" ]; then
  when="$( [ -f "$CHECKED" ] && tr -d '[:space:]' < "$CHECKED" || echo unknown )"
  say "${GRN}unchanged${RST} (last checked $when)"
  exit 0
fi

say "${RED}the specification has changed${RST}"
say ""
say "Nothing here is broken. The collection still validates against the version"
say "it was written to, and that version is no longer current."
say ""
say "1. Read the diff at <$SPEC_URL>"
say "2. Decide whether a rule in scripts/validate-skills.sh should change."
say "3. If so, change it and let the validator name the skills it now rejects."
say "4. scripts/check-upstream.sh --accept   to record the new fingerprint"
say ""
say "Do not step 4 first. The fingerprint is what stops this check reporting"
say "again, so accepting it early silences the signal permanently."
exit 1