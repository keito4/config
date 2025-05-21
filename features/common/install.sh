#!/bin/sh
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [ -f "$REPO_ROOT/script/import.sh" ]; then
  /bin/zsh "$REPO_ROOT/script/import.sh"
fi
