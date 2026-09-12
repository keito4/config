#!/usr/bin/env bats

# Integration tests for update-claude-code.sh script
#
# get_latest_version()/claude update の呼び出しはネットワークと claude CLI に
# 依存するため直接は実行しない。代わりに、副作用のない純粋なロジック
# (バージョン抽出・Dockerfile 更新判定) を同じ実装で複製した一時スクリプトで検証する。
# これは update-actions.bats / update-libraries.bats と同じ手法。

load ../test_helper/test_helper

@test "update-claude-code.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/update-claude-code.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "update-claude-code.sh has proper error handling with set -euo pipefail" {
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/update-claude-code.sh"
}

@test "update-claude-code.sh sources lib/output.sh for log helpers" {
  grep -q 'source "\$SCRIPT_DIR/lib/output.sh"' "${REPO_ROOT}/script/update-claude-code.sh"
}

@test "update-claude-code.sh derives DOCKERFILE from PROJECT_ROOT" {
  grep -q 'DOCKERFILE="\${PROJECT_ROOT}/.devcontainer/Dockerfile"' "${REPO_ROOT}/script/update-claude-code.sh"
}

@test "update-claude-code.sh falls back to Dockerfile-only update when claude CLI is missing" {
  grep -q 'command -v claude' "${REPO_ROOT}/script/update-claude-code.sh"
  grep -q 'Claude CLI が見つかりません' "${REPO_ROOT}/script/update-claude-code.sh"
}

@test "get_dockerfile_version extracts the version pinned on the install.sh line" {
  local dockerfile="${TEST_TEMP_DIR}/Dockerfile"
  cat > "$dockerfile" << 'EOF'
FROM ubuntu:24.04
RUN curl -fsSL https://claude.ai/install.sh | bash -s 2.1.3
EOF

  local test_script="${TEST_TEMP_DIR}/get-version.sh"
  cat > "$test_script" << EOF
#!/usr/bin/env bash
set -euo pipefail
DOCKERFILE="${dockerfile}"
get_dockerfile_version() {
    grep "claude.ai/install.sh" "\${DOCKERFILE}" | grep -o 'bash -s [0-9.]*' | cut -d' ' -f3
}
get_dockerfile_version
EOF
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  [ "$output" = "2.1.3" ]
}

@test "update_dockerfile_version rewrites only the install.sh line when the version changed" {
  local dockerfile="${TEST_TEMP_DIR}/Dockerfile"
  cat > "$dockerfile" << 'EOF'
FROM ubuntu:24.04
ENV SOME_OTHER_VERSION=2.1.3
RUN curl -fsSL https://claude.ai/install.sh | bash -s 2.1.3
EOF

  local test_script="${TEST_TEMP_DIR}/update-version.sh"
  cat > "$test_script" << EOF
#!/usr/bin/env bash
set -euo pipefail
DOCKERFILE="${dockerfile}"
log_info() { :; }
log_success() { :; }
get_dockerfile_version() {
    grep "claude.ai/install.sh" "\${DOCKERFILE}" | grep -o 'bash -s [0-9.]*' | cut -d' ' -f3
}
update_dockerfile_version() {
    local new_version="\$1"
    local current_version
    current_version=\$(get_dockerfile_version)

    if [[ "\${current_version}" == "\${new_version}" ]]; then
        log_info "Dockerfile は既に最新バージョンです (\${current_version})"
        return 1
    fi

    sed -i "/claude.ai\/install.sh/s|bash -s \${current_version}|bash -s \${new_version}|" "\${DOCKERFILE}"
    log_success "Dockerfile を \${current_version} → \${new_version} に更新しました"
    return 0
}
update_dockerfile_version "2.2.0"
EOF
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  grep -q 'bash -s 2.2.0' "$dockerfile"
  # 無関係な行 (同じバージョン文字列を含む ENV) は書き換えられない
  grep -q 'SOME_OTHER_VERSION=2.1.3' "$dockerfile"
}

@test "update_dockerfile_version is a no-op and returns 1 when already up to date" {
  local dockerfile="${TEST_TEMP_DIR}/Dockerfile"
  cat > "$dockerfile" << 'EOF'
FROM ubuntu:24.04
RUN curl -fsSL https://claude.ai/install.sh | bash -s 2.1.3
EOF

  local test_script="${TEST_TEMP_DIR}/update-version-noop.sh"
  cat > "$test_script" << EOF
#!/usr/bin/env bash
set -euo pipefail
DOCKERFILE="${dockerfile}"
log_info() { :; }
log_success() { :; }
get_dockerfile_version() {
    grep "claude.ai/install.sh" "\${DOCKERFILE}" | grep -o 'bash -s [0-9.]*' | cut -d' ' -f3
}
update_dockerfile_version() {
    local new_version="\$1"
    local current_version
    current_version=\$(get_dockerfile_version)

    if [[ "\${current_version}" == "\${new_version}" ]]; then
        log_info "Dockerfile は既に最新バージョンです (\${current_version})"
        return 1
    fi

    sed -i "/claude.ai\/install.sh/s|bash -s \${current_version}|bash -s \${new_version}|" "\${DOCKERFILE}"
    log_success "Dockerfile を \${current_version} → \${new_version} に更新しました"
    return 0
}
update_dockerfile_version "2.1.3"
EOF
  chmod +x "$test_script"

  run "$test_script"
  [ "$status" -eq 1 ]
  grep -q 'bash -s 2.1.3' "$dockerfile"
}
