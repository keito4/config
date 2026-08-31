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

@test "install-skills.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/install-skills.sh"
    [ -x "$REPO_ROOT/script/install-skills.sh" ]
}

@test "install-skills.sh delegates to install skills library" {
    grep -q 'source "$SCRIPT_DIR/lib/install_skills.sh"' "$REPO_ROOT/script/install-skills.sh"
    grep -q 'install_skills_main "$@"' "$REPO_ROOT/script/install-skills.sh"
    grep -q "install_skills_main()" "$REPO_ROOT/script/lib/install_skills.sh"
}

@test "install-skills.sh stays below critical complexity threshold" {
    run "$REPO_ROOT/script/code-complexity-check.sh" --files "$REPO_ROOT/script/install-skills.sh" --json
    assert_success
    printf '%s\n' "$output" | grep -q '"critical_complexity_count": 0'
}

@test "restore-cli-auth.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/restore-cli-auth.sh"
    [ -x "$REPO_ROOT/script/restore-cli-auth.sh" ]
}

@test "setup-team-protection.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-team-protection.sh"
    [ -x "$REPO_ROOT/script/setup-team-protection.sh" ]
}

@test "setup-team-protection.sh delegates to setup team protection library" {
    grep -q 'source "$SCRIPT_DIR/lib/setup_team_protection.sh"' "$REPO_ROOT/script/setup-team-protection.sh"
    grep -q 'setup_team_protection_main "$@"' "$REPO_ROOT/script/setup-team-protection.sh"
    grep -q "setup_team_protection_main()" "$REPO_ROOT/script/lib/setup_team_protection.sh"
}

@test "setup-team-protection.sh defines include_existing_environment_branches function" {
    grep -q "include_existing_environment_branches()" "$REPO_ROOT/script/lib/setup_team_protection.sh"
}

@test "setup-team-protection.sh initializes BRANCHES_EXPLICIT to false" {
    grep -q "BRANCHES_EXPLICIT=false" "$REPO_ROOT/script/lib/setup_team_protection.sh"
}

@test "setup-team-protection.sh sets BRANCHES_EXPLICIT=true when --branches is given" {
    grep -q "BRANCHES_EXPLICIT=true" "$REPO_ROOT/script/lib/setup_team_protection.sh"
}

@test "setup-team-protection.sh stays below critical complexity threshold" {
    run "$REPO_ROOT/script/code-complexity-check.sh" --files "$REPO_ROOT/script/setup-team-protection.sh" --json
    assert_success
    printf '%s\n' "$output" | grep -q '"critical_complexity_count": 0'
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
    assert_file_exists "$REPO_ROOT/templates/setup-file-length-check.sh"
    [ -x "$REPO_ROOT/templates/setup-file-length-check.sh" ]
}

@test "brew-deps.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/brew-deps.sh"
    [ -x "$REPO_ROOT/script/brew-deps.sh" ]
}

@test "install-npm-globals.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/install-npm-globals.sh"
    [ -x "$REPO_ROOT/script/install-npm-globals.sh" ]
}

@test "repo-maintenance.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/repo-maintenance.sh"
    [ -x "$REPO_ROOT/script/repo-maintenance.sh" ]
}

@test "setup-ci.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-ci.sh"
    [ -x "$REPO_ROOT/script/setup-ci.sh" ]
}

# Ubicloud 導入済み owner では Ubicloud ランナーを、それ以外では ubuntu-latest を
# 生成することを固定する。ここが崩れると新規リポジトリだけ枯渇したランナーに戻る。
setup_ci_fixture() {
    local dir="$1" remote="$2"

    mkdir -p "$dir"
    git -C "$dir" init --quiet
    if [ -n "$remote" ]; then
        git -C "$dir" remote add origin "$remote"
    fi
    printf '{"name":"fixture","scripts":{"lint":"true","test":"true","build":"true"}}\n' > "$dir/package.json"
}

@test "setup-ci.sh uses the Ubicloud runner for Ubicloud-enabled owners" {
    local dir="$TEST_TEMP_DIR/oykot"
    setup_ci_fixture "$dir" "git@github.com:OYKOT-jp/fixture.git"

    run bash "$REPO_ROOT/script/setup-ci.sh" --target "$dir"
    [ "$status" -eq 0 ]

    grep -q "runs-on: ubicloud-standard-2" "$dir/.github/workflows/ci.yml"
    ! grep -q "runs-on: ubuntu-latest" "$dir/.github/workflows/ci.yml"
    # コピーしたテンプレートも配置時に書き換わること
    ! grep -rq "runs-on: ubuntu-latest" "$dir/.github/workflows/"
}

@test "setup-ci.sh keeps ubuntu-latest for owners without Ubicloud" {
    local dir="$TEST_TEMP_DIR/personal"
    setup_ci_fixture "$dir" "https://github.com/keito4/fixture.git"

    run bash "$REPO_ROOT/script/setup-ci.sh" --target "$dir"
    [ "$status" -eq 0 ]

    grep -q "runs-on: ubuntu-latest" "$dir/.github/workflows/ci.yml"
    ! grep -q "ubicloud" "$dir/.github/workflows/ci.yml"
}

@test "setup-ci.sh falls back to ubuntu-latest without a git remote" {
    local dir="$TEST_TEMP_DIR/no-remote"
    setup_ci_fixture "$dir" ""

    run bash "$REPO_ROOT/script/setup-ci.sh" --target "$dir"
    [ "$status" -eq 0 ]

    grep -q "runs-on: ubuntu-latest" "$dir/.github/workflows/ci.yml"
}

@test "setup-ci.sh honours an explicit CI_RUNNER override" {
    local dir="$TEST_TEMP_DIR/override"
    setup_ci_fixture "$dir" "https://github.com/keito4/fixture.git"

    CI_RUNNER=ubicloud-standard-2-arm run bash "$REPO_ROOT/script/setup-ci.sh" --target "$dir"
    [ "$status" -eq 0 ]

    grep -q "runs-on: ubicloud-standard-2-arm" "$dir/.github/workflows/ci.yml"
}

@test "setup-ci.sh keeps GitHub expressions intact in the terraform workflow" {
    local dir="$TEST_TEMP_DIR/terraform"
    setup_ci_fixture "$dir" "git@github.com:OYKOT-jp/fixture.git"
    touch "$dir/main.tf"

    run bash "$REPO_ROOT/script/setup-ci.sh" --target "$dir" --type terraform
    [ "$status" -eq 0 ]

    grep -q 'group: ${{ github.workflow }}-${{ github.ref }}' "$dir/.github/workflows/ci.yml"
    grep -q "runs-on: ubicloud-standard-2" "$dir/.github/workflows/ci.yml"
}

@test "setup-new-repo.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-new-repo.sh"
    [ -x "$REPO_ROOT/script/setup-new-repo.sh" ]
}

@test "setup-claude-build.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/setup-claude-build.sh"
    [ -x "$REPO_ROOT/script/setup-claude-build.sh" ]
}

@test "check-trivyignore-review.sh exists and reports due review entries" {
    assert_file_exists "$REPO_ROOT/script/check-trivyignore-review.sh"
    [ -x "$REPO_ROOT/script/check-trivyignore-review.sh" ]

    run env TODAY=2026-09-01 "$REPO_ROOT/script/check-trivyignore-review.sh" "$REPO_ROOT/.trivyignore"
    assert_success
    printf '%s\n' "$output" | grep -Fq "Trivy ignore entries due for review"
}
