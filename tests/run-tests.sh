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

# ------------------------------------------------------------------- summary
printf '\n'
if [ "$failures" -gt 0 ]; then
  printf '%s%d passed, %d failed%s\n' "$RED" "$passes" "$failures" "$RST"
  exit 1
fi
printf '%sall %d cases passed%s\n' "$GRN" "$passes" "$RST"
exit 0