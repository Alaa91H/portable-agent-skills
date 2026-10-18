#!/usr/bin/env bash
#
# sync-agents.sh - mirror the canonical skills into every agent discovery root.
#
# There is exactly one source of truth: .opencode/skills. Every other agent
# convention is a generated copy of it, because an agent can only discover a
# skill that lives where it looks.
#
#   .opencode/skills   canonical source (OpenCode project convention)
#   skills/            the spec's own layout, and the Claude Code plugin root
#   .claude/skills     Claude Code, project scope
#   .agents/skills     the open spec's convention (VS Code Copilot, Codex, ...)
#   .github/skills     GitHub Copilot
#
# The copies are committed so that a fresh clone works with every agent without
# a build step. `--check` is the CI gate that makes drift impossible.
#
# Usage: scripts/sync-agents.sh [--check]
#   --check   report drift, change nothing (exit 1 if any target is stale)

set -uo pipefail

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SRC=".opencode/skills"
TARGETS="skills .claude/skills .agents/skills .github/skills"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  RED=''; GRN=''; DIM=''; BLD=''; RST=''
fi

if [ ! -d "$SRC" ]; then
  printf 'error: canonical source %s not found\n' "$SRC" >&2
  exit 2
fi

printf '%ssyncing agent discovery roots%s\n' "$BLD" "$RST"

copied=0
removed=0
drift=0

shopt -s nullglob

for target in $TARGETS; do
  # Drop any skill directory that no longer exists upstream.
  for d in "$target"/*/; do
    d="${d%/}"
    name="${d##*/}"
    if [ ! -d "$SRC/$name" ]; then
      if [ "$CHECK" -eq 1 ]; then
        printf '  %sstale%s   %-44s no longer in %s\n' "$RED" "$RST" "$target/$name" "$SRC"
        drift=$((drift + 1))
      else
        rm -rf "$d"
        printf '  %sremoved%s %s\n' "$DIM" "$RST" "$target/$name"
        removed=$((removed + 1))
      fi
    fi
  done

  for s in "$SRC"/*/; do
    s="${s%/}"
    name="${s##*/}"
    dest="$target/$name"

    # Compare every file before deciding, so a single mismatch is reported
    # once rather than once per copy.
    needs=0
    for f in "$s"/*; do
      [ -f "$f" ] || continue
      rel="${f#$s/}"
      if [ ! -f "$dest/$rel" ] || ! cmp -s "$f" "$dest/$rel"; then
        needs=1
        break
      fi
    done
    # Files present upstream but missing downstream, and extra files downstream.
    if [ "$needs" -eq 0 ]; then
      while IFS= read -r rel; do
        if [ ! -f "$s/$rel" ]; then needs=1; break; fi
      done < <(cd "$dest" 2>/dev/null && find . -type f -printf '%P\n' 2>/dev/null)
    fi

    [ "$needs" -eq 1 ] || continue

    if [ "$CHECK" -eq 1 ]; then
      printf '  %sdrift%s   %s\n' "$RED" "$RST" "$target/$name"
      drift=$((drift + 1))
    else
      rm -rf "$dest"
      mkdir -p "$(dirname "$dest")"
      cp -R "$s" "$dest"
      printf '  %ssynced%s  %s\n' "$GRN" "$RST" "$target/$name"
      copied=$((copied + 1))
    fi
  done
done

printf '\n'
if [ "$CHECK" -eq 1 ]; then
  if [ "$drift" -gt 0 ]; then
    printf '%s%d target(s) out of sync%s - run scripts/sync-agents.sh\n' "$RED" "$drift" "$RST"
    exit 1
  fi
  printf '%sall agent discovery roots are in sync%s\n' "$GRN" "$RST"
  exit 0
fi

printf '%s%d mirrored, %d removed%s\n' "$GRN" "$copied" "$removed" "$RST"
exit 0