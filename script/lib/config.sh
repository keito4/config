#!/usr/bin/env zsh
# Common configuration functions for import/export scripts

set -euo pipefail

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
  local shared_files=(settings.json CLAUDE.md)
  for file in "${shared_files[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Imported $file"
    fi
  done

  # ディレクトリのコピー
  local shared_dirs=(commands agents hooks)
  for dir in "${shared_dirs[@]}"; do
    if [[ -d "$source_dir/$dir" ]]; then
      mkdir -p "$target_dir/$dir"
      cp -r "$source_dir/$dir"/* "$target_dir/$dir/" 2>/dev/null || true
      echo "✅ Imported $dir/"
    fi
  done

  # プラグイン設定
  if [[ -d "$source_dir/plugins" ]]; then
    mkdir -p "$target_dir/plugins"
    local plugin_files=(config.json known_marketplaces.json)
    for file in "${plugin_files[@]}"; do
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
  local shared_files=(settings.json CLAUDE.md)
  for file in "${shared_files[@]}"; do
    if [[ -f "$source_dir/$file" ]]; then
      cp "$source_dir/$file" "$target_dir/$file"
      echo "✅ Exported $file"
    fi
  done

  # ディレクトリのエクスポート
  local shared_dirs=(commands agents hooks)
  for dir in "${shared_dirs[@]}"; do
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
    local plugin_files=(config.json known_marketplaces.json)
    for file in "${plugin_files[@]}"; do
      if [[ -f "$source_dir/plugins/$file" ]]; then
        cp "$source_dir/plugins/$file" "$target_dir/plugins/$file"
        echo "✅ Exported plugins/$file"
      fi
    done
  fi
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
