#!/usr/bin/env bash
#
# check-i18n.sh - verify the translation index and every translated document.
#
# A translation is the one artefact in this repository that nothing generates and
# nothing compares. That combination is how the marketplace manifest sat two
# releases out of date and the six index mirrors went missing entirely, both
# times unnoticed. Translations get worse, not better, if left to discipline.
#
# So every translated document carries two machine-readable markers:
#
#   <!-- i18n: lang=es clusters=18 skills=79 -->
#   <!-- cluster: Craft and process -->
#
# The first declares what the document is and what it must contain. The second
# appears once per cluster, with the cluster title in the canonical English form
# from skills.sh.json, so drift is a string comparison rather than a judgement
# call about whether a translation still looks right.
#
# The cluster titles stay English on purpose. They are identifiers used by
# docs/catalog.md and by the generators, and translating them would create a
# second vocabulary to keep in sync. What is translated is everything a reader
# needs: the framing, the quick start, the install commands, and what each
# domain covers.
#
# Usage: scripts/check-i18n.sh
# Exit:  0 when every language is present and consistent, 1 otherwise.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

I18N_DIR="docs/i18n"
INDEX="$I18N_DIR/README.md"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; BLD=''; RST=''
fi

fail() { printf '  %sFAIL%s  %s\n' "$RED" "$RST" "$*"; ERRORS=$((ERRORS + 1)); }
pass() { printf '  %sok%s    %s\n' "$GRN" "$RST" "$*"; }
ERRORS=0

if [ ! -f "$INDEX" ]; then
  printf '%serror%s  %s is missing\n' "$RED" "$RST" "$INDEX" >&2
  exit 1
fi

printf '%stranslations%s\n' "$BLD" "$RST"

# The canonical facts every translated document must agree with.
want_clusters="$(grep -c '^      "title":' skills.sh.json)"
want_skills="$(find .opencode/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"

# Languages are declared in the index, one per marker, so adding a language is
# a new file plus one line here rather than a code change.
langs="$(sed -n 's/.*<!-- lang: \([a-zA-Z-]*\) -->.*/\1/p' "$INDEX")"
[ -n "$langs" ] || { printf '  %sFAIL%s  no languages declared in %s\n' "$RED" "$RST" "$INDEX"; exit 1; }

lang_n=0
IFS_SAVE="$IFS"
IFS='
'
for lang in $langs; do
  IFS="$IFS_SAVE"
  lang_n=$((lang_n + 1))
  f="$I18N_DIR/$lang.md"

  if [ ! -f "$f" ]; then
    fail "$lang: $f is declared but missing"
    IFS='
'
    continue
  fi

  # Marker must declare the language and the counts.
  marker="$(grep -o '<!-- i18n:[^>]*-->' "$f" | head -n 1)"
  case "$marker" in
    *"lang=$lang"*) : ;;
    *) fail "$lang: marker does not declare lang=$lang"; IFS='
'; continue ;;
  esac

  # The marker is piped rather than passed as an argument. As an argument it
  # would be read as a filename, and grep would report the whole marker as a
  # missing file rather than as what it actually is, which is text in hand.
  got_clusters="$(printf '%s' "$marker" | grep -o 'clusters=[0-9]*' | head -n 1 | cut -d= -f2)"
  got_skills="$(printf '%s' "$marker" | grep -o 'skills=[0-9]*' | head -n 1 | cut -d= -f2)"

  if [ "$got_clusters" != "$want_clusters" ]; then
    fail "$lang: marker claims $got_clusters clusters, repository has $want_clusters"
    IFS='
'; continue
  fi
  if [ "$got_skills" != "$want_skills" ]; then
    fail "$lang: marker claims $got_skills skills, repository has $want_skills"
    IFS='
'; continue
  fi

  # Cluster titles must match skills.sh.json exactly, in the same order.
  want_titles="$(grep '^      "title":' skills.sh.json | sed 's/.*: "//; s/",\?//')"
  got_titles="$(sed -n 's/.*<!-- cluster: \(.*\) -->.*/\1/p' "$f")"

  if [ "$want_titles" != "$got_titles" ]; then
    fail "$lang: cluster list does not match skills.sh.json"
    printf '%s\n' "$got_titles" > "/tmp/i18n-got.$$"
    printf '%s\n' "$want_titles" > "/tmp/i18n-want.$$"
    diff "/tmp/i18n-want.$$" "/tmp/i18n-got.$$" | head -n 8 | sed 's/^/          /'
    rm -f "/tmp/i18n-got.$$" "/tmp/i18n-want.$$"
    IFS='
'; continue
  fi

  # An undeclared language is drift in the other direction: a translation nobody
  # can find. Untranslatable leftovers are excluded explicitly, never silently.
  for g in "$I18N_DIR"/*.md; do
    gbase="${g##*/}"; gbase="${gbase%.md}"
    [ "$gbase" = "README" ] && continue
    case "$langs" in
      *"$gbase"*) : ;;
      *) fail "$gbase.md exists but is not declared in $INDEX"; IFS='
'; break ;;
    esac
  done

  pass "$lang: $want_clusters clusters, $want_skills skills"
  IFS='
'
done
IFS="$IFS_SAVE"

printf '\n'
if [ "$ERRORS" -gt 0 ]; then
  printf '%s%d translation problem(s) across %d language(s)%s\n' "$RED" "$ERRORS" "$lang_n" "$RST"
  exit 1
fi
printf '%s%d language(s) present and consistent with skills.sh.json%s\n' "$GRN" "$lang_n" "$RST"
exit 0