# Codespaces Secrets Management

GitHub Codespaces のシークレットとリポジトリの紐付けを CLI で管理します。

## Usage

```bash
/codespaces-secrets
/codespaces-secrets list
/codespaces-secrets sync
```

## What It Does

GUI (https://github.com/settings/codespaces) を使わずに、Codespaces シークレットのリポジトリ紐付けを管理します。

### Features

- **シークレット一覧**: 現在のシークレットと紐付けリポジトリを表示
- **リポジトリ管理**: 管理対象リポジトリの追加・削除
- **一括同期**: 設定ファイルのリポジトリを全シークレットに紐付け
- **差分表示**: 設定と現在の状態の差分を確認

### Configuration

設定ファイルは `~/.config/codespaces-secrets/repos.txt` に保存されます（Git管理外）。

## Commands

```bash
# シークレットと紐付けリポジトリを表示
./script/codespaces-secrets.sh list

# 管理対象リポジトリ一覧を表示
./script/codespaces-secrets.sh repos

# リポジトリを追加
./script/codespaces-secrets.sh repos add owner/repo

# リポジトリを削除
./script/codespaces-secrets.sh repos remove owner/repo

# エディタで設定ファイルを編集
./script/codespaces-secrets.sh repos edit

# 設定と現在の状態の差分を表示
./script/codespaces-secrets.sh diff

# 全シークレットにリポジトリを紐付け
./script/codespaces-secrets.sh sync

# 特定のシークレットにリポジトリを紐付け
./script/codespaces-secrets.sh sync SECRET_NAME

# 現在の設定からファイルを初期化
./script/codespaces-secrets.sh init
```

## Example Output

```
=== Codespaces シークレット一覧 ===

MY_API_KEY
  - your-org/project-a
  - your-name/my-project

DATABASE_URL
  - your-org/project-a

SECRET_TOKEN
  - your-org/project-a
  - your-org/project-b
  - your-name/my-project
```

## Workflow

1. **初期化**: `./script/codespaces-secrets.sh init` で現在の設定を取得
2. **リポジトリ追加**: `./script/codespaces-secrets.sh repos add owner/repo` で対象リポジトリを追加
3. **差分確認**: `./script/codespaces-secrets.sh diff` で同期が必要なシークレットを確認
4. **同期**: `./script/codespaces-secrets.sh sync` で全シークレットにリポジトリを紐付け

## Environment Variables

| Variable                        | Description            | Default                        |
| ------------------------------- | ---------------------- | ------------------------------ |
| `CODESPACES_SECRETS_CONFIG_DIR` | 設定ディレクトリのパス | `~/.config/codespaces-secrets` |

## Requirements

- GitHub CLI (`gh`) がインストールされ、認証済みであること
- 対象リポジトリへのアクセス権限

## Implementation

This command is implemented in `script/codespaces-secrets.sh`.
