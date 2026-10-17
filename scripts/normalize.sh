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
is_text() {
  local raw clean
  raw="$(head -c 8192 "$1" | wc -c)"
  clean="$(head -c 8192 "$1" | LC_ALL=C tr -d '\000' | wc -c)"
  [ "$raw" -eq "$clean" ]
}

has_bom() {
  [ "$(head -c 3 "$1" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ]
}

has_cr() {
  LC_ALL=C grep -q $'\r' "$1" 2>/dev/null
}

changed=0
issues=0

printf '%snormalizing%s\n' "$BLD" "$RST"

while IFS= read -r -d '' f; do
  case "$f" in
    ./.git/*|./node_modules/*|./dist/*) continue ;;
  esac
  [ -f "$f" ] || continue
  is_text "$f" || continue

  problems=""
  has_bom "$f" && problems+="bom "
  has_cr "$f" && problems+="crlf "
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
done < <(find . -type f -print0)

printf '\n'
if [ "$CHECK" -eq 1 ]; then
  if [ "$issues" -gt 0 ]; then
    printf '%s%d file(s) need normalizing%s - run scripts/normalize.sh\n' "$RED" "$issues" "$RST"
    exit 1
  fi
  printf '%severything is already normalized%s\n' "$GRN" "$RST"
  exit 0
fi

printf '%snormalized %d file(s)%s\n' "$GRN" "$changed" "$RST"
exit 0