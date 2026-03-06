# Create Codespace

GitHub Codespace を CLI から作成します。

## Usage

```bash
/create-codespace
/create-codespace -b feature/my-feature -m premiumLinux
/create-codespace -n "My Dev Environment"
```

## What It Does

`gh codespace create` をラップし、このリポジトリの推奨設定でCodespaceを作成します。

### Features

- **ブランチ指定**: 任意のブランチで Codespace を作成
- **マシンサイズ選択**: 用途に応じたスペックを選択
- **アイドルタイムアウト設定**: 自動停止までの時間を指定
- **表示名設定**: Codespace に名前を付けて管理しやすく
- **ドライラン**: 実行コマンドを確認してから実行

## Commands

```bash
# デフォルト設定で作成（現在のブランチ、standardLinux32gb）
./script/create-codespace.sh

# 特定のブランチで大きいマシンを使用
./script/create-codespace.sh -b feature/my-feature -m premiumLinux

# 表示名を指定
./script/create-codespace.sh -n "My Dev Environment"

# ローカル用 devcontainer を使用
./script/create-codespace.sh -c .devcontainer/devcontainer.json

# ドライラン（コマンド確認のみ）
./script/create-codespace.sh --dry-run

# 利用可能なマシンサイズを表示
./script/create-codespace.sh --list-machines
```

## Options

| Option                | Description                  | Default                                      |
| --------------------- | ---------------------------- | -------------------------------------------- |
| `-b, --branch`        | ブランチ                     | 現在のブランチ                               |
| `-m, --machine`       | マシンサイズ                 | `standardLinux32gb`                          |
| `-r, --repo`          | リポジトリ (`owner/repo`)    | 現在のリポジトリ                             |
| `-t, --idle-timeout`  | アイドルタイムアウト         | `30m`                                        |
| `-n, --name`          | 表示名 (48文字以内)          | なし                                         |
| `-c, --devcontainer`  | devcontainer.json のパス     | `.devcontainer/codespaces/devcontainer.json` |
| `-l, --list-machines` | 利用可能なマシンサイズを表示 | -                                            |
| `-d, --dry-run`       | 実行せずにコマンドを表示     | -                                            |

## Machine Sizes

| Name                | CPU     | RAM  | Storage |
| ------------------- | ------- | ---- | ------- |
| `basicLinux32gb`    | 2-core  | 8GB  | 32GB    |
| `standardLinux32gb` | 4-core  | 16GB | 32GB    |
| `premiumLinux`      | 8-core  | 32GB | 64GB    |
| `largePremiumLinux` | 16-core | 64GB | 128GB   |

## Requirements

- GitHub CLI (`gh`) がインストールされ、認証済みであること (`gh auth login`)

## Implementation

This command is implemented in `script/create-codespace.sh`.
