#!/usr/bin/env bash
#
# build-catalog.sh - build the publishable HTTP skill catalog in ./dist.
#
# OpenCode loads an HTTP catalog from a base URL that contains index.json, and
# fetches each listed file from <base-url>/<skill-name>/<file>. This script
# produces exactly that layout from the canonical ./.opencode/skills tree, so
# the repository can be served as-is by any static host.
#
#   https://opencode.ai/v2/docs/skills  (catalogs)
#
# Usage: scripts/build-catalog.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC=".opencode/skills"
OUT="dist"

if [ ! -d "$SRC" ]; then
  printf 'error: %s not found\n' "$SRC" >&2
  exit 2
fi

# The catalog cache is keyed on `version`, so it must change whenever any file
# changes. The commit count is a cheap, monotonic proxy that needs no tagging.
VERSION="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
[ "$VERSION" -ge 1 ] 2>/dev/null || VERSION=1

rm -rf "$OUT"
mkdir -p "$OUT"

count=0
entries=""

for d in "$SRC"/*/; do
  d="${d%/}"
  name="${d##*/}"

  if [ -f "$d/SKILL.md" ]; then
    entry_file="SKILL.md"
  elif [ -f "$d/$name.md" ]; then
    entry_file="$name.md"
  else
    printf 'skipping %s (no SKILL.md)\n' "$name" >&2
    continue
  fi

  mkdir -p "$OUT/$name"
  ( cd "$d" && find . -type f -not -path '*/.git/*' -print0 ) \
    | while IFS= read -r -d '' rel; do
        rel="${rel#./}"
        mkdir -p "$OUT/$name/$(dirname "$rel")"
        cp "$d/$rel" "$OUT/$name/$rel"
      done

  files="$(cd "$d" && find . -type f -not -path '*/.git/*' -printf '%P\n' | LC_ALL=C sort)"

  # description is required so a host can do level-1 progressive disclosure from
  # index.json alone, without fetching every SKILL.md. This is what the MCP
  # skills extension expects of skill://index.json.
  desc="$(sed -n 's/^description:[[:space:]]*//p' "$d/$entry_file" | head -n 1)"
  desc="${desc#\"}"; desc="${desc%\"}"
  desc="$(printf '%s' "$desc" | sed 's/\\/\\\\/g; s/"/\\"/g')"

  file_json=""
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -n "$file_json" ] && file_json+=", "
    file_json+="\"$rel\""
  done <<EOF
$files
EOF

  [ -n "$entries" ] && entries+=","
  entries+="
    {
      \"name\": \"$name\",
      \"version\": \"$VERSION\",
      \"description\": \"$desc\",
      \"files\": [$file_json]
    }"

  count=$((count + 1))
  printf '  %-40s %s files\n' "$name" "$(printf '%s\n' "$files" | grep -c '')"
done

{
  printf '{\n'
  printf '  "skills": [%s\n' "$entries"
  printf '  ]\n'
  printf '}\n'
} > "$OUT/index.json"

printf '\nbuilt %d skill(s) into %s (version %s)\n' "$count" "$OUT" "$VERSION"