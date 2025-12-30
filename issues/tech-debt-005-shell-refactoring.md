# Issue #005: シェルスクリプトのリファクタリング

## 優先度

🟡 **中**

## 現状

- **重複コード**: Claude設定処理が2箇所（import.sh, export.sh）
- **モジュール化**: 限定的（lib/ に2ファイルのみ）
- **関数の長さ**: 一部が50行以上
- **エラーハンドリング**: 一貫性が不十分

## 問題の詳細

### 重複コードパターン

#### パターン1: Claude設定のコピー処理

```bash
# script/import.sh (L88-115)
if [[ -d "$REPO_PATH/.claude" ]]; then
  mkdir -p ~/.claude
  [[ -f "$REPO_PATH/.claude/settings.json" ]] && cp ...
  if [[ -d "$REPO_PATH/.claude/commands" ]]; then
    mkdir -p ~/.claude/commands
    cp -r "$REPO_PATH/.claude/commands"/* ~/.claude/commands/
  fi
  # ... 繰り返し
fi

# script/export.sh (L79-104)
if [[ -d ~/.claude ]]; then
  [[ -f ~/.claude/settings.json ]] && cp ...
  if [[ -d ~/.claude/commands ]] && [[ -n "$(ls -A ~/.claude/commands)" ]]; then
    mkdir -p "$REPO_PATH/.claude/commands"
    cp -r ~/.claude/commands/* "$REPO_PATH/.claude/commands/"
  fi
  # ... 繰り返し
fi
```

**影響**: 28行の重複、保守性の低下

#### パターン2: プラットフォーム固有の処理

```bash
# 複数のスクリプトで繰り返される
if type brew >/dev/null 2>&1; then
  brew bundle --file ...
fi

if type cursor >/dev/null 2>&1; then
  cursor --install-extension ...
fi
```

## 実装計画

### Step 1: 共通ライブラリ関数の作成（8時間）

```bash
# script/lib/config.sh（新規作成）
#!/usr/bin/env zsh
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

  sed -E '/^\[user\]/,/^\[/{
    s/^[[:space:]]*name[[:space:]]*=.*$/	# name = # Configure with: git config --global user.name "Your Name"/
    s/^[[:space:]]*email[[:space:]]*=.*$/	# email = # Configure with: git config --global user.email "your.email@example.com"/
    s/^[[:space:]]*signingkey[[:space:]]*=.*$/	# signingkey = # Configure with: git config --global user.signingkey "$(cat ~/.ssh\/id_ed25519.pub)"/
  }' "$input_file" > "$output_file"

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
```

### Step 2: エラーハンドリングの統一（4時間）

```bash
# script/lib/errors.sh（新規作成）
#!/usr/bin/env zsh

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
```

### Step 3: import.shのリファクタリング（6時間）

```bash
# script/import.sh（リファクタリング後）
#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/devcontainer.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/errors.sh"

REPO_PATH="${REPO_PATH:-$(pwd)}"

platform::assert_supported

# DevContainerモードの設定
if [[ "${PLATFORM_IN_DEVCONTAINER}" = true ]]; then
  export NONINTERACTIVE=1
  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes
fi

# Homebrewのインストール
install_homebrew() {
  if ! type brew >/dev/null 2>&1; then
    errors::info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
  fi
}

# パッケージのインストール（プラットフォーム固有）
install_packages_linux() {
  errors::require_command brew "See https://brew.sh"
  brew bundle --file "$REPO_PATH/brew/LinuxBrewfile"
}

install_packages_darwin() {
  errors::require_command brew "See https://brew.sh"
  brew bundle --file "$REPO_PATH/brew/MacOSBrewfile"

  if type cursor >/dev/null 2>&1 && [[ -f "$REPO_PATH/vscode/extensions.txt" ]]; then
    <"$REPO_PATH/vscode/extensions.txt" xargs -L1 cursor --install-extension
  fi
}

# Oh My Zshのインストール
install_oh_my_zsh() {
  if [[ ! -d ~/.oh-my-zsh ]]; then
    errors::info "Installing Oh My Zsh..."
    env RUNZSH=${RUNZSH:-no} CHSH=${CHSH:-no} KEEP_ZSHRC=${KEEP_ZSHRC:-yes} \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  if [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
    errors::info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  fi
}

# Git設定のインポート
import_git_config() {
  errors::require_directory "$REPO_PATH/git"

  [[ -d "$REPO_PATH/git" ]] && cp -r -f "$REPO_PATH/git" ~/

  if [[ -f "$REPO_PATH/git/gitconfig" ]]; then
    cp "$REPO_PATH/git/gitconfig" ~/.gitconfig
    errors::warn "個人情報がコメントアウトされています"
    echo "    git config --global user.name \"Your Name\""
    echo "    git config --global user.email \"your.email@example.com\""
  fi

  [[ -f "$REPO_PATH/git/gitignore" ]] && cp "$REPO_PATH/git/gitignore" ~/.gitignore
  [[ -f "$REPO_PATH/git/gitattributes" ]] && cp "$REPO_PATH/git/gitattributes" ~/.gitattributes
}

# Zsh設定のインポート
import_zsh_config() {
  [[ -d "$REPO_PATH/.zsh" ]] && cp -r -f "$REPO_PATH/.zsh" ~/
  [[ -f "$REPO_PATH/dot/.zprofile" ]] && cp "$REPO_PATH/dot/.zprofile" ~/.zprofile

  if [[ -f "$REPO_PATH/dot/.zshrc" ]]; then
    cp "$REPO_PATH/dot/.zshrc" ~/.zshrc
    errors::warn "トークンがなくなっています"
    echo "    トークンは ~/.zsh/configs/pre/.env.secret に設定してください"
  fi

  [[ -f "$REPO_PATH/dot/.zshrc.devcontainer" ]] && \
    cp "$REPO_PATH/dot/.zshrc.devcontainer" ~/.zshrc.devcontainer

  # Peco設定
  if [[ -d "$REPO_PATH/dot/.peco" ]]; then
    mkdir -p ~/.peco
    cp -r "$REPO_PATH/dot/.peco"/* ~/.peco/
  fi
}

# npm global packagesのインストール
install_npm_globals() {
  if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
    errors::info "Installing npm global packages..."
    npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")
  fi
}

# メイン処理
main() {
  install_homebrew
  platform::run_task install_packages
  install_oh_my_zsh
  import_git_config
  import_zsh_config

  # Claude設定のインポート（新しい共通関数を使用）
  if [[ -d "$REPO_PATH/.claude" ]]; then
    config::import_claude "$REPO_PATH/.claude"
  fi

  # DevContainerブートストラップ
  if devcontainer::is_active; then
    devcontainer::bootstrap
  fi

  install_npm_globals

  # リポジトリのクローン
  if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
    errors::info "Cloning repositories with ghq..."
    gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
  fi

  errors::success "Import completed successfully!"
}

main "$@"
```

### Step 4: export.shのリファクタリング（6時間）

```bash
# script/export.sh（リファクタリング後）
#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/errors.sh"

REPO_PATH="${REPO_PATH:-$(pwd)}"

# 必要なディレクトリを作成
create_directories() {
  local dirs=(brew vscode git npm .zsh dot .claude)
  for dir in "${dirs[@]}"; do
    mkdir -p "$REPO_PATH/$dir"
  done
}

# VS Code拡張のエクスポート（プラットフォーム固有）
export_extensions_darwin() {
  if type cursor >/dev/null 2>&1; then
    cursor --list-extensions > "$REPO_PATH/vscode/extensions.txt"
    errors::success "VS Code extensions exported"
  fi
}

export_extensions_linux() {
  # Linux では通常エクスポートしない
  :
}

# Brewfileのエクスポート（プラットフォーム固有）
export_brew_bundle_linux() {
  errors::require_command brew
  brew bundle dump --file "$REPO_PATH/brew/LinuxBrewfile" --force --all
  errors::success "Linux Brewfile exported"
}

export_brew_bundle_darwin() {
  errors::require_command brew
  brew bundle dump --file "$REPO_PATH/brew/MacOSBrewfile" --force --all
  errors::success "macOS Brewfile exported"
}

# Git設定のエクスポート
export_git_config() {
  if [[ -f ~/.gitconfig ]]; then
    config::filter_gitconfig ~/.gitconfig "$REPO_PATH/git/gitconfig"
  fi

  [[ -f ~/.gitignore ]] && cat ~/.gitignore > "$REPO_PATH/git/gitignore"
  [[ -f ~/.gitattributes ]] && cat ~/.gitattributes > "$REPO_PATH/git/gitattributes"
}

# Zsh設定のエクスポート
export_zsh_config() {
  [[ -d ~/.zsh ]] && cp -r -f ~/.zsh "$REPO_PATH"
  [[ -f ~/.zprofile ]] && cp ~/.zprofile "$REPO_PATH/dot/.zprofile"

  if [[ -f ~/.zshrc ]]; then
    config::filter_credentials ~/.zshrc "$REPO_PATH/dot/.zshrc"
  fi

  [[ -f ~/.zshrc.devcontainer ]] && \
    cp ~/.zshrc.devcontainer "$REPO_PATH/dot/.zshrc.devcontainer"

  # Peco設定
  if [[ -d ~/.peco ]]; then
    mkdir -p "$REPO_PATH/dot/.peco"
    cp -r ~/.peco/* "$REPO_PATH/dot/.peco/"
  fi
}

# npm global packagesのエクスポート
export_npm_globals() {
  if type npm >/dev/null 2>&1; then
    npm list -g --depth=0 --json > "$REPO_PATH/npm/global.json" 2>/dev/null || \
      echo '{}' > "$REPO_PATH/npm/global.json"
    errors::success "npm global packages exported"
  fi
}

# メイン処理
main() {
  create_directories

  platform::run_task export_extensions

  if type brew >/dev/null 2>&1 && [[ "${PLATFORM_IN_DEVCONTAINER}" = false ]]; then
    platform::run_task export_brew_bundle
  fi

  export_git_config
  export_zsh_config
  export_npm_globals

  # Claude設定のエクスポート（新しい共通関数を使用）
  if [[ -d ~/.claude ]]; then
    config::export_claude ~/.claude "$REPO_PATH/.claude"
  fi

  errors::success "Export completed successfully!"
}

main "$@"
```

## タスクリスト

- [ ] script/lib/config.sh の作成
- [ ] script/lib/errors.sh の作成
- [ ] import.sh のリファクタリング
- [ ] export.sh のリファクタリング
- [ ] 既存の統合テストの更新
- [ ] 新しい共通関数のユニットテスト作成
- [ ] ドキュメントの更新
- [ ] コードレビュー

## 成功基準

- [ ] 重複コード 50行以上削減
- [ ] 関数の長さ ≤ 50行
- [ ] エラーハンドリングが一貫している
- [ ] すべてのテストが通過
- [ ] shellcheck違反なし

## ROI計算

**投資**

- lib/config.sh作成: 8時間
- lib/errors.sh作成: 4時間
- import.shリファクタリング: 6時間
- export.shリファクタリング: 6時間
- テスト更新: 8時間
- ドキュメント: 2時間
- **合計**: 34時間 × $150/h = $5,100

**リターン**

- 保守性向上: デバッグ時間 30%削減 → 3時間/月
- 新機能追加速度: 20%向上 → 2時間/月
- **月次節約**: 5時間
- **年間節約**: 60時間 × $150 = $9,000
- **ROI**: 76% (初年度)、253% (2年累積)

## 関連Issue

- #001: テストカバレッジ不足（テストの更新が必要）
- #002: shellcheck導入（リファクタリング後に実行）
- #004: 統合テスト実装（共通関数のテストが必要）

## 参考リンク

- [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Zsh Best Practices](https://zsh.sourceforge.io/Guide/zshguide.html)
