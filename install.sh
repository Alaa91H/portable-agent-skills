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
#   ./install.sh --update               # pull the newest source and refresh mirrors
#
# Options:
#   --global        install into the user-level directory (all projects)
#   --local         install into the current project (default)
#   --only <ids>    comma-separated subset
#   --dest <path>   explicit destination, overriding any target table
#   --uninstall     remove a previously installed copy
#   --list          print every available skill id and exit
#   --update        update the source from origin, then continue with the rest
#   --version       print the collection version and exit
#   -h, --help      this message

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/.opencode/skills"

AGENT=""
SCOPE="local"
ONLY=""
DEST=""
UNINSTALL=0
LIST=0
UPDATE=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,25p' "$0" | sed 's/^#*  *//'; exit 0 ;;
    --list) LIST=1; shift ;;
    --global) SCOPE="global"; shift ;;
    --local) SCOPE="local"; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    --dest) DEST="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    --update) UPDATE=1; shift ;;
    --version) if [ -f "$ROOT/VERSION" ]; then tr -d '[:space:]' < "$ROOT/VERSION"; else echo unknown; fi; echo; exit 0 ;;
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

# ------------------------------------------------------------------ update
#
# Refresh the source in place. Nothing is regenerated here, and that is a
# deliberate architectural choice rather than an omission: every mirror in this
# repository is a committed artifact produced by CI and gated by a --check test.
# A pull therefore brings the regenerated mirrors with it, and regenerating
# again locally would duplicate work the project's contract already assigns to
# CI while risking a half-refreshed tree that no longer matches the commit.
#
# What this does instead of regenerating: pull, then report exactly what
# changed, because "updated" is not useful to a caller that has to restart an
# agent anyway.
if [ "$UPDATE" -eq 1 ]; then
  was="$( [ -f "$ROOT/VERSION" ] && tr -d '[:space:]' < "$ROOT/VERSION" || echo none )"
  had_count="$(find "$SRC" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  before="$( [ -f "$ROOT/VERSION" ] && cat "$ROOT/VERSION" || echo none )"

  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    if git -C "$ROOT" pull --ff-only --quiet 2>/dev/null; then
      printf 'source updated to %s\n' "$(git -C "$ROOT" rev-parse --short HEAD)"
    elif git -C "$ROOT" remote get-url origin >/dev/null 2>&1; then
      printf '%ssource not updated: the checkout has local commits, or origin is unreachable%s\n' "$YEL" "$RST"
      printf 'continuing with the version already present\n'
    else
      printf '%sthis checkout has no origin configured%s\n' "$YEL" "$RST"
      printf 'add one with: git remote add origin <url>\n'
    fi
  else
    printf '%sthis copy is not a git checkout; install from a release archive to update%s\n' "$YEL" "$RST"
  fi

  now="$( [ -f "$ROOT/VERSION" ] && tr -d '[:space:]' < "$ROOT/VERSION" || echo none )"
  has_count="$(find "$SRC" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

  if [ "$before" = "$now" ] && [ "$had_count" = "$has_count" ]; then
    printf 'already current: version %s, %s skill(s)\n' "$now" "$has_count"
  else
    [ "$before" = "$now" ] || printf 'version %s -> %s\n' "$before" "$now"
    [ "$had_count" = "$has_count" ] || printf 'skill count %s -> %s\n' "$had_count" "$has_count"
    if [ -f "$ROOT/CHANGELOG.md" ]; then
      printf 'what changed in %s:\n' "$now"
      sed -n "/^## \[$now\]/,/^## \[/{/^## \[$now\]/d; /^## \[/d; p;}" "$ROOT/CHANGELOG.md" \
        | grep -E '^### |^- \*\*' | head -n 24 | sed 's/^/  /'
    fi
  fi

  [ -n "$AGENT" ] || [ -n "$DEST" ] || exit 0
fi

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
  [ -f "$ROOT/VERSION" ] && printf 'collection version %s\n' "$(tr -d '[:space:]' < "$ROOT/VERSION")"
  printf 'Restart your agent to pick them up.\n'
  printf 'Later: %s./install.sh --update %s%s --global   to refresh and reinstall\n' "$DIM" "$AGENT" "$RST"
fi
exit 0