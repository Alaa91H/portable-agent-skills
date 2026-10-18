#!/usr/bin/env bash
#
# install.sh - install these skills into any supported agent, globally or locally.
#
# Every agent that follows the open Agent Skills specification discovers skills
# from a directory of <skill-id>/SKILL.md. This script copies the collection into
# whichever of those directories your agent reads.
#
# Usage:
#   ./install.sh                        # list agents and their status
#   ./install.sh opencode --global      # all skills into the user's OpenCode
#   ./install.sh claude --only sql-query-performance
#   ./install.sh --list                 # show skill ids
#
# Options:
#   --global        install into the user-level directory (all projects)
#   --local         install into the current project (default)
#   --only <ids>    comma-separated subset
#   --dest <path>   explicit destination, overriding any target table
#   --uninstall     remove a previously installed copy
#   --list          print every available skill id and exit
#   -h, --help      this message

set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.opencode/skills"

AGENT=""
SCOPE="local"
ONLY=""
DEST=""
UNINSTALL=0
LIST=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,22p' "$0" | sed 's/^#\{1,\} \{0,\\}//'; exit 0 ;;
    --list) LIST=1; shift ;;
    --global) SCOPE="global"; shift ;;
    --local) SCOPE="local"; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    --dest) DEST="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    -*) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) AGENT="$1"; shift ;;
  esac
done

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; DIM=''; BLD=''; RST=''
fi

die() { printf '%serror:%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }

# name | human label | local path | global path
#
# Local paths come from each agent's documented project convention. Where several
# agents share one convention the path appears once, because installing once
# serves all of them.
AGENTS_TABLE="
opencode|OpenCode|.opencode/skills|\$HOME/.config/opencode/skills
agents|Spec clients: Codex, Cline, Kilo, Amp, Zed, Goose, Gemini CLI, Augment, Roo, Cursor, Copilot, Junie, Devin|.agents/skills|\$HOME/.agents/skills
claude|Claude Code|.claude/skills|\$HOME/.claude/skills
github|GitHub Copilot|.github/skills|\$HOME/.github/skills
cursor|Cursor|.cursor/skills|\$HOME/.cursor/skills
devin|Windsurf / Devin Desktop|.devin/skills|\$HOME/.codeium/windsurf/skills
cline|Cline|.cline/skills|\$HOME/.cline/skills
roo|Roo Code|.roo/skills|\$HOME/.roo/skills
junie|JetBrains Junie|.junie/skills|\$HOME/.junie/skills
kilo|Kilo Code|.kilo/skills|\$HOME/.kilo/skills
trae|Trae|.trae/skills|\$HOME/.trae/skills
augment|Augment|.augment/skills|\$HOME/.augment/skills
gemini|Gemini CLI|.gemini/skills|\$HOME/.gemini/skills
codex|OpenAI Codex CLI|.codex/skills|\$HOME/.codex/skills
"

resolve_path() {
  # Expand $HOME and relative prefixes into a real absolute path.
  local p="$1"
  case "$p" in
    '$HOME'/*) p="$HOME/${p#\$HOME/}" ;;
    ./*|./*) p="$(pwd)/${p#./}" ;;
  esac
  printf '%s' "$p"
}

if [ "$LIST" -eq 1 ]; then
  [ -d "$SRC" ] || die "canonical skills not found at $SRC"
  for d in "$SRC"/*/; do printf '%s\n' "${d%/}" | sed 's|.*/||'; done
  exit 0
fi

if [ -z "$AGENT" ] && [ -z "$DEST" ]; then
  [ -d "$SRC" ] || die "canonical skills not found at $SRC"
  printf '%sAgent Skills collection%s - %s skills\n\n' "$BLD" "$RST" "$(find "$SRC" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  printf 'Usage: ./install.sh <agent> [--global] [--only <ids>]\n\n'
  printf '%-12s %-56s %s\n' "AGENT" "LOCAL" "STATUS"
  printf '%-12s %-56s %s\n' "-----" "-----" "------"
  while IFS='|' read -r name label localp globalp; do
    [ -n "$name" ] || continue
    l="$(resolve_path "$localp")"
    g="$(resolve_path "$globalp")"
    if   [ -d "$l" ]; then st="${GRN}local${RST}"
    elif [ -d "$g" ]; then st="${YEL}global${RST}"
    else                   st="not installed"
    fi
    printf '%-12s %-56s %b\n' "$name" "$l" "$st"
  done <<EOF
$AGENTS_TABLE
EOF
  printf '\nGlobal targets:\n'
  while IFS='|' read -r name label localp globalp; do
    [ -n "$name" ] || continue
    printf '  %-12s %s\n' "$name" "$(resolve_path "$globalp")"
  done <<EOF
$AGENTS_TABLE
EOF
  printf '\nRun ./install.sh <agent> --global to install for the current user.\n'
  exit 0
fi

if [ -n "$DEST" ]; then
  target="$(resolve_path "$DEST")"
else
  line="$(printf '%s\n' "$AGENTS_TABLE" | grep "^${AGENT}|" || true)"
  [ -n "$line" ] || die "unknown agent '$AGENT'. Run ./install.sh to see supported agents."
  localp="$(printf '%s' "$line" | cut -d'|' -f3)"
  globalp="$(printf '%s' "$line" | cut -d'|' -f4)"
  if [ "$SCOPE" = "global" ]; then
    target="$(resolve_path "$globalp")"
  else
    target="$(resolve_path "$localp")"
  fi
fi

[ -d "$SRC" ] || die "canonical skills not found at $SRC"

# Build the list of skills to act on.
skills=()
for d in "$SRC"/*/; do skills+=("${d%/}"); done
[ "${#skills[@]}" -gt 0 ] || die "no skills found in $SRC"

if [ -n "$ONLY" ]; then
  IFS=',' read -r -a wanted <<EOF
$ONLY
EOF
  selected=()
  for w in "${wanted[@]}"; do
    w="$(printf '%s' "$w" | tr -d '[:space:]')"
    [ -n "$w" ] || continue
    match=""
    for s in "${skills[@]}"; do
      [ "${s##*/}" = "$w" ] && match="$s"
    done
    [ -n "$match" ] || die "no such skill: '$w'. Run ./install.sh --list."
    selected+=("$match")
  done
  skills=("${selected[@]}")
fi

mkdir -p "$target" || die "cannot create $target"

count=0
for s in "${skills[@]}"; do
  name="${s##*/}"
  dest="$target/$name"
  if [ "$UNINSTALL" -eq 1 ]; then
    if [ -d "$dest" ]; then
      rm -rf "$dest"
      printf '  %sremoved%s  %s\n' "$DIM" "$RST" "$name"
      count=$((count + 1))
    fi
  else
    rm -rf "$dest"
    cp -R "$s" "$dest"
    count=$((count + 1))
  fi
done

if [ "$UNINSTALL" -eq 1 ]; then
  printf '\n%sremoved %d skill(s) from %s%s\n' "$YEL" "$count" "$target" "$RST"
else
  printf '\n%sinstalled %d skill(s) to %s%s\n' "$GRN" "$count" "$target" "$RST"
  printf 'Restart your agent to pick them up.\n'
fi
exit 0