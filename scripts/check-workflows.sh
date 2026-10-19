#!/usr/bin/env bash
#
# check-workflows.sh - verify the GitHub Actions workflows.
#
# Two things are checked, and neither needs a YAML parser, which matters
# because a parser is not available on every machine that has to run this and
# a gate that only runs in one place is a gate nobody watches.
#
# 1. Every action reference is pinned to a commit SHA.
#
#    A tag can be moved after it has been reviewed. A commit cannot. This
#    repository ships ci-pipeline-security, which says to pin, and a
#    repository that publishes the rule is not credible if it breaks it. The
#    check catches the most likely way that happens: someone adds a step and
#    writes `uses: actions/checkout@v4` out of habit.
#
# 2. The indentation of the list items under a `steps:` key is consistent.
#
#    This is not a YAML parser and does not claim to be one. It checks the
#    specific structural rule that a hand edit breaks most often: a list item
#    indented differently from its siblings. That is exactly how the pin
#    commit broke all four workflows at once: the `uses:` line was written two
#    spaces shallower than the `- name:` lines around it, so every workflow
#    failed to parse and every job silently never started.
#
# Usage: scripts/check-workflows.sh
# Exit:  0 when every workflow passes, 1 otherwise.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; BLD=''; RST=''
fi

ERRORS=0
fail() { printf '  %sFAIL%s  %s\n' "$RED" "$RST" "$*"; ERRORS=$((ERRORS + 1)); }
pass() { printf '  %sok%s    %s\n' "$GRN" "$RST" "$*"; }

WF_DIR=".github/workflows"
printf '%sworkflows%s\n' "$BLD" "$RST"

[ -d "$WF_DIR" ] || { printf '%serror%s  %s does not exist\n' "$RED" "$RST" "$WF_DIR" >&2; exit 1; }

for f in "$WF_DIR"/*.yml; do
  [ -f "$f" ] || continue
  name="${f##*/}"

  # --- 1. every action pinned to a SHA -------------------------------------
  unpinned="$(grep -nE 'uses:[[:space:]]*[^ ]+@[^ ]+$' "$f" | grep -vE '@[0-9a-f]{40}([[:space:]]|$)' || true)"
  if [ -n "$unpinned" ]; then
    fail "$name: an action is not pinned to a commit SHA"
    printf '%s\n' "$unpinned" | sed 's/^/          /'
    printf 'hint pin to the full SHA and put the version in the comment above it\n'
  else
    n=$(grep -cE 'uses:[[:space:]]*[^ ]+@[0-9a-f]{40}([[:space:]]|$)' "$f")
    if [ "$n" -gt 0 ]; then
      pass "$name: $n action reference(s) pinned to a SHA"
    else
      pass "$name: no action references"
    fi
  fi

  # --- 2. list items under a steps: key share one indentation -------------
  #
  # A small awk pass. It reports the line number of any list item whose
  # indentation differs from the first list item in the same steps block.
  bad_indent="$(awk '
    /^[[:space:]]*steps:[[:space:]]*$/ {
      in_steps = 1; expect = 0; next
    }
    in_steps {
      # a new key at the same or lower level ends the steps block
      if ($0 ~ /^[^[:space:]]/ || $0 ~ /^[[:space:]]{0,4}[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]*$/) {
        in_steps = 0; next
      }
      if ($0 ~ /^[[:space:]]*-[[:space:]]/) {
        match($0, /^[[:space:]]*/)
        ind = RLENGTH
        if (expect == 0) { expect = ind }
        else if (ind != expect) {
          printf "line %d: list item indented %d spaces, the others in this block use %d\n", FNR, ind, expect
        }
      }
    }
  ' "$f")"
  if [ -n "$bad_indent" ]; then
    fail "$name: list items under a steps: key are indented inconsistently"
    printf '%s\n' "$bad_indent" | sed 's/^/          /'
  else
    pass "$name: list indentation is consistent"
  fi

  # --- 3. no tabs, ever ---------------------------------------------------
  if grep -qP '\t' "$f" 2>/dev/null || grep -q "$(printf '\t')" "$f"; then
    fail "$name: contains a tab, which YAML forbids for indentation"
  else
    pass "$name: no tabs"
  fi
done

printf '\n'
if [ "$ERRORS" -gt 0 ]; then
  printf '%s%d workflow problem(s)%s\n' "$RED" "$ERRORS" "$RST"
  exit 1
fi
printf '%sall workflows pass%s\n' "$GRN" "$RST"
exit 0
