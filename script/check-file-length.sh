#!/usr/bin/env bash
#
# check-file-length.sh - ステージされたファイルの行数チェック
#
# 除外パターンは .filelengthignore で管理（.gitignore と同じ記法）
#

set -euo pipefail

HARD_LIMIT=500
WARN_LIMIT=350
REPO_ROOT="$(git rev-parse --show-toplevel)"
IGNORE_FILE="$REPO_ROOT/.filelengthignore"

# ステージされた TS/JS ファイル（削除以外）を取得
staged_files() {
  git diff --cached --name-only --diff-filter=d -- \
    '*.ts' '*.tsx' '*.js' '*.jsx'
}

# .filelengthignore のパターンで除外判定（git check-ignore を .gitignore 記法で流用）
is_ignored() {
  local file="$1"
  [ ! -f "$IGNORE_FILE" ] && return 1
  echo "$file" |
    git -c "core.excludesFile=$IGNORE_FILE" check-ignore --no-index -q --stdin 2>/dev/null
}

errors=()
warnings=()

while IFS= read -r file; do
  [ -z "$file" ] && continue
  is_ignored "$file" && continue

  line_count=$(git show ":$file" 2>/dev/null | wc -l)

  if [ "$line_count" -ge "$HARD_LIMIT" ]; then
    errors+=("  ❌ ${file} (${line_count}行)")
  elif [ "$line_count" -ge "$WARN_LIMIT" ]; then
    warnings+=("  ⚠️  ${file} (${line_count}行)")
  fi
done < <(staged_files)

# 警告の出力（コミットはブロックしない）
if [ ${#warnings[@]} -gt 0 ]; then
  echo ""
  echo "[file-length] ⚠️  ${WARN_LIMIT}行超 — 分割を検討してください"
  printf '%s\n' "${warnings[@]}"
fi

# エラーの出力（コミットをブロック）
if [ ${#errors[@]} -gt 0 ]; then
  echo ""
  echo "[file-length] ❌ ${HARD_LIMIT}行以上のファイルはコミットできません"
  printf '%s\n' "${errors[@]}"
  echo ""
  echo "対処方法:"
  echo "  1. ファイルを分割する"
  echo "  2. .filelengthignore に除外パターンを追加する"
  exit 1
fi
