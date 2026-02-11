#!/usr/bin/env bash
set -euo pipefail

# Codespace作成スクリプト
# Usage: ./script/create-codespace.sh [options]

# デフォルト値（現在のgit情報から取得）
get_current_branch() {
  git branch --show-current 2>/dev/null || echo "main"
}

get_current_repo() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if [[ -n "${remote_url}" ]]; then
    # SSH形式: git@github.com:owner/repo.git
    # HTTPS形式: https://github.com/owner/repo.git
    echo "${remote_url}" | sed -E 's|.*github\.com[:/]||; s|\.git$||'
  else
    echo "keito4/config"
  fi
}

DEFAULT_BRANCH="$(get_current_branch)"
DEFAULT_MACHINE="standardLinux32gb"
DEFAULT_REPO="$(get_current_repo)"
DEFAULT_IDLE_TIMEOUT="30m"
DEFAULT_DEVCONTAINER_PATH=".devcontainer/codespaces/devcontainer.json"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Codespaceを作成します。

Options:
  -b, --branch <branch>       ブランチ (default: ${DEFAULT_BRANCH})
  -m, --machine <size>        マシンサイズ (default: ${DEFAULT_MACHINE})
  -r, --repo <owner/repo>     リポジトリ (default: ${DEFAULT_REPO})
  -t, --idle-timeout <time>   アイドルタイムアウト (default: ${DEFAULT_IDLE_TIMEOUT})
  -n, --name <name>           表示名 (48文字以内)
  -c, --devcontainer <path>   devcontainer.jsonのパス (default: ${DEFAULT_DEVCONTAINER_PATH})
  -l, --list-machines         利用可能なマシンサイズを表示
  -d, --dry-run               実行せずにコマンドを表示
  -h, --help                  このヘルプを表示

Machine sizes:
  basicLinux32gb      2-core,  8GB RAM,  32GB storage
  standardLinux32gb   4-core, 16GB RAM,  32GB storage (default)
  premiumLinux        8-core, 32GB RAM,  64GB storage
  largePremiumLinux  16-core, 64GB RAM, 128GB storage

Examples:
  # デフォルト設定で作成
  $(basename "$0")

  # 特定のブランチで大きいマシンを使用
  $(basename "$0") -b feature/my-feature -m premiumLinux

  # 表示名を指定
  $(basename "$0") -n "My Dev Environment"

  # ローカル用devcontainerを使用
  $(basename "$0") -c .devcontainer/devcontainer.json

  # ドライラン（コマンド確認のみ）
  $(basename "$0") --dry-run
EOF
}

list_machines() {
  echo -e "${BLUE}=== 利用可能なマシンサイズ ===${NC}"
  echo ""
  printf "%-20s %-10s %-12s %-15s\n" "Name" "CPU" "RAM" "Storage"
  printf "%-20s %-10s %-12s %-15s\n" "--------------------" "----------" "------------" "---------------"
  printf "%-20s %-10s %-12s %-15s\n" "basicLinux32gb" "2-core" "8GB" "32GB"
  printf "%-20s %-10s %-12s %-15s\n" "standardLinux32gb" "4-core" "16GB" "32GB"
  printf "%-20s %-10s %-12s %-15s\n" "premiumLinux" "8-core" "32GB" "64GB"
  printf "%-20s %-10s %-12s %-15s\n" "largePremiumLinux" "16-core" "64GB" "128GB"
}

# 引数の解析
BRANCH="${DEFAULT_BRANCH}"
MACHINE="${DEFAULT_MACHINE}"
REPO="${DEFAULT_REPO}"
IDLE_TIMEOUT="${DEFAULT_IDLE_TIMEOUT}"
DEVCONTAINER_PATH="${DEFAULT_DEVCONTAINER_PATH}"
DISPLAY_NAME=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--branch)
      BRANCH="$2"
      shift 2
      ;;
    -m|--machine)
      MACHINE="$2"
      shift 2
      ;;
    -r|--repo)
      REPO="$2"
      shift 2
      ;;
    -t|--idle-timeout)
      IDLE_TIMEOUT="$2"
      shift 2
      ;;
    -n|--name)
      DISPLAY_NAME="$2"
      shift 2
      ;;
    -c|--devcontainer)
      DEVCONTAINER_PATH="$2"
      shift 2
      ;;
    -l|--list-machines)
      list_machines
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}" >&2
      usage
      exit 1
      ;;
  esac
done

# gh CLI のチェック
if ! command -v gh &>/dev/null; then
  echo -e "${RED}Error: gh CLI がインストールされていません${NC}" >&2
  echo "インストール: https://cli.github.com/"
  exit 1
fi

# 認証チェック
if ! gh auth status &>/dev/null; then
  echo -e "${RED}Error: gh CLI で認証されていません${NC}" >&2
  echo "認証: gh auth login"
  exit 1
fi

# マシンサイズのバリデーション
valid_machines=("basicLinux32gb" "standardLinux32gb" "premiumLinux" "largePremiumLinux")
if [[ ! " ${valid_machines[*]} " =~ " ${MACHINE} " ]]; then
  echo -e "${RED}Error: Invalid machine size '${MACHINE}'${NC}" >&2
  echo "Valid options: ${valid_machines[*]}"
  exit 1
fi

# 表示名のバリデーション
if [[ -n "${DISPLAY_NAME}" && ${#DISPLAY_NAME} -gt 48 ]]; then
  echo -e "${RED}Error: Display name must be 48 characters or less${NC}" >&2
  exit 1
fi

# コマンドの構築
CMD=(gh codespace create)
CMD+=(-R "${REPO}")
CMD+=(-b "${BRANCH}")
CMD+=(-m "${MACHINE}")
CMD+=(--idle-timeout "${IDLE_TIMEOUT}")
CMD+=(--devcontainer-path "${DEVCONTAINER_PATH}")

if [[ -n "${DISPLAY_NAME}" ]]; then
  CMD+=(-d "${DISPLAY_NAME}")
fi

# 実行
echo -e "${BLUE}=== Codespace 作成 ===${NC}"
echo ""
echo -e "リポジトリ:         ${GREEN}${REPO}${NC}"
echo -e "ブランチ:           ${GREEN}${BRANCH}${NC}"
echo -e "マシンサイズ:       ${GREEN}${MACHINE}${NC}"
echo -e "アイドルタイムアウト: ${GREEN}${IDLE_TIMEOUT}${NC}"
echo -e "DevContainer:       ${GREEN}${DEVCONTAINER_PATH}${NC}"
if [[ -n "${DISPLAY_NAME}" ]]; then
  echo -e "表示名:             ${GREEN}${DISPLAY_NAME}${NC}"
fi
echo ""

if [[ "${DRY_RUN}" == true ]]; then
  echo -e "${YELLOW}[Dry Run] 実行コマンド:${NC}"
  echo "${CMD[*]}"
  exit 0
fi

echo -e "${BLUE}Codespaceを作成中...${NC}"
echo ""

if "${CMD[@]}"; then
  echo ""
  echo -e "${GREEN}Codespaceが作成されました！${NC}"
  echo ""
  echo -e "接続するには:"
  echo -e "  SSH:        ${YELLOW}gh codespace ssh${NC}"
  echo -e "  VS Code:    ${YELLOW}gh codespace code${NC}"
  echo -e "  ブラウザ:   ${YELLOW}gh codespace view --web${NC}"
  echo ""
  echo -e "管理コマンド:"
  echo -e "  一覧表示:   ${YELLOW}gh codespace list${NC}"
  echo -e "  停止:       ${YELLOW}gh codespace stop${NC}"
  echo -e "  削除:       ${YELLOW}gh codespace delete${NC}"
else
  echo -e "${RED}Codespaceの作成に失敗しました${NC}" >&2
  exit 1
fi
