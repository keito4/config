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

@test "setup-claude.sh sources output library for colors and logging" {
  # Verify that setup-claude.sh sources output.sh (which defines colors and log functions)
  grep -q 'source.*output.sh' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh sources claude_plugins library" {
  # Verify that setup-claude.sh sources claude_plugins.sh (which defines plugin management functions)
  grep -q 'source.*claude_plugins.sh' "${REPO_ROOT}/script/setup-claude.sh"
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

@test "setup-claude.sh references plugins.txt" {
  # Verify plugins.txt is used
  grep -q 'plugins.txt' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh references known_marketplaces" {
  # Verify known_marketplaces.json is used
  grep -q 'known_marketplaces' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh delegates marketplace detection to library" {
  # Verify marketplace detection is delegated to claude_plugins.sh
  grep -q 'detect_and_add_marketplaces' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh calls plugins library for installation" {
  # Verify plugin installation is delegated to claude_plugins.sh
  grep -q 'plugins::' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh delegates plugin file parsing to library" {
  # Comment/empty line skipping is handled by claude_plugins.sh
  grep -q 'plugins::' "${REPO_ROOT}/script/setup-claude.sh"
}

@test "setup-claude.sh has comprehensive error handling" {
  # Verify error handling patterns
  grep -q 'if \[\[ ! -f' "${REPO_ROOT}/script/setup-claude.sh"
  grep -q 'log_warn' "${REPO_ROOT}/script/setup-claude.sh"
}
