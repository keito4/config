#!/usr/bin/env bash
# ============================================================================
# MCP Token Exposure Fix
# 展開済みトークンを argv に渡している MCP 定義を、環境変数経由へ書き換える
# ============================================================================
# 背景:
#   linear / supabase / sentry-elu は、シェルが展開したトークンを
#   mcp-remote や @sentry/mcp-server の *コマンドライン引数* に渡していたため、
#   同一ユーザーの任意プロセスから `ps` で平文のまま読めた。
#
# 対策の根拠 (いずれも実装を確認済み):
#   - mcp-remote は --header 値の `${VAR}` を process.env から展開する
#     dist/chunk-*.js: headers[key] = value.replace(/\$\{([^}]+)}/g, ...)
#     ヘッダ引数の正規表現は ^([A-Za-z0-9_-]+):\s*(.*)$ なので
#     コロン直後にスペースを置かない形式で渡す。
#   - @sentry/mcp-server は env.SENTRY_ACCESS_TOKEN / env.SENTRY_HOST を読む。
#
# 注意:
#   既定スコープの状態ファイルは ~/.claude/.claude.json ではなく ~/.claude.json
#   (旧レイアウト)。~/.claude/.claude.json だけ直しても既定セッションには効かない。
#   反映には対象セッションの再起動が必要 (MCP は起動時に spawn される)。
# ============================================================================
#
# SC2016: $LINEAR_API_KEY 等は MCP 起動時に bash -lc 側で展開させるため、
# ここでは意図的に literal のまま埋め込む (このスクリプトで展開してはならない)。
# shellcheck disable=SC2016

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/lib/output.sh
source "$REPO_ROOT/script/lib/output.sh"

# 管理対象の MCP サーバー名 (lib/output.sh と同じく bash 4.0+ が前提)
MANAGED_SERVERS="linear supabase sentry-elu"

# 全定義に共通する前置き: 資格情報の読み込みと npx キャッシュの固定
COMMON_PRELUDE='set -a; . "$HOME/.devcontainer.env"; set +a; export npm_config_cache="${TMPDIR:-/tmp}/mcp-npm-cache"; mkdir -p "$npm_config_cache"; '

# サーバー名 -> トークンを環境変数へ逃がした起動コマンド
server_command() {
    case "$1" in
        linear)
            printf '%s' 'export LINEAR_AUTH_HEADER="Bearer $LINEAR_API_KEY"; exec npx -y mcp-remote https://mcp.linear.app/mcp --header '"'"'Authorization:${LINEAR_AUTH_HEADER}'"'"''
            ;;
        supabase)
            printf '%s' 'export SUPABASE_AUTH_HEADER="Bearer $SUPABASE_ACCESS_TOKEN"; exec npx -y mcp-remote '"'"'https://mcp.supabase.com/mcp?read_only=true'"'"' --header '"'"'Authorization:${SUPABASE_AUTH_HEADER}'"'"''
            ;;
        sentry-elu)
            printf '%s' 'export SENTRY_ACCESS_TOKEN="$ELU_SENTRY_TOKEN" SENTRY_HOST=sentry.io; exec npx -y @sentry/mcp-server@latest'
            ;;
        *)
            print_error "未知の MCP サーバー: $1"
            return 1
            ;;
    esac
}

# サーバー名 -> .claude.json の mcpServers エントリ (JSON 1 行)
server_json() {
    local cmd
    cmd="$(server_command "$1")"
    MCP_CMD="${COMMON_PRELUDE}${cmd}" python3 -c '
import json, os
print(json.dumps({"type": "stdio", "command": "bash",
                  "args": ["-lc", os.environ["MCP_CMD"]], "env": {}}, ensure_ascii=False))'
}

# config dir の .claude.json が argv にトークンを渡していないか検査する
check_config_dir() {
    local dir="$1"
    local file="$dir/.claude.json"
    if [ ! -f "$file" ]; then
        print_info "スキップ (.claude.json なし): $dir"
        return 0
    fi
    MCP_FILE="$file" MCP_SERVERS="$MANAGED_SERVERS" python3 -c '
import json, os, sys
servers = json.load(open(os.environ["MCP_FILE"])).get("mcpServers", {})
leaked = []
for name in os.environ["MCP_SERVERS"].split():
    entry = servers.get(name)
    if entry is None:
        print("  %-12s -- (未設定)" % name)
        continue
    args = entry.get("args") or ["", ""]
    cmd = args[1] if len(args) > 1 else ""
    if "--access-token" in cmd or '"'"'--header "Authorization: Bearer'"'"' in cmd:
        leaked.append(name)
        print("  %-12s NG (argv にトークン)" % name)
    else:
        print("  %-12s OK" % name)
sys.exit(1 if leaked else 0)'
}

# 対象 config dir に向けて claude CLI を実行する。
# 既定スコープ ($HOME/.claude.json) は CLAUDE_CONFIG_DIR 未設定で解決させること。
# $HOME を明示すると claude が $HOME を config dir とみなし ~/backups 等を作ってしまう。
mcp_cli() {
    local dir="$1"
    shift
    if [ "$dir" = "$HOME" ]; then
        claude "$@"
    else
        CLAUDE_CONFIG_DIR="$dir" claude "$@"
    fi
}

# config dir の管理対象サーバーを安全な定義へ置き換える
apply_config_dir() {
    local dir="$1"
    local file="$dir/.claude.json"
    local name
    if [ ! -f "$file" ]; then
        print_info "スキップ (.claude.json なし): $dir"
        return 0
    fi
    cp -p "$file" "$file.pre-mcp-token-fix.$(date +%Y%m%d-%H%M%S)"
    for name in $MANAGED_SERVERS; do
        mcp_cli "$dir" mcp remove -s user "$name" >/dev/null 2>&1 || true
        mcp_cli "$dir" mcp add-json -s user "$name" "$(server_json "$name")" >/dev/null
    done
}

usage() {
    cat <<'USAGE'
Usage: fix-mcp-token-exposure.sh [--check | --print <server>] [config_dir ...]

  (既定)            管理対象 MCP を安全な定義へ置き換える (claude CLI が必要)
  --check           置き換え済みかどうかを検査するだけ (書き込みなし)
  --print <server>  生成される mcpServers エントリの JSON を出力する
  --list            管理対象のサーバー名を出力する

config_dir の既定は $HOME と ~/.claude-private。
既定スコープの状態ファイルは ~/.claude/.claude.json ではなく ~/.claude.json
(旧レイアウト) なので、config_dir としては $HOME を指定する。
USAGE
}

main() {
    local mode="apply"
    case "${1:-}" in
        --check) mode="check"; shift ;;
        --print) shift; server_json "${1:?--print にはサーバー名が必要です}"; return 0 ;;
        --list) echo "$MANAGED_SERVERS" | tr ' ' '\n'; return 0 ;;
        -h | --help) usage; return 0 ;;
    esac

    local dirs=("$@")
    if [ ${#dirs[@]} -eq 0 ]; then
        # $HOME は既定スコープの ~/.claude.json を指す (mcp_cli を参照)。
        dirs=("$HOME" "$HOME/.claude-private")
    fi

    if [ "$mode" = "apply" ] && ! command -v claude >/dev/null 2>&1; then
        print_error "claude CLI が見つかりません。--check なら CLI なしで検査できます。"
        return 1
    fi

    local dir failed=0
    for dir in "${dirs[@]}"; do
        printf '### %s\n' "$dir"
        [ "$mode" = "apply" ] && apply_config_dir "$dir"
        check_config_dir "$dir" || failed=1
    done

    if [ "$failed" -ne 0 ]; then
        print_error "argv にトークンを渡す MCP 定義が残っています。"
        return 1
    fi
    print_success "管理対象の MCP 定義は全て安全な形式です。"
    if [ "$mode" = "apply" ]; then
        print_warning "反映には対象 config dir のセッション再起動が必要です。"
    fi
}

main "$@"
