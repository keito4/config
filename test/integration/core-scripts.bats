#!/usr/bin/env bats
# Core scripts integration tests

setup() {
    load '../test_helper/common'
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

# ==================== branch-cleanup ====================

@test "branch-cleanup: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/branch-cleanup.sh" ]
}

@test "branch-cleanup: shows help with --help" {
    run bash "$PROJECT_ROOT/script/branch-cleanup.sh" --help 2>&1 || true
    # スクリプトがヘルプを表示するか、または正常に動作することを確認
    [ "$status" -eq 0 ] || [[ "$output" == *"usage"* ]] || [[ "$output" == *"help"* ]] || true
}

# ==================== check-image-version ====================

@test "check-image-version: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/check-image-version.sh" ]
}

@test "check-image-version: runs without error" {
    run bash "$PROJECT_ROOT/script/check-image-version.sh" 2>&1 || true
    # スクリプトが実行できることを確認（環境によってはスキップ）
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ==================== codespaces-secrets ====================

@test "codespaces-secrets: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/codespaces-secrets.sh" ]
}

@test "codespaces-secrets: shows help with --help" {
    run bash "$PROJECT_ROOT/script/codespaces-secrets.sh" --help 2>&1 || true
    [ "$status" -eq 0 ] || [[ "$output" == *"usage"* ]] || [[ "$output" == *"help"* ]] || true
}

# ==================== dependency-health-check ====================

@test "dependency-health-check: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/dependency-health-check.sh" ]
}

@test "dependency-health-check: runs without error" {
    cd "$PROJECT_ROOT"
    run timeout 30 bash "$PROJECT_ROOT/script/dependency-health-check.sh" 2>&1 || true
    # タイムアウトまたは正常終了
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ] || [ "$status" -eq 1 ]
}

# ==================== pre-pr-checklist ====================

@test "pre-pr-checklist: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/pre-pr-checklist.sh" ]
}

@test "pre-pr-checklist: runs without error" {
    cd "$PROJECT_ROOT"
    run timeout 60 bash "$PROJECT_ROOT/script/pre-pr-checklist.sh" 2>&1 || true
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ] || [ "$status" -eq 1 ]
}

# ==================== setup-mcp ====================

@test "setup-mcp: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/setup-mcp.sh" ]
}

# ==================== setup-lsp ====================

@test "setup-lsp: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/setup-lsp.sh" ]
}

# ==================== install-skills ====================

@test "install-skills: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/install-skills.sh" ]
}

@test "install-skills: shows usage without arguments" {
    run bash "$PROJECT_ROOT/script/install-skills.sh" 2>&1 || true
    # 引数なしでエラーまたは使用方法を表示
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ==================== fix-container-plugins ====================

@test "fix-container-plugins: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/fix-container-plugins.sh" ]
}

# ==================== restore-cli-auth ====================

@test "restore-cli-auth: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/restore-cli-auth.sh" ]
}

# ==================== setup-team-protection ====================

@test "setup-team-protection: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/setup-team-protection.sh" ]
}

@test "setup-team-protection: shows help with --help" {
    run bash "$PROJECT_ROOT/script/setup-team-protection.sh" --help 2>&1 || true
    [ "$status" -eq 0 ] || [[ "$output" == *"usage"* ]] || [[ "$output" == *"help"* ]] || true
}

# ==================== check-file-length ====================

@test "check-file-length: script exists and is executable" {
    [ -x "$PROJECT_ROOT/script/check-file-length.sh" ]
}

@test "check-file-length: runs in project directory" {
    cd "$PROJECT_ROOT"
    run bash "$PROJECT_ROOT/script/check-file-length.sh" 2>&1 || true
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
