#!/usr/bin/env bash
# Resolve workspace:* dependencies before publishing monorepo packages
#
# This script resolves `workspace:*` dependencies to actual versions before
# publishing to npm. It's designed to work with pnpm workspaces and semantic-release.
#
# Usage:
#   ./resolve-workspace-deps.sh [package.json path]
#
# Environment variables:
#   WORKSPACE_PACKAGE_SCOPE - Package scope name (e.g., "@scope/shared")
#   WORKSPACE_TAG_PREFIX    - Git tag prefix pattern (e.g., "shared-v")
#   WORKSPACE_DEP_KEY       - Dependency key in package.json (default: "dependencies")
#   WORKSPACE_VERSION_RANGE - Version range prefix (default: "^")
#   REPO_ROOT              - Repository root path (auto-detected if not set)

set -euo pipefail

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
  printf "${BLUE}==> %s${NC}\n" "$1"
}

log_success() {
  printf "${GREEN}✓ %s${NC}\n" "$1"
}

log_warn() {
  printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

log_error() {
  printf "${RED}✗ %s${NC}\n" "$1" >&2
}

# 設定変数（環境変数から取得、またはデフォルト値を使用）
PACKAGE_SCOPE="${WORKSPACE_PACKAGE_SCOPE:-}"
TAG_PREFIX="${WORKSPACE_TAG_PREFIX:-}"
DEP_KEY="${WORKSPACE_DEP_KEY:-dependencies}"
VERSION_RANGE="${WORKSPACE_VERSION_RANGE:-^}"
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# パッケージ.jsonファイルのパス（引数から取得、またはカレントディレクトリ）
PACKAGE_JSON="${1:-package.json}"

# 必須パラメータのチェック
if [[ -z "$PACKAGE_SCOPE" ]]; then
  log_error "WORKSPACE_PACKAGE_SCOPE environment variable is required"
  echo "Example: export WORKSPACE_PACKAGE_SCOPE='@scope/shared'" >&2
  exit 1
fi

if [[ -z "$TAG_PREFIX" ]]; then
  log_error "WORKSPACE_TAG_PREFIX environment variable is required"
  echo "Example: export WORKSPACE_TAG_PREFIX='shared-v'" >&2
  exit 1
fi

# package.jsonの存在確認
if [[ ! -f "$PACKAGE_JSON" ]]; then
  log_error "Package file not found: $PACKAGE_JSON"
  exit 1
fi

# jqの存在確認
if ! command -v jq >/dev/null 2>&1; then
  log_error "jq is required but not installed"
  exit 1
fi

log "Resolving workspace:* dependencies in $PACKAGE_JSON"

# workspace:* 依存が存在するかチェック
WORKSPACE_DEPS=$(jq -r ".$DEP_KEY // {} | to_entries[] | select(.value == \"workspace:*\") | .key" "$PACKAGE_JSON")

if [[ -z "$WORKSPACE_DEPS" ]]; then
  log_warn "No workspace:* dependencies found in $DEP_KEY"
  exit 0
fi

log "Found workspace:* dependencies:"
echo "$WORKSPACE_DEPS" | while IFS= read -r dep; do
  echo "  - $dep"
done

# パッケージスコープのディレクトリを特定
PACKAGE_NAME=$(echo "$PACKAGE_SCOPE" | sed 's|^@[^/]*/||')
SHARED_PACKAGE_DIR="${REPO_ROOT}/packages/${PACKAGE_NAME}"

# バージョンの取得（Gitタグから、フォールバックとしてpackage.jsonから）
log "Resolving version for $PACKAGE_SCOPE"

SHARED_VERSION=""

# Gitタグから取得を試みる（semantic-releaseが作成するタグ）
if git rev-parse --git-dir > /dev/null 2>&1; then
  SHARED_VERSION=$(git describe --tags --match "${TAG_PREFIX}*" --abbrev=0 2>/dev/null | sed "s/${TAG_PREFIX}//" || true)

  if [[ -n "$SHARED_VERSION" ]]; then
    log_success "Version from git tag: $SHARED_VERSION"
  fi
fi

# Gitタグが見つからない場合、package.jsonから取得
if [[ -z "$SHARED_VERSION" ]]; then
  if [[ -f "$SHARED_PACKAGE_DIR/package.json" ]]; then
    SHARED_VERSION=$(jq -r '.version' "$SHARED_PACKAGE_DIR/package.json")
    log_warn "Version from package.json: $SHARED_VERSION (no git tag found)"
  else
    log_error "Could not determine version: no git tag and $SHARED_PACKAGE_DIR/package.json not found"
    exit 1
  fi
fi

# バージョンの妥当性チェック
if [[ ! "$SHARED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  log_error "Invalid version format: $SHARED_VERSION"
  exit 1
fi

# package.jsonを更新
log "Updating $PACKAGE_JSON"

# 一時ファイルを使用して更新
TEMP_FILE=$(mktemp)

# workspace:* を実際のバージョンに置換
jq --arg pkg "$PACKAGE_SCOPE" \
   --arg version "${VERSION_RANGE}${SHARED_VERSION}" \
   --arg depKey "$DEP_KEY" \
   "if .[\$depKey][\$pkg] == \"workspace:*\" then .[\$depKey][\$pkg] = \$version else . end" \
   "$PACKAGE_JSON" > "$TEMP_FILE"

# 更新内容を確認
if diff -q "$PACKAGE_JSON" "$TEMP_FILE" > /dev/null 2>&1; then
  log_warn "No changes made to $PACKAGE_JSON"
  rm -f "$TEMP_FILE"
  exit 0
fi

# ファイルを置換
mv "$TEMP_FILE" "$PACKAGE_JSON"

log_success "Updated $PACKAGE_SCOPE: workspace:* → ${VERSION_RANGE}${SHARED_VERSION}"
log_success "Workspace dependencies resolved successfully"
