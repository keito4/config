#!/usr/bin/env bash
#
# AGENTS.md の自動生成セクションをリポジトリの現在の状態から再生成する。
# <!-- BEGIN AUTO-GENERATED --> 〜 <!-- END AUTO-GENERATED --> 間を置換。
#
# Usage: bash script/update-agents-md.sh [--check]
#   --check: 差分確認のみ。差分があれば exit 1。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=script/lib/agents-md-data.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/agents-md-data.sh"

AGENTS_MD="AGENTS.md"
TEMPLATE="$SCRIPT_DIR/lib/agents-md-template.md"
CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

if [[ ! -f "$AGENTS_MD" ]] || ! grep -q "BEGIN AUTO-GENERATED" "$AGENTS_MD"; then
  echo "skip: $AGENTS_MD missing AUTO-GENERATED markers"
  exit 0
fi

emit() {
  local -n out_ref=$1
  shift
  local IFS=$'\x1f'
  local joined="$*"
  out_ref+="| ${joined//$'\x1f'/ | } |"$'\n'
}

detect_pm() {
  local entry
  # bun > yarn > pnpm > npm (matches original precedence)
  for entry in "bun.lockb:bun" "bun.lock:bun" "yarn.lock:yarn" "pnpm-lock.yaml:pnpm"; do
    [[ -f "${entry%%:*}" ]] && { echo "${entry##*:}"; return; }
  done
  echo "npm"
}

# shellcheck disable=SC2034 # NODE_VER / PM consumed by template via eval
NODE_VER=$(jq -r '.engines.node // empty' package.json 2>/dev/null)
# shellcheck disable=SC2034
PM=$(detect_pm)
HAS_NIX=false
[[ -f "nix/flake.nix" ]] && HAS_NIX=true

table_header() {
  # shellcheck disable=SC2034 # nameref consumed by emit's local -n
  local -n hdr_ref=$1
  shift
  emit hdr_ref "$@"
  local -i n=$#
  local args=()
  while ((n--)); do args+=("---"); done
  emit hdr_ref "${args[@]}"
}

collect_dirs() {
  local out=""
  table_header out "Directory" "Purpose"
  local d name purpose sub wf_count
  for d in .*/; do
    [[ "$d" == "./" || "$d" == "../" ]] && continue
    name="${d%/}"
    [[ "$name" == .git || "$name" == .git-* ]] && continue

    if [[ "$name" == ".claude" ]]; then
      for sub in "${CLAUDE_SUB_ORDER[@]}"; do
        [[ -d ".claude/$sub" ]] && emit out "\`.claude/$sub/\`" "${CLAUDE_SUB_PURPOSE[$sub]}"
      done
      continue
    fi
    if [[ "$name" == ".github" ]]; then
      wf_count=$(find .github/workflows -maxdepth 1 -name '*.yml' 2>/dev/null | wc -l | tr -d ' ')
      emit out "\`.github/workflows/\`" "GitHub Actions CI/CD workflows ($wf_count workflows)"
      continue
    fi
    purpose="${DOT_DIR_PURPOSE[$name]:-}"
    [[ -n "$purpose" ]] && emit out "\`$name/\`" "$purpose"
  done
  for d in */; do
    name="${d%/}"
    [[ "$REG_DIR_SKIP" == *" $name "* ]] && continue
    purpose="${REG_DIR_PURPOSE[$name]:-$name}"
    emit out "\`$name/\`" "$purpose"
  done
  echo -n "$out"
}

_extract_desc() {
  # Extracts description from a Markdown file.
  # Handles two formats:
  #   1. YAML frontmatter: --- / description: <value> / ---
  #   2. Heading paragraph: # Title\n\n<first paragraph>
  #   3. Plain text: first non-empty line
  awk '
    BEGIN { in_fm=0; found_fm=0; past_h=0 }
    /^---$/ {
      if (!found_fm) {
        if (!in_fm) { in_fm=1 } else { in_fm=0; found_fm=1 }
        next
      }
    }
    in_fm && /^description:/ { sub(/^description:[[:space:]]*/, ""); print; exit }
    !in_fm && /^#/ { past_h=1; next }
    !in_fm && (past_h || found_fm) && /^[[:space:]]*$/ { next }
    !in_fm && NF { print; exit }
  ' "$1"
}

collect_commands() {
  local out=""
  table_header out "Command" "Description"
  local cmd base desc
  for cmd in .claude/commands/*.md; do
    [[ ! -f "$cmd" ]] && continue
    base=$(basename "$cmd" .md)
    [[ "$base" == "README" ]] && continue
    desc=$(_extract_desc "$cmd")
    emit out "\`/$base\`" "${desc:-(no description)}"
  done
  echo -n "$out"
}

_truncate_desc() {
  # Strips HTML/example noise and truncates to first sentence or 100 chars.
  local raw="$1"
  # Strip <example>...</example> and anything after <
  raw="${raw%%<*}"
  raw="${raw%"${raw##*[! ]}"}" # rtrim
  # Truncate at first ". " boundary, keeping the period
  if [[ "$raw" == *". "* ]]; then
    raw="${raw%%". "*}."
  fi
  # Hard cap at 100 chars
  if [[ ${#raw} -gt 100 ]]; then
    raw="${raw:0:97}..."
  fi
  echo -n "$raw"
}

collect_agents() {
  [[ ! -d ".claude/agents" ]] && return 0
  local out=""
  table_header out "Agent" "Description"
  local f base desc
  for f in .claude/agents/*.md; do
    [[ ! -f "$f" ]] && continue
    base=$(basename "$f" .md)
    [[ "$base" == "README" ]] && continue
    desc=$(_truncate_desc "$(_extract_desc "$f")")
    emit out "\`$base\`" "${desc:-(no description)}"
  done
  echo -n "$out"
}

collect_skills() {
  [[ ! -d ".claude/skills" ]] && return 0
  local out=""
  table_header out "Skill" "Description"
  local f base desc
  for f in .claude/skills/*.md; do
    [[ ! -f "$f" ]] && continue
    base=$(basename "$f" .md)
    [[ "$base" == "README" ]] && continue
    desc=$(_truncate_desc "$(_extract_desc "$f")")
    emit out "\`$base\`" "${desc:-(no description)}"
  done
  echo -n "$out"
}

collect_workflows() {
  local out=""
  table_header out "Workflow" "Purpose"
  local wf base name
  for wf in .github/workflows/*.yml; do
    [[ ! -f "$wf" ]] && continue
    base=$(basename "$wf")
    name=$(grep -m1 '^name:' "$wf" | sed 's/^name: *//' | tr -d "'\"")
    emit out "\`$base\`" "${name:-(unnamed)}"
  done
  echo -n "$out"
}

collect_quality_gates() {
  local out=""
  table_header out "Script" "Command" "Purpose"
  local key val
  for key in "${QG_ORDER[@]}"; do
    val=$(jq -r --arg k "$key" '.scripts[$k] // empty' package.json 2>/dev/null)
    [[ -n "$val" ]] && emit out "\`$key\`" "\`$val\`" "${QG_PURPOSE[$key]}"
  done
  echo -n "$out"
}

collect_extra_tests_line() {
  local key val parts="" var label
  for key in "test:integration" "test:coverage" "test:all"; do
    val=$(jq -r --arg k "$key" '.scripts[$k] // empty' package.json 2>/dev/null)
    [[ -z "$val" ]] && continue
    var="EXTRA_TEST_LABEL_${key//:/_}"
    label="${!var:-}"
    parts+=" \`$key\` $label,"
  done
  [[ -z "$parts" ]] && return 0
  echo -n "Additional test commands:${parts%,}"
}

collect_hooks() {
  local out=""
  table_header out "Hook" "Trigger" "Purpose"
  local hook base trigger purpose entry parts
  declare -A trig pur
  for entry in "${HOOK_TABLE[@]}"; do
    IFS='|' read -ra parts <<<"$entry"
    trig[${parts[0]}]=${parts[1]}
    pur[${parts[0]}]=${parts[2]}
  done
  for hook in .claude/hooks/*.py; do
    [[ ! -f "$hook" ]] && continue
    base=$(basename "$hook")
    trigger="${trig[$base]:-Unknown}"
    purpose="${pur[$base]:-${base%.py}}"
    emit out "\`$base\`" "$trigger" "$purpose"
  done
  echo -n "$out"
}

# Build content from template via envsubst.
# Variables exported below are consumed by envsubst; shellcheck cannot trace them.
render_template() {
  local nix_line=""
  [[ "$HAS_NIX" == "true" ]] && nix_line=$'\n'"- **macOS Environment**: nix-darwin + home-manager (\`nix/flake.nix\`)"
  export NODE_VER PM
  export DIRS=""
  export COMMANDS=""
  export AGENTS=""
  export SKILLS=""
  export WORKFLOWS=""
  export QUALITY_GATES=""
  export HOOKS=""
  export EXTRA_LINE=""
  export NIX_LINE="$nix_line"
  DIRS=$(collect_dirs)
  COMMANDS=$(collect_commands)
  AGENTS=$(collect_agents)
  SKILLS=$(collect_skills)
  WORKFLOWS=$(collect_workflows)
  QUALITY_GATES=$(collect_quality_gates)
  HOOKS=$(collect_hooks)
  EXTRA_LINE=$(collect_extra_tests_line)
  # shellcheck disable=SC2016 # envsubst takes a literal allowlist of variable names
  envsubst '${NODE_VER} ${PM} ${DIRS} ${COMMANDS} ${AGENTS} ${SKILLS} ${WORKFLOWS} ${QUALITY_GATES} ${HOOKS} ${EXTRA_LINE} ${NIX_LINE}' <"$TEMPLATE"
}

build_full_content() {
  local head tail body
  head=$(sed '/<!-- BEGIN AUTO-GENERATED -->/q' "$AGENTS_MD")
  tail=$(sed -n '/<!-- END AUTO-GENERATED -->/,$p' "$AGENTS_MD")
  body=$(render_template)
  printf '%s\n%s\n\n%s' "$head" "$body" "$tail"
}

write_target() {
  local target=$1 content
  content=$(build_full_content)
  printf '%s\n' "$content" > "$target"
  if command -v npx >/dev/null 2>&1; then
    npx prettier --write "$target" >/dev/null 2>&1 || true
  fi
}

if $CHECK_ONLY; then
  # Use system tempdir: .context/ is in .prettierignore, which would skip our format step.
  # Append .md so prettier picks the markdown parser.
  TMPDIR_BASE=$(mktemp -d -t agents-md-check.XXXXXXXXXX)
  TMPFILE="$TMPDIR_BASE/AGENTS.md"
  trap 'rm -rf "$TMPDIR_BASE"' EXIT
  write_target "$TMPFILE"
  if ! diff -q "$AGENTS_MD" "$TMPFILE" >/dev/null 2>&1; then
    echo "warning: AGENTS.md auto-generated section is out of date"
    diff "$AGENTS_MD" "$TMPFILE" | head -30
    exit 1
  fi
  echo "ok: AGENTS.md auto-generated section is up to date"
  exit 0
fi

write_target "$AGENTS_MD"
echo "updated: AGENTS.md auto-generated section"
