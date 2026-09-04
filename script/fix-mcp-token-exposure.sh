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
#
# 2026-09-05 追記 — npx 起動は遅く、かつ壊れる:
#   sentry-elu は `npx -y @sentry/mcp-server@latest` で起動していた。`@latest` は
#   起動のたびにレジストリ解決を走らせるため遅く (freee-mcp で実測 20.0 秒、
#   Claude Code の起動タイムアウトは 30 秒)、さらに複数の MCP が同じ npx キャッシュを
#   共有するため、並行起動でキャッシュが ENOTEMPTY を起こすと起動自体が失敗する
#   (2026-09-05 に実際に slack/sentry-elu が同時に CONNECTION_CLOSED になった)。
#   そこでグローバル導入済みバイナリの直叩きへ移す。前提として次が要る:
#       npm i -g @sentry/mcp-server
#   トレードオフとして npx の自動更新は失われ、更新は `npm i -g` が必要になる。
#   バイナリの絶対パスは *定義生成時* に `npm prefix -g` から解決して埋め込む
#   (起動時に PATH 解決へ依存しない。MCP は login shell の PATH に
#   ~/.local/bin を持たないことがある)。
#
# 2026-08-26 追記 — config dir だけを見ていては足りない:
#   この検査は当初 config dir の .claude.json しか見ておらず、
#   *プロジェクトスコープの .mcp.json* を対象外にしていた。そのため
#   あるリポジトリの .mcp.json が古い形式のまま残り
#   (--header "Authorization: Bearer $VAR" はダブルクォートなので
#   シェルが exec 前に展開する)、linear/supabase/sentry/vercel 4サーバー分の
#   平文トークンが argv に載っていたのに、--check は
#   「管理対象の MCP 定義は全て安全な形式です」と緑を返していた。
#
#   さらに定義が正しくても *それ以前に起動したセッション* は古い argv を
#   保持し続ける (MCP は起動時 spawn なので定義修正だけでは消えない)。
#   よって検査は3層で行う:
#     1. config dir の .claude.json   (従来)
#     2. プロジェクトの .mcp.json     (--scan-projects)
#     3. 実行中プロセスの argv        (--scan-processes)
#   3 が最終的な事実。1 と 2 が緑でも 3 が赤なら該当セッションの再起動が要る。
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

# プロジェクトスコープの .mcp.json を探すルート
PROJECT_ROOT_DEFAULT="$HOME/develop"

# 全定義に共通する前置き: 資格情報の読み込み
COMMON_PRELUDE='set -a; . "$HOME/.devcontainer.env"; set +a; '

# npx で起動するサーバーだけに要る前置き: npx キャッシュの固定
NPX_CACHE_PRELUDE='export npm_config_cache="${TMPDIR:-/tmp}/mcp-npm-cache"; mkdir -p "$npm_config_cache"; '

# npm i -g で入るバイナリの置き場。定義生成時に解決して絶対パスを埋め込む。
npm_global_bin() {
    printf '%s/bin' "$(npm prefix -g)"
}

# サーバー名 -> トークンを環境変数へ逃がした起動コマンド
server_command() {
    case "$1" in
        linear)
            printf '%s%s' "$NPX_CACHE_PRELUDE" 'export LINEAR_AUTH_HEADER="Bearer $LINEAR_API_KEY"; exec npx -y mcp-remote https://mcp.linear.app/mcp --header '"'"'Authorization:${LINEAR_AUTH_HEADER}'"'"''
            ;;
        supabase)
            printf '%s%s' "$NPX_CACHE_PRELUDE" 'export SUPABASE_AUTH_HEADER="Bearer $SUPABASE_ACCESS_TOKEN"; exec npx -y mcp-remote '"'"'https://mcp.supabase.com/mcp?read_only=true'"'"' --header '"'"'Authorization:${SUPABASE_AUTH_HEADER}'"'"''
            ;;
        sentry-elu)
            printf '%s"%s/sentry-mcp"' 'export SENTRY_ACCESS_TOKEN="$ELU_SENTRY_TOKEN" SENTRY_HOST=sentry.io; exec ' "$(npm_global_bin)"
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
    # shellcheck disable=SC2086  # MANAGED_SERVERS は意図的に単語分割する
    python3 "$REPO_ROOT/script/lib/mcp_audit.py" configdir "$file" $MANAGED_SERVERS
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
    local backup
    backup="$file.pre-mcp-token-fix.$(date +%Y%m%d-%H%M%S)"
    cp -p "$file" "$backup"
    # cp -p は元ファイルのパーミッションを引き継ぐが、万一 $file 自体が
    # 緩いパーミッションで作られていた場合に備え、平文トークンを含む
    # バックアップは明示的に自分専用へ絞る。
    chmod 600 "$backup"
    for name in $MANAGED_SERVERS; do
        mcp_cli "$dir" mcp remove -s user "$name" >/dev/null 2>&1 || true
        mcp_cli "$dir" mcp add-json -s user "$name" "$(server_json "$name")" >/dev/null
    done
}

# プロジェクトスコープの .mcp.json を検査する (報告のみ・書き換えはしない)
#
# 共有リポジトリに配られているファイルを勝手に書き換えると、他人の作業や
# コミットに紛れ込む。ここでは検出して直し方を示すに留める。
check_project_mcp_json() {
    python3 "$REPO_ROOT/script/lib/mcp_audit.py" projects "${1:-$PROJECT_ROOT_DEFAULT}"
}

# 実行中の MCP プロセスの argv を検査する
#
# 定義を直しても、それ以前に起動したセッションは古い argv を保持し続ける。
# ここが最終的な事実なので、定義が緑でもこちらを必ず見る。
check_running_processes() {
    python3 "$REPO_ROOT/script/lib/mcp_audit.py" processes
}

usage() {
    cat <<'USAGE'
Usage: fix-mcp-token-exposure.sh [--check | --audit | --print <server>] [config_dir ...]

  (既定)            管理対象 MCP を安全な定義へ置き換える (claude CLI が必要)
  --check           config dir の .claude.json だけを検査する (書き込みなし)
  --audit           --check に加えてプロジェクトの .mcp.json と
                    実行中プロセスの argv も検査する (推奨・書き込みなし)
  --scan-projects [root]  プロジェクトの .mcp.json だけを検査する (既定 ~/develop)
  --scan-processes        実行中プロセスの argv だけを検査する
  --print <server>  生成される mcpServers エントリの JSON を出力する
  --list            管理対象のサーバー名を出力する

⚠️ --check は config dir しか見ないので、プロジェクトの .mcp.json に古い定義が
   残っていても緑になる (2026-08-26 に実際に見逃した)。通常は --audit を使う。
   実行中プロセスの argv が最終的な事実で、定義が緑でも古いセッションが
   生きていれば赤になる。その場合は該当セッションの再起動が要る。

前提: sentry-elu はグローバル導入済みバイナリを直叩きする (npx 起動は遅く、
共有 npx キャッシュの破損で起動不能になるため)。事前に次を実行しておくこと:
    npm i -g @sentry/mcp-server

config_dir の既定は $HOME と ~/.claude-private。
既定スコープの状態ファイルは ~/.claude/.claude.json ではなく ~/.claude.json
(旧レイアウト) なので、config_dir としては $HOME を指定する。
USAGE
}

main() {
    local mode="apply"
    case "${1:-}" in
        --check) mode="check"; shift ;;
        --audit) mode="audit"; shift ;;
        --scan-projects)
            shift
            printf '### プロジェクトの .mcp.json (%s)\n' "${1:-$PROJECT_ROOT_DEFAULT}"
            check_project_mcp_json "${1:-$PROJECT_ROOT_DEFAULT}"
            return $?
            ;;
        --scan-processes)
            printf '### 実行中プロセスの argv\n'
            check_running_processes
            return $?
            ;;
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

    if [ "$mode" = "audit" ]; then
        python3 "$REPO_ROOT/script/lib/mcp_audit.py" audit "$PROJECT_ROOT_DEFAULT" || failed=1
    fi

    if [ "$failed" -ne 0 ]; then
        print_error "argv にトークンを渡す MCP 定義が残っています。"
        return 1
    fi
    print_success "管理対象の MCP 定義は全て安全な形式です。"
    if [ "$mode" = "apply" ]; then
        print_warning "反映には対象 config dir のセッション再起動が必要です。"
        print_warning "*.pre-mcp-token-fix.* バックアップには旧トークンが平文で残っています。反映確認後は削除してください。"
    fi
}

main "$@"
