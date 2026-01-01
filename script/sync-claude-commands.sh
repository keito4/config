#!/usr/bin/env bash
# ============================================================================
# Claude Commands Sync Script
# .claude/commands/ をユーザーレベル (~/.claude/commands/) に同期します
# ============================================================================

set -euo pipefail

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SOURCE_DIR="${PROJECT_ROOT}/.claude/commands"
TARGET_DIR="${HOME}/.claude/commands"

log_info "Claude コマンドの同期を開始します..."

# ソースディレクトリの存在確認
if [[ ! -d "$SOURCE_DIR" ]]; then
    log_warn "ソースディレクトリが見つかりません: ${SOURCE_DIR}"
    exit 0
fi

# ターゲットディレクトリを作成
mkdir -p "$TARGET_DIR"

# コマンドファイルをコピー
log_info "コピー元: ${SOURCE_DIR}"
log_info "コピー先: ${TARGET_DIR}"

if cp -r "$SOURCE_DIR/"* "$TARGET_DIR/" 2>/dev/null; then
    # コピーされたファイル数をカウント
    file_count=$(find "$SOURCE_DIR" -type f -name "*.md" | wc -l | xargs)
    log_success "Claude コマンド ${file_count} 個を ${TARGET_DIR} に同期しました"

    # 同期されたコマンド一覧を表示
    log_info "同期されたコマンド:"
    find "$TARGET_DIR" -type f -name "*.md" -exec basename {} .md \; | sort | sed 's/^/  - \//'
else
    log_warn "コマンドのコピーに失敗しました"
    exit 1
fi

log_success "Claude コマンドの同期が完了しました！"
