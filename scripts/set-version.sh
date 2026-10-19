#!/usr/bin/env bash
#
# set-version.sh - move every version-bearing file to one version, together.
#
# A version lives in more than one place: ./VERSION, the marketplace manifest
# the Claude plugin marketplace reads, and the README, which quotes both the
# current release and an example of the update manifest. Each of those is a
# plain file that nothing regenerates, so each one is a place where a release
# can leave the repository inconsistent with itself.
#
# That is not hypothetical. v1.2.0 bumped ./VERSION and moved the manifest
# nowhere, so check-repo-state.sh failed on the release commit itself, the
# validate workflow went red, the release workflow went red, and the tagged
# artifact was broken by the tag. The tag was cut from a commit that the
# repository's own validator rejected.
#
# So the rule is: a version is moved by this script and by nothing else. It is
# called by scripts/release.sh before the release commit, and it is idempotent,
# so running it twice changes nothing the second time.
#
# Usage: scripts/set-version.sh <version>
# Exit:  0 when every file now carries the version, 1 otherwise.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'
else
  RED=''; GRN=''; RST=''
fi

VERSION_FILE="${VERSION_FILE:-$ROOT/VERSION}"
MARKETPLACE="${MARKETPLACE:-$ROOT/.claude-plugin/marketplace.json}"
README_FILE="${README_FILE:-$ROOT/README.md}"

NEW="${1:-}"
if [ -z "$NEW" ]; then
  printf 'usage: scripts/set-version.sh <version>\n' >&2
  exit 2
fi
if ! grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' <<<"$NEW"; then
  printf 'error: %s is not a semantic version\n' "$NEW" >&2
  exit 2
fi

# set_in <file> <pattern-with-one-capture-group-around-the-value> <must-survive>
#
# The pattern must capture the text either side of the value in groups 1 and 2,
# and the replacement is \1<version>\2. Matching the value alone and replacing
# it with the version destroys the surrounding syntax: the marketplace manifest
# loses its quotes and stops being JSON, and the README loses its key. That
# happened on the first run of this script.
#
# The third argument is a literal that has to still be present afterwards. It
# is how the surrounding syntax is checked, because a file that still contains
# the version but has lost its key would pass a naive check.
set_in() {
  local file="$1" pattern="$2" survivor="$3" before after matches
  [ -f "$file" ] || { printf '  skip    %s (absent)\n' "${file##*/}"; return 0; }
  before="$(cat "$file")"

  # Count first. A pattern that matches more than once would move every copy,
  # and this script's job is to move exactly one. The count is also how a file
  # that is already correct is recognised, so there is no separate "already
  # set" case to get wrong.
  matches="$(grep -cE "$pattern" <<<"$before")"
  if [ "$matches" -eq 0 ]; then
    printf '  FAIL    %s has no version where one is expected\n' "${file##*/}"
    return 1
  fi
  if [ "$matches" -gt 1 ]; then
    printf '  FAIL    %s has %s places matching the version, expected exactly 1\n' "${file##*/}" "$matches"
    return 1
  fi

  # sed -E, not the default: the capture groups are written ( ) and without it
  # they are literal parentheses, the pattern matches nothing, and the failure
  # looks like a missing value rather than a broken regex.
  after="$(printf '%s' "$before" | sed -E "s/$pattern/\\1$NEW\\2/")"

  if [ "$before" = "$after" ]; then
    # The rewrite changed nothing. That is success when the file already said
    # the new version, and failure otherwise, and telling them apart is the
    # whole reason this script is idempotent.
    case "$after" in
      *"$NEW"*) printf '  ok      %s (already %s)\n' "${file##*/}" "$NEW"; return 0 ;;
      *) printf '  FAIL    %s did not change and does not carry %s\n' "${file##*/}" "$NEW"; return 1 ;;
    esac
  fi

  case "$after" in
    *"$survivor"*) : ;;
    *) printf '  FAIL    %s lost %s while being rewritten\n' "${file##*/}" "$survivor"; return 1 ;;
  esac
  case "$after" in
    *"$NEW"*) : ;;
    *) printf '  FAIL    %s does not contain the new version\n' "${file##*/}"; return 1 ;;
  esac

  printf '%s' "$after" > "$file" || { printf '  FAIL    %s could not be written\n' "${file##*/}"; return 1; }
  printf '  set     %s -> %s\n' "${file##*/}" "$NEW"
}

fail=0
printf '%ssetting version %s%s\n' "$GRN" "$NEW" "$RST"

printf '%s\n' "$NEW" > "$VERSION_FILE" || { printf 'error: cannot write %s\n' "$VERSION_FILE" >&2; exit 1; }
printf '  set     VERSION -> %s\n' "$NEW"

set_in "$MARKETPLACE" '("version"[[:space:]]*:[[:space:]]*")[^"]*(")' '"version"' || fail=1
set_in "$README_FILE" '(Current release: \*\*)[0-9][^*]*(\*\*)' 'Current release: **' || fail=1
set_in "$README_FILE" '("collectionVersion"[[:space:]]*:[[:space:]]*")[^"]*(")' '"collectionVersion"' || fail=1

if [ "$fail" -ne 0 ]; then
  printf '%sversion was not moved everywhere%s\n' "$RED" "$RST" >&2
  exit 1
fi

# Verify with the gate that owns this question, rather than with a second
# opinion written here. If the two disagree, the gate is right, because the
# gate is what CI runs.
if [ -f scripts/check-repo-state.sh ]; then
  if ! bash scripts/check-repo-state.sh >/dev/null 2>&1; then
    printf '%sthe repository state check disagrees; run scripts/check-repo-state.sh%s\n' "$RED" "$RST" >&2
    bash scripts/check-repo-state.sh 2>&1 | sed 's/^/  /' >&2
    exit 1
  fi
fi

printf '%severy version-bearing file now says %s%s\n' "$GRN" "$NEW" "$RST"
exit 0
