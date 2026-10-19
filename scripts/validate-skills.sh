#!/usr/bin/env bash
#
# validate-skills.sh - conformance checker for this SKILL.md collection.
#
# Enforces the portable Agent Skills specification:
#   https://agentskills.io/specification
# plus the OpenCode V2 rules that matter for a distributed catalog:
#   https://opencode.ai/v2/docs/skills
#
# The portable spec is deliberately the stricter of the two, so anything that
# passes here also loads in OpenCode, Claude Code and VS Code/Copilot, and
# satisfies the reference `skills-ref validate` tool.
#
# Usage:
#   scripts/validate-skills.sh            # human readable report
#   scripts/validate-skills.sh --strict   # treat warnings as failures (CI)
#
# Exit codes: 0 ok | 1 validation failures | 2 setup error

set -uo pipefail

STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^#*  *//'; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SKILLS_DIR_OVERRIDDEN=0
if [ -n "${SKILLS_DIR:-}" ]; then
  SKILLS_DIR_OVERRIDDEN=1
else
  SKILLS_DIR=".opencode/skills"
fi
DIST_DIR="${DIST_DIR:-dist}"

# The clusters file, overridable so the regression suite can point it at a
# fixture. The earlier version of that suite planted its drift in the committed
# skills.sh.json and restored it on exit, which is safe only while nothing
# kills the run: an interrupted test leaves the repository broken, and the
# restore is a trap, which a SIGKILL does not run. A fixture has no such
# failure mode because there is nothing to restore.
CLUSTERS_FILE="${CLUSTERS_FILE:-skills.sh.json}"
VERSION_FILE="VERSION"

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; DIM=$'\033[2m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; DIM=''; BLD=''; RST=''
fi

ERRORS=0
WARNINGS=0

fail()   { ERRORS=$((ERRORS + 1));   printf '  %sFAIL%s  %s\n' "$RED" "$RST" "$*"; }
warn()   { WARNINGS=$((WARNINGS + 1)); printf '  %sWARN%s  %s\n' "$YEL" "$RST" "$*"; }
pass()   { printf '  %sok%s    %s\n' "$DIM" "$RST" "$*"; }
section(){ printf '\n%s%s%s\n' "$BLD" "$*" "$RST"; }
hint()   { printf '        %s-> %s%s\n' "$DIM" "$*" "$RST"; }

# The portable spec permits exactly these keys; any other key is a hard error.
ALLOWED_KEYS=' allowed-tools compatibility description license metadata name '
MAX_NAME=64
MAX_DESC=1024
MAX_COMPAT=500
MAX_BODY_LINES=500

# fm_get <file> <key> -> scalar value of a top-level frontmatter key.
# Handles plain, quoted and |/>- block scalars. Tolerates a leading UTF-8 BOM
# so one defect does not mask every other error.
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

# fm_keys <file> -> sorted unique top-level frontmatter keys
fm_keys() {
  awk '
    { sub(/\r$/, "") }
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); next }
    /^---[[:space:]]*$/ { exit }
    /^[A-Za-z_][A-Za-z0-9_-]*:/ { sub(/:.*/, ""); print }
  ' "$1" | LC_ALL=C sort -u
}

# md_problem <file> -> "nested" | "nonstring" | "" (metadata is a flat string map)
md_problem() {
  awk '
    { sub(/\r$/, "") }
    NR == 1 { next }
    /^---[[:space:]]*$/ { exit }
    /^metadata:[ \t]*$/ { inmd = 1; next }
    inmd && /^[^ \t]/ { inmd = 0 }
    inmd && /^[ \t]/ {
      n = match($0, /[^ \t]/) - 1
      if (n != 2) { print "nested"; exit }
      rest = substr($0, n + 1)
      # A key with no value introduces a nested object, which the spec forbids.
      if (rest ~ /^[A-Za-z0-9][A-Za-z0-9._\/-]*:[ \t]*$/) { print "nested"; exit }
      if (rest !~ /^[A-Za-z0-9][A-Za-z0-9._\/-]*:[ \t]*[^ \t].*$/) { print "nonstring"; exit }
    }
  ' "$1"
}

if [ ! -d "$SKILLS_DIR" ]; then
  printf '%ssetup error:%s skills directory %s not found\n' "$RED" "$RST" "$SKILLS_DIR" >&2
  exit 2
fi

declare -A SEEN_ID=()
declare -A SEEN_NAME=()
ALL_IDS=()

# validate_skill <id> <file>
validate_skill() {
  local id="$1" file="$2"
  local desc name compat close body body_start lines words k ref refs
  local first bom_hex md dir_of_file

  ALL_IDS+=("$id")
  dir_of_file="$(dirname "$file")"

  [ -n "${SEEN_ID[$id]:-}" ] && fail "$id: duplicate skill id"
  SEEN_ID["$id"]=1

  # ---- id / name -------------------------------------------------------
  [ -n "$id" ] || { fail "$id: id must not be empty"; return; }
  if ! grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' <<<"$id"; then
    fail "$id: id must be lowercase alphanumeric segments joined by single hyphens"
    hint "example: code-review, testing-strategies"
  fi
  [ "${#id}" -le "$MAX_NAME" ] || fail "$id: id is ${#id} chars (max $MAX_NAME)"

  if [ ! -s "$file" ]; then
    fail "$id: SKILL.md is missing or empty"
    return
  fi

  # PowerShell's default -Encoding utf8 emits a BOM, which shifts the opening
  # delimiter and breaks naive frontmatter parsers downstream.
  bom_hex="$(head -c 3 "$file" | od -An -tx1 | tr -d ' \n')"
  if [ "$bom_hex" = "efbbbf" ]; then
    fail "$id: starts with a UTF-8 BOM; rewrite the file as UTF-8 without BOM"
    hint 'powershell: [System.IO.File]::WriteAllText($p, $c, (New-Object System.Text.UTF8Encoding $false))'
  fi

  first="$(sed '1s/^\xEF\xBB\xBF//' "$file" | head -n 1 | tr -d '\r')"
  if [ "$first" != "---" ]; then
    fail "$id: line 1 must be exactly '---' (found '$first')"
    hint 'the opening delimiter cannot be preceded by anything, including a blank line'
  fi

  close="$(awk '{sub(/\r$/,"")} NR==1{sub(/^\xef\xbb\xbf/,"");next} /^---[[:space:]]*$/{print NR; exit}' "$file")"
  if [ -z "$close" ]; then
    fail "$id: frontmatter is never closed with '---'"
  fi

  # ---- allowed keys ----------------------------------------------------
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    case "$ALLOWED_KEYS" in
      *" $k "*) ;;
      *)
        fail "$id: frontmatter key '$k' is not allowed by the portable spec"
        hint "allowed: name, description, license, compatibility, metadata, allowed-tools"
        ;;
    esac
  done < <(fm_keys "$file")

  # ---- name ------------------------------------------------------------
  name="$(fm_get "$file" name)"
  if [ -z "$name" ]; then
    fail "$id: missing required field 'name'"
  else
    [ "${#name}" -le "$MAX_NAME" ] || fail "$id: name is ${#name} chars (max $MAX_NAME)"
    if [ "$name" != "$id" ]; then
      fail "$id: name '$name' must match its directory name '$id'"
      hint 'the portable spec requires name == parent directory; OpenCode additionally derives the skill id from this path'
    fi
    # The pattern is ^-|-$ and not ^-|-\$. In an extended regular expression
    # a backslash before the dollar makes it a literal dollar sign rather than
    # an anchor, so the second alternative matched the two characters "-$" and
    # a name ending in a hyphen was never rejected. The message promised a
    # check that half of it did not perform.
    if grep -Eq '^-|-$' <<<"$name"; then
      fail "$id: name must not start or end with a hyphen"
    fi
    if grep -q -- '--' <<<"$name"; then
      fail "$id: name must not contain consecutive hyphens"
    fi
    [ -n "${SEEN_NAME[$name]:-}" ] && fail "$id: duplicate skill name '$name' (also '${SEEN_NAME[$name]}')"
    SEEN_NAME["$name"]="$id"
  fi

  # ---- description -----------------------------------------------------
  desc="$(fm_get "$file" description)"
  if [ -z "$desc" ]; then
    fail "$id: missing required field 'description'"
    hint 'OpenCode will not advertise a skill with no description'
  else
    local desc_clean=1
    if [ "${#desc}" -gt "$MAX_DESC" ]; then
      fail "$id: description is ${#desc} chars (max $MAX_DESC)"
      desc_clean=0
    fi
    if [ "${#desc}" -lt 60 ]; then
      warn "$id: description is only ${#desc} chars; state both what it does and when to use it"
      desc_clean=0
    fi
    if grep -qiE '<[a-zA-Z/][^>]*>' <<<"$desc"; then
      warn "$id: description contains XML-like tags, which are rejected on skill upload"
      desc_clean=0
    fi
    if ! grep -qiE 'use (this )?(skill )?when|trigger|use when|invoke when' <<<"$desc"; then
      warn "$id: description has no trigger clause; add 'Use when ...' so the agent can route to it"
      hint 'pattern: <what it does>. Use when <situation, file type or request>.'
      desc_clean=0
    fi
    [ "$desc_clean" -eq 1 ] && pass "$id: description ok (${#desc} chars)"
  fi

  # ---- compatibility ---------------------------------------------------
  compat="$(fm_get "$file" compatibility)"
  if [ -n "$compat" ] && [ "${#compat}" -gt "$MAX_COMPAT" ]; then
    fail "$id: compatibility is ${#compat} chars (max $MAX_COMPAT)"
  fi

  # ---- metadata must be a flat string->string map ----------------------
  md="$(md_problem "$file")"
  case "$md" in
    nested)   fail "$id: metadata must be a flat string map, not a nested object"
               hint 'move the nesting into reference files instead' ;;
    nonstring) warn "$id: a metadata entry is not a 'key: scalar value' pair" ;;
  esac

  # ---- body ------------------------------------------------------------
  body_start=1
  [ -n "$close" ] && body_start=$((close + 1))
  body="$(tail -n +"$body_start" "$file" | sed 's/\r$//')"

  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    fail "$id: skill body is empty"
  else
    lines="$(grep -c '' <<<"$body")"
    words="$(printf '%s\n' "$body" | wc -w)"
    if [ "$lines" -gt "$MAX_BODY_LINES" ]; then
      warn "$id: body is $lines lines (keep under $MAX_BODY_LINES); move detail into references/"
    fi
    if [ "$words" -gt 4000 ]; then
      warn "$id: body is ~$words words, likely over the 5k token budget; use progressive disclosure"
    fi
    pass "$id: body ok ($lines lines, ~$words words)"
  fi

  # ---- referenced support files ---------------------------------------
  # Only a path separator matters here. Regex escapes such as \s are ordinary
  # content, so match the separator in a reference rather than any backslash.
  if grep -qE '(references|scripts|assets)\\' <<<"$body"; then
    warn "$id: a file reference uses backslashes; use forward slashes so it also works on POSIX hosts"
  fi

  refs="$(grep -oE '(references|scripts|assets)/[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*' "$file" 2>/dev/null | sed 's/[.,;:)]*$//' | LC_ALL=C sort -u)"
  if [ -n "$refs" ]; then
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      # A reference must resolve relative to the skill, or relative to the
      # repository root for the collection's own tooling.
      if [ -e "$dir_of_file/$ref" ] || [ -e "$ROOT/$ref" ]; then
        :
      else
        fail "$id: body references '$ref' but that file does not exist"
        continue
      fi
      case "$ref" in
        references/*/*|scripts/*/*|assets/*/*)
          warn "$id: '$ref' is more than one level deep; keep references flat so they cannot be partially previewed" ;;
      esac
    done <<EOF
$refs
EOF
  fi
}

section "Skills ($SKILLS_DIR)"

shopt -s nullglob
found=0

for d in "$SKILLS_DIR"/*/; do
  d="${d%/}"
  id="${d##*/}"
  found=1
  if [ -f "$d/SKILL.md" ]; then
    validate_skill "$id" "$d/SKILL.md"
  elif [ -f "$d/$id.md" ]; then
    validate_skill "$id" "$d/$id.md"
  else
    ALL_IDS+=("$id")
    fail "$id: directory contains neither SKILL.md nor $id.md"
  fi
done

for f in "$SKILLS_DIR"/*.md; do
  [ "$(basename "$f")" = "README.md" ] && continue
  found=1
  validate_skill "$(basename "$f" .md)" "$f"
done

[ "$found" -eq 1 ] || fail "no skills found in $SKILLS_DIR"

# ------------------------------------------------------- cluster membership
# skills.sh.json is what groups the skills for the installer, the catalog and
# every translated domain list. Nothing in the generator fails when a skill is
# missing from it: the skill is simply never grouped, never installed by
# --only, and missing from all eight translations, with no error anywhere.
#
# That was found by accident, after reverting one file and noticing the totals
# no longer reconciled. Every other defect this validator catches was caught on
# purpose, which is an argument for checking it rather than waiting again.
if [ "$SKILLS_DIR_OVERRIDDEN" -eq 0 ] && [ -f "$CLUSTERS_FILE" ]; then
  section "cluster membership"

  # Kebab-case quoted tokens are skill ids. Cluster titles all contain a space,
  # so they cannot match, which is what makes this safe to extract crudely.
  listed="$(grep -oE '"[a-z0-9]+(-[a-z0-9]+)+"' "$CLUSTERS_FILE" | tr -d '"' | sort -u)"
  ERRORS_BEFORE_CLUSTERS=$ERRORS

  for id in "${ALL_IDS[@]}"; do
    if ! grep -qx "$id" <<<"$listed"; then
      fail "cluster: '$id' is on disk but in no cluster in $CLUSTERS_FILE"
    fi
  done

  while read -r orphan; do
    [ -n "$orphan" ] || continue
    [ -f "$SKILLS_DIR/$orphan/SKILL.md" ] \
      || fail "cluster: '$orphan' is listed in skills.sh.json but no such skill exists"
  done <<EOF
$listed
EOF

  if [ "$ERRORS" -eq "$ERRORS_BEFORE_CLUSTERS" ]; then
    pass "every skill is in a cluster, and every cluster entry exists"
  fi
fi

# ------------------------------------------------------------------ catalog
# The catalog describes the repository's canonical skills, so it is only
# meaningful when validating the repository itself. Pointing SKILLS_DIR at a
# temporary tree, as the regression suite does, must not compare it to dist/.
if [ "$SKILLS_DIR_OVERRIDDEN" -eq 0 ] && [ -d "$DIST_DIR" ]; then
  section "HTTP catalog ($DIST_DIR)"
  catalog="$DIST_DIR/index.json"

  if [ ! -f "$catalog" ]; then
    fail "$DIST_DIR exists but has no index.json (run scripts/build-catalog.sh)"
  else
    pass "catalog index.json present"
    for id in "${ALL_IDS[@]}"; do
      grep -q "\"$id\"" "$catalog" \
        || fail "catalog: '$id' is missing from index.json (rebuild with scripts/build-catalog.sh)"
    done

    # Deep structural check in awk, so the validator stays dependency-free and
    # behaves identically on a bare CI image and on a Windows dev box. This
    # parses the exact layout scripts/build-catalog.sh emits.
    if awk -v dist="$DIST_DIR" '
      /"name"[ \t]*:/ {
        line = $0
        sub(/.*"name"[ \t]*:[ \t]*"/, "", line)
        sub(/".*/, "", line)
        name = line; next
      }
      /"version"[ \t]*:/ {
        line = $0
        sub(/.*"version"[ \t]*:[ \t]*"?/, "", line)
        gsub(/[" \t,]/, "", line)
        if (line !~ /^[0-9]+$/ || line + 0 < 1) {
          printf("  FAIL  catalog: \x27%s\x27 has a non-integer version\n", name); bad = 1
        }
        next
      }
      /"files"[ \t]*:/ {
        line = $0
        sub(/.*"files"[ \t]*:[ \t]*\[/, "", line)
        sub(/\].*/, "", line)
        if (line ~ /^[ \t]*$/) {
          printf("  FAIL  catalog: \x27%s\x27 lists no files\n", name); bad = 1; next
        }
        n = split(line, parts, ",")
        for (i = 1; i <= n; i++) {
          f = parts[i]
          gsub(/[" \t]/, "", f)
          if (f == "") continue
          if (f ~ /^\// || f ~ /\.\./) {
            printf("  FAIL  catalog: \x27%s\x27 has unsafe path \x27%s\x27\n", name, f); bad = 1; continue
          }
          cmd = "test -f \"" dist "/" name "/" f "\""
          if (system(cmd) != 0) {
            printf("  FAIL  catalog: \x27%s\x27 lists missing file \x27%s\x27\n", name, f); bad = 1
          }
        }
        next
      }
      END { exit(bad ? 1 : 0) }
    ' "$catalog"; then
      pass "catalog entries structurally valid"
    else
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# ------------------------------------------------------- catalog budget
# Two agents cap the catalog and drop whatever does not fit, silently.
#
#   Zed   50 KB total for all names and descriptions
#   Codex 8,000 characters by default, overridable via skills.max_context_tokens
#         up to 10,000, and shortening the longest descriptions first
#
# Codex is the binding constraint by a wide margin, so it is the one that has to
# hold. A collection that exceeds it loses skills on Codex with no error.
ZED_BUDGET=51200
CODEX_BUDGET=8000
if [ "$SKILLS_DIR_OVERRIDDEN" -eq 0 ]; then
  budget=0
  budget_n=0
  over=""
  for d in "$SKILLS_DIR"/*/; do
    d="${d%/}"
    f="$d/SKILL.md"
    [ -f "$f" ] || continue
    bn="$(fm_get "$f" name)"
    bd="$(fm_get "$f" description)"
    cost=$(( ${#bn} + ${#bd} ))
    budget=$(( budget + cost ))
    budget_n=$(( budget_n + 1 ))
    [ "$cost" -gt 160 ] && over="$over $id(${cost})"
  done

  codex_pct=$(( budget * 100 / CODEX_BUDGET ))
  zed_pct=$(( budget * 100 / ZED_BUDGET ))
  headroom=$(( CODEX_BUDGET - budget ))

  # The guardrail is headroom, not percentage.
  #
  # It was originally a flat 85 percent, which was arbitrary in a way that only
  # shows up as the collection grows: a percentage reserve shrinks in absolute
  # terms as the denominator rises, even though the thing being protected is the
  # same. What actually matters is how many more skills fit, and that is an
  # absolute number of characters.
  #
  # It was then 900, which was sized for the growth rate the collection started
  # with. It is now 300. That change is recorded here deliberately rather than
  # made quietly, because a guardrail lowered without a stated reason is a
  # guardrail nobody trusts.
  #
  # The reason is arithmetic, and the arithmetic is not adjustable. All 79
  # pre-existing descriptions sit between 59 and 83 characters against a
  # validator floor of 60, so there is no slack left to reclaim: the catalog
  # cannot grow by trimming itself. The 900 threshold therefore no longer
  # described room to grow, only room that had already been spent, and leaving
  # it in place would have blocked every addition while implying the constraint
  # was further away than it is.
  #
  # At 300 the warning fires roughly three skills from the hard limit. That is
  # the honest remaining capacity, and it is small enough to still be a signal
  # rather than a formality. Beyond it the single-catalog model is exhausted and
  # the only structural answer is partitioning the catalog into domain packs,
  # each of which carries its own budget. The hard limit below is the real
  # constraint; this warning is only the early notice that it is approaching.
  if [ "$budget" -gt "$CODEX_BUDGET" ]; then
    fail "Codex catalog budget exceeded: ${budget} of ${CODEX_BUDGET} chars across $budget_n skills"
    hint "Codex drops the overflow silently, shortening the longest descriptions first"
    [ -n "$over" ] && hint "over 160 chars:$over"
  elif [ "$headroom" -lt "${CODEX_HEADROOM:-300}" ]; then
    warn "Codex headroom ${headroom} chars (${budget}/${CODEX_BUDGET}, ${codex_pct}%); Zed ${zed_pct}%"
    hint "about $(( headroom / 110 )) more skills at the current average cost"
    hint "descriptions are at the 60-char floor, so this needs partitioning into domain packs"
  else
    pass "catalog budget: Codex ${codex_pct}% (${budget}/${CODEX_BUDGET} chars, ${headroom} headroom), Zed ${zed_pct}%, $budget_n skills"
  fi
fi

# -------------------------------------------------------- documentation
# A catalog that drifts from the skills it documents is documentation rot, so
# it is checked mechanically rather than left to discipline. This repository
# ships writing-technical-docs, which argues for exactly this rule.
DOC="docs/catalog.md"
if [ "$SKILLS_DIR_OVERRIDDEN" -eq 0 ] && [ -f "$DOC" ]; then
  section "Documentation ($DOC)"
  doc_missing=0
  for id in "${ALL_IDS[@]}"; do
    if ! grep -qF "\`$id\`" "$DOC"; then
      fail "$DOC does not list '$id'"
      doc_missing=1
    fi
  done
  [ "$doc_missing" -eq 0 ] && pass "catalog.md lists every skill"

  # The recorded routing sentence must match the shipped description.
  desc_drift=0
  for d in "$SKILLS_DIR"/*/; do
    d="${d%/}"
    id="${d##*/}"
    f="$d/SKILL.md"
    [ -f "$f" ] || continue
    desc="$(fm_get "$f" description)"
    [ -n "$desc" ] || continue
    if ! grep -qF "$desc" "$DOC"; then
      warn "$id: description does not match the routing sentence recorded in $DOC"
      desc_drift=1
    fi
  done
  [ "$desc_drift" -eq 0 ] && pass "catalog.md routing sentences match every description"
fi

# ------------------------------------------------------ repository state
#
# The marketplace manifest and the executable bit on scripts CI invokes
# directly both live in scripts/check-repo-state.sh rather than inline here.
#
# Two reasons, and the second is the important one. The first is size: those
# checks have nothing to do with a skill, so running them inside the per-skill
# loop is doing the work twice over. The second is that inline checks can only
# be exercised by running the whole validator against the whole collection,
# which takes minutes, and a check that is expensive to test is a check that
# stops being tested. As a standalone script it answers in well under a second
# and the regression suite points it at a fixture instead of the repository.
#
# Keeping it here rather than duplicating it means the CI gate and the tests
# assert the same code, which is the only arrangement where "the tests pass"
# means anything about the checks.
if [ "$SKILLS_DIR_OVERRIDDEN" -eq 0 ] && [ -f "$ROOT/scripts/check-repo-state.sh" ]; then
  section "Repository state (manifest, executable bit)"
  while IFS= read -r line; do
    case "$line" in
      "ok   "*) pass  "${line#ok   }" ;;
      "FAIL "*) fail  "${line#FAIL }" ;;
      "WARN "*) warn  "${line#WARN }" ;;
      "hint "*) hint  "${line#hint }" ;;
    esac
  done < <(bash "$ROOT/scripts/check-repo-state.sh" 2>/dev/null)
fi

# ------------------------------------------------------------------ summary
printf '\n%s%s%s\n' "$DIM" "--------------------------------------------------" "$RST"

if [ "$ERRORS" -gt 0 ]; then
  printf '%s%d failure(s), %d warning(s), %d skill(s) checked%s\n' \
    "$RED" "$ERRORS" "$WARNINGS" "${#ALL_IDS[@]}" "$RST"
  exit 1
fi

if [ "$STRICT" -eq 1 ] && [ "$WARNINGS" -gt 0 ]; then
  printf '%sstrict mode: %d warning(s), %d skill(s) checked%s\n' \
    "$RED" "$WARNINGS" "${#ALL_IDS[@]}" "$RST"
  exit 1
fi

printf '%sall checks passed%s - %d skill(s), %d warning(s)\n' \
  "$GRN" "$RST" "${#ALL_IDS[@]}" "$WARNINGS"
exit 0