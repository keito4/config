#!/usr/bin/env bats
# fix-mcp-token-exposure.sh の振る舞いテスト
# 生成される MCP 定義が argv にトークンを載せないことを保証する

load ../test_helper/test_helper

SCRIPT() { echo "$REPO_ROOT/script/fix-mcp-token-exposure.sh"; }

# 検査用の .claude.json を作る。$1 = 出力先ディレクトリ, $2 = leaky|hardened
write_config() {
    local dir="$1" variant="$2"
    mkdir -p "$dir"
    if [ "$variant" = "leaky" ]; then
        cat > "$dir/.claude.json" <<'JSON'
{
  "mcpServers": {
    "linear": {
      "type": "stdio",
      "command": "bash",
      "args": ["-lc", "exec npx -y mcp-remote https://mcp.linear.app/mcp --header \"Authorization: Bearer $LINEAR_API_KEY\""],
      "env": {}
    },
    "supabase": {
      "type": "stdio",
      "command": "bash",
      "args": ["-lc", "exec npx -y mcp-remote https://mcp.supabase.com/mcp --header \"Authorization: Bearer $SUPABASE_ACCESS_TOKEN\""],
      "env": {}
    },
    "sentry-elu": {
      "type": "stdio",
      "command": "bash",
      "args": ["-lc", "exec npx -y @sentry/mcp-server@latest --access-token=\"$ELU_SENTRY_TOKEN\""],
      "env": {}
    }
  }
}
JSON
    else
        local entries="" name
        echo '{ "mcpServers": {' > "$dir/.claude.json"
        for name in linear supabase sentry-elu; do
            entries="${entries}${entries:+,}\"$name\": $("$(SCRIPT)" --print "$name")"
        done
        printf '%s' "$entries" >> "$dir/.claude.json"
        echo '} }' >> "$dir/.claude.json"
    fi
}

@test "fix-mcp-token-exposure.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/fix-mcp-token-exposure.sh"
    [ -x "$REPO_ROOT/script/fix-mcp-token-exposure.sh" ]
}

@test "--list reports the managed MCP servers" {
    run "$(SCRIPT)" --list
    assert_success
    [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" -eq 3 ]
    printf '%s\n' "$output" | grep -qx 'linear'
    printf '%s\n' "$output" | grep -qx 'supabase'
    printf '%s\n' "$output" | grep -qx 'sentry-elu'
}

@test "--print emits valid JSON for every managed server" {
    local name
    for name in linear supabase sentry-elu; do
        run "$(SCRIPT)" --print "$name"
        assert_success
        printf '%s' "$output" | python3 -c 'import json,sys; json.load(sys.stdin)'
    done
}

@test "--print rejects an unknown server" {
    run "$(SCRIPT)" --print no-such-server
    [ "$status" -ne 0 ]
}

@test "generated definitions never embed a secret in argv" {
    local name
    for name in linear supabase sentry-elu; do
        run "$(SCRIPT)" --print "$name"
        assert_success
        # JSON をデコードしてから判定する (シェル側のエスケープに依存しない)
        printf '%s' "$output" | python3 -c '
import json, sys
cmd = json.load(sys.stdin)["args"][1]
assert "--access-token" not in cmd, "token passed via --access-token: " + cmd
assert "--header \"Authorization: Bearer" not in cmd, "token expanded into argv: " + cmd
'
    done
}

@test "mcp-remote headers use the placeholder form its parser accepts" {
    run "$(SCRIPT)" --print linear
    assert_success
    # コロン直後にスペースを置かない形式 (mcp-remote の ^([A-Za-z0-9_-]+):\s*(.*)$ に合わせる)
    printf '%s' "$output" | grep -q 'Authorization:\${LINEAR_AUTH_HEADER}'
    printf '%s' "$output" | grep -q 'export LINEAR_AUTH_HEADER='

    run "$(SCRIPT)" --print supabase
    assert_success
    printf '%s' "$output" | grep -q 'Authorization:\${SUPABASE_AUTH_HEADER}'
    printf '%s' "$output" | grep -q 'export SUPABASE_AUTH_HEADER='
}

@test "sentry passes its token through the environment" {
    run "$(SCRIPT)" --print sentry-elu
    assert_success
    printf '%s' "$output" | grep -q 'export SENTRY_ACCESS_TOKEN='
    printf '%s' "$output" | grep -q 'SENTRY_HOST=sentry.io'
}

@test "--check fails on a config dir that leaks tokens through argv" {
    write_config "$TEST_TEMP_DIR/leaky" leaky
    run "$(SCRIPT)" --check "$TEST_TEMP_DIR/leaky"
    [ "$status" -ne 0 ]
    printf '%s\n' "$output" | grep -q 'NG'
}

@test "--check passes on a config dir built from the generated definitions" {
    write_config "$TEST_TEMP_DIR/hardened" hardened
    run "$(SCRIPT)" --check "$TEST_TEMP_DIR/hardened"
    assert_success
    ! printf '%s\n' "$output" | grep -q 'NG'
}

@test "--check skips a directory without .claude.json" {
    mkdir -p "$TEST_TEMP_DIR/empty"
    run "$(SCRIPT)" --check "$TEST_TEMP_DIR/empty"
    assert_success
}

@test "--check does not modify the inspected config" {
    write_config "$TEST_TEMP_DIR/leaky" leaky
    local before
    before="$(md5 -q "$TEST_TEMP_DIR/leaky/.claude.json" 2>/dev/null || md5sum "$TEST_TEMP_DIR/leaky/.claude.json" | cut -d' ' -f1)"
    run "$(SCRIPT)" --check "$TEST_TEMP_DIR/leaky"
    local after
    after="$(md5 -q "$TEST_TEMP_DIR/leaky/.claude.json" 2>/dev/null || md5sum "$TEST_TEMP_DIR/leaky/.claude.json" | cut -d' ' -f1)"
    [ "$before" = "$after" ]
}

@test "fix-mcp-token-exposure.sh stays below critical complexity threshold" {
    run "$REPO_ROOT/script/code-complexity-check.sh" --files "$REPO_ROOT/script/fix-mcp-token-exposure.sh" --json
    assert_success
    printf '%s\n' "$output" | grep -q '"critical_complexity_count": 0'
}
