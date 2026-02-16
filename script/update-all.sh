#!/usr/bin/env bash
# ============================================================================
# Unified Update Orchestrator
# 全依存関係（npm, Claude Code, GitHub Actions）を一括更新します
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# オプション解析
skip_libs=false
skip_claude=false
skip_actions=false

for arg in "$@"; do
  case "$arg" in
    --skip-libs) skip_libs=true ;;
    --skip-claude) skip_claude=true ;;
    --skip-actions) skip_actions=true ;;
    --help|-h)
      echo "Usage: $(basename "$0") [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --skip-libs      update:libs をスキップ"
      echo "  --skip-claude    update:claude をスキップ"
      echo "  --skip-actions   update:actions をスキップ"
      echo "  --help, -h       ヘルプを表示"
      exit 0
      ;;
    *)
      log_error "不明なオプション: $arg"
      exit 1
      ;;
  esac
done

log_info "一括更新を開始します..."
echo ""

# 各ステップの結果を記録
declare -A step_results

# Step 1: npm 依存関係 + グローバルツール
if [[ "$skip_libs" == "true" ]]; then
  log_warn "[SKIP] update:libs (--skip-libs)"
  step_results[libs]="skipped"
else
  log_info "===== Step 1/3: npm 依存関係更新 ====="
  set +e
  bash "${SCRIPT_DIR}/update-libraries.sh"
  libs_exit=$?
  set -e
  if [[ $libs_exit -eq 0 ]]; then
    step_results[libs]="success"
  else
    step_results[libs]="failed"
    log_error "update:libs が失敗しました (exit code: ${libs_exit})"
  fi
  echo ""
fi

# Step 2: Claude Code (Dockerfile)
if [[ "$skip_claude" == "true" ]]; then
  log_warn "[SKIP] update:claude (--skip-claude)"
  step_results[claude]="skipped"
else
  log_info "===== Step 2/3: Claude Code 更新 ====="
  set +e
  bash "${SCRIPT_DIR}/update-claude-code.sh"
  claude_exit=$?
  set -e
  if [[ $claude_exit -eq 0 ]]; then
    step_results[claude]="success"
  else
    step_results[claude]="failed"
    log_error "update:claude が失敗しました (exit code: ${claude_exit})"
  fi
  echo ""
fi

# Step 3: GitHub Actions バージョン
if [[ "$skip_actions" == "true" ]]; then
  log_warn "[SKIP] update:actions (--skip-actions)"
  step_results[actions]="skipped"
else
  log_info "===== Step 3/3: GitHub Actions 更新 ====="
  set +e
  bash "${SCRIPT_DIR}/update-actions.sh"
  actions_exit=$?
  set -e
  if [[ $actions_exit -eq 0 ]]; then
    step_results[actions]="success"
  else
    step_results[actions]="failed"
    log_error "update:actions が失敗しました (exit code: ${actions_exit})"
  fi
  echo ""
fi

# 最終サマリ
echo "============================================"
log_info "更新サマリ:"
has_failure=false
for step in libs claude actions; do
  result="${step_results[$step]}"
  case "$result" in
    success)  echo -e "  ${GREEN}[OK]${NC}   ${step}" ;;
    failed)   echo -e "  ${RED}[FAIL]${NC} ${step}"; has_failure=true ;;
    skipped)  echo -e "  ${YELLOW}[SKIP]${NC} ${step}" ;;
  esac
done
echo "============================================"

if [[ "$has_failure" == "true" ]]; then
  log_error "一部のステップが失敗しました"
  exit 1
fi

log_success "全ての更新が完了しました！"
