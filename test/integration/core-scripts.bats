#!/usr/bin/env bats
# Core scripts integration tests
# These tests verify that scripts exist and are executable

load ../test_helper/test_helper

# ==================== Script Existence Tests ====================

@test "branch-cleanup.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/branch-cleanup.sh"
    [ -x "$REPO_ROOT/script/branch-cleanup.sh" ]
}

@test "audit-references.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/audit-references.sh"
    [ -x "$REPO_ROOT/script/audit-references.sh" ]
}

@test "check-image-version.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/check-image-version.sh"
    [ -x "$REPO_ROOT/script/check-image-version.sh" ]
}

@test "codespaces-secrets.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/codespaces-secrets.sh"
    [ -x "$REPO_ROOT/script/codespaces-secrets.sh" ]
}

@test "dependency-health-check.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/dependency-health-check.sh"
    [ -x "$REPO_ROOT/script/dependency-health-check.sh" ]
}

@test "pre-pr-checklist.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/pre-pr-checklist.sh"
    [ -x "$REPO_ROOT/script/pre-pr-checklist.sh" ]
}

@test "setup-lsp.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-lsp.sh"
    [ -x "$REPO_ROOT/script/setup-lsp.sh" ]
}

@test "install-skills.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/install-skills.sh"
    [ -x "$REPO_ROOT/script/install-skills.sh" ]
}

@test "fix-container-plugins.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/fix-container-plugins.sh"
    [ -x "$REPO_ROOT/script/fix-container-plugins.sh" ]
}

@test "restore-cli-auth.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/restore-cli-auth.sh"
    [ -x "$REPO_ROOT/script/restore-cli-auth.sh" ]
}

@test "setup-team-protection.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-team-protection.sh"
    [ -x "$REPO_ROOT/script/setup-team-protection.sh" ]
}

@test "setup-team-protection.sh defines include_existing_environment_branches function" {
    grep -q "include_existing_environment_branches()" "$REPO_ROOT/script/setup-team-protection.sh"
}

@test "setup-team-protection.sh initializes BRANCHES_EXPLICIT to false" {
    grep -q "BRANCHES_EXPLICIT=false" "$REPO_ROOT/script/setup-team-protection.sh"
}

@test "setup-team-protection.sh sets BRANCHES_EXPLICIT=true when --branches is given" {
    grep -q "BRANCHES_EXPLICIT=true" "$REPO_ROOT/script/setup-team-protection.sh"
}

@test "check-file-length.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/check-file-length.sh"
    [ -x "$REPO_ROOT/script/check-file-length.sh" ]
}

@test "create-codespace.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/create-codespace.sh"
    [ -x "$REPO_ROOT/script/create-codespace.sh" ]
}

@test "setup-file-length-check.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-file-length-check.sh"
    [ -x "$REPO_ROOT/script/setup-file-length-check.sh" ]
}

@test "brew-deps.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/brew-deps.sh"
    [ -x "$REPO_ROOT/script/brew-deps.sh" ]
}

@test "install-npm-globals.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/install-npm-globals.sh"
    [ -x "$REPO_ROOT/script/install-npm-globals.sh" ]
}

@test "setup-claude-build.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-claude-build.sh"
    [ -x "$REPO_ROOT/script/setup-claude-build.sh" ]
}
