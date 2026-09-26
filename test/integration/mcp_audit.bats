#!/usr/bin/env bats
# script/lib/mcp_audit.py の振る舞いテスト
#
# fix-mcp-token-exposure.sh は configdir サブコマンドしか間接的にテストされて
# おらず、実際の漏洩検知ロジック (leaking_servers) を使う projects サブコマンド
# と CLI dispatch は未検証だった。ここではそれらを直接カバーする。

load ../test_helper/test_helper

MCP_AUDIT() { echo "$REPO_ROOT/script/lib/mcp_audit.py"; }

write_mcp_json() {
    local path="$1" body="$2"
    mkdir -p "$(dirname "$path")"
    printf '%s' "$body" > "$path"
}

@test "mcp_audit.py exists and is executable" {
    assert_file_exists "$(MCP_AUDIT)"
    [ -x "$(MCP_AUDIT)" ]
}

@test "projects flags a server that leaks a token via double-quoted header" {
    write_mcp_json "$TEST_TEMP_DIR/proj/.mcp.json" '{
  "mcpServers": {
    "leaky": {
      "args": ["-lc", "exec mcp-remote https://mcp.example.com --header \"Authorization: Bearer $TOKEN\""]
    }
  }
}'

    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/proj"
    [ "$status" -eq 1 ]
    printf '%s\n' "$output" | grep -q 'NG'
    printf '%s\n' "$output" | grep -q 'leaky'
}

@test "projects flags a server that leaks a token via --access-token" {
    write_mcp_json "$TEST_TEMP_DIR/proj/.mcp.json" '{
  "mcpServers": {
    "sentry": {
      "args": ["-lc", "exec sentry-mcp --access-token=\"$SENTRY_TOKEN\""]
    }
  }
}'

    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/proj"
    [ "$status" -eq 1 ]
    printf '%s\n' "$output" | grep -q 'NG'
    printf '%s\n' "$output" | grep -q 'sentry'
}

@test "projects passes a server using the single-quoted \${VAR} placeholder form" {
    write_mcp_json "$TEST_TEMP_DIR/proj/.mcp.json" '{
  "mcpServers": {
    "safe": {
      "args": ["-lc", "exec mcp-remote https://mcp.example.com --header '"'"'Authorization:${TOKEN}'"'"'"]
    }
  }
}'

    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/proj"
    assert_success
    ! printf '%s\n' "$output" | grep -q 'NG'
}

@test "projects skips .mcp.json files under node_modules" {
    write_mcp_json "$TEST_TEMP_DIR/proj/node_modules/pkg/.mcp.json" '{
  "mcpServers": {
    "leaky": {
      "args": ["-lc", "exec mcp-remote https://mcp.example.com --header \"Authorization: Bearer $TOKEN\""]
    }
  }
}'

    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/proj"
    assert_success
    ! printf '%s\n' "$output" | grep -q 'NG'
}

@test "projects skips .mcp.json files under plugins/marketplaces" {
    write_mcp_json "$TEST_TEMP_DIR/proj/plugins/marketplaces/foo/.mcp.json" '{
  "mcpServers": {
    "leaky": {
      "args": ["-lc", "exec mcp-remote https://mcp.example.com --header \"Authorization: Bearer $TOKEN\""]
    }
  }
}'

    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/proj"
    assert_success
    ! printf '%s\n' "$output" | grep -q 'NG'
}

@test "projects tolerates an unreadable .mcp.json without crashing" {
    write_mcp_json "$TEST_TEMP_DIR/proj/.mcp.json" 'not valid json'

    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/proj"
    assert_success
    printf '%s\n' "$output" | grep -q '読めない'
}

@test "projects returns success and skips a missing root directory" {
    run python3 "$(MCP_AUDIT)" projects "$TEST_TEMP_DIR/does-not-exist"
    assert_success
    printf '%s\n' "$output" | grep -q 'スキップ'
}

@test "processes subcommand runs without crashing" {
    run python3 "$(MCP_AUDIT)" processes
    assert_success
    printf '%s\n' "$output" | grep -q 'プレースホルダ形式で動作中'
}

@test "unknown subcommand prints usage and exits non-zero" {
    run python3 "$(MCP_AUDIT)"
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qi 'mcp'
}
