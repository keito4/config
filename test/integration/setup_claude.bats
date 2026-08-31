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

# ---------------------------------------------------------------------------
# commands / agents / skills の追加 CLAUDE_CONFIG_DIR へのリンク
# 実際にスクリプトを偽 HOME で起動し、リンクが張られたかを検証する
# ---------------------------------------------------------------------------

# 偽 HOME を用意して setup-claude.sh を実行する
# claude CLI はスタブに差し替え、プラグイン導入で外部に触れないようにする
run_setup_in_fake_home() {
  local fake_home="$1"
  mkdir -p "${fake_home}/.claude" "${fake_home}/.stub-bin"
  cat > "${fake_home}/.stub-bin/claude" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
  chmod +x "${fake_home}/.stub-bin/claude"

  # 既定では実在の private-config に触れないよう、存在しないパスへ向ける。
  # 個別テストは PRIVATE_CONFIG_DIR を設定して上書きできる。
  HOME="$fake_home" \
  PATH="${fake_home}/.stub-bin:${PATH}" \
  PRIVATE_CONFIG_DIR="${PRIVATE_CONFIG_DIR:-${fake_home}/no-private-config}" \
    run bash "${REPO_ROOT}/script/setup-claude.sh"
}

# 追加 config dir は settings.json / .claude.json を持つものだけが対象になる。
# フィクスチャも初期化済みにしないと list_extra_config_dirs から除外される。
init_extra_config_dir() {
  local dir="$1"
  mkdir -p "$dir"
  echo '{}' > "${dir}/settings.json"
}

@test "setup-claude.sh links commands/agents/skills into extra config dirs" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"/{commands,agents,skills}
  init_extra_config_dir "${fake_home}/.claude-private"
  echo "canonical" > "${fake_home}/.claude/commands/session-close.md"

  run_setup_in_fake_home "$fake_home"

  local name
  for name in commands agents skills; do
    [ -L "${fake_home}/.claude-private/${name}" ]
    [ "$(readlink "${fake_home}/.claude-private/${name}")" = "${fake_home}/.claude/${name}" ]
  done

  # リンク越しに正本のファイルが読めること（宣言ではなく実体で確認）
  [ "$(cat "${fake_home}/.claude-private/commands/session-close.md")" = "canonical" ]
}

@test "setup-claude.sh links content into every extra config dir" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude/commands"
  init_extra_config_dir "${fake_home}/.claude-private"
  init_extra_config_dir "${fake_home}/.claude-elu"

  run_setup_in_fake_home "$fake_home"

  [ -L "${fake_home}/.claude-private/commands" ]
  [ -L "${fake_home}/.claude-elu/commands" ]
}

@test "setup-claude.sh content linking is idempotent" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude/commands"
  init_extra_config_dir "${fake_home}/.claude-private"

  run_setup_in_fake_home "$fake_home"
  [ -L "${fake_home}/.claude-private/commands" ]

  run_setup_in_fake_home "$fake_home"
  [ "$status" -eq 0 ]
  [ -L "${fake_home}/.claude-private/commands" ]
  [ "$(readlink "${fake_home}/.claude-private/commands")" = "${fake_home}/.claude/commands" ]
}

@test "setup-claude.sh does not clobber an existing real directory" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude/commands"
  init_extra_config_dir "${fake_home}/.claude-private"
  mkdir -p "${fake_home}/.claude-private/commands"
  echo "dir-specific" > "${fake_home}/.claude-private/commands/local-only.md"

  run_setup_in_fake_home "$fake_home"

  # 実体ディレクトリは温存され、中身が消えていないこと
  [ ! -L "${fake_home}/.claude-private/commands" ]
  [ "$(cat "${fake_home}/.claude-private/commands/local-only.md")" = "dir-specific" ]
}

@test "setup-claude.sh replaces a symlink that points elsewhere" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude/commands" "${fake_home}/stale"
  init_extra_config_dir "${fake_home}/.claude-private"
  ln -s "${fake_home}/stale" "${fake_home}/.claude-private/commands"

  run_setup_in_fake_home "$fake_home"

  [ "$(readlink "${fake_home}/.claude-private/commands")" = "${fake_home}/.claude/commands" ]
}

@test "setup-claude.sh skips content missing from the canonical dir" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude/commands"
  init_extra_config_dir "${fake_home}/.claude-private"

  run_setup_in_fake_home "$fake_home"

  # ~/.claude に agents が無いなら壊れたリンクを作らない
  # （skills はリポジトリのスキル展開で必ず作られるため、判定に使えない）
  [ ! -e "${fake_home}/.claude-private/agents" ]
  [ ! -L "${fake_home}/.claude-private/agents" ]
}

@test "setup-claude.sh ignores ~/.claude-* dirs that are not config dirs" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude/commands" "${fake_home}/.claude-worklog"
  echo '{"permissions":{"allow":[]}}' > "${fake_home}/.claude/settings.json"
  init_extra_config_dir "${fake_home}/.claude-private"

  run_setup_in_fake_home "$fake_home"

  # 初期化済みの config dir には従来どおり同期される（この判定が空振りしないことの担保）
  [ -L "${fake_home}/.claude-private/commands" ]
  grep -q "permissions" "${fake_home}/.claude-private/settings.json"

  # hook 置き場のような ~/.claude-* を config dir と誤認して汚さない
  [ ! -e "${fake_home}/.claude-worklog/settings.json" ]
  [ ! -e "${fake_home}/.claude-worklog/commands" ]
}

@test "setup-claude.sh syncs permissions.allow into extra config dirs" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"
  cat > "${fake_home}/.claude/settings.json" <<'JSON'
{"permissions":{"allow":["Write(~/.claude-worklog/**)","Edit(~/.claude-worklog/**)"]}}
JSON
  mkdir -p "${fake_home}/.claude-private"
  echo '{"model":"opus"}' > "${fake_home}/.claude-private/settings.json"

  run_setup_in_fake_home "$fake_home"

  jq -e '.permissions.allow
    | index("Write(~/.claude-worklog/**)") != null
      and index("Edit(~/.claude-worklog/**)") != null' \
    "${fake_home}/.claude-private/settings.json"
  [ "$(jq -r '.model' "${fake_home}/.claude-private/settings.json")" = "opus" ]
}

# ---------------------------------------------------------------------------
# ~/.claude/settings.json はホスト所有（symlink にしない）
# ---------------------------------------------------------------------------

@test "setup-claude.sh seeds ~/.claude/settings.json from the repository baseline" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"

  run_setup_in_fake_home "$fake_home"

  [ -f "${fake_home}/.claude/settings.json" ]
  [ ! -L "${fake_home}/.claude/settings.json" ]
  cmp -s "${fake_home}/.claude/settings.json" "${REPO_ROOT}/.claude/settings.json"
}

@test "setup-claude.sh replaces a settings.json symlink with a real file, keeping its content" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"
  echo '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"agent-deck hook-handler"}]}]}}' \
    > "${fake_home}/host-settings.json"
  ln -s "${fake_home}/host-settings.json" "${fake_home}/.claude/settings.json"

  run_setup_in_fake_home "$fake_home"

  # ホスト固有の hook を追跡ファイルへ書き戻させないため、実体に切り離す
  [ ! -L "${fake_home}/.claude/settings.json" ]
  grep -q "agent-deck hook-handler" "${fake_home}/.claude/settings.json"
  jq -e '.permissions.allow | index("Write(~/.claude-worklog/**)") != null' \
    "${fake_home}/.claude/settings.json"
}

@test "setup-claude.sh merges baseline permissions.allow without overwriting host settings" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"
  cat > "${fake_home}/.claude/settings.json" <<'JSON'
{
  "model": "opus",
  "hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "agent-deck hook-handler"}]}]},
  "permissions": {
    "allow": ["Bash(host-only:*)", "Write(~/.claude-worklog/**)"],
    "deny": ["Read(./secrets/**)"],
    "ask": ["Bash(git push:*)"]
  }
}
JSON

  run_setup_in_fake_home "$fake_home"

  jq --slurpfile baseline "${REPO_ROOT}/.claude/settings.json" -e '
    .model == "opus"
    and .hooks.SessionStart[0].hooks[0].command == "agent-deck hook-handler"
    and .permissions.deny == ["Read(./secrets/**)"]
    and .permissions.ask == ["Bash(git push:*)"]
    and .permissions.allow[0] == "Bash(host-only:*)"
    and ([.permissions.allow[] | select(. == "Write(~/.claude-worklog/**)")] | length) == 1
    and (($baseline[0].permissions.allow - .permissions.allow) | length) == 0
  ' "${fake_home}/.claude/settings.json"
}

@test "setup-claude.sh permissions.allow merge is idempotent" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"
  echo '{"permissions":{"allow":["Bash(host-only:*)"]}}' > "${fake_home}/.claude/settings.json"

  run_setup_in_fake_home "$fake_home"
  cp "${fake_home}/.claude/settings.json" "${TEST_TEMP_DIR}/settings-after-first-run.json"

  run_setup_in_fake_home "$fake_home"

  cmp -s "${TEST_TEMP_DIR}/settings-after-first-run.json" "${fake_home}/.claude/settings.json"
  [[ "$output" == *"permissions.allow は最新です"* ]]
}

@test "setup-claude.sh preserves an invalid existing settings.json" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"
  echo 'not json' > "${fake_home}/.claude/settings.json"

  run_setup_in_fake_home "$fake_home"

  [ "$(cat "${fake_home}/.claude/settings.json")" = "not json" ]
  [[ "$output" == *"不正なJSONまたは permissions.allow の形式が不正"* ]]
}

@test "setup-claude.sh preserves explicit null permissions values" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"

  local fixture
  for fixture in '{"permissions":null}' '{"permissions":{"allow":null}}'; do
    echo "$fixture" > "${fake_home}/.claude/settings.json"

    run_setup_in_fake_home "$fake_home"

    [ "$(cat "${fake_home}/.claude/settings.json")" = "$fixture" ]
    [[ "$output" == *"不正なJSONまたは permissions.allow の形式が不正"* ]]
  done
}

# ---------------------------------------------------------------------------
# リポジトリ／private-config のスキルを ~/.claude/skills に展開する
# ---------------------------------------------------------------------------

@test "setup-claude.sh links repository skills into ~/.claude/skills" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"

  run_setup_in_fake_home "$fake_home"

  # リポジトリのスキルは <name>/SKILL.md 形式で、~/.claude 側にリンクされる
  [ -L "${fake_home}/.claude/skills/ci-check" ]
  # リンク越しにリポジトリの正本が読めること（宣言ではなく実体で確認）
  [ "$(cat "${fake_home}/.claude/skills/ci-check/SKILL.md")" = "$(cat "${REPO_ROOT}/.claude/skills/ci-check/SKILL.md")" ]
}

@test "setup-claude.sh does not treat README.md or skills.txt as skills" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"

  run_setup_in_fake_home "$fake_home"

  [ ! -e "${fake_home}/.claude/skills/README" ]
  [ ! -e "${fake_home}/.claude/skills/skills" ]
}

@test "setup-claude.sh materializes private-config skills as SKILL.md symlinks" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local private="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${fake_home}/.claude" "${private}/.claude/skills"
  printf -- '---\nname: oykot-tasks\n---\nbody\n' > "${private}/.claude/skills/oykot-tasks.md"

  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"

  # <name>/SKILL.md が正本ファイルへの symlink になっていること
  [ -L "${fake_home}/.claude/skills/oykot-tasks/SKILL.md" ]
  [ "$(readlink "${fake_home}/.claude/skills/oykot-tasks/SKILL.md")" = "${private}/.claude/skills/oykot-tasks.md" ]
  # リンク越しに正本の内容が読めること（宣言ではなく実体で確認）
  [ "$(cat "${fake_home}/.claude/skills/oykot-tasks/SKILL.md")" = "$(cat "${private}/.claude/skills/oykot-tasks.md")" ]
}

@test "setup-claude.sh replaces an existing real SKILL.md copy with a symlink to private-config" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local private="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${fake_home}/.claude/skills/oykot-tasks" "${private}/.claude/skills"
  echo "canonical" > "${private}/.claude/skills/oykot-tasks.md"
  echo "stale copy" > "${fake_home}/.claude/skills/oykot-tasks/SKILL.md"

  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"

  [ -L "${fake_home}/.claude/skills/oykot-tasks/SKILL.md" ]
  [ "$(cat "${fake_home}/.claude/skills/oykot-tasks/SKILL.md")" = "canonical" ]
}

@test "setup-claude.sh materializes directory-form private skills as a symlinked directory" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local private="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${fake_home}/.claude" "${private}/.claude/skills/review-queue/scripts"
  printf -- '---\nname: review-queue\n---\nbody\n' > "${private}/.claude/skills/review-queue/SKILL.md"
  echo "scan" > "${private}/.claude/skills/review-queue/scripts/scan.sh"

  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"

  # SKILL.md 以外の補助ファイルも一緒に見える必要があるため、ディレクトリごとリンクする
  [ -L "${fake_home}/.claude/skills/review-queue" ]
  [ "$(readlink "${fake_home}/.claude/skills/review-queue")" = "${private}/.claude/skills/review-queue" ]
  [ "$(cat "${fake_home}/.claude/skills/review-queue/scripts/scan.sh")" = "scan" ]
}

@test "setup-claude.sh replaces a real directory copy of a private skill with a symlink" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local private="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${fake_home}/.claude/skills/review-queue" "${private}/.claude/skills/review-queue"
  echo "canonical" > "${private}/.claude/skills/review-queue/SKILL.md"
  echo "stale copy" > "${fake_home}/.claude/skills/review-queue/SKILL.md"

  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"

  [ -L "${fake_home}/.claude/skills/review-queue" ]
  [ "$(cat "${fake_home}/.claude/skills/review-queue/SKILL.md")" = "canonical" ]
}

@test "setup-claude.sh private skill linking is idempotent for both forms" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local private="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${fake_home}/.claude" "${private}/.claude/skills/review-queue"
  echo "flat" > "${private}/.claude/skills/oykot-tasks.md"
  echo "dir" > "${private}/.claude/skills/review-queue/SKILL.md"

  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"
  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"

  [ "$status" -eq 0 ]
  [ -L "${fake_home}/.claude/skills/oykot-tasks/SKILL.md" ]
  [ -L "${fake_home}/.claude/skills/review-queue" ]
  [ "$(cat "${fake_home}/.claude/skills/review-queue/SKILL.md")" = "dir" ]
}

@test "setup-claude.sh ignores private-config directories without SKILL.md" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local private="${TEST_TEMP_DIR}/private-config"
  mkdir -p "${fake_home}/.claude" "${private}/.claude/skills/scheduled-notes"
  echo "not a skill" > "${private}/.claude/skills/scheduled-notes/README.md"

  PRIVATE_CONFIG_DIR="$private" run_setup_in_fake_home "$fake_home"

  [ "$status" -eq 0 ]
  [ ! -e "${fake_home}/.claude/skills/scheduled-notes" ]
}

@test "setup-claude.sh skips private skills when private-config is absent" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "${fake_home}/.claude"

  PRIVATE_CONFIG_DIR="${TEST_TEMP_DIR}/does-not-exist" run_setup_in_fake_home "$fake_home"

  [ "$status" -eq 0 ]
  [ ! -e "${fake_home}/.claude/skills/oykot-tasks" ]
}
