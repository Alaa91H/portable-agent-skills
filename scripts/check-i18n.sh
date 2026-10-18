#!/usr/bin/env bash
#
# check-i18n.sh - verify the translation index and every translated document.
#
# A translation is the one artefact in this repository that nothing generates and
# nothing compares. That combination is how the marketplace manifest sat two
# releases out of date and the six index mirrors went missing entirely, both
# times unnoticed. Translations get worse, not better, if left to discipline.
#
# Each translated document carries machine-readable markers:
#
#   <!-- i18n: lang=es clusters=18 skills=83 -->
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
# The markers are necessary and not sufficient. When the collection grew from 79
# to 83 skills, every marker was updated and eighteen counts in the prose of all
# eight documents were not, and the gate passed. A marker is a declaration about
# a document, not a summary of it, so the numbers written in the prose are
# checked against the repository directly.
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
want_titles="$(grep '^      "title":' skills.sh.json | sed 's/.*: "//; s/",\?//')"

# The agent count comes from the installer's own table. agents.json is not the
# source: it holds five protocol entries, and grepping it for "id" returned
# eleven, which reads like an answer and is not one. AGENTS_TABLE is the only
# place the fourteen supported targets are actually declared.
want_agents="$(awk '/^AGENTS_TABLE="/,/^"$/' install.sh | grep -c '^[a-z0-9-]*|')"

# Arabic-Indic digits, so the Arabic document's numbers are scanned like the rest.
#
# The spaces are load-bearing. Written as "for d in ٠١٢٣٤٥٦٧٨٩" the list does
# not word-split under Git Bash, the whole run of ten digits arrives as a single
# word, and the result is one useless substitution, s/٠١٢٣٤٥٦٧٨٩/0/g, that
# normalises nothing. It still looks correct in the source and silently checks
# nothing. Separating with spaces makes the list ten words on every platform.
digits_sed=""
i=0
for d in ٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩; do
  digits_sed="${digits_sed}s/$d/$i/g;"
  i=$((i + 1))
done

langs="$(sed -n 's/.*<!-- lang: \([a-zA-Z-]*\) -->.*/\1/p' "$INDEX")"
[ -n "$langs" ] || { printf '  %sFAIL%s  no languages declared in %s\n' "$RED" "$RST" "$INDEX"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

lang_n=0
# A pipeline would run the loop in a subshell and lose the error count, so the
# list is redirected into a file rather than piped.
printf '%s\n' "$langs" > "$tmp/langs"

while read -r lang; do
  [ -n "$lang" ] || continue
  lang_n=$((lang_n + 1))
  f="$I18N_DIR/$lang.md"
  bad=""

  if [ ! -f "$f" ]; then
    fail "$lang: $f is declared but missing"
    continue
  fi

  marker="$(grep -o '<!-- i18n:[^>]*-->' "$f" | head -n 1)"

  # The marker is piped rather than passed as an argument. As an argument it
  # would be read as a filename, and grep would report the whole marker as a
  # missing file rather than as what it actually is, which is text in hand.
  case "$marker" in
    *"lang=$lang"*) : ;;
    *) fail "$lang: marker does not declare lang=$lang"; continue ;;
  esac

  got_clusters="$(printf '%s' "$marker" | grep -o 'clusters=[0-9]*' | head -n 1 | cut -d= -f2)"
  got_skills="$(printf '%s' "$marker" | grep -o 'skills=[0-9]*' | head -n 1 | cut -d= -f2)"

  if [ "$got_clusters" != "$want_clusters" ]; then
    fail "$lang: marker claims $got_clusters clusters, repository has $want_clusters"
    continue
  fi
  if [ "$got_skills" != "$want_skills" ]; then
    fail "$lang: marker claims $got_skills skills, repository has $want_skills"
    continue
  fi

  # Cluster titles must match skills.sh.json exactly, in the same order.
  got_titles="$(sed -n 's/.*<!-- cluster: \(.*\) -->.*/\1/p' "$f")"
  if [ "$want_titles" != "$got_titles" ]; then
    fail "$lang: cluster list does not match skills.sh.json"
    printf '%s\n' "$want_titles" > "$tmp/want"
    printf '%s\n' "$got_titles"  > "$tmp/got"
    diff "$tmp/want" "$tmp/got" | head -n 8 | sed 's/^/          /'
    continue
  fi

  # Every two-digit number in the prose must be a count the repository actually
  # has. Ordered-list markers and the HTML markers are removed first, since the
  # markers are checked above and the list markers are structure, not claims.
  # Single digits are left alone: Japanese prose writes "these 2 fields" and
  # treating that as drift would train everyone to ignore this check.
  sed "$digits_sed" "$f" \
    | sed -e 's/^[ \t]*[0-9][0-9]*\.[ \t]*/ /' -e 's/<!--[^>]*-->/ /g' \
    | grep -oE '(^|[^A-Za-z0-9_.])[0-9]{2,}([^A-Za-z0-9_.]|$)' \
    | grep -oE '[0-9]{2,}' | sort -u > "$tmp/nums"

  while read -r n; do
    [ -n "$n" ] || continue
    case " $want_skills $want_clusters $want_agents " in
      *" $n "*) : ;;
      *) bad="$bad $n" ;;
    esac
  done < "$tmp/nums"

  if [ -n "$bad" ]; then
    fail "$lang: prose states a count the repository does not have:$bad"
    fail "  (skills=$want_skills clusters=$want_clusters agents=$want_agents)"
    continue
  fi

  pass "$lang: $want_clusters clusters, $want_skills skills, counts consistent"
done < "$tmp/langs"

# An undeclared language is drift in the other direction: a translation nobody
# can find. Exclusions are explicit, never silent.
for g in "$I18N_DIR"/*.md; do
  gbase="${g##*/}"; gbase="${gbase%.md}"
  [ "$gbase" = "README" ] && continue
  grep -qx "$gbase" "$tmp/langs" || fail "$gbase.md exists but is not declared in $INDEX"
done

printf '\n'
if [ "$ERRORS" -gt 0 ]; then
  printf '%s%d translation problem(s) across %d language(s)%s\n' "$RED" "$ERRORS" "$lang_n" "$RST"
  exit 1
fi
printf '%s%d language(s) present and consistent with skills.sh.json%s\n' "$GRN" "$lang_n" "$RST"
exit 0