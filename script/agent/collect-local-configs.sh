#!/usr/bin/env bash
# Inventory local/secret-looking config files without reading their contents.

set -euo pipefail

ROOTS=()
CONTEXT_DIR="${CONTEXT_DIR:-.context}"
OUTPUT=""

usage() {
  cat <<'EOF'
Usage: script/agent/collect-local-configs.sh [--root DIR ...] [--output FILE]

Collects paths, size, and mtime for local config candidates such as
config.local.json, settings.local.json, .env.local, auth.json, and
credentials-like JSON files.

The report intentionally does not copy or print file contents.

When --root is omitted, the scan is limited to common configuration locations
instead of walking the entire home directory.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOTS+=("${2:?--root requires a value}")
      shift 2
      ;;
    --output)
      OUTPUT="${2:?--output requires a value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$OUTPUT" ]]; then
  OUTPUT="$CONTEXT_DIR/local-config-candidates.tsv"
fi

if [[ "${#ROOTS[@]}" -eq 0 ]]; then
  ROOTS=(
    "$HOME/.config"
    "$HOME/.claude"
    "$HOME/.codex"
    "$HOME/Library/Application Support/Code/User"
    "$HOME/Library/Application Support/Cursor/User"
    "$HOME/develop"
  )
fi

mkdir -p "$(dirname "$OUTPUT")"

classify_path() {
  local path="${1:?path required}"
  local base
  base="$(basename "$path")"

  case "$base" in
    config.local.json|settings.local.json|*.local.json|*.local.jsonc)
      printf 'local-json'
      ;;
    *.local.toml)
      printf 'local-toml'
      ;;
    *.local.yaml|*.local.yml)
      printf 'local-yaml'
      ;;
    .env.local|*.env.local|*.local.env)
      printf 'local-env'
      ;;
    auth.json|hosts.yml|credentials.json|*credentials*.json|secret.json|secrets.json|*.secret.json|*.secrets.json)
      printf 'auth-or-secret-candidate'
      ;;
    *credential*.json)
      printf 'auth-or-secret-candidate'
      ;;
    token.json|tokens.json|*.token.json|*.tokens.json|*auth-token*.json|*auth_token*.json|*access-token*.json|*access_token*.json|*refresh-token*.json|*refresh_token*.json|*api-token*.json|*api_token*.json)
      printf 'auth-or-secret-candidate'
      ;;
    *)
      printf 'local-config-candidate'
      ;;
  esac
}

file_size() {
  local path="${1:?path required}"
  stat -f '%z' "$path" 2>/dev/null || stat -c '%s' "$path"
}

file_mtime() {
  local path="${1:?path required}"
  stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%S%z' "$path" 2>/dev/null || stat -c '%y' "$path"
}

printf 'category\tbytes\tmtime\tpath\n' >"$OUTPUT"

for root in "${ROOTS[@]}"; do
  [[ -d "$root" ]] || continue

  while IFS= read -r -d '' path; do
    category="$(classify_path "$path")"
    bytes="$(file_size "$path")"
    mtime="$(file_mtime "$path")"
    printf '%s\t%s\t%s\t%s\n' "$category" "$bytes" "$mtime" "$path" >>"$OUTPUT"
  done < <(
    find "$root" \
      \( \
        -name .git -o \
        -name .context -o \
        -name .next -o \
        -name .terraform -o \
        -name .terragrunt-cache -o \
        -name .turbo -o \
        -name .vercel -o \
        -name .venv -o \
        -name __pycache__ -o \
        -name checkpoints -o \
        -path "$HOME/.claude/cache" -o \
        -path "$HOME/.claude/plugins/cache" -o \
        -path "$HOME/.claude/plugins/marketplaces" -o \
        -path "$HOME/.claude/sessions" -o \
        -path "$HOME/.claude/telemetry" -o \
        -path "$HOME/.codex/cache" -o \
        -path "$HOME/.codex/log" -o \
        -path "$HOME/.codex/logs" -o \
        -path "$HOME/.codex/memories" -o \
        -path "$HOME/.codex/sessions" -o \
        -path "$HOME/.codex/tmp" -o \
        -name node_modules -o \
        -name venv -o \
        -name vendor -o \
        -path '*/globalStorage' -o \
        -path '*/workspaceStorage' \
      \) -prune -o \
      -type f \
      \( \
        -name 'config.local.json' -o \
        -name 'settings.local.json' -o \
        -name '*.local.json' -o \
        -name '*.local.jsonc' -o \
        -name '*.local.toml' -o \
        -name '*.local.yaml' -o \
        -name '*.local.yml' -o \
        -name '.env.local' -o \
        -name '*.env.local' -o \
        -name '*.local.env' -o \
        -name 'auth.json' -o \
        -name 'hosts.yml' -o \
        -name 'credentials.json' -o \
        -name '*credentials*.json' -o \
        -name '*credential*.json' -o \
        -name 'secret.json' -o \
        -name 'secrets.json' -o \
        -name '*.secret.json' -o \
        -name '*.secrets.json' -o \
        -name 'token.json' -o \
        -name 'tokens.json' -o \
        -name '*.token.json' -o \
        -name '*.tokens.json' -o \
        -name '*auth-token*.json' -o \
        -name '*auth_token*.json' -o \
        -name '*access-token*.json' -o \
        -name '*access_token*.json' -o \
        -name '*refresh-token*.json' -o \
        -name '*refresh_token*.json' -o \
        -name '*api-token*.json' -o \
        -name '*api_token*.json' \
      \) -print0 2>/dev/null
  )
done

printf 'Wrote %s\n' "$OUTPUT"
