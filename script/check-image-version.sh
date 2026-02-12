#!/usr/bin/env bash
#
# check-image-version.sh - DevContainer イメージのバージョン情報を表示
#

set -euo pipefail

VERSION_FILE="/etc/config-base-version"

# バージョンファイルの確認
if [ -f "$VERSION_FILE" ]; then
  VERSION=$(cat "$VERSION_FILE")
  echo "config-base version: $VERSION"
else
  echo "config-base version: unknown (version file not found)"
  echo ""
  echo "Note: Version tracking was added in v1.64.0"
  echo "Consider updating to the latest image: ghcr.io/keito4/config-base:latest"
  exit 1
fi

# オプション: 詳細表示
if [ "${1:-}" = "-v" ] || [ "${1:-}" = "--verbose" ]; then
  echo ""
  echo "Additional info:"
  echo "  Image source: https://github.com/keito4/config"
  echo "  Releases: https://github.com/keito4/config/releases"

  # Docker ラベルから追加情報を取得（コンテナ外で実行時）
  if command -v docker &> /dev/null; then
    CURRENT_IMAGE=$(docker inspect --format '{{.Config.Image}}' "$(hostname)" 2>/dev/null || echo "")
    if [ -n "$CURRENT_IMAGE" ]; then
      echo "  Current image: $CURRENT_IMAGE"
    fi
  fi
fi
