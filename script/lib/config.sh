#!/usr/bin/env zsh
# Common configuration functions for import/export scripts

set -euo pipefail

# Constants for Claude configuration
typeset -ga CONFIG_CLAUDE_SHARED_FILES=(settings.json CLAUDE.md)
typeset -ga CONFIG_CLAUDE_SHARED_DIRS=(commands agents hooks)
typeset -ga CONFIG_CLAUDE_PLUGIN_FILES=(config.json known_marketplaces.json)

# Constants for Codex configuration
typeset -ga CONFIG_CODEX_SHARED_FILES=(config.toml)
typeset -ga CONFIG_CODEX_SHARED_DIRS=(prompts)

# Constants for Cursor configuration
typeset -ga CONFIG_CURSOR_SHARED_DIRS=(rules)

# Claude設定のインポート
config::import_claude() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.claude}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Claude設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CLAUDE_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Imported $file"
    fi
  done

  # ディレクトリのコピー
  for dir in "${CONFIG_CLAUDE_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
      echo "✅ Imported $dir/"
    fi
  done

  # プラグイン設定
  if [[ -d "$source_dir/plugins" ]]; then
    mkdir -p "$target_dir/plugins"
    for file in "${CONFIG_CLAUDE_PLUGIN_FILES[@]}"; do
      if [[ -f "$source_dir/plugins/$file" ]]; then
        cp "$source_dir/plugins/$file" "$target_dir/plugins/$file"
        echo "✅ Imported plugins/$file"
      fi
    done
  fi
}

# Claude設定のエクスポート
config::export_claude() {
  local source_dir="${1:-$HOME/.claude}"
  local target_dir="${2:?Target directory required}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Claude設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CLAUDE_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Exported $file"
    fi
  done

  # ディレクトリのエクスポート
  for dir in "${CONFIG_CLAUDE_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]] && [[ -n "$(ls -A "$source_dir/$dir" 2>/dev/null)" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null && \
        echo "✅ Exported $dir/" || \
        echo "⚠️  No $dir found"
    fi
  done

  # プラグイン設定
  if [[ -d "$source_dir/plugins" ]]; then
    mkdir -p "$target_dir/plugins"
    for file in "${CONFIG_CLAUDE_PLUGIN_FILES[@]}"; do
      if [[ -f "$source_dir/plugins/$file" ]]; then
        cp "$source_dir/plugins/$file" "$target_dir/plugins/$file"
        echo "✅ Exported plugins/$file"
      fi
    done
  fi
}

# MCP設定のインポート
config::import_mcp() {
  local source_file="${1:?Source file required}"
  local target_file="${2:-$HOME/.mcp.json}"

  if [[ ! -f "$source_file" ]]; then
    echo "⚠️  MCP設定ファイルが見つかりません: $source_file"
    return 1
  fi

  cp "$source_file" "$target_file"
  echo "✅ Imported .mcp.json"
  echo "⚠️  注意: 環境変数を設定してください"
  echo "    - OPENAI_API_KEY: o3-search用"
  echo "    - LINEAR_API_KEY: Linear MCP用"
}

# MCP設定のエクスポート
config::export_mcp() {
  local source_file="${1:-$HOME/.mcp.json}"
  local target_file="${2:?Target file required}"

  if [[ ! -f "$source_file" ]]; then
    echo "⚠️  MCP設定ファイルが見つかりません: $source_file"
    return 1
  fi

  # APIキーをプレースホルダーに置換
  sed -E 's/"(sk-[a-zA-Z0-9]+)"/"${OPENAI_API_KEY}"/g' "$source_file" > "$target_file"
  echo "✅ Exported .mcp.json (API keys replaced with placeholders)"
}

# Codex設定のインポート
config::import_codex() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.codex}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Codex設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CODEX_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Imported codex/$file"
    fi
  done

  # ディレクトリのコピー
  for dir in "${CONFIG_CODEX_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
      echo "✅ Imported codex/$dir/"
    fi
  done
}

# Codex設定のエクスポート
config::export_codex() {
  local source_dir="${1:-$HOME/.codex}"
  local target_dir="${2:?Target directory required}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Codex設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CODEX_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Exported codex/$file"
    fi
  done

  # ディレクトリのエクスポート
  for dir in "${CONFIG_CODEX_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]] && [[ -n "$(ls -A "$source_dir/$dir" 2>/dev/null)" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null && \
        echo "✅ Exported codex/$dir/" || \
        echo "⚠️  No codex/$dir found"
    fi
  done
}

# Cursor設定のインポート
config::import_cursor() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.cursor}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Cursor設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  # ディレクトリのコピー
  for dir in "${CONFIG_CURSOR_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
      echo "✅ Imported cursor/$dir/"
    fi
  done
}

# Cursor設定のエクスポート
config::export_cursor() {
  local source_dir="${1:-$HOME/.cursor}"
  local target_dir="${2:?Target directory required}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Cursor設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  # ディレクトリのエクスポート
  for dir in "${CONFIG_CURSOR_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]] && [[ -n "$(ls -A "$source_dir/$dir" 2>/dev/null)" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null && \
        echo "✅ Exported cursor/$dir/" || \
        echo "⚠️  No cursor/$dir found"
    fi
  done
}

# Git設定のフィルタリング
config::filter_gitconfig() {
  local input_file="${1:?Input file required}"
  local output_file="${2:?Output file required}"

  # macOS (BSD sed) compatible version
  sed -E -e '/^\[user\]/,/^\[/{' \
    -e 's/^[[:space:]]*name[[:space:]]*=.*$/	# name = # Configure with: git config --global user.name "Your Name"/' \
    -e 's/^[[:space:]]*email[[:space:]]*=.*$/	# email = # Configure with: git config --global user.email "your.email@example.com"/' \
    -e 's/^[[:space:]]*signingkey[[:space:]]*=.*$/	# signingkey = # Configure with: git config --global user.signingkey "$(cat ~\/.ssh\/id_ed25519.pub)"/' \
    -e '}' "$input_file" > "$output_file"

  echo "✅ gitconfig exported (personal info filtered)"
}

# クレデンシャルのフィルタリング
config::filter_credentials() {
  local input_file="${1:?Input file required}"
  local output_file="${2:?Output file required}"

  local credential_pattern='export\s+(NPM_TOKEN|BUNDLE_RUBYGEMS__[A-Z_]*|[A-Z_]*TOKEN|[A-Z_]*SECRET|[A-Z_]*PASSWORD|[A-Z_]*API_KEY|[A-Z_]*CREDENTIAL)='

  if grep -q -E "$credential_pattern" "$input_file"; then
    grep -v -E "$credential_pattern" "$input_file" > "$output_file"
    echo "⚠️  Credentials filtered from $(basename "$input_file")"
  else
    cp "$input_file" "$output_file"
    echo "✅ No credentials found in $(basename "$input_file")"
  fi
}
