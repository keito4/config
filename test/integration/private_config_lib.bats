#!/usr/bin/env bats

# Integration tests for script/lib/private_config.sh
#
# This library loads organization-specific secrets/config (org.env) and
# validates environment variable names before they are embedded into other
# scripts. It is security-sensitive (command-injection guard, no eval on
# untrusted file content) but had no test coverage.

load ../test_helper/test_helper

@test "private_config.sh script exists" {
  local script="${REPO_ROOT}/script/lib/private_config.sh"
  assert_file_exists "$script"
}

@test "private_config::org_env_path defaults to PRIVATE_CONFIG_DIR fallback under HOME" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  unset PRIVATE_CONFIG_DIR
  run private_config::org_env_path
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/develop/github.com/keito4/private-config/config/org.env" ]
}

@test "private_config::org_env_path respects PRIVATE_CONFIG_DIR override" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  export PRIVATE_CONFIG_DIR="${TEST_TEMP_DIR}/private-config"
  run private_config::org_env_path
  [ "$status" -eq 0 ]
  [ "$output" = "${TEST_TEMP_DIR}/private-config/config/org.env" ]
}

@test "private_config::load_org_env is a no-op when org.env does not exist" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  export PRIVATE_CONFIG_DIR="${TEST_TEMP_DIR}/missing"
  run private_config::load_org_env
  [ "$status" -eq 0 ]
}

@test "private_config::load_org_env exports KEY=VALUE lines and strips surrounding quotes" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  export PRIVATE_CONFIG_DIR="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${PRIVATE_CONFIG_DIR}/config"
  cat > "${PRIVATE_CONFIG_DIR}/config/org.env" <<'EOF'
# a comment line

ORG_NAME="acme"
ORG_PLAIN=example
EOF

  unset ORG_NAME ORG_PLAIN
  private_config::load_org_env

  [ "$ORG_NAME" = "acme" ]
  [ "$ORG_PLAIN" = "example" ]
}

@test "private_config::load_org_env does not overwrite a variable already set by the caller" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  export PRIVATE_CONFIG_DIR="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${PRIVATE_CONFIG_DIR}/config"
  cat > "${PRIVATE_CONFIG_DIR}/config/org.env" <<'EOF'
ORG_NAME="from-file"
EOF

  export ORG_NAME="from-caller"
  private_config::load_org_env

  [ "$ORG_NAME" = "from-caller" ]
}

@test "private_config::load_org_env ignores malformed lines without executing them" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  export PRIVATE_CONFIG_DIR="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${PRIVATE_CONFIG_DIR}/config"
  local marker="${TEST_TEMP_DIR}/pwned"
  cat > "${PRIVATE_CONFIG_DIR}/config/org.env" <<EOF
not a valid line
ORG_PAYLOAD=\$(touch ${marker})
EOF

  unset ORG_PAYLOAD
  private_config::load_org_env

  # The value must be stored literally (no eval/command substitution).
  [ "$ORG_PAYLOAD" = '$(touch '"${marker}"')' ]
  [ ! -e "$marker" ]
}

@test "private_config::assert_env_name accepts a valid uppercase identifier" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  run private_config::assert_env_name "SOME_LABEL" "SENTRY_MCP_TOKEN_ENV"
  [ "$status" -eq 0 ]
}

@test "private_config::assert_env_name rejects an invalid name and exits non-zero" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  run private_config::assert_env_name "SOME_LABEL" '$(rm -rf /tmp/x)'
  [ "$status" -ne 0 ]
  [[ "$output" == *"SOME_LABEL"* ]]
}

@test "private_config::list_contains matches case-insensitively" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  run private_config::list_contains "Acme Globex initech" "GLOBEX"
  [ "$status" -eq 0 ]
}

@test "private_config::list_contains fails when item is absent" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  run private_config::list_contains "acme globex" "initech"
  [ "$status" -ne 0 ]
}

@test "private_config::list_contains fails for an empty needle" {
  source "${REPO_ROOT}/script/lib/private_config.sh"

  run private_config::list_contains "acme globex" ""
  [ "$status" -ne 0 ]
}
