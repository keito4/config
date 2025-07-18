# Brew Cleanup Suggestions

## 重複しているパッケージ

### 1. Python管理
- **miniconda** → pyenvを使用しているため不要
- **python@3.10, python@3.11** → 他のパッケージが依存していないため削除可能
- **python@3.12** → gcloud-cli, llvm@16が依存しているため保持
- **python@3.13** → llvmが依存しているため保持
  ```bash
  brew uninstall --cask miniconda
  brew uninstall python@3.10 python@3.11
  # python@3.12, python@3.13は依存関係があるため保持
  ```

### 2. MySQL Client
- **mysql-client** と **mysql-client@8.4** → 一つに統一
  ```bash
  brew uninstall mysql-client
  # mysql-client@8.4を使用
  ```

### 3. Google Cloud SDK
- **gcloud-cli** と **google-cloud-sdk** → 同じもの
  ```bash
  brew uninstall --cask google-cloud-sdk
  # gcloud-cliを使用
  ```

### 4. Tailscale
- **tailscale** と **tailscale-app** → 一つに統一
  ```bash
  brew uninstall tailscale
  # tailscale-appを使用
  ```

### 5. コードエディタ
- **visual-studio-code** と **cursor** → 用途に応じて選択
  - 両方使っている場合は問題なし
  - 片方しか使わない場合は削除を検討

## 不要な可能性があるパッケージ

### 開発ツール
- **emacs** → 他のエディタを使用している場合
- **carthage** → 最近のiOS開発ではSwift Package Managerが主流
- **nvm** → nodebrewやasdfを使用している場合

### 古いバージョン
- **llvm@16** → 特定の用途がなければ最新版で十分
- **postgresql@14** → 最新版を使用している場合

### ユーティリティ
- **six** → Python 2/3互換性ライブラリ（Python 2サポート終了）
- **cfr-decompiler** → Javaデコンパイラ（特定用途のみ）

### エンターテインメント
- **cowsay, figlet, toilet, sl** → 実用性なし（楽しみのため）

## 推奨される削除コマンド

```bash
# 重複パッケージの削除
brew uninstall --cask miniconda
brew uninstall python@3.10 python@3.11 python@3.12 python@3.13
brew uninstall mysql-client  # mysql-client@8.4を使用
brew uninstall --cask google-cloud-sdk  # gcloud-cliを使用
brew uninstall tailscale  # tailscale-appを使用

# 不要な可能性があるパッケージ
brew uninstall six
brew uninstall carthage  # Swift Package Managerを使用する場合

# クリーンアップ
brew cleanup --prune=all
brew autoremove
```

## PATH設定の確認

`.zshrc`から以下を削除：
- Anaconda/Miniconda関連のPATH
- 重複するPython関連のPATH

## 確認事項

削除前に確認：
1. 各パッケージが他のパッケージの依存関係でないか
   ```bash
   brew uses --installed <package-name>
   ```

2. 現在使用中でないか
   ```bash
   which <command-name>
   ```