#!/usr/bin/env zsh
# shellcheck disable=SC1071 # zsh-specific script; ShellCheck has no zsh parser.
# Common configuration functions for import/export scripts

set -euo pipefail

# Constants for Claude configuration
typeset -ga CONFIG_CLAUDE_SHARED_FILES=(settings.json CLAUDE.md)
typeset -ga CONFIG_CLAUDE_SHARED_DIRS=(commands agents hooks)
typeset -ga CONFIG_CLAUDE_PLUGIN_FILES=(config.json known_marketplaces.json)

# Constants for Codex configuration
# config.toml は含めない: Codex 自身が端末固有の状態（projects.*.trust_level,
# marketplaces.*, プラグイン有効化, 絶対パス入り MCP 定義）を config.toml に
# 書き戻すため、symlink 配備すると追跡ファイルが恒久的に dirty になる。
# 代わりに config::deploy_codex_config でベースをローカル実ファイルへマージ配備する。
typeset -ga CONFIG_CODEX_SHARED_FILES=()
typeset -ga CONFIG_CODEX_SHARED_DIRS=(prompts rules)

# このライブラリを起点にした script/ ディレクトリの絶対パス（sourced でも解決できる %x を使う）
typeset -g CONFIG_SCRIPT_DIR="${${(%):-%x}:A:h:h}"

# Constants for Cursor configuration
typeset -ga CONFIG_CURSOR_SHARED_FILES=(mcp.json)
typeset -ga CONFIG_CURSOR_SHARED_DIRS=(rules)

# Constants for Gemini configuration
typeset -ga CONFIG_GEMINI_SHARED_FILES=(settings.json)
typeset -ga CONFIG_GEMINI_SHARED_DIRS=()

# Repository directories managed by import/export scripts
typeset -ga CONFIG_MANAGED_REPO_DIRS=(
  brew
  vscode
  git
  npm
  .zsh
  dot
  .claude
  .codex
  .cursor
  .gemini
)

config::ensure_managed_repo_dirs() {
  local repo_path="${1:?Repository path required}"
  local dir

  for dir in "${CONFIG_MANAGED_REPO_DIRS[@]}"; do
    mkdir -p "$repo_path/$dir"
  done
}

# ============================================================================
# Generic import/export functions
# ============================================================================

# Generic tool config import
# Usage: config::_import_tool <tool_name> <source_dir> <target_dir> <files_array_name> [dirs_array_name] [plugin_files_array_name]
config::_import_tool() {
  local tool_name="${1:?Tool name required}"
  local source_dir="${2:?Source directory required}"
  local target_dir="${3:?Target directory required}"
  local -a shared_files=("${(@P)4}")
  local dirs_array_name="${5:-}"
  local plugin_files_array_name="${6:-}"
  local use_symlink="${CLAUDE_IMPORT_SYMLINK:-1}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  ${tool_name}設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  # 絶対パスに変換
  source_dir="$(cd "$source_dir" && pwd)"
  mkdir -p "$target_dir"

  local label="${tool_name:l}"
  [[ "$label" == "claude" ]] && label=""

  # 共有設定ファイル
  for file in "${shared_files[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      local display_name="${label:+$label/}$file"
      if [[ "$use_symlink" == "1" ]]; then
        ln -snf "$source_dir/$file" "$target_dir/$file"
        echo "🔗 Linked $display_name"
      else
        cp "$source_dir/$file" "$target_dir/$file"
        echo "✅ Imported $display_name"
      fi
    fi
  done

  # ディレクトリのリンクまたはコピー
  if [[ -n "$dirs_array_name" ]]; then
    local -a shared_dirs=("${(@P)dirs_array_name}")
    for dir in "${shared_dirs[@]}"; do
      if [[ -d "$source_dir/$dir" ]]; then
        local display_name="${label:+$label/}$dir/"
        if [[ "$use_symlink" == "1" ]]; then
          if [[ -d "$target_dir/$dir" && ! -L "$target_dir/$dir" ]]; then
            rm -rf "$target_dir/$dir"
          fi
          ln -snf "$source_dir/$dir" "$target_dir/$dir"
          echo "🔗 Linked $display_name"
        else
          mkdir -p "$target_dir/$dir"
          cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
          echo "✅ Imported $display_name"
        fi
      fi
    done
  fi

  # プラグイン設定（Claude専用）
  if [[ -n "$plugin_files_array_name" && -d "$source_dir/plugins" ]]; then
    local -a plugin_files=("${(@P)plugin_files_array_name}")
    mkdir -p "$target_dir/plugins"
    for file in "${plugin_files[@]}"; do
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

# Generic tool config export
# Usage: config::_export_tool <tool_name> <source_dir> <target_dir> <files_array_name> [dirs_array_name] [plugin_files_array_name]
config::_export_tool() {
  local tool_name="${1:?Tool name required}"
  local source_dir="${2:?Source directory required}"
  local target_dir="${3:?Target directory required}"
  local -a shared_files=("${(@P)4}")
  local dirs_array_name="${5:-}"
  local plugin_files_array_name="${6:-}"

  if [[ ! -d "$source_dir" ]]; then
    echo "⚠️  ${tool_name}設定ディレクトリが見つかりません: $source_dir"
    return 1
  fi

  mkdir -p "$target_dir"

  local label="${tool_name:l}"
  [[ "$label" == "claude" ]] && label=""

  # 共有設定ファイル
  for file in "${shared_files[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Exported ${label:+$label/}$file"
    fi
  done

  # ディレクトリのエクスポート
  if [[ -n "$dirs_array_name" ]]; then
    local -a shared_dirs=("${(@P)dirs_array_name}")
    for dir in "${shared_dirs[@]}"; do
      if [[ -d "$source_dir/$dir" ]] && [[ -n "$(ls -A "$source_dir/$dir" 2>/dev/null)" ]]; then
        mkdir -p "$target_dir/$dir"
        cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null && \
          echo "✅ Exported ${label:+$label/}$dir/" || \
          echo "⚠️  No ${label:+$label/}$dir found"
      fi
    done
  fi

  # プラグイン設定（Claude専用）
  if [[ -n "$plugin_files_array_name" && -d "$source_dir/plugins" ]]; then
    local -a plugin_files=("${(@P)plugin_files_array_name}")
    mkdir -p "$target_dir/plugins"
    for file in "${plugin_files[@]}"; do
      if [[ -f "$source_dir/plugins/$file" ]]; then
        cp "$source_dir/plugins/$file" "$target_dir/plugins/$file"
        echo "✅ Exported plugins/$file"
      fi
    done
  fi
}

# ============================================================================
# Tool-specific wrapper functions (backward compatible)
# ============================================================================

config::import_claude() {
  config::_import_tool "Claude" \
    "${1:?Source directory required}" \
    "${2:-$HOME/.claude}" \
    CONFIG_CLAUDE_SHARED_FILES \
    CONFIG_CLAUDE_SHARED_DIRS \
    CONFIG_CLAUDE_PLUGIN_FILES
}

config::export_claude() {
  config::_export_tool "Claude" \
    "${1:-$HOME/.claude}" \
    "${2:?Target directory required}" \
    CONFIG_CLAUDE_SHARED_FILES \
    CONFIG_CLAUDE_SHARED_DIRS \
    CONFIG_CLAUDE_PLUGIN_FILES
}

# Codex の config.toml をベース→ローカルの深いマージで配備する
# （ベース定義キーはベース優先、ローカルのみのキー＝端末状態は保持。
#   配備先が symlink なら実ファイルへ自動移行する。詳細は script/codex-config-merge.py）
config::deploy_codex_config() {
  local base="${1:?Base config.toml required}"
  local target="${2:?Target config.toml required}"
  local merge_script="$CONFIG_SCRIPT_DIR/codex-config-merge.py"

  if command -v uv >/dev/null 2>&1 && [[ -f "$merge_script" ]]; then
    if uv run --script --quiet "$merge_script" "$base" "$target"; then
      echo "✅ Deployed codex/config.toml (merge)"
      return 0
    fi
    echo "⚠️  codex/config.toml のマージ配備に失敗しました" >&2
    return 1
  fi

  # uv が無い環境のフォールバック（マージはしないが dirty の原因は残さない）
  if [[ -L "$target" ]]; then
    local content
    content="$(cat "$target")"
    rm "$target"
    printf '%s' "$content" >"$target"
    echo "⚠️  uv が無いためマージをスキップ（symlink は実ファイル化しました）: $target"
  elif [[ ! -e "$target" ]]; then
    cp "$base" "$target"
    echo "✅ Seeded codex/config.toml (uv 無しのため単純コピー)"
  else
    echo "⚠️  uv が無いため codex/config.toml のマージをスキップしました"
  fi
}

config::import_codex() {
  local source_dir="${1:?Source directory required}"
  local target_dir="${2:-$HOME/.codex}"

  config::_import_tool "Codex" \
    "$source_dir" \
    "$target_dir" \
    CONFIG_CODEX_SHARED_FILES \
    CONFIG_CODEX_SHARED_DIRS

  if [[ -f "$source_dir/config.toml" ]]; then
    config::deploy_codex_config "$source_dir/config.toml" "$target_dir/config.toml"
  fi
}

# 注意: config.toml は export しない（端末固有状態がリポジトリへ逆流するため）。
# 共有設定を変えたいときはリポジトリの .codex/config.toml を直接編集する。
config::export_codex() {
  config::_export_tool "Codex" \
    "${1:-$HOME/.codex}" \
    "${2:?Target directory required}" \
    CONFIG_CODEX_SHARED_FILES \
    CONFIG_CODEX_SHARED_DIRS
}

config::import_cursor() {
  config::_import_tool "Cursor" \
    "${1:?Source directory required}" \
    "${2:-$HOME/.cursor}" \
    CONFIG_CURSOR_SHARED_FILES \
    CONFIG_CURSOR_SHARED_DIRS
}

config::export_cursor() {
  config::_export_tool "Cursor" \
    "${1:-$HOME/.cursor}" \
    "${2:?Target directory required}" \
    CONFIG_CURSOR_SHARED_FILES \
    CONFIG_CURSOR_SHARED_DIRS
}

config::import_gemini() {
  config::_import_tool "Gemini" \
    "${1:?Source directory required}" \
    "${2:-$HOME/.gemini}" \
    CONFIG_GEMINI_SHARED_FILES || return 0  # Gemini: warning only
}

config::export_gemini() {
  config::_export_tool "Gemini" \
    "${1:-$HOME/.gemini}" \
    "${2:?Target directory required}" \
    CONFIG_GEMINI_SHARED_FILES || return 0  # Gemini: warning only
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
