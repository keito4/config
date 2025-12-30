#!/usr/bin/env zsh
# Standard error handling functions

# エラーメッセージの標準化
errors::fatal() {
  local message="${1:?Error message required}"
  echo "❌ FATAL: $message" >&2
  exit 1
}

errors::warn() {
  local message="${1:?Warning message required}"
  echo "⚠️  WARNING: $message" >&2
}

errors::info() {
  local message="${1:?Info message required}"
  echo "ℹ️  INFO: $message"
}

errors::success() {
  local message="${1:?Success message required}"
  echo "✅ $message"
}

# コマンドの存在チェック
errors::require_command() {
  local cmd="${1:?Command name required}"
  local install_hint="${2:-}"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    local msg="Required command not found: $cmd"
    if [[ -n "$install_hint" ]]; then
      msg="$msg\nInstall with: $install_hint"
    fi
    errors::fatal "$msg"
  fi
}

# ファイルの存在チェック
errors::require_file() {
  local file="${1:?File path required}"
  local error_msg="${2:-File not found: $file}"

  if [[ ! -f "$file" ]]; then
    errors::fatal "$error_msg"
  fi
}

# ディレクトリの存在チェック
errors::require_directory() {
  local dir="${1:?Directory path required}"
  local error_msg="${2:-Directory not found: $dir}"

  if [[ ! -d "$dir" ]]; then
    errors::fatal "$error_msg"
  fi
}
