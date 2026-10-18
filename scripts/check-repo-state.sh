#!/usr/bin/env bash
#
# check-repo-state.sh - check the facts about the repository itself that other
# tools publish: the marketplace manifest, and whether the scripts CI invokes
# directly are actually executable.
#
# These were inline in validate-skills.sh, which made them impossible to test in
# isolation: the only way to exercise them was to run the whole validator against
# the whole collection, roughly two minutes on Windows and several per
# assertion. That is long enough that the checks get skipped locally, which is
# the same reason they went unnoticed when they were already broken.
#
# Every path is overridable so a test can point the checks at a fixture and get
# an answer in milliseconds.
#
# Usage: scripts/check-repo-state.sh
#
# Environment overrides:
#   REPO_ROOT     repository root                  (default: this script's parent)
#   MARKETPLACE   marketplace manifest             (default: .claude-plugin/marketplace.json)
#   VERSION_FILE  version file                     (default: VERSION)
#   SKILLS_DIR    skill tree                       (default: .opencode/skills)
#   CHECK_EXEC    1 to run the executable-bit check (default: 1)
#
# Output: one line per fact, prefixed "ok ", "FAIL " or "hint " so a caller can
# replay them into its own reporting.
# Exit:   0 when everything passed, 1 otherwise.

set -uo pipefail

ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MARKETPLACE="${MARKETPLACE:-$ROOT/.claude-plugin/marketplace.json}"
VERSION_FILE="${VERSION_FILE:-$ROOT/VERSION}"
SKILLS_DIR="${SKILLS_DIR:-$ROOT/.opencode/skills}"
CHECK_EXEC="${CHECK_EXEC:-1}"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; RST=''
fi

failures=0

# ------------------------------------------------------------- marketplace
#
# A published manifest that is written by hand drifts, because nothing
# regenerates it and nothing compares it to a source of truth. The one that
# shipped here advertised version 1.0.0 and 23 skills while the collection was at
# 1.1.0 with 69, and the only reason it surfaced is that publishing was imminent.
#
# Two facts are pinned, each to a source that cannot drift independently: the
# version against ./VERSION, and the advertised count against the number of skills
# actually present. The count is the one that rots quietly, because it is prose.
if [ -f "$MARKETPLACE" ]; then
  # Unanchored on purpose. Anchoring to the start of the line makes the check
  # depend on the manifest being pretty-printed, so reformatting the file breaks
  # a check that has nothing to do with formatting. Both patterns are read with a
  # leading .* for the same reason.
  declared_version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MARKETPLACE" | head -n 1)"
  actual_version="$(tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null)"

  if [ -z "$declared_version" ]; then
    printf 'FAIL %s%s has no version%s\n' "$RED" "${MARKETPLACE##*/}" "$RST"
    failures=$((failures + 1))
  elif [ "$declared_version" != "$actual_version" ]; then
    printf 'FAIL %smarketplace advertises version %s but VERSION is %s%s\n' \
      "$RED" "$declared_version" "$actual_version" "$RST"
    printf 'hint bump the marketplace version, or run scripts/release.sh <version>\n'
    failures=$((failures + 1))
  else
    printf 'ok   marketplace version matches VERSION (%s)\n' "$actual_version"
  fi

  real_count=0
  if [ -d "$SKILLS_DIR" ]; then
    for d in "$SKILLS_DIR"/*/; do
      [ -f "${d%/}/SKILL.md" ] && real_count=$((real_count + 1))
    done
  fi

  advertised="$(sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([0-9][0-9]*\).*/\1/p' "$MARKETPLACE" | head -n 1)"
  if [ -z "$advertised" ]; then
    printf 'WARN %s%s states no skill count, so it cannot be checked%s\n' "$YEL" "${MARKETPLACE##*/}" "$RST"
  elif [ "$advertised" != "$real_count" ]; then
    printf 'FAIL %smarketplace advertises %s skills but %s are present%s\n' \
      "$RED" "$advertised" "$real_count" "$RST"
    printf 'hint update the description count to %s\n' "$real_count"
    failures=$((failures + 1))
  else
    printf 'ok   marketplace advertises the right skill count (%s)\n' "$real_count"
  fi
fi

# --------------------------------------------------------- executable bit
#
# Every script here is invoked as `scripts/foo.sh` by the CI workflows, which on
# a POSIX host means the file needs the executable bit or the step exits 126 with
# "Permission denied".
#
# This repository is authored on Windows, where core.fileMode is false and the
# filesystem has no exec bit, so git records 100644 for everything and nothing
# fails locally. The first CI run failed at its first step on every branch, with
# an error naming a permission problem rather than a content problem.
#
# A defect that exists only on the platform you are not developing on is
# invisible to the person best placed to fix it, which is the whole argument for
# checking the committed mode rather than the working tree.
#
# One awk pass over the whole listing. This started as three subprocesses per
# tracked file, which on a thousand-file checkout cost more than every other
# check combined, and is exactly the failure shell-and-text-tooling warns about.
if [ "$CHECK_EXEC" = "1" ] && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  exec_stats="$(git -C "$ROOT" ls-files -s 2>/dev/null | awk '
    { p = $4 }
    p ~ /\.sh$/ || p == "install.sh" {
      total++
      if ($1 != "100755") bad = bad " " p
    }
    END { printf "%d|%s", total + 0, bad }
  ')"

  exec_n="${exec_stats%%|*}"
  not_exec="${exec_stats#*|}"

  if [ "$exec_n" -eq 0 ]; then
    printf 'ok   no shell scripts are tracked\n'
  elif [ -n "$not_exec" ]; then
    printf 'FAIL %sscript(s) not committed as executable (mode 100644):%s%s\n' "$RED" "$not_exec" "$RST"
    printf 'hint fix with: git update-index --chmod=+x install.sh scripts/*.sh tests/*.sh\n'
    hintmode="$(git -C "$ROOT" config core.fileMode 2>/dev/null || echo unset)"
    printf 'hint core.fileMode is %s here, so chmod on disk does nothing\n' "$hintmode"
    failures=$((failures + 1))
  else
    printf 'ok   all %s scripts are committed as executable\n' "$exec_n"
  fi
fi

exit $(( failures > 0 ? 1 : 0 ))