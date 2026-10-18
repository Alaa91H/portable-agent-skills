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

# Two different numbers, for two different jobs. Conflating them is a real bug
# and it is easy to conflate them, because both are called "version".
#
#   catalog version   a cache key. Hosts key their cache on this, so it must
#                     change whenever ANY file changes. The commit count is a
#                     cheap monotonic proxy that needs no tagging.
#   collection version the product version from ./VERSION, which changes only
#                     when a human decides to cut a release.
#
# Using the semver alone for the cache key would silently serve a stale catalog
# after every skill edit that did not come with a release, which is most of them.
CATALOG_VERSION="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
[ "$CATALOG_VERSION" -ge 1 ] 2>/dev/null || CATALOG_VERSION=1
COLLECTION_VERSION="$(tr -d '[:space:]' < VERSION 2>/dev/null || echo 0.0.0)"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
BUILT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

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
      \"version\": \"$CATALOG_VERSION\",
      \"collectionVersion\": \"$COLLECTION_VERSION\",
      \"description\": \"$desc\",
      \"files\": [$file_json]
    }"

  count=$((count + 1))
  printf '  %-40s %s files\n' "$name" "$(printf '%s\n' "$files" | grep -c '')"
done

# A content digest over every published file, so a client can tell "newer" from
# "different" without downloading the catalog. It is computed over paths and
# contents together, because a renamed file with identical contents is a change
# a consumer must see.
DIGEST="$(find "$SRC" -type f -name '*.md' -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 sha256sum 2>/dev/null \
  | sha256sum 2>/dev/null | cut -c1-16)"
[ -n "$DIGEST" ] || DIGEST="unavailable"

{
  printf '{\n'
  printf '  "collectionVersion": "%s",\n' "$COLLECTION_VERSION"
  printf '  "catalogVersion": %s,\n' "$CATALOG_VERSION"
  printf '  "commit": "%s",\n' "$COMMIT"
  printf '  "builtAt": "%s",\n' "$BUILT_AT"
  printf '  "skillCount": %d,\n' "$count"
  printf '  "digest": "%s",\n' "$DIGEST"
  printf '  "skills": [%s\n' "$entries"
  printf '  ]\n'
  printf '}\n'
} > "$OUT/index.json"

# A standalone manifest for anything that wants to poll for updates without
# parsing the catalog. It stays small and stable, so a poller can cache it
# cheaply and re-fetch only when the digest changes.
{
  printf '{\n'
  printf '  "collectionVersion": "%s",\n' "$COLLECTION_VERSION"
  printf '  "catalogVersion": %s,\n' "$CATALOG_VERSION"
  printf '  "commit": "%s",\n' "$COMMIT"
  printf '  "builtAt": "%s",\n' "$BUILT_AT"
  printf '  "skillCount": %d,\n' "$count"
  printf '  "digest": "%s",\n' "$DIGEST"
  printf '  "index": "index.json"\n'
  printf '}\n'
} > "$OUT/update-manifest.json"

printf '\nbuilt %d skill(s) into %s\n' "$count" "$OUT"
printf '  collection %s, catalog key %s, commit %s\n' "$COLLECTION_VERSION" "$CATALOG_VERSION" "$COMMIT"
printf '  digest %s\n' "$DIGEST"