#!/usr/bin/env bats

load ../test_helper/test_helper

extract_mcp_env_vars() {
  {
    grep -Eoh '\$\{[A-Z0-9_]+\}' \
      "$REPO_ROOT/.codex/config.toml" \
      "$REPO_ROOT/.gemini/settings.json" || true
    sed -nE 's/.*bearer_token_env_var = "([A-Z0-9_]+)".*/\1/p' \
      "$REPO_ROOT/.codex/config.toml"
    sed -nE 's/.*env_vars = \[([^]]+)\].*/\1/p' \
      "$REPO_ROOT/.codex/config.toml" |
      tr ',' '\n' |
      tr -d ' "'
  } |
    sed -E 's/^\$\{([^}]+)\}$/\1/' |
    grep -E '^[A-Z0-9_]+$' |
    sort -u
}

@test "MCP credential template covers configured and documented environment variables" {
  # テンプレート（op:// の vault/item 名を含む）は keito4/private-config で管理する。
  # CI など private-config が無い環境ではスキップし、ローカルでのみ整合性を検証する。
  local templates_dir="${CREDENTIALS_TEMPLATES_DIR:-$HOME/develop/github.com/keito4/private-config/credentials/templates}"
  local template="$templates_dir/mcp.env.template"
  local readme="$REPO_ROOT/credentials/README.md"
  local referenced_vars
  local optional_vars=(N8N_API_URL N8N_API_KEY)
  local var

  if [ ! -f "$template" ]; then
    skip "credentials templates are managed in keito4/private-config (not available here)"
  fi
  assert_file_exists "$readme"
  ! grep -q "setup-env.sh\\|setup-mcp.sh" "$template"

  referenced_vars="$(extract_mcp_env_vars)"
  [ -n "$referenced_vars" ]

  while IFS= read -r var; do
    grep -q "^${var}=op://Dev/" "$template"
    grep -q "$var" "$readme"
  done <<< "$referenced_vars"

  for var in "${optional_vars[@]}"; do
    grep -q "^${var}=op://Dev/" "$template"
    grep -q "$var" "$readme"
  done
}
