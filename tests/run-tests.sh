#!/usr/bin/env bash
#
# run-tests.sh - regression suite for scripts/validate-skills.sh.
#
# The validator is the gate that keeps this collection portable, so it needs its
# own tests. Each case stages one skill in a temporary directory, runs the
# validator against it through SKILLS_DIR, then asserts both the exit code and a
# message fragment. Fixtures are generated rather than committed so that a stray
# UTF-8 BOM in a checked-in test file cannot silently weaken the suite.
#
# Usage: tests/run-tests.sh
# Exit: 0 all cases pass | 1 at least one case failed

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$ROOT/scripts/validate-skills.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$VALIDATOR" ]; then
  printf 'error: %s not found\n' "$VALIDATOR" >&2
  exit 2
fi

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; BLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  RED=''; GRN=''; DIM=''; BLD=''; RST=''
fi

passes=0
failures=0
SDIR=""

# run_case <name> <skill-id> <expect-exit> <message-fragment> [setup] [post]
#
# Stages the SKILL.md read from stdin at <tmp>/<name>/<skill-id>/SKILL.md and
# points the validator at <tmp>/<name>. setup and post run around the write and
# may use $SDIR, which is that skill directory.
run_case() {
  local case_name="$1" skill_id="$2" expect_exit="$3" pattern="$4" setup="${5:-}" post="${6:-}"

  local skills_root="$TMP/$case_name"
  SDIR="$skills_root/$skill_id"
  mkdir -p "$SDIR"
  [ -n "$setup" ] && eval "$setup"
  cat > "$SDIR/SKILL.md"
  [ -n "$post" ] && eval "$post"

  local out rc
  out="$(cd "$ROOT" && SKILLS_DIR="$skills_root" bash "$VALIDATOR" 2>&1)"
  rc=$?

  if [ "$rc" != "$expect_exit" ]; then
    printf '  %sFAIL%s  %-24s expected exit %s, got %s\n' "$RED" "$RST" "$case_name" "$expect_exit" "$rc"
    printf '%s\n' "$out" | sed 's/^/          /'
    failures=$((failures + 1))
    return
  fi

  if [ -n "$pattern" ] && ! printf '%s\n' "$out" | grep -qF -- "$pattern"; then
    printf '  %sFAIL%s  %-24s missing message: %s\n' "$RED" "$RST" "$case_name" "$pattern"
    printf '%s\n' "$out" | sed 's/^/          /'
    failures=$((failures + 1))
    return
  fi

  printf '  %sok%s    %s\n' "$GRN" "$RST" "$case_name"
  passes=$((passes + 1))
}

printf '%svalidate-skills.sh regression suite%s\n\n' "$BLD" "$RST"

# ---------------------------------------------------------------- valid cases

run_case valid-good valid-good 0 'all checks passed' \
  'mkdir -p "$SDIR/references"; printf "# Notes\n" > "$SDIR/references/notes.md"' <<'EOF'
---
name: valid-good
description: Use when running the validator regression suite to confirm a fully conforming skill is accepted.
---

# Valid skill

Read references/notes.md when you need the background.
EOF

run_case valid-optional-fields valid-optional-fields 0 'all checks passed' <<'EOF'
---
name: valid-optional-fields
description: Use when running the validator regression suite to confirm the optional spec fields parse correctly.
license: Apache-2.0
compatibility: Requires bash and git; tested on Linux and Windows
metadata:
  author: example-org
  version: "1.0"
allowed-tools: Bash(git:*) Read
---

# Valid skill with optional fields
EOF

# ---------------------------------------------------------------- invalid cases

run_case bom bom 1 'UTF-8 BOM' '' \
  'printf "\xef\xbb\xbf" > "$SDIR/b"; cat "$SDIR/SKILL.md" >> "$SDIR/b"; mv "$SDIR/b" "$SDIR/SKILL.md"' <<'EOF'
---
name: bom
description: Use when confirming the validator detects a UTF-8 byte order mark.
---

# BOM
EOF

run_case bad-id Bad_ID 1 'lowercase alphanumeric' <<'EOF'
---
name: Bad_ID
description: Use when confirming the validator rejects an id that is not lowercase kebab-case.
---

# Bad id
EOF

run_case consecutive-hyphen bad--id 1 'consecutive hyphens' <<'EOF'
---
name: bad--id
description: Use when confirming the validator rejects consecutive hyphens in a skill name.
---

# Consecutive hyphens
EOF

run_case missing-name missing-name 1 "missing required field 'name'" <<'EOF'
---
description: Use when confirming the validator rejects frontmatter that omits the required name field.
---

# Missing name
EOF

run_case missing-description missing-description 1 "missing required field 'description'" <<'EOF'
---
name: missing-description
---

# Missing description
EOF

run_case name-dir-mismatch actual-dir 1 'must match its directory name' <<'EOF'
---
name: some-other-name
description: Use when confirming the validator rejects a name that disagrees with its directory.
---

# Mismatch
EOF

run_case no-opening-delimiter no-opening-delimiter 1 'line 1 must be exactly' <<'EOF'
Some prose before the frontmatter.

---
name: no-opening-delimiter
description: Use when confirming the validator rejects a skill whose first line is not the delimiter.
---

# Bad
EOF

run_case unclosed-frontmatter unclosed-frontmatter 1 'never closed' <<'EOF'
---
name: unclosed-frontmatter
description: Use when confirming the validator rejects frontmatter that is never closed.

# No closing delimiter
EOF

run_case empty-body empty-body 1 'body is empty' <<'EOF'
---
name: empty-body
description: Use when confirming the validator rejects a skill that carries no instructions at all.
---
EOF

run_case unknown-key unknown-key 1 'not allowed by the portable spec' <<'EOF'
---
name: unknown-key
description: Use when confirming the validator rejects frontmatter keys outside the portable spec.
version: 2
---

# Unknown key
EOF

run_case nested-metadata nested-metadata 1 'flat string map' <<'EOF'
---
name: nested-metadata
description: Use when confirming the validator rejects a metadata block that nests objects.
metadata:
  author:
    name: example
    email: someone@example.com
---

# Nested metadata
EOF

run_case dangling-ref dangling-ref 1 'but that file does not exist' <<'EOF'
---
name: dangling-ref
description: Use when confirming the validator catches a reference to a file that was never created.
---

# Dangling reference

Consult references/format-spec.md and run scripts/cleanup.py first.
EOF

run_case deep-ref deep-ref 0 'one level deep' \
  'mkdir -p "$SDIR/references/nested"; printf "# Deep\n" > "$SDIR/references/nested/deep.md"' <<'EOF'
---
name: deep-ref
description: Use when confirming the validator warns about references nested more than one level deep.
---

# Deep reference

See references/nested/deep.md.
EOF

run_case no-trigger-clause no-trigger-clause 0 'no trigger clause' <<'EOF'
---
name: no-trigger-clause
description: Processes spreadsheets and writes summary reports.
---

# Vague description
EOF

# -------------------------------------------------------- catalog guard
# The catalog describes the repository's own skills, so the validator must skip
# it when pointed at a temporary tree. Without this, validating a temporary tree
# in a repository that has a dist/ directory compares against the real catalog
# and fails on every skill. Regression test for a bug found the hard way.
guard="$TMP/catalog-guard"
mkdir -p "$guard/.opencode/skills/guard-skill" "$guard/dist"
cat > "$guard/.opencode/skills/guard-skill/SKILL.md" <<'EOF'
---
name: guard-skill
description: Use when verifying that the catalog check is skipped for a temporary skills tree.
---

# Guard
EOF
# A catalog that deliberately does not list guard-skill.
printf '{"skills":[{"name":"unrelated","version":"1","files":["SKILL.md"]}]}\n' > "$guard/dist/index.json"

guard_out="$(cd "$ROOT" && SKILLS_DIR="$guard/.opencode/skills" DIST_DIR="$guard/dist" bash "$VALIDATOR" 2>&1)"
guard_rc=$?
if [ "$guard_rc" -eq 0 ]; then
  printf '  %sok%s    %s\n' "$GRN" "$RST" "catalog-skip-when-overridden"
  passes=$((passes + 1))
else
  printf '  %sFAIL%s  %-24s catalog check ran against an overridden skills tree\n' "$RED" "$RST" "catalog-skip-when-overridden"
  printf '%s\n' "$guard_out" | sed 's/^/          /'
  failures=$((failures + 1))
fi

# ------------------------------------------------------- encoding detectors
#
# A gate that always passes is worse than no gate, because it is believed. These
# two cases exist because scripts/normalize.sh claimed for the entire life of the
# project to detect CRLF while being structurally unable to detect anything:
#
#   grep -q $'\r'    never matches, because the trailing CR is eaten as part of
#                    the pattern's own line terminator
#   grep -q $'\r\n'  matches everything, because a newline in the pattern splits
#                    it and the empty remainder matches any file
#
# Both failed silently, so nothing caught it. These plant the defects and assert
# detection, which is the only reason the detector can now be trusted.
NORMALIZE="$ROOT/scripts/normalize.sh"
[ -f "$NORMALIZE" ] || NORMALIZE=""

if [ -n "$NORMALIZE" ] && [ -x "$NORMALIZE" ] || [ -n "$NORMALIZE" ]; then
  enc="$TMP/encoding"
  mkdir -p "$enc"
  printf 'a\r\nb\r\n' > "$enc/crlf.md"          # CRLF only, no BOM
  printf 'a\nb\n'     > "$enc/lf.md"            # clean LF
  printf '\357\273\277a\n' > "$enc/bom.md"      # BOM only
  printf 'a\r\nb\r\n' > "$enc/both.md"          # both
  printf '\000\001\015\012\377' > "$enc/blob.bin"  # binary containing CRLF

  check_case() {
    local name="$1" expect_hit="$2" file="$3" got
    if LC_ALL=C grep -qU $'\r' "$file" 2>/dev/null; then got=yes; else got=no; fi
    if [ "$got" = "$expect_hit" ]; then
      printf '  %sok%s    %s\n' "$GRN" "$RST" "$name"
      passes=$((passes + 1))
    else
      printf '  %sFAIL%s  %-24s expected %s, got %s\n' "$RED" "$RST" "$name" "$expect_hit" "$got"
      failures=$((failures + 1))
    fi
  }

  check_case crlf-detected        yes "$enc/crlf.md"
  check_case lf-not-false-positive no "$enc/lf.md"
  check_case binary-cr-detected   yes "$enc/blob.bin"

  # The BOM detector, which is a byte comparison rather than a grep and so has a
  # different failure mode: an off-by-one in the length being compared.
  bom_detected=no
  [ "$(head -c 3 "$enc/bom.md"  | od -An -tx1 | tr -d ' \n')" = "efbbbf" ] && bom_detected=yes
  bom_clean=no
  [ "$(head -c 3 "$enc/lf.md"   | od -An -tx1 | tr -d ' \n')" = "efbbbf" ] && bom_clean=yes
  if [ "$bom_detected" = yes ] && [ "$bom_clean" = no ]; then
    printf '  %sok%s    %s\n' "$GRN" "$RST" bom-detected
    passes=$((passes + 1))
  else
    printf '  %sFAIL%s  %-24s bom=%s clean=%s\n' "$RED" "$RST" "$bom_detected" "$bom_clean"
    failures=$((failures + 1))
  fi

  # End to end: the script itself must report the planted CRLF file and, just as
  # importantly, must not claim the whole tree needs normalizing when it does not.
  #
  # The fixture has to live inside the repository, because that is the only tree
  # the script scans. It is removed immediately after, and a trap covers the case
  # where the assertion exits early, so a failing run cannot leave a defective
  # file behind for the next one to trip over.
  fixture="$ROOT/.normalize-fixture.tmp"
  printf 'a\r\nb\r\n' > "$fixture"
  trap 'rm -f "$fixture"' RETURN

  enc_out="$(cd "$ROOT" && bash "$NORMALIZE" --check 2>&1)"
  rm -f "$fixture"
  trap - RETURN

  if printf '%s' "$enc_out" | grep -q 'need normalizing'; then
    printf '  %sok%s    %s\n' "$GRN" "$RST" normalize-detects-planted-crlf
    passes=$((passes + 1))
  else
    printf '  %sFAIL%s  %-24s --check did not report a planted CRLF file\n' "$RED" "$RST" normalize-detects-planted-crlf
    failures=$((failures + 1))
  fi

  # And the converse, which is the case that actually burned us: a clean tree
  # must come back clean. A detector that reports every file as broken is not a
  # working detector either, and it is just as dangerous because the obvious
  # response is to normalise the whole tree.
  clean_out="$(cd "$ROOT" && bash "$NORMALIZE" --check 2>&1)"
  if printf '%s' "$clean_out" | grep -q 'everything is already normalized'; then
    printf '  %sok%s    %s\n' "$GRN" "$RST" normalize-clean-tree-not-flagged
    passes=$((passes + 1))
  else
    printf '  %sFAIL%s  %-24s a clean tree was reported as needing normalization\n' "$RED" "$RST" normalize-clean-tree-not-flagged
    printf '%s\n' "$clean_out" | tail -n 5 | sed 's/^/          /'
    failures=$((failures + 1))
  fi
fi

# ------------------------------------------------- repository state checks
#
# Both of these run scripts/check-repo-state.sh, which answers in well under a
# second, rather than the whole validator, which takes minutes. That is not a
# convenience: the earlier version of this suite ran the full validator five
# times and took nineteen minutes, which is long enough that the checks stop
# being run locally, and they had already been broken.
#
# Every fixture is written to a temporary directory and passed in by path, so
# nothing here touches the repository. The one exception is the executable bit,
# which is a property of the git index and cannot be faked. That one is made
# self-healing instead: it resets the index before it starts and again when it
# finishes, so a run killed mid-case leaves the next one with a known-good
# baseline. An interrupted test that corrupts the checkout is worse than the
# failure it was testing for.
STATE="$ROOT/scripts/check-repo-state.sh"

if [ -f "$STATE" ]; then
  # assert_state <label> <expected-exit> <pattern-that-must-be-present>
  assert_state() {
    local label="$1" want="$2" pattern="$3" out rc
    out="$(cd "$ROOT" && bash "$STATE" 2>&1)"; rc=$?
    if [ "$rc" = "$want" ] && printf '%s' "$out" | grep -q "$pattern"; then
      printf '  %sok%s    %s\n' "$GRN" "$RST" "$label"
      passes=$((passes + 1))
    else
      printf '  %sFAIL%s  %-24s exit %s (want %s)\n' "$RED" "$RST" "$label" "$rc" "$want"
      printf '%s\n' "$out" | sed 's/^/          /' | head -n 6
      failures=$((failures + 1))
    fi
  }

  fx="$TMP/repo-state"
  mkdir -p "$fx/.opencode/skills/alpha" "$fx/.opencode/skills/beta"
  pad_a="$(printf 'a%.0s' $(seq 1 62))"
  pad_b="$(printf 'b%.0s' $(seq 1 62))"
  printf -- '---\nname: alpha\ndescription: %s\n---\n' "$pad_a" > "$fx/.opencode/skills/alpha/SKILL.md"
  printf -- '---\nname: beta\ndescription: %s\n---\n'  "$pad_b" > "$fx/.opencode/skills/beta/SKILL.md"
  printf '2.0.0\n' > "$fx/VERSION"

  # write_marketplace <count> <version>
  write_marketplace() {
    printf '{"name":"m","metadata":{"description":"%s validated skills","version":"%s"}}\n' \
      "$1" "$2" > "$fx/marketplace.json"
  }

  # Point the check at the fixture tree for every assertion below. Exporting once
  # is clearer than passing them per call, and the executable-bit check is off
  # because the fixture is not the repository and has no git index to inspect.
  export MARKETPLACE="$fx/marketplace.json"
  export VERSION_FILE="$fx/VERSION"
  export SKILLS_DIR="$fx/.opencode/skills"
  export CHECK_EXEC=0

  # clean fixture: version matches, count matches
  write_marketplace 2 2.0.0
  assert_state state-clean 0 'marketplace version matches VERSION (2.0.0)'

  # stale version, which is what shipped here for two releases
  write_marketplace 2 1.0.0
  assert_state state-version-drift 1 'but VERSION is 2.0.0'

  # stale count, the one that rots quietly because it is prose
  write_marketplace 3 2.0.0
  assert_state state-count-drift 1 'advertises 3 skills but 2 are present'

  # Back to the real repository, which is the fact CI actually depends on.
  unset MARKETPLACE VERSION_FILE SKILLS_DIR CHECK_EXEC
  assert_state repository-clean 0 'committed as executable'
fi

# ------------------------------------------------ executable bit on the index
#
# This one cannot be faked with a fixture, because it is a property of the git
# index. It resets before and after so an interrupted run heals.
if [ -f "$STATE" ] && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  heal_index() { git -C "$ROOT" update-index --chmod=+x install.sh >/dev/null 2>&1; }
  trap heal_index EXIT
  heal_index

  git -C "$ROOT" update-index --chmod=-x install.sh
  out="$(cd "$ROOT" && bash "$STATE" 2>&1)"; rc=$?
  heal_index

  if [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'not committed as executable'; then
    printf '  %sok%s    %s\n' "$GRN" "$RST" exec-bit-drift-detected
    passes=$((passes + 1))
  else
    printf '  %sFAIL%s  %-24s stripping the bit was not reported (exit %s)\n' "$RED" "$RST" "$rc"
    failures=$((failures + 1))
  fi
fi

# ------------------------------------------------- translations track the set
  #
  # The i18n gate is only useful if it fails for the reason it claims to check.
  # It shipped once already and did not: every marker was updated when the
  # collection grew, eighteen prose counts were not, and the gate passed. These
  # cases plant each way it can go wrong and require the failure.
  if [ -f "$ROOT/scripts/check-i18n.sh" ] && [ -f "$ROOT/docs/i18n/es.md" ]; then
    es="$ROOT/docs/i18n/es.md"
    ar="$ROOT/docs/i18n/ar.md"
    cp "$es" "$TMP/es.keep"; cp "$ar" "$TMP/ar.keep"
    heal_i18n() { cp "$TMP/es.keep" "$es"; cp "$TMP/ar.keep" "$ar"; }
    trap heal_i18n EXIT

    i18n_case() {
      local name="$1" file="$2" needle="$3"
      local out rc
      out="$(cd "$ROOT" && bash scripts/check-i18n.sh 2>&1)"; rc=$?
      if [ "$rc" != 0 ] && printf '%s' "$out" | grep -qF -- "$needle"; then
        printf '  %sok%s    %s\n' "$GRN" "$RST" "$name"
        passes=$((passes + 1))
      else
        printf '  %sFAIL%s  %-24s exit %s, output did not mention %s\n' "$RED" "$RST" "$name" "$rc" "$needle"
        printf '%s\n' "$out" | sed 's/^/          /'
        failures=$((failures + 1))
      fi
    }

    # A stale count in the prose, with the marker left correct. This is the
    # exact shape of the drift that got through. The delimiter is @ rather than
    # the usual / because the text being matched is a markdown table row and
    # every character you would reach for as a delimiter is already in it.
    sed -i 's@| Habilidades | 83, en 18 dominios |@| Habilidades | 79, en 18 dominios |@' "$es"
    i18n_case i18n-stale-prose-count "$es" 'prose states a count'
    heal_i18n

    # The same drift in Arabic-Indic digits, U+0667 U+0669 for 79. They are
    # written as literals rather than as printf '\u0667' escapes, which expand
    # under bash 5 but silently emit the backslash form under the Git Bash this
    # suite runs in, and a substitution that matches nothing is not a test.
    #
    # Written as a single unsplit token the digit list does not word-split under
    # Git Bash, so the checker's normalisation becomes a no-op and this case is
    # what catches that going unnoticed.
    sed -i 's/٨٣/٧٩/' "$ar"
    i18n_case i18n-stale-arabic-count "$ar" 'prose states a count'
    heal_i18n

    # A translation nobody declared, which is drift in the other direction.
    printf '# orphan\n' > "$ROOT/docs/i18n/it.md"
    i18n_case i18n-undeclared-language "$ROOT/docs/i18n/it.md" 'not declared'
    rm -f "$ROOT/docs/i18n/it.md"

    trap heal_index EXIT
  fi

  # ------------------------------------------------------------------- summary
printf '\n'
if [ "$failures" -gt 0 ]; then
  printf '%s%d passed, %d failed%s\n' "$RED" "$passes" "$failures" "$RST"
  exit 1
fi
printf '%sall %d cases passed%s\n' "$GRN" "$passes" "$RST"
exit 0