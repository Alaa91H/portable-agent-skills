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
    -h|--help) sed -n '2,17p' "$0" | sed 's/^#\{1,\} \{0,\\}//'; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SKILLS_DIR="${SKILLS_DIR:-.opencode/skills}"
DIST_DIR="${DIST_DIR:-dist}"

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
  if ! printf '%s' "$id" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
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
    if printf '%s' "$name" | grep -Eq '^-|-\$'; then
      fail "$id: name must not start or end with a hyphen"
    fi
    if printf '%s' "$name" | grep -q -- '--'; then
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
    if printf '%s' "$desc" | grep -qiE '<[a-zA-Z/][^>]*>'; then
      warn "$id: description contains XML-like tags, which are rejected on skill upload"
      desc_clean=0
    fi
    if ! printf '%s' "$desc" | grep -qiE 'use (this )?(skill )?when|trigger|use when|invoke when'; then
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
    lines="$(printf '%s\n' "$body" | grep -c '')"
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
  if printf '%s' "$body" | grep -q '\\'; then
    warn "$id": body contains backslashes; reference files with forward slashes only
  fi

  refs="$(grep -oE '(references|scripts|assets)/[A-Za-z0-9._/-]+' "$file" 2>/dev/null | sed 's/[.,;:)]*$//' | LC_ALL=C sort -u)"
  if [ -n "$refs" ]; then
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      if [ ! -e "$dir_of_file/$ref" ]; then
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

# ------------------------------------------------------------------ catalog
if [ -d "$DIST_DIR" ]; then
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

    if command -v python3 >/dev/null 2>&1; then
      python3 - "$catalog" "$DIST_DIR" <<'PY' || true
import json, os, sys
catalog, dist = sys.argv[1], sys.argv[2]
with open(catalog, encoding="utf-8") as fh:
    data = json.load(fh)
R, F = "\033[31m", "\033[0m"
bad = 0
for entry in data.get("skills", []):
    name = entry.get("name", "<unnamed>")
    version = str(entry.get("version", ""))
    files = entry.get("files", [])
    if not version.isdigit() or int(version) < 1:
        print(f"  {R}FAIL{R}  catalog: '{name}' has non-integer version {version!r}")
        bad += 1
    if not files:
        print(f"  {R}FAIL{R}  catalog: '{name}' lists no files")
        bad += 1
    for rel in files:
        if os.path.isabs(rel) or ".." in rel.split("/"):
            print(f"  {R}FAIL{R}  catalog: '{name}' has unsafe path {rel!r}")
            bad += 1
        elif not os.path.isfile(os.path.join(dist, name, rel)):
            print(f"  {R}FAIL{R}  catalog: '{name}' lists missing file {rel!r}")
            bad += 1
print(f"  \033[32mok\033[0m    catalog entries structurally valid" if not bad else "")
sys.exit(1 if bad else 0)
PY
    else
      pass "skipping deep catalog check (python3 unavailable)"
    fi
  fi
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