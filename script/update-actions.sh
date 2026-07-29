#!/usr/bin/env bash
# ============================================================================
# GitHub Actions Version Update Script
# .github/workflows/ 配下のアクションを最新バージョンに更新します
# ============================================================================

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run|--check) DRY_RUN=true ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKFLOWS_DIR="${PROJECT_ROOT}/.github/workflows"

# Source shared output library (provides log_info, log_success, log_warn, color vars)
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/output.sh" 2>/dev/null || {
  GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' RED='\033[0;31m' NC='\033[0m'
  log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
  log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
  log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
  log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
}

# 必須コマンドチェック
if ! command -v gh >/dev/null 2>&1; then
  log_error "gh (GitHub CLI) is required to update actions"
  exit 1
fi

log_info "GitHub Actions バージョン更新を開始します..."

# sed メタ文字エスケープ
escape_sed() {
  printf '%s' "$1" | sed 's/[.[\/*^$]/\\&/g'
}

# SemVer タグかどうか判定（v prefix 有無両対応）
is_semver_tag() {
  local ref="$1"
  [[ "$ref" =~ ^v?[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]
}

# SHA ピンニングかどうか判定（40文字hex）
is_sha_pin() {
  local ref="$1"
  [[ "$ref" =~ ^[0-9a-f]{40}$ ]]
}

# 最新タグを取得
get_latest_tag() {
  local owner_repo="$1"
  local tag

  # まず releases/latest を試行
  tag=$(gh api "repos/${owner_repo}/releases/latest" --jq '.tag_name' 2>/dev/null) || true

  if [[ -n "$tag" ]]; then
    echo "$tag"
    return 0
  fi

  # フォールバック: 最新タグを取得
  tag=$(gh api "repos/${owner_repo}/tags?per_page=1" --jq '.[0].name' 2>/dev/null) || true

  if [[ -n "$tag" ]]; then
    echo "$tag"
    return 0
  fi

  return 1
}

# v prefix の調整
normalize_tag() {
  local current_ref="$1"
  local latest_tag="$2"

  if [[ "$current_ref" == v* ]]; then
    # 現在のタグが v 付き → v 付きで返す
    if [[ "$latest_tag" == v* ]]; then
      echo "$latest_tag"
    else
      echo "v${latest_tag}"
    fi
  else
    # 現在のタグが v なし → v を除去
    echo "${latest_tag#v}"
  fi
}

# 更新対象外の参照かどうか判定（ローカルアクション・SHA固定・メジャータグ固定・ブランチ固定など）
is_ignorable_reference() {
  local full_action="$1"
  local current_ref="$2"

  # ローカルアクション (./) や docker:// はスキップ
  if [[ "$full_action" == ./* ]] || [[ "$full_action" == docker://* ]]; then
    return 0
  fi

  # SHA ピンニングはスキップ
  if is_sha_pin "$current_ref"; then
    return 0
  fi

  # メジャータグ固定（v1, v3 など数字のみ）はスキップ
  if [[ "$current_ref" =~ ^v?[0-9]+$ ]]; then
    return 0
  fi

  # ブランチ固定（master, main など）はスキップ
  if [[ "$current_ref" == "master" ]] || [[ "$current_ref" == "main" ]]; then
    return 0
  fi

  # SemVer タグのみ更新対象
  if ! is_semver_tag "$current_ref"; then
    return 0
  fi

  return 1
}

# owner/repo を抽出（サブパス対応: org/repo/path → org/repo）
extract_owner_repo() {
  local full_action="$1"
  local slash_count

  slash_count=$(echo "$full_action" | tr -cd '/' | wc -c | tr -d ' ')
  if [[ "$slash_count" -ge 2 ]]; then
    echo "$full_action" | cut -d'/' -f1-2
  else
    echo "$full_action"
  fi
}

# 全ワークフローファイルでアクション参照を置換
replace_action_ref() {
  local full_action="$1"
  local current_ref="$2"
  local new_ref="$3"
  local escaped_action wf

  escaped_action=$(escape_sed "$full_action")

  for wf in "${workflow_files[@]}"; do
    sed -i.bak "s|\(uses:.*\)${escaped_action}@${current_ref}|\1${escaped_action}@${new_ref}|g" "$wf" && rm -f "$wf.bak"
  done
}

# 1つの uses: 行を処理し、更新可能なら反映する
# 更新結果は processed_actions / updated_actions / skipped_actions（グローバル）に記録する
process_uses_line() {
  local line="$1"
  local full_action current_ref owner_repo latest_tag new_ref action_key

  [[ "$line" =~ uses:[[:space:]]*([^@]+)@([^[:space:]#]+) ]] || return 0

  full_action=$(echo "${BASH_REMATCH[1]}" | xargs)
  current_ref="${BASH_REMATCH[2]}"

  is_ignorable_reference "$full_action" "$current_ref" && return 0

  # 処理済みチェック（同一アクション＋同一バージョンは1回のみ）
  action_key="${full_action}@${current_ref}"
  [[ -n "${processed_actions[$action_key]+x}" ]] && return 0
  processed_actions[$action_key]=1

  owner_repo=$(extract_owner_repo "$full_action")

  latest_tag=$(get_latest_tag "$owner_repo") || true
  if [[ -z "$latest_tag" ]]; then
    log_warn "[SKIP] ${full_action}: リリース情報取得失敗"
    skipped_actions+=("${full_action}@${current_ref}")
    return 0
  fi

  new_ref=$(normalize_tag "$current_ref" "$latest_tag")

  # 既に最新ならスキップ
  [[ "$current_ref" == "$new_ref" ]] && return 0

  log_info "${full_action}: ${current_ref} -> ${new_ref}"

  if [[ "$DRY_RUN" == false ]]; then
    replace_action_ref "$full_action" "$current_ref" "$new_ref"
  fi

  updated_actions+=("${full_action}: ${current_ref} -> ${new_ref}")
}

# 全ワークフローファイルの uses: 行を走査
scan_workflow_files() {
  local workflow_file line

  for workflow_file in "${workflow_files[@]}"; do
    while IFS= read -r line; do
      process_uses_line "$line"
    done < <(grep 'uses:' "$workflow_file" || true)
  done
}

# 変更サマリ表示
print_summary() {
  local update skip

  echo ""
  if [[ ${#updated_actions[@]} -gt 0 ]]; then
    log_success "更新されたアクション:"
    for update in "${updated_actions[@]}"; do
      echo "  - $update"
    done
  else
    log_success "全てのアクションは最新です"
  fi

  if [[ ${#skipped_actions[@]} -gt 0 ]]; then
    echo ""
    log_warn "スキップされたアクション:"
    for skip in "${skipped_actions[@]}"; do
      echo "  - $skip"
    done
  fi

  echo ""
  log_success "GitHub Actions バージョン更新完了！"
}

# ワークフローファイルを収集
workflow_files=()
while IFS= read -r -d '' file; do
  workflow_files+=("$file")
done < <(find "${WORKFLOWS_DIR}" -name '*.yml' -o -name '*.yaml' | tr '\n' '\0')

if [[ ${#workflow_files[@]} -eq 0 ]]; then
  log_warn "ワークフローファイルが見つかりません"
  exit 0
fi

log_info "${#workflow_files[@]} 個のワークフローファイルを検出"

# 重複排除のため処理済みアクションを記録
declare -A processed_actions
declare -a updated_actions=()
declare -a skipped_actions=()

scan_workflow_files
print_summary
