#!/usr/bin/env bash
#
# sync-rules.sh - generate flat instruction files for agents that cannot read SKILL.md.
#
# Not every agent implements the Agent Skills spec. Several read a flat rules
# directory instead, with agent-specific frontmatter and no progressive
# disclosure. Those agents cannot mount the collection directly, so this script
# derives what they can consume from the canonical source:
#
#   on-demand mirrors   the full body, with frontmatter the agent uses to decide
#                       relevance, which reproduces progressive disclosure
#   index mirrors       a single pointer file, for agents that always load every
#                       rule and would overflow context with 23 full bodies
#
# Edit .opencode/skills only. CI runs this with --check, so drift is impossible.
#
# Usage: scripts/sync-rules.sh [--check]

set -uo pipefail

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SRC=".opencode/skills"

# Agents that load a rule on demand when its description matches.
# Windsurf is now Devin Desktop; .devin is the current root and .windsurf the
# legacy fallback, so both are generated.
ON_DEMAND=".cursor/rules:mdc .roo/rules:md .windsurf/rules:md .devin/rules:md .cline/rules:md .trae/rules:md"

# Agents that always load every rule. These get a single pointer file.
# Space separated, not colon separated. The loop splits on whitespace only, so a
# colon-joined list arrives as ONE word: the six index mirrors were never written
# by this loop at all, and the check was comparing a single path that does not
# exist. On Windows the redirection to that nonexistent path failed quietly and
# the gate passed; on Linux it reported the failure. Six files that agents read
# on every session were effectively unguarded.
INDEX_FILES=".clinerules/agent-skills.md .continue/rules/agent-skills.md .goose/agent-skills.md .rules/agent-skills.md .amazonq/rules/agent-skills.md .augment/rules/agent-skills.md"

# Root-level files some agents read without a directory.
ROOT_INDEX_FILES=".cursorrules AGENTS.md GEMINI.md CONVENTIONS.md CLAUDE.md AmazonQ.md TABNINE.md"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; DIM=''; BLD=''; RST=''
fi

[ -d "$SRC" ] || { printf 'error: %s not found\n' "$SRC" >&2; exit 2; }

# yaml_quote <string> -> a double-quoted YAML scalar, safe for any content
yaml_quote() {
  printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

# body_after_frontmatter <file> -> everything after the closing ---
# Two delimiters must be seen: the opening and the closing. Printing after the
# first one would re-emit the frontmatter as body. The counter must not be named
# "close", which is an awk builtin and silently yields an empty result as a
# variable.
body_after_frontmatter() {
  awk '
    { sub(/\r$/, "") }
    NR == 1 { sub(/^\xef\xbb\xbf/, "") }
    /^---[[:space:]]*$/ { n++; next }
    n >= 2 { print }
  ' "$1"
}

fm_get() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v ~ /^[|>][-+]?$/) { inblock = 1; blk = ""; next }
      if (substr(v, 1, 1) == "\"") v = substr(v, 2)
      if (length(v) && substr(v, length(v), 1) == "\"") v = substr(v, 1, length(v) - 1)
      print v; exit
    }
    inblock {
      if ($0 ~ /^[ \t]/ || $0 == "") { t = $0; sub(/^[ \t]+/, "", t); blk = blk (blk == "" ? "" : " ") t; next }
      print blk; exit
    }
  ' "$1"
}

printf '%sgenerating flat rule mirrors%s\n' "$BLD" "$RST"

written=0
drift=0

# Every temporary file this script creates is removed on the way out, whatever
# happens. A run interrupted between creating a temporary file and renaming it
# leaves the temporary file in the tree, and the next `git add -A` commits it.
# The name carries the process id, so the file that gets committed is a
# different one on every run, which is why it is not noticed by anything that
# compares content.
#
# The list is emptied as each file is renamed or removed, so the trap does not
# delete a file that has already become the real output.
TMP_FILES=""

cleanup_tmp() {
  local f
  for f in $TMP_FILES; do
    [ -n "$f" ] && rm -f "$f"
  done
}
# TERM and INT are trapped explicitly because a signal that is not trapped
# terminates the shell without running the EXIT trap. SIGKILL cannot be trapped
# by anything, so scripts/check-repo-state.sh also fails the build when a
# temporary file is found in the tree: the gate is the protection, the trap is
# only tidiness.
trap cleanup_tmp EXIT
trap cleanup_tmp TERM
trap cleanup_tmp INT

emit() {
  # emit <path> <content-producer...> ; compares before writing when checking
  local path="$1"
  shift
  local tmp="$path.tmp.$$"
  TMP_FILES="$TMP_FILES $tmp"

  # A write that fails must stop the run. Without this, a redirect to a path
  # whose directory does not exist fails, the status is discarded, and the
  # script continues as if the file had been written. On Windows that failure
  # was invisible; on Linux it surfaced as a gate failure. Either way the six
  # index mirrors this function is responsible for were never created, while the
  # documentation claimed support for five agents that read them.
  if ! "$@" > "$tmp"; then
    printf '  %serror%s   could not write %s (is its directory present?)\n' "$RED" "$RST" "$tmp" >&2
    rm -f "$tmp"
    return 2
  fi

  if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
    rm -f "$tmp"
    TMP_FILES="${TMP_FILES% $tmp}"
    return 0
  fi

  if [ "$CHECK" -eq 1 ]; then
    printf '  %sdrift%s   %s\n' "$RED" "$RST" "$path"
    rm -f "$tmp"
    TMP_FILES="${TMP_FILES% $tmp}"
    drift=$((drift + 1))
    return 1
  fi

  mkdir -p "$(dirname "$path")"
  mv "$tmp" "$path"
  TMP_FILES="${TMP_FILES% $tmp}"
  printf '  %swrote%s   %s\n' "$GRN" "$RST" "$path"
  written=$((written + 1))
  return 0
}

# ------------------------------------------------------- on-demand mirrors
# Each agent has its own frontmatter keys, so the block is built per target
# rather than shared. Omitting `globs` keeps the file agentic rather than
# always-applied, which is what preserves progressive disclosure for that agent.
for entry in $ON_DEMAND; do
  dir="${entry%:*}"
  ext="${entry##*:}"

  case "$dir" in
    .windsurf/rules) lead="trigger: model_decision" ;;
    *)               lead="" ;;
  esac

  for d in "$SRC"/*/; do
    d="${d%/}"
    id="${d##*/}"
    f="$d/SKILL.md"
    [ -f "$f" ] || continue

    desc="$(fm_get "$f" description)"
    body="$(body_after_frontmatter "$f")"

    {
      printf -- '---\n'
      [ -n "$lead" ] && printf '%s\n' "$lead"
      printf 'description: %s\n' "$(yaml_quote "$desc")"
      [ "$dir" = ".cursor/rules" ] && printf 'alwaysApply: false\n'
      printf -- '---\n\n'
      printf '%s\n' "$body"
    } > "$dir/$id.$ext.$$"

    emit "$dir/$id.$ext" cat "$dir/$id.$ext.$$"
    rm -f "$dir/$id.$ext.$$"
  done
done

# ------------------------------------------------------------ index mirrors
build_index() {
  cat <<'EOF'
# Agent Skills

This repository provides a collection of validated Agent Skills. They are
SKILL.md files under `.opencode/skills/`, which several agents load directly.
If your agent reads flat rule files instead, the same guidance is available as
one rule per skill.

## When to load a skill

Only the name and description of each skill are listed here. Load a skill's full
instructions when its description matches the task in front of you. Do not
attempt to follow a skill from its description alone; the description states when
to use it, not what to do.

## The collection

EOF

  for d in "$SRC"/*/; do
    d="${d%/}"
    id="${d##*/}"
    f="$d/SKILL.md"
    [ -f "$f" ] || continue
    desc="$(fm_get "$f" description)"
    printf -- '- **%s** — %s\n' "$id" "$desc"
  done

  cat <<'EOF'

## Using them

If your agent supports the Agent Skills specification, the skills are already
available and you will see them offered by name. Otherwise, read the relevant
file directly:

- OpenCode, Claude Code, Copilot, and other spec clients: `.opencode/skills/<id>/SKILL.md`
- This rule set: one Markdown file per skill, in the rules directory beside this file

## Rules

- Load a skill before starting work that matches it, not after.
- Do not load several skills that overlap; pick the closest match.
- If a skill contradicts the immediate instructions you were given, follow the
  immediate instructions and say so.
EOF
}

for entry in $INDEX_FILES; do
  emit "$entry" build_index || exit $?
done

# Root-level files that agents read without a rules directory.
# These point at the collection and stay short, since they are always loaded.
build_root_pointer() {
  # The count is derived, never written by hand: a stale number in an index
  # that agents read on every session is worse than no number.
  total=0
  for d in "$SRC"/*/; do [ -f "$d/SKILL.md" ] && total=$((total + 1)); done

  printf '# Agent Skills\n\n'
  printf 'This repository contains %d validated Agent Skills.\n\n' "$total"
  cat <<'EOF'
If your agent supports the Agent Skills specification (`SKILL.md`), they are
already discoverable: they live under `.opencode/skills/` and are mirrored into
this repository's `skills/`, `.claude/skills/`, `.agents/skills/`, and
`.github/skills/` directories. Nothing further is needed.

If instead you are reading this as a flat instruction file, here is the index:

EOF
  for d in "$SRC"/*/; do
    d="${d%/}"
    id="${d##*/}"
    f="$d/SKILL.md"
    [ -f "$f" ] || continue
    desc="$(fm_get "$f" description)"
    printf -- '- **%s** — %s\n' "$id" "$desc"
  done
  cat <<'EOF'

Full instructions: `.opencode/skills/<id>/SKILL.md`.

Load a skill when its description matches the task. The description says when to
use it; the file says what to do. Do not work from the description alone.
EOF
}

for f in $ROOT_INDEX_FILES; do
  emit "$f" build_root_pointer
done

printf '\n'
if [ "$CHECK" -eq 1 ]; then
  if [ "$drift" -gt 0 ]; then
    printf '%s%d generated file(s) out of date%s - run scripts/sync-rules.sh\n' "$RED" "$drift" "$RST"
    exit 1
  fi
  printf '%sall generated rule files are in sync%s\n' "$GRN" "$RST"
  exit 0
fi

printf '%s%d file(s) written%s\n' "$GRN" "$written" "$RST"
exit 0