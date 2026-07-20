#!/usr/bin/env bats

# Integration tests for script/credentials/providers/op.sh
#
# This is the security-sensitive credential injection path used by
# script/credentials.sh, but had no test coverage.

load ../test_helper/test_helper

@test "op.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/credentials/providers/op.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "credential_provider::name returns 1password" {
  source "${REPO_ROOT}/script/credentials/providers/op.sh"

  run credential_provider::name
  [ "$status" -eq 0 ]
  [ "$output" = "1password" ]
}

@test "credential_provider::ensure_ready fails with guidance when op CLI is missing" {
  source "${REPO_ROOT}/script/credentials/providers/op.sh"

  # Force `command -v op` to fail regardless of the host environment, then
  # restore PATH so teardown's `rm -rf` keeps working.
  local original_path="$PATH"
  export PATH="${TEST_TEMP_DIR}"
  run credential_provider::ensure_ready
  export PATH="$original_path"

  [ "$status" -ne 0 ]
  [[ "$output" == *"1Password CLI (op) is not installed"* ]]
}

@test "credential_provider::ensure_ready fails with guidance when not signed in" {
  source "${REPO_ROOT}/script/credentials/providers/op.sh"

  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/op" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "account" ] && [ "$2" = "list" ]; then
  exit 1
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/op"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"

  run credential_provider::ensure_ready
  [ "$status" -ne 0 ]
  [[ "$output" == *"Not signed in to 1Password"* ]]
}

@test "credential_provider::ensure_ready succeeds when op is installed and signed in" {
  source "${REPO_ROOT}/script/credentials/providers/op.sh"

  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/op" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/op"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"

  run credential_provider::ensure_ready
  [ "$status" -eq 0 ]
}

@test "credential_provider::inject calls op inject with the given template and output" {
  source "${REPO_ROOT}/script/credentials/providers/op.sh"

  mkdir -p "${TEST_TEMP_DIR}/bin"
  local log="${TEST_TEMP_DIR}/op-calls.log"
  cat > "${TEST_TEMP_DIR}/bin/op" <<EOF
#!/usr/bin/env bash
echo "\$@" >> "${log}"
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/op"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"

  credential_provider::inject "template.env" "output.env"

  [ -f "$log" ]
  grep -q -- "inject --in-file template.env --out-file output.env" "$log"
}
