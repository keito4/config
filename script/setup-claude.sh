#!/usr/bin/env bash
# ============================================================================
# Claude Code Setup Script
# このスクリプトは .claude/ の設定を ~/.claude/ に同期し、プラグインをインストールします
# ============================================================================

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_CLAUDE_DIR="${REPO_ROOT}/.claude"
USER_CLAUDE_DIR="${HOME}/.claude"

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 使用方法
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Claude Code の設定を同期し、プラグインをインストールします。

OPTIONS:
    -s, --sync-only       設定ファイルの同期のみ（プラグインインストールなし）
    -p, --plugins-only    プラグインのインストールのみ
    -f, --force           既存ファイルを上書き
    -d, --dry-run         実行せずに処理内容を表示
    -h, --help            このヘルプを表示

EXAMPLES:
    $(basename "$0")              # 全同期＋プラグインインストール
    $(basename "$0") --sync-only  # 設定ファイルのみ同期
    $(basename "$0") --force      # 既存ファイルも上書き

EOF
    exit 0
}

# オプション解析
SYNC_ONLY=false
PLUGINS_ONLY=false
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--sync-only)
            SYNC_ONLY=true
            shift
            ;;
        -p|--plugins-only)
            PLUGINS_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Claude CLI の存在確認
check_claude_cli() {
    if ! command -v claude &> /dev/null; then
        log_warn "Claude CLI が見つかりません。プラグインのインストールはスキップされます。"
        return 1
    fi
    return 0
}

# ディレクトリの同期
sync_directory() {
    local src_dir="$1"
    local dest_dir="$2"
    local dir_name="$3"

    if [[ ! -d "$src_dir" ]]; then
        log_warn "${dir_name} ディレクトリが見つかりません: ${src_dir}"
        return 0
    fi

    log_info "${dir_name} を同期中..."

    # 宛先ディレクトリを作成
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY-RUN] mkdir -p ${dest_dir}"
    else
        mkdir -p "$dest_dir"
    fi

    # ファイルをコピー
    local copied=0
    local skipped=0
    for file in "$src_dir"/*; do
        [[ -f "$file" ]] || continue
        local filename=$(basename "$file")
        local dest_file="${dest_dir}/${filename}"

        if [[ -f "$dest_file" && "$FORCE" == false ]]; then
            log_warn "  スキップ: ${filename} (既存ファイル、--force で上書き可能)"
            skipped=$((skipped + 1))
        else
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY-RUN] cp ${file} ${dest_file}"
            else
                cp "$file" "$dest_file"
                log_success "  コピー: ${filename}"
            fi
            copied=$((copied + 1))
        fi
    done

    log_info "${dir_name}: ${copied} ファイルをコピー、${skipped} ファイルをスキップ"
}

# 設定ファイルの同期
sync_settings() {
    local src_settings="${REPO_CLAUDE_DIR}/settings.json"
    local dest_settings="${USER_CLAUDE_DIR}/settings.json"

    if [[ ! -f "$src_settings" ]]; then
        log_warn "settings.json が見つかりません"
        return 0
    fi

    log_info "settings.json を同期中..."

    if [[ -f "$dest_settings" ]]; then
        # 既存の設定がある場合はマージの案内のみ
        log_warn "既存の settings.json が見つかりました"
        log_info "手動でマージするか、--force オプションで上書きしてください"
        if [[ "$FORCE" == true ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY-RUN] cp ${src_settings} ${dest_settings}"
            else
                cp "$src_settings" "$dest_settings"
                log_success "settings.json を上書きしました"
            fi
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY-RUN] cp ${src_settings} ${dest_settings}"
        else
            mkdir -p "$USER_CLAUDE_DIR"
            cp "$src_settings" "$dest_settings"
            log_success "settings.json をコピーしました"
        fi
    fi
}

# プラグインのインストール
install_plugins() {
    local plugins_file="${REPO_CLAUDE_DIR}/plugins/plugins.txt"

    if [[ ! -f "$plugins_file" ]]; then
        log_warn "plugins.txt が見つかりません: ${plugins_file}"
        return 0
    fi

    if ! check_claude_cli; then
        return 0
    fi

    log_info "プラグインをインストール中..."

    local installed=0
    local failed=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # 空行とコメント行をスキップ
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # 前後の空白を除去
        local plugin=$(echo "$line" | xargs)
        [[ -z "$plugin" ]] && continue

        log_info "  インストール中: ${plugin}"

        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY-RUN] claude plugin install ${plugin}"
            installed=$((installed + 1))
        else
            if claude plugin install "$plugin" 2>/dev/null; then
                log_success "  完了: ${plugin}"
                installed=$((installed + 1))
            else
                log_warn "  スキップまたは失敗: ${plugin}"
                failed=$((failed + 1))
            fi
        fi
    done < "$plugins_file"

    log_info "プラグイン: ${installed} インストール完了、${failed} 失敗/スキップ"
}

# メイン処理
main() {
    log_info "Claude Code セットアップを開始します..."
    log_info "リポジトリ: ${REPO_ROOT}"
    log_info "ユーザー設定: ${USER_CLAUDE_DIR}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "ドライランモード: 実際の変更は行われません"
        echo ""
    fi

    # 設定ファイルの同期
    if [[ "$PLUGINS_ONLY" == false ]]; then
        sync_directory "${REPO_CLAUDE_DIR}/commands" "${USER_CLAUDE_DIR}/commands" "commands"
        sync_directory "${REPO_CLAUDE_DIR}/agents" "${USER_CLAUDE_DIR}/agents" "agents"
        sync_directory "${REPO_CLAUDE_DIR}/hooks" "${USER_CLAUDE_DIR}/hooks" "hooks"
        sync_settings
        echo ""
    fi

    # プラグインのインストール
    if [[ "$SYNC_ONLY" == false ]]; then
        install_plugins
        echo ""
    fi

    log_success "Claude Code セットアップが完了しました！"
}

main
