# macOS 新規マシンセットアップ

新規 Mac (Apple Silicon) をこのリポジトリの nix-darwin 構成で立ち上げる手順。
実際の新規マシンセットアップ (oykotnoMacBook-Air, 2026-07) で検証済み。

## 前提

- Apple Silicon Mac (`aarch64-darwin`)
- 管理者権限のあるユーザー
- `git` が使えること (初回 `git` 実行時に Xcode Command Line Tools が入る)

## 1. リポジトリの取得

ghq 階層に配置する (zsh エイリアスや private-config 参照がこのパスを前提とする)。

```bash
mkdir -p ~/develop/github.com/keito4
git clone https://github.com/keito4/config.git ~/develop/github.com/keito4/config
```

## 2. Homebrew のインストール

nix-darwin の homebrew モジュールは brew 本体がインストール済みであることを前提とする。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

サードパーティ tap の信頼設定 (Homebrew 6+) は activation 時に自動で行われる
(`nix/modules/homebrew.nix` の preActivation)。

## 3. Nix のインストール

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

> **Note**: Determinate Nix を使う場合、nix-darwin の Nix 管理と衝突するため
> flake のホスト定義で `determinateNix = true` を指定する (手順 5)。

## 4. GUI 前提の準備

- **App Store にサインイン**する (`masApps` の Xcode / LINE 等のインストールに必要)
- **Kanary を手動インストール**する ([ADR 0016](../adr/0016-use-kanary-for-keyboard-remapping.md))。
  <https://kanary.download/download> から ZIP を取得し、`Kanary.app` を
  `/Applications` または `~/Applications` に配置する。無いと activation が
  システムチェックで失敗する。

## 5. flake にホストを追加

`nix/flake.nix` の `darwinConfigurations` に新規マシンのエントリを追加する。

```nix
"<hostname>" = mkDarwin {
  hostname = "<hostname>";   # scutil --get LocalHostName の値
  username = "<username>";   # whoami の値
  determinateNix = true;     # Determinate Nix の場合のみ
};
```

## 6. 初回の darwin-rebuild

初回は darwin-rebuild が未導入のため `nix run` で実行する。

```bash
sudo /nix/var/nix/profiles/default/bin/nix run nix-darwin/master#darwin-rebuild \
  --extra-experimental-features "nix-command flakes" \
  -- switch --flake ~/develop/github.com/keito4/config/nix
```

初回は Cask 群のインストールで時間がかかる。2 回目以降は `make nix-switch`
(または zsh エイリアス `nix-switch`) で適用できる。

## 7. Claude Code / エージェント設定

```bash
# Claude Code CLI (ネイティブインストーラー、~/.local/bin に配置)
curl -fsSL https://claude.ai/install.sh | bash

# private-config (dotfiles の symlink 先)
gh repo clone keito4/private-config ~/develop/github.com/keito4/private-config

# 設定同期 + プラグインインストール
cd ~/develop/github.com/keito4/config
make claude-setup
```

`.claude` / `.mcp.json` / codex / cursor / gemini の設定取り込みは
`./script/import.sh` (または `script/lib/config.sh` の `config::import_*`) で行う。

## 8. 個人設定

```bash
# Git の個人情報 (リポジトリ側は意図的に未設定)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 1Password にサインインした後
make credentials
```

## 9. 権限の許可 (GUI)

初回起動時に macOS の許可が必要:

- **Kanary**: Gatekeeper の確認、アクセシビリティ / 入力監視
- **skhd**: アクセシビリティ (許可しないと IME ショートカットが動かない)
- **Xcode**: 初回起動時のライセンス同意

## トラブルシューティング

| 症状                                                     | 原因 / 対処                                                                   |
| -------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `error: Determinate detected, aborting activation`       | flake のホスト定義に `determinateNix = true` を指定する                       |
| `error: Kanary.app is required for keyboard remapping.`  | 手順 4 の Kanary をインストールする                                           |
| `Refusing to load formula ... from untrusted tap`        | preActivation が自動で `brew trust` する。手動なら `brew trust <tap>`         |
| `typeset: -g: invalid option` でスクリプトやテストが失敗 | macOS 標準 bash 3.2 が原因。brew の `bash` (Brewfile 管理) が入っているか確認 |
| `warning: $HOME ... is not owned by you`                 | sudo 実行時の無害な警告                                                       |
