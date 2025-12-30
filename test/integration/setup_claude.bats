#!/usr/bin/env bats

# Integration tests for setup-claude.sh script

load ../test_helper/test_helper

@test "setup-claude.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/setup-claude.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "setup-claude.sh requires bash 4.0+" {
  # Verify the script checks for bash version
  grep -q 'if \[\[ "\${BASH_VERSINFO\[0\]}" -lt 4 \]\]' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'このスクリプトは bash 4.0 以降が必要です' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh uses strict error handling" {
  # Verify the script uses set -euo pipefail
  grep -q 'set -euo pipefail' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh defines color constants" {
  # Verify color definitions
  grep -q "GREEN=" "${REPO_ROOT}/script/setup-claude.sh"
  grep -q "YELLOW=" "${REPO_ROOT}/script/setup-claude.sh"
  grep -q "BLUE=" "${REPO_ROOT}/script/setup-claude.sh"
  grep -q "NC=" "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh defines log functions" {
  # Verify log functions exist
  grep -q 'log_info()' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'log_success()' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'log_warn()' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh sets CLAUDE_DIR to HOME/.claude" {
  # Verify CLAUDE_DIR path
  grep -q 'CLAUDE_DIR="\${HOME}/.claude"' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh sets PLUGINS_DIR correctly" {
  # Verify PLUGINS_DIR path
  grep -q 'PLUGINS_DIR="\${CLAUDE_DIR}/plugins"' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh detects repository root" {
  # Verify REPO_ROOT detection
  grep -q 'REPO_ROOT=' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'cd.*dirname.*BASH_SOURCE' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh checks for claude CLI" {
  # Verify claude CLI check
  grep -q 'if ! command -v claude' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'Claude CLI が見つかりません' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh creates temporary directory" {
  # Verify tmp directory creation
  grep -q 'mkdir -p.*tmp' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'export TMPDIR=' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh copies plugins.txt from repository" {
  # Verify plugins.txt copy logic
  grep -q 'if \[\[ -f "\${REPO_PLUGINS_DIR}/plugins.txt" \]\]' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'cp.*plugins.txt' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh handles template substitution" {
  # Verify template processing with sed
  grep -q 'sed.*{{HOME}}' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'known_marketplaces.json.template' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh uses associative arrays for marketplaces" {
  # Verify associative array usage
  grep -q 'declare -A marketplaces_needed' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh parses plugins.txt for marketplace names" {
  # Verify marketplace extraction logic
  grep -q 'if \[\[ "$line" =~ @' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'BASH_REMATCH' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh skips comments and empty lines" {
  # Verify comment/empty line skipping
  grep -q '\[\[ -z "$line" \|\| "$line" =~ .*# \]\]' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh has comprehensive error handling" {
  # Verify error handling patterns
  grep -q 'if \[\[ ! -f' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'log_warn' "${REPO_ROOT}/script/setup-claude.sh"
}
