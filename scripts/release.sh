#!/usr/bin/env bash
#
# release.sh - cut a release of the skill collection.
#
# A release covers the collection as a whole, because all three of a new skill, a
# changed routing sentence, and a changed validator change which skills a
# consumer ends up with. They are the same kind of event.
#
# The script refuses to cut a release unless every gate passes, so a tag can
# never point at a collection that does not validate.
#
# Usage:
#   scripts/release.sh 1.2.0            # cut the release, commit and tag
#   scripts/release.sh 1.2.0 --dry-run  # run every gate, change nothing
#   scripts/release.sh --show           # print the current version and latest tag

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; DIM=$'\033[2m'; YEL=$'\033[33m'; RST=$'\033[0m'
else
  RED=''; GRN=''; DIM=''; BLD=''; YEL=''; RST=''; fi

VERSION_FILE="VERSION"
CHANGELOG="CHANGELOG.md"

die()  { printf '%serror:%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }
step() { printf '\n%s%s%s\n' "$BLD" "$*" "$RST"; }
ok()   { printf '  %sok%s    %s\n' "$GRN" "$RST" "$*"; }

current_version() { [ -f "$VERSION_FILE" ] && tr -d '[:space:]' < "$VERSION_FILE"; }

DRY=0
NEW=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --show)    printf 'version: %s\nlatest tag: %s\n' "$(current_version)" "$(git describe --tags --abbrev=0 2>/dev/null || echo none)"; exit 0 ;;
    -*)        die "unknown option: $a" ;;
    *)         NEW="$a" ;;
  esac
done

[ -n "$NEW" ] || die "usage: scripts/release.sh <version> [--dry-run]"

# ---------------------------------------------------------------- validate
if ! grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' <<<"$NEW"; then
  die "'$NEW' is not a semantic version (expected MAJOR.MINOR.PATCH)"
fi

step "Gates"
for gate in \
  "scripts/normalize.sh --check" \
  "scripts/set-descriptions.sh --check" \
  "scripts/validate-skills.sh --strict" \
  "scripts/sync-agents.sh --check" \
  "scripts/sync-rules.sh --check" \
  "scripts/build-catalog-doc.sh --check" \
  "scripts/check-i18n.sh" \
  "tests/run-tests.sh"
do
  # shellcheck disable=SC2086
  if out="$(bash $gate 2>&1)"; then
    ok "$gate"
  else
    printf '  %sFAIL%s  %s\n' "$RED" "$RST" "$gate"
    printf '%s\n' "$out" | tail -n 12 | sed 's/^/          /'
    # Stop here rather than running the remaining gates. The list runs from
    # cheapest to most expensive, and the last one is the full regression suite.
    # A release that fails after twenty minutes of tests taught you nothing you
    # would not have learned in thirty seconds, which is exactly what happened
    # here: the first attempt ran the whole suite before reporting a defect
    # that the first gate would have caught.
    die "gate failed; nothing was released"
  fi
done

CUR="$(current_version)"
if [ "$(git rev-list --count HEAD)" -gt 0 ]; then
  latest_tag="$(git describe --tags --abbrev=0 2>/dev/null || echo '')"
  if [ -n "$latest_tag" ] && [ "${latest_tag#v}" = "$NEW" ]; then
    die "tag v$NEW already exists"
  fi
fi

# ------------------------------------------------------------- changelog
step "Changelog"
if ! grep -q "^## \[$NEW\]" "$CHANGELOG"; then
  if [ "$DRY" -eq 1 ]; then
    printf '  %swould add%s a section for %s to %s\n' "$YEL" "$RST" "$NEW" "$CHANGELOG"
  else
    die "$CHANGELOG has no section for $NEW; write the release notes first"
  fi
else
  ok "$CHANGELOG documents $NEW"
fi

# ----------------------------------------------------------------- write
if [ "$DRY" -eq 1 ]; then
  step "Dry run"
  printf '  version   %s -> %s\n' "$CUR" "$NEW"
  printf '  tag       v%s\n' "$NEW"
  printf '  commit    %s\n' "$(git rev-parse --short HEAD)"
  printf '\n%srelease %s is ready; re-run without --dry-run to cut it%s\n' "$GRN" "$NEW" "$RST"
  exit 0
fi

step "Cutting release $NEW"

# Every file that carries the version is moved by one script, in the same
# commit, or the repository's own validator fails on the release commit.
#
# This is not hypothetical. check-repo-state.sh compares the version the
# marketplace manifest advertises against ./VERSION, and the v1.2.0 release
# commit changed one of them and not the other. The tagged build was therefore
# broken by the tag itself: the validate workflow and the release workflow both
# went red on the commit that was supposed to be the good one.
#
# The rule this encodes: a version is moved by scripts/set-version.sh and by
# nothing else. A half-moved version is the failure mode, and it is silent.
if ! bash scripts/set-version.sh "$NEW"; then
  die "could not move the version to every file"
fi
ok "version moved everywhere"

git add "$VERSION_FILE" ".claude-plugin/marketplace.json" README.md || die "git add failed"
git commit -q -m "Release $NEW" || die "git commit failed"
ok "committed"

git tag -a "v$NEW" -m "Release $NEW" || die "git tag failed"
ok "tagged v$NEW"

step "Done"
printf '  version %s -> %s\n' "$CUR" "$NEW"
printf '\n%sPublish it with:%s\n' "$BLD" "$RST"
printf '  git push origin main --follow-tags\n'
printf '\nThe release workflow then publishes the catalog and changelog from the tag.\n'
exit 0