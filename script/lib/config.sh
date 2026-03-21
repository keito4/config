#!/usr/bin/env zsh
# Common configuration functions for import/export scripts

set -euo pipefail

# Constants for Claude configuration
typeset -ga CONFIG_CLAUDE_SHARED_FILES=(settings.json CLAUDE.md)
typeset -ga CONFIG_CLAUDE_SHARED_DIRS=(commands agents hooks)
typeset -ga CONFIG_CLAUDE_PLUGIN_FILES=(config.json known_marketplaces.json)

# Constants for Codex configuration
typeset -ga CONFIG_CODEX_SHARED_FILES=(config.toml)
typeset -ga CONFIG_CODEX_SHARED_DIRS=(prompts rules)

# Constants for Cursor configuration
typeset -ga CONFIG_CURSOR_SHARED_FILES=(mcp.json)
typeset -ga CONFIG_CURSOR_SHARED_DIRS=(rules)

# Constants for Gemini configuration
typeset -ga CONFIG_GEMINI_SHARED_FILES=(settings.json)

# Claude設定のインポート
config::import_claude() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.claude}"
  local use_symlink="${CLAUDE_IMPORT_SYMLINK:-1}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Claude設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  # 絶対パスに変換
  source_dir="$(cd "$source_dir" && pwd)"

  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CLAUDE_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        ln -snf "$source_dir/$file" "$target_dir/$file"
        echo "🔗 Linked $file"
      else
        cp "$source_dir/$file" "$target_dir/$file"
        echo "✅ Imported $file"
      fi
    fi
  done

  # ディレクトリのリンクまたはコピー
  for dir in "${CONFIG_CLAUDE_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        # 既存の通常ディレクトリを削除してからリンク（シンボリックリンクは ln -snf で上書き可能）
        if [[ -d "$target_dir/$dir" && ! -L "$target_dir/$dir" ]]; then
          rm -rf "$target_dir/$dir"
        fi
        ln -snf "$source_dir/$dir" "$target_dir/$dir"
        echo "🔗 Linked $dir/"
      else
        mkdir -p "$target_dir/$dir"
        cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
        echo "✅ Imported $dir/"
      fi
    fi
  done

  # プラグイン設定
  if [[ -d "$source_dir/plugins" ]]; then
    mkdir -p "$target_dir/plugins"
    for file in "${CONFIG_CLAUDE_PLUGIN_FILES[@]}"; do
      if [[ -f "$source_dir/plugins/$file" ]]; then
        if [[ "$use_symlink" == "1" ]]; then
          ln -snf "$source_dir/plugins/$file" "$target_dir/plugins/$file"
          echo "🔗 Linked plugins/$file"
        else
          cp "$source_dir/plugins/$file" "$target_dir/plugins/$file"
          echo "✅ Imported plugins/$file"
        fi
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
  local use_symlink="${CLAUDE_IMPORT_SYMLINK:-1}"

  if [[ ! -f "$source_file" ]]; then
    echo "⚠️  MCP設定ファイルが見つかりません: $source_file"
    return 1
  fi

  source_file="$(cd "$(dirname "$source_file")" && pwd)/$(basename "$source_file")"

  if [[ "$use_symlink" == "1" ]]; then
    ln -snf "$source_file" "$target_file"
    echo "🔗 Linked .mcp.json"
  else
    cp "$source_file" "$target_file"
    echo "✅ Imported .mcp.json"
  fi
}

# MCP設定のエクスポート
config::export_mcp() {
  local source_file="${1:-$HOME/.mcp.json}"
  local target_file="${2:?Target file required}"

  if [[ ! -f "$source_file" ]]; then
    echo "⚠️  MCP設定ファイルが見つかりません: $source_file"
    return 1
  fi

  cp "$source_file" "$target_file"
  echo "✅ Exported .mcp.json"
}

# Codex設定のインポート
config::import_codex() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.codex}"
  local use_symlink="${CLAUDE_IMPORT_SYMLINK:-1}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Codex設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  source_dir="$(cd "$source_dir" && pwd)"
  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CODEX_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        ln -snf "$source_dir/$file" "$target_dir/$file"
        echo "🔗 Linked codex/$file"
      else
        cp "$source_dir/$file" "$target_dir/$file"
        echo "✅ Imported codex/$file"
      fi
    fi
  done

  # ディレクトリのリンクまたはコピー
  for dir in "${CONFIG_CODEX_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        if [[ -d "$target_dir/$dir" && ! -L "$target_dir/$dir" ]]; then
          rm -rf "$target_dir/$dir"
        fi
        ln -snf "$source_dir/$dir" "$target_dir/$dir"
        echo "🔗 Linked codex/$dir/"
      else
        mkdir -p "$target_dir/$dir"
        cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
        echo "✅ Imported codex/$dir/"
      fi
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
  local use_symlink="${CLAUDE_IMPORT_SYMLINK:-1}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Cursor設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  source_dir="$(cd "$source_dir" && pwd)"
  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_CURSOR_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        ln -snf "$source_dir/$file" "$target_dir/$file"
        echo "🔗 Linked cursor/$file"
      else
        cp "$source_dir/$file" "$target_dir/$file"
        echo "✅ Imported cursor/$file"
      fi
    fi
  done

  # ディレクトリのリンクまたはコピー
  for dir in "${CONFIG_CURSOR_SHARED_DIRS[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        if [[ -d "$target_dir/$dir" && ! -L "$target_dir/$dir" ]]; then
          rm -rf "$target_dir/$dir"
        fi
        ln -snf "$source_dir/$dir" "$target_dir/$dir"
        echo "🔗 Linked cursor/$dir/"
      else
        mkdir -p "$target_dir/$dir"
        cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
        echo "✅ Imported cursor/$dir/"
      fi
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

  # 共有設定ファイル
  for file in "${CONFIG_CURSOR_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Exported cursor/$file"
    fi
  done

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

# Gemini設定のインポート
config::import_gemini() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.gemini}"
  local use_symlink="${CLAUDE_IMPORT_SYMLINK:-1}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Gemini設定ディレクトリが見つかりません: $source_dir"
    return 0  # エラーではなく警告で継続
  fi

  source_dir="$(cd "$source_dir" && pwd)"
  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_GEMINI_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      if [[ "$use_symlink" == "1" ]]; then
        ln -snf "$source_dir/$file" "$target_dir/$file"
        echo "🔗 Linked gemini/$file"
      else
        cp "$source_dir/$file" "$target_dir/$file"
        echo "✅ Imported gemini/$file"
      fi
    fi
  done
}

# Gemini設定のエクスポート
config::export_gemini() {
  local source_dir="${1:-$HOME/.gemini}"
  local target_dir="${2:?Target directory required}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  Gemini設定ディレクトリが見つかりません: $source_dir"
    return 0  # エラーではなく警告で継続
  fi

  mkdir -p "$target_dir"

  # 共有設定ファイル
  for file in "${CONFIG_GEMINI_SHARED_FILES[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Exported gemini/$file"
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
    -e 's/^[[:space:]]*signingkey[[:space:]]*=.*$/	# signingkey = # Configure with: git config --global user.signingkey ~\/.ssh\/id_ed25519.pub/' \
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
