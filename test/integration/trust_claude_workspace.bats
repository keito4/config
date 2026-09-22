#!/usr/bin/env bats

# Integration tests for trust-claude-workspace.sh
#
# このスクリプトは ~/.claude.json の projects[<workspace>].hasTrustDialogAccepted
# を true にする。既存の設定ファイル全体を破壊せず、他のプロジェクトや同じ
# プロジェクト内の他のキーを保持したままマージすることが重要な安全上の要件。
# 壊れた JSON を上書きして設定を消してしまわないことも合わせて検証する。

load ../test_helper/test_helper

@test "trust-claude-workspace.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/trust-claude-workspace.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "creates ~/.claude.json and marks the workspace as trusted when no config exists" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "$fake_home"

  HOME="$fake_home" run "${REPO_ROOT}/script/trust-claude-workspace.sh" "/workspace/one"

  assert_success
  assert_file_exists "${fake_home}/.claude.json"
  run node -e "const c=require('${fake_home}/.claude.json'); process.exit(c.projects['/workspace/one'].hasTrustDialogAccepted === true ? 0 : 1)"
  assert_success
}

@test "preserves unrelated existing projects when trusting a new workspace" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "$fake_home"
  cat > "${fake_home}/.claude.json" << 'EOF'
{
  "projects": {
    "/workspace/existing": { "hasTrustDialogAccepted": true, "customField": "keep-me" }
  }
}
EOF

  HOME="$fake_home" run "${REPO_ROOT}/script/trust-claude-workspace.sh" "/workspace/new"

  assert_success
  run node -e "
    const c = require('${fake_home}/.claude.json');
    const existing = c.projects['/workspace/existing'];
    const created = c.projects['/workspace/new'];
    process.exit(
      existing.hasTrustDialogAccepted === true &&
      existing.customField === 'keep-me' &&
      created.hasTrustDialogAccepted === true
        ? 0 : 1
    );
  "
  assert_success
}

@test "preserves other keys already stored on the same project entry" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "$fake_home"
  cat > "${fake_home}/.claude.json" << 'EOF'
{
  "projects": {
    "/workspace/one": { "hasTrustDialogAccepted": false, "mcpServers": { "foo": {} } }
  }
}
EOF

  HOME="$fake_home" run "${REPO_ROOT}/script/trust-claude-workspace.sh" "/workspace/one"

  assert_success
  run node -e "
    const c = require('${fake_home}/.claude.json');
    const entry = c.projects['/workspace/one'];
    process.exit(entry.hasTrustDialogAccepted === true && entry.mcpServers && entry.mcpServers.foo ? 0 : 1);
  "
  assert_success
}

@test "refuses to overwrite an unparsable existing ~/.claude.json" {
  local fake_home="${TEST_TEMP_DIR}/home"
  mkdir -p "$fake_home"
  printf '{ not valid json' > "${fake_home}/.claude.json"

  HOME="$fake_home" run "${REPO_ROOT}/script/trust-claude-workspace.sh" "/workspace/one"

  assert_failure
  # 元の (壊れた) 内容がそのまま残っており、上書きで消えていないこと
  grep -q 'not valid json' "${fake_home}/.claude.json"
}

@test "defaults the workspace to the current directory when no argument is given" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local workdir="${TEST_TEMP_DIR}/some-project"
  mkdir -p "$fake_home" "$workdir"

  # NOTE: `env -C` は子プロセスへ「物理パス」の PWD を渡すため、macOS の
  #       /var -> private/var シンボリックリンク配下にある一時ディレクトリでは
  #       スクリプトが見る $PWD が $workdir と一致しない (Linux の /tmp は
  #       シンボリックリンクではないので差が出ない)。実運用と同じくシェルの
  #       `cd` 経由で起動し、論理パスを保ったまま既定値を検証する。
  HOME="$fake_home" run bash -c 'cd "$1" && exec "$2"' _ \
    "$workdir" "${REPO_ROOT}/script/trust-claude-workspace.sh"

  assert_success
  run node -e "
    const c = require('${fake_home}/.claude.json');
    process.exit(c.projects['${workdir}'] && c.projects['${workdir}'].hasTrustDialogAccepted === true ? 0 : 1);
  "
  assert_success
}
