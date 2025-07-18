# DevContainer移行に伴う削除可能パッケージ

## 基本方針
DevContainerで開発を行う場合、ローカルに必要なのは：
1. **コンテナランタイム**: Docker/OrbStack/Rancher Desktop
2. **エディタ**: VS Code/Cursor
3. **Git**: 基本的なバージョン管理
4. **コミュニケーション**: Slack/Discord等

## 削除可能なパッケージ（DevContainerで提供可能）

### 🗑️ プログラミング言語・ランタイム
```bash
# 言語ランタイム
brew uninstall go
brew uninstall rust
brew uninstall deno
brew uninstall bun
brew uninstall openjdk
brew uninstall php
brew uninstall rbenv
brew uninstall nvm
brew uninstall yarn

# Python関連（uvも含む）
brew uninstall uv
brew uninstall pipenv
brew uninstall python@3.10 python@3.11
# python@3.12, python@3.13は依存関係のため保持
```

### 🗑️ クラウド・インフラツール
```bash
# AWS
brew uninstall awscli
brew uninstall aws-sam-cli
brew uninstall aws-sso-util

# Azure
brew uninstall azure-cli

# Google Cloud（gcloud-cliは依存関係のため注意）
# brew uninstall gcloud-cli  # llvmが依存している場合は保持

# Kubernetes/Container
brew uninstall helm
brew uninstall kubectl  # もしインストールされている場合

# その他
brew uninstall terraform
brew uninstall tfenv
brew uninstall sops
```

### 🗑️ データベースクライアント
```bash
brew uninstall mysql-client
brew uninstall mysql-client@8.4
brew uninstall postgresql@14
brew uninstall supabase
```

### 🗑️ 開発ツール
```bash
# ビルドツール
brew uninstall cmake

# Git関連（ghとghqは便利なので検討）
# brew uninstall gh  # GitHub CLIは便利かも
# brew uninstall ghq # リポジトリ管理は便利かも

# その他開発ツール
brew uninstall act  # GitHub Actions実行
brew uninstall carthage
brew uninstall llvm@16  # 特定用途がなければ
```

### 🗑️ エディタ・開発環境
```bash
brew uninstall emacs
brew uninstall --cask postman  # API開発
brew uninstall --cask tableplus  # DB管理
```

## 🔒 ローカルに残すべきパッケージ

### 必須
- **git**: バージョン管理の基本
- **docker** または **orbstack/rancher**: コンテナランタイム
- **visual-studio-code** または **cursor**: エディタ

### 推奨（便利ツール）
- **gh**: GitHub CLI（PR作成等）
- **ghq**: リポジトリ管理
- **fzf/peco**: ファジーファインダー
- **jq**: JSON処理
- **1password-cli**: クレデンシャル管理
- **tailscale**: VPN

### macOS固有
- **mas**: Mac App Store CLI
- **coreutils**: GNU版コマンド
- **karabiner-elements**: キーボードカスタマイズ
- **raycast/alfred**: ランチャー
- **bettertouchtool/bartender**: UI拡張

## 削除コマンドまとめ

```bash
# 開発言語・ランタイム
brew uninstall go rust deno bun openjdk php rbenv nvm yarn uv pipenv

# クラウドツール
brew uninstall awscli aws-sam-cli aws-sso-util azure-cli terraform tfenv sops helm

# データベース
brew uninstall mysql-client mysql-client@8.4 postgresql@14 supabase

# 開発ツール
brew uninstall cmake act carthage emacs

# Casks
brew uninstall --cask postman tableplus

# Python（依存関係がない場合のみ）
brew uninstall python@3.10 python@3.11

# クリーンアップ
brew cleanup --prune=all
brew autoremove
```

## 移行後の開発フロー

1. **プロジェクトクローン**
   ```bash
   ghq get github.com/org/repo
   cd $(ghq root)/github.com/org/repo
   ```

2. **DevContainerで開く**
   ```bash
   code .  # または cursor .
   # Command Palette: "Reopen in Container"
   ```

3. **開発作業**
   - すべての開発ツールはコンテナ内で利用可能
   - ローカルはGitとエディタのみ使用

## 注意事項

- 依存関係を確認してから削除
  ```bash
  brew uses --installed <package>
  ```
- チームメンバーと相談（共通の開発環境の場合）
- 段階的に削除（一度に全部削除しない）