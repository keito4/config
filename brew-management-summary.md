# Brew Package Management Summary (2025-07)

## 🎯 現在の管理方針

### DevContainer中心の開発環境
- 開発ツールの大部分はDevContainer内で提供
- ローカルには必要最小限のツールのみ保持
- プロジェクトごとの環境分離を実現

## 📦 現在のパッケージ状況

### 🗑️ 削除済みパッケージ

#### Python環境
- ✅ **anaconda** (cask) - pyenvからuvへ移行後、完全削除
- ✅ **miniconda** (cask) - 同上
- ✅ **pyenv** - uvへ移行
- ✅ **python@3.10, python@3.11** - 依存関係なしのため削除
- ⚠️ **python@3.12, python@3.13** - gcloud-cli, llvmの依存関係のため保持

#### 開発言語・ツール
- ✅ **go** - DevContainerで提供
- ✅ **rust** - DevContainerで提供
- ✅ **bun** - DevContainerで提供
- ✅ **php** - DevContainerで提供
- ✅ **rbenv** - DevContainerで提供
- ✅ **yarn** - DevContainerで提供
- ✅ **cmake** - DevContainerで提供
- ✅ **act** - DevContainerで提供
- ✅ **uv** - DevContainerでPython環境を管理

#### データベース・バックエンド
- ✅ **mysql-client** - 重複のため削除（mysql-client@8.4を保持）
- ✅ **google-cloud-sdk** (cask) - gcloud-cliと重複

#### その他
- ✅ **llvm@16** - 特定用途なしのため削除
- ✅ **postman** (cask) - DevContainerまたはWebで利用

### 🔒 保持しているパッケージ

#### 必須ツール
- **git** - バージョン管理
- **docker** - コンテナランタイム
- **cursor** (cask) - メインエディタ
- **visual-studio-code** (cask) - サブエディタ

#### CLI便利ツール
- **gh** - GitHub CLI
- **ghq** - リポジトリ管理
- **fzf** - ファジーファインダー
- **peco** - インタラクティブフィルタ
- **jq** - JSON処理
- **tig** - Gitビューア
- **tree** - ディレクトリ構造表示

#### macOS専用
- **mas** - Mac App Store CLI
- **coreutils** - GNU版コマンド
- **trash** - ゴミ箱管理

#### セキュリティ・ネットワーク
- **1password** (cask) - パスワード管理
- **1password-cli** (cask) - CLI版
- **tailscale-app** (cask) - VPN

#### 生産性ツール
- **raycast** (cask) - ランチャー
- **alfred** (cask) - ランチャー（代替）
- **karabiner-elements** (cask) - キーボードカスタマイズ
- **bettertouchtool** (cask) - トラックパッド拡張
- **bartender** (cask) - メニューバー管理

#### コミュニケーション
- **slack** (cask)
- **discord** (cask)
- **zoom** (cask)
- **notion** (cask)

#### AI関連
- **claude** (cask)
- **chatgpt** (cask)
- **cursor** (cask) - AI搭載エディタ

## 📁 Brewfile管理

### ファイル構成
```
brew/
├── MacOSBrewfile              # 全パッケージ（自動生成）
├── StandaloneBrewfile         # 依存関係のないパッケージ（自動生成）
├── CategorizedBrewfile        # カテゴリ別整理（自動生成）
└── README.md                  # ドキュメント
```

### 管理コマンド
```bash
# パッケージ状況確認
make brew-leaves         # スタンドアロンパッケージ一覧
make brew-categorized    # カテゴリ別表示

# Brewfile生成
make brew-generate       # 各種Brewfileを自動生成

# 依存関係確認
make brew-deps pkg=git   # パッケージの依存関係
make brew-uses pkg=jq    # パッケージを使用するもの
```

## 🔄 今後の方針

### ローカル環境の最小化
1. 開発ツールはDevContainerに集約
2. ローカルは管理・通信ツールのみ
3. プロジェクトごとに環境を分離

### パッケージ選定基準
- **残す**: システム全体で使用、DevContainerで提供困難
- **削除**: 開発専用、DevContainerで提供可能

### 定期メンテナンス
```bash
# 不要パッケージの確認
brew leaves              # 依存されていないパッケージ
brew autoremove         # 不要な依存関係を削除

# クリーンアップ
brew cleanup --prune=all
```

## 📝 Notes

- Python環境は完全にDevContainer内で管理
- クラウドCLIツールもDevContainer内で管理
- データベースクライアントもDevContainer内で管理
- エディタとGitのみローカルに必須