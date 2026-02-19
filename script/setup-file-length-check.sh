#!/usr/bin/env bash
# ============================================================================
# setup-file-length-check.sh - ファイル行数チェックのセットアップ
#
# 使用方法:
#   ./setup-file-length-check.sh          # カレントディレクトリにセットアップ
#   ./setup-file-length-check.sh /path    # 指定ディレクトリにセットアップ
# ============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="/usr/local/share/config-templates"

echo "[INFO] ファイル行数チェックをセットアップします..."

# ターゲットディレクトリに移動
cd "$TARGET_DIR"

# scripts ディレクトリを作成
mkdir -p scripts

# check-file-length.sh をコピー
if [ -f "$SCRIPT_DIR/check-file-length.sh" ]; then
  cp "$SCRIPT_DIR/check-file-length.sh" scripts/
  chmod +x scripts/check-file-length.sh
  echo "[SUCCESS] scripts/check-file-length.sh をコピーしました"
elif [ -f /usr/local/script/check-file-length.sh ]; then
  cp /usr/local/script/check-file-length.sh scripts/
  chmod +x scripts/check-file-length.sh
  echo "[SUCCESS] scripts/check-file-length.sh をコピーしました"
else
  echo "[ERROR] check-file-length.sh が見つかりません"
  exit 1
fi

# .filelengthignore をコピー（存在しない場合のみ）
if [ ! -f .filelengthignore ]; then
  if [ -f "$TEMPLATE_DIR/.filelengthignore.template" ]; then
    cp "$TEMPLATE_DIR/.filelengthignore.template" .filelengthignore
    echo "[SUCCESS] .filelengthignore を作成しました"
  else
    # テンプレートがない場合は最小限の内容で作成
    cat > .filelengthignore << 'IGNORE'
# .filelengthignore - 行数チェックの除外パターン
# .gitignore と同じ記法でパターンを指定

# 自動生成ファイル
**/*.generated.*
**/*.gen.*

# ビルド出力
dist/**
build/**
.next/**
node_modules/**
IGNORE
    echo "[SUCCESS] .filelengthignore を作成しました（デフォルト）"
  fi
else
  echo "[INFO] .filelengthignore は既に存在します"
fi

# Husky pre-commit に追加（.husky/pre-commit が存在する場合）
if [ -f .husky/pre-commit ]; then
  if ! grep -q "check-file-length.sh" .husky/pre-commit; then
    echo "" >> .husky/pre-commit
    echo "echo \"[husky] Running file length check...\"" >> .husky/pre-commit
    echo "bash scripts/check-file-length.sh || exit 1" >> .husky/pre-commit
    echo "[SUCCESS] .husky/pre-commit に filelength チェックを追加しました"
  else
    echo "[INFO] .husky/pre-commit には既に filelength チェックが含まれています"
  fi
else
  echo "[INFO] .husky/pre-commit が見つかりません（手動で追加してください）"
  echo "      npx husky add .husky/pre-commit \"bash scripts/check-file-length.sh\""
fi

echo ""
echo "[SUCCESS] ファイル行数チェックのセットアップが完了しました"
echo ""
echo "設定:"
echo "  - 警告閾値: 350行（FILE_LENGTH_WARN_LIMIT で変更可）"
echo "  - エラー閾値: 500行（FILE_LENGTH_HARD_LIMIT で変更可）"
echo "  - 除外設定: .filelengthignore"
