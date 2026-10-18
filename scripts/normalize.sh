#!/usr/bin/env bash
#
# normalize.sh - strip UTF-8 BOMs and force LF line endings across the repo.
#
# A UTF-8 BOM shifts the opening '---' of SKILL.md frontmatter, which breaks
# naive YAML parsers and corrupts the HTTP catalog round-trip. PowerShell's
# default -Encoding utf8 emits one, so this is easy to introduce by accident on
# Windows. CRLF breaks the shell commands embedded in skill bodies when they
# are copied to a POSIX host, because the trailing CR survives into the command.
#
# Run this before committing, then run scripts/validate-skills.sh.
#
# Usage: scripts/normalize.sh [--check]
#   --check   report problems, change nothing (exit 1 if any are found)

set -uo pipefail

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; BLD=''; RST=''
fi

# A file is text when the first 8 KiB contain no NUL byte. Bash cannot hold a
# NUL inside a string, so this compares byte counts rather than grepping for \0.
#
# Only ever called on candidates, never on every file in the tree. That
# distinction is the whole performance story: this costs five processes per
# call, so applying it to the full tree costs thousands. The scan below finds
# candidates in two batched greps instead, which is O(1) processes.
is_text() {
  local raw clean
  raw="$(head -c 8192 "$1" | wc -c)"
  clean="$(head -c 8192 "$1" | LC_ALL=C tr -d '\000' | wc -c)"
  [ "$raw" -eq "$clean" ]
}

# ---------------------------------------------------------------------------
# Detecting a carriage return with grep is less obvious than it should be, and
# every wrong answer here fails in the same direction: it reports "clean".
#
# Measured on GNU grep, against a file known to contain CRLF:
#
#   grep -q $'\r'          never matches. The trailing CR is consumed as part of
#                           the pattern's own line terminator, leaving an empty
#                           pattern that matches nothing. -P does not help.
#   grep -q $'\r\n'        matches EVERYTHING. A newline inside a pattern splits
#                           it into two patterns, and the resulting empty pattern
#                           matches every file, so an LF-only tree looks like
#                           CRLF. This is the dangerous one: it fails loudly, and
#                           the obvious "fix" is to make the tree match.
#   grep -q '[[:cntrl:]]'  no match; CR is not a control-class member.
#   grep -qU $'\r'         correct. -U drops newline sensitivity, so the CR is an
#                           ordinary byte in the middle of a line.
#
# The asymmetry is the trap. A detector that silently never matches looks
# exactly like a clean repository, so it is trusted until somebody plants a
# defective file to test it. This one reported "already normalized" for the
# entire life of the project while being unable to detect anything.
#
# The size-comparison form is the portable alternative, at two processes per
# file rather than one:  [ "$(tr -d '\r' < f | wc -c)" -eq "$(wc -c < f)" ]
# ---------------------------------------------------------------------------
has_cr() {
  LC_ALL=C grep -qU $'\r' "$1" 2>/dev/null
}

has_bom() {
  [ "$(head -c 3 "$1" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ]
}

ALL="$(mktemp)"; CRS="$(mktemp)"; BOMS="$(mktemp)"; CANDS="$(mktemp)"
trap 'rm -f "$ALL" "$CRS" "$BOMS" "$CANDS"' EXIT

printf '%snormalizing%s\n' "$BLD" "$RST"

find . -type f \
  -not -path './.git/*' \
  -not -path './node_modules/*' \
  -not -path './dist/*' \
  -print0 > "$ALL"

file_count="$(tr '\0' '\n' < "$ALL" | grep -c '' || true)"
[ -n "$file_count" ] || file_count=0

changed=0
issues=0

if [ "$file_count" -gt 0 ]; then
  # Two batched grep passes over the whole tree. Note that -z is deliberately
  # absent: combined with -U it makes grep list nothing at all. -l output is
  # newline-separated, which is safe here because a newline inside a filename
  # would break this scan; that is a documented limitation, not an oversight.
  xargs -0 grep -lU $'\r'         < "$ALL" > "$CRS"  2>/dev/null || true
  xargs -0 grep -l  $'^\xef\xbb\xbf' < "$ALL" > "$BOMS" 2>/dev/null || true

  LC_ALL=C sort -u "$CRS" "$BOMS" > "$CANDS"

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    is_text "$f" || continue

    problems=""
    has_bom "$f" && problems+="bom "
    has_cr  "$f" && problems+="crlf "
    [ -n "$problems" ] || continue

    if [ "$CHECK" -eq 1 ]; then
      printf '  %sneeds normalizing%s  %-58s (%s)\n' "$RED" "$RST" "$f" "$problems"
      issues=$((issues + 1))
      continue
    fi

    tmp="$f.norm.$$"

    if has_bom "$f"; then
      tail -c +4 "$f" > "$tmp" || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
    else
      cat "$f" > "$tmp" || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
    fi

    tr -d '\r' < "$tmp" > "$tmp.2" && mv "$tmp.2" "$f"
    rm -f "$tmp"

    # Guarantee exactly one trailing newline.
    if [ -s "$f" ] && [ "$(tail -c 1 "$f" | od -An -tx1 | tr -d ' \n')" != "0a" ]; then
      printf '\n' >> "$f"
    fi

    printf '  %sfixed%s  %-58s (%s)\n' "$GRN" "$RST" "$f" "$problems"
    changed=$((changed + 1))
  done < "$CANDS"
fi

printf '\n'
if [ "$CHECK" -eq 1 ]; then
  if [ "$issues" -gt 0 ]; then
    printf '%s%d file(s) need normalizing%s - run scripts/normalize.sh\n' "$RED" "$issues" "$RST"
    exit 1
  fi
  printf '%severything is already normalized%s (%d file(s) scanned)\n' "$GRN" "$RST" "$file_count"
  exit 0
fi

printf '%snormalized %d file(s)%s (%d scanned)\n' "$GRN" "$changed" "$RST" "$file_count"
exit 0