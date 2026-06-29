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
  local template="$REPO_ROOT/credentials/templates/mcp.env.template"
  local readme="$REPO_ROOT/credentials/README.md"
  local referenced_vars
  local optional_vars=(
    N8N_API_URL
    N8N_API_KEY
    ELU_SENTRY_TOKEN
    GEMINI_API_KEY
    ELU_NOTION_API_KEY
    OYKOT_NOTION_API_KEY
    GITHUB_TOKEN
    NODE_AUTH_TOKEN
  )
  local var

  assert_file_exists "$template"
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

  ! grep -q "^OP_SERVICE_ACCOUNT_TOKEN=" "$template"
  grep -q "OP_SERVICE_ACCOUNT_TOKEN" "$readme"
}
