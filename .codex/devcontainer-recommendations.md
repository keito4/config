# DevContainer 推奨設定ガイド

## 目的

Elu-co-jp配下の全リポジトリで統一されたDevContainer環境を提供し、開発者体験を向上させる。

**重要**: 本ガイドの推奨設定は、**Claude Code（AI開発アシスタント）が基本的に動作すること**を前提としています。すべての設定例は、Claude Code環境での動作を保証します。

## ベースイメージ

```json
{
  "image": "ghcr.io/keito4/config-base:1.13.1"
}
```

**最新バージョン**: 1.15.0（management_toolsで使用中）
**推奨バージョン**: 1.13.1+（安定版として広く採用）

## Claude Code動作のための必須設定

Claude Code（AI開発アシスタント）を動作させるための最小限の設定です。

### 1. ベースイメージ

```json
{
  "image": "ghcr.io/keito4/config-base:1.13.1"
}
```

- config-baseイメージには`@anthropic-ai/claude-code` CLIが既にインストール済み
- バージョン1.13.1以降を推奨

### 2. 必須mounts

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.codex,target=/home/vscode/.codex,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"
  ]
}
```

| マウント  | 目的                                    | 必須度   |
| --------- | --------------------------------------- | -------- |
| `.codex`  | Codex設定・プロンプト・エージェント定義 | **必須** |
| `.claude` | Claude認証情報・セッション履歴          | **必須** |

### 3. postCreateCommand

```json
{
  "postCreateCommand": "/usr/local/bin/setup-claude.sh"
}
```

または既存のコマンドに追加：

```json
{
  "postCreateCommand": "npm ci && npm run prepare && /usr/local/bin/setup-claude.sh"
}
```

- `setup-claude.sh`は`.claude`ディレクトリの初期化とClaude CLIの設定を実行
- 環境変数`ANTHROPIC_API_KEY`が必要（`.devcontainer.env`または1Passwordで管理）

### 4. 環境変数（推奨）

```json
{
  "runArgs": ["--env-file=${localEnv:HOME}/.devcontainer.env"]
}
```

`.devcontainer.env`に以下を含める：

```bash
ANTHROPIC_API_KEY=***
```

### Claude Code最小構成例

```json
{
  "name": "Project Name",
  "image": "ghcr.io/keito4/config-base:1.13.1",
  "mounts": [
    "source=${localEnv:HOME}/.codex,target=/home/vscode/.codex,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"
  ],
  "postCreateCommand": "/usr/local/bin/setup-claude.sh",
  "runArgs": ["--env-file=${localEnv:HOME}/.devcontainer.env"]
}
```

## 必須Features（全プロジェクト共通）

### 1. GitHub CLI

```json
"ghcr.io/devcontainers/features/github-cli:1": {}
```

- 利用率: 100% (8/8)
- 用途: PR作成、Issue管理、GitHub Actions連携

### 2. Docker-in-Docker

```json
"ghcr.io/devcontainers/features/docker-in-docker:2": {
  "moby": true,
  "dockerDashComposeVersion": "v2"
}
```

- 利用率: 87.5% (7/8)
- 用途: コンテナビルド、Docker Compose実行

### 3. Git

```json
"ghcr.io/devcontainers/features/git:1": {
  "version": "latest"
}
```

- 用途: バージョン管理（config-baseに含まれるが明示推奨）

## プロジェクトタイプ別推奨Features

### Node.js/TypeScriptプロジェクト

```json
{
  "ghcr.io/devcontainers/features/node:1": {
    "version": "20"
  },
  "ghcr.io/devcontainers-extra/features/pnpm:2": {
    "version": "latest"
  },
  "ghcr.io/eitsupi/devcontainer-features/jq-likes:2": {
    "jqVersion": "latest",
    "yqVersion": "latest"
  }
}
```

### Supabaseプロジェクト

```json
{
  "ghcr.io/devcontainers-extra/features/supabase-cli": {
    "version": "latest"
  }
}
```

- 利用率: 75% (6/8)
- 必須ケース: Supabase使用プロジェクト全般

### E2Eテスト環境

```json
{
  "ghcr.io/schlich/devcontainer-features/playwright:0": {}
}
```

- 利用率: 75% (6/8)
- 用途: ブラウザ自動テスト

### インフラ/DevOpsプロジェクト

```json
{
  "ghcr.io/devcontainers/features/terraform:1": {
    "version": "latest"
  },
  "ghcr.io/devcontainers/features/aws-cli:1": {
    "version": "latest"
  },
  "ghcr.io/devcontainers/features/azure-cli:1": {
    "version": "latest"
  },
  "ghcr.io/dhoeric/features/google-cloud-cli:1": {}
}
```

## オプションFeatures（特定用途向け）

### 1Password統合（機密情報管理）

```json
{
  "ghcr.io/flexwie/devcontainer-features/op:1": {
    "version": "latest"
  }
}
```

- 利用例: management_tools, pulse_survey
- 用途: 環境変数・シークレット管理

### act（ローカルGitHub Actions実行）

```json
{
  "ghcr.io/dhoeric/features/act:1": {}
}
```

- 利用例: recall_ai, package_manager
- 用途: CI/CDワークフローのローカルテスト

### Rust開発環境

```json
{
  "ghcr.io/devcontainers/features/rust:1": {},
  "ghcr.io/lee-orr/rusty-dev-containers/cargo-binstall:0": {
    "packages": "similarity-ts"
  }
}
```

- 利用例: recall_ai（similarity-tsビルド用）

### Python開発環境

```json
{
  "ghcr.io/devcontainers/features/python:1": {
    "version": "latest"
  }
}
```

- 利用例: management_tools, pulse_survey

## 標準mounts設定

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.cursor,target=/home/vscode/.cursor,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.codex,target=/home/vscode/.codex,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"
  ]
}
```

### マウント解説

| パス         | 目的                                | 利用率 | Claude Code |
| ------------ | ----------------------------------- | ------ | ----------- |
| `.cursor`    | Cursor IDE設定同期                  | 100%   | -           |
| `.gitconfig` | Git設定継承                         | 100%   | -           |
| `.config/gh` | GitHub CLI認証情報                  | 87.5%  | -           |
| `.codex`     | Codex設定・プロンプト・エージェント | 62.5%  | **必須**    |
| `.claude`    | Claude認証情報・セッション履歴      | 37.5%  | **必須**    |

**注意**: Claude Codeを使用する場合、`.codex`と`.claude`のマウントは**必須**です。

## 環境変数管理

### runArgs設定

```json
{
  "runArgs": ["--env-file=${localEnv:HOME}/.devcontainer.env"]
}
```

### `.devcontainer.env`ファイル例

```bash
# Claude Code (必須)
ANTHROPIC_API_KEY=***

# AWS
AWS_PROFILE=default
AWS_REGION=ap-northeast-1

# Supabase
SUPABASE_ACCESS_TOKEN=***
SUPABASE_DB_PASSWORD=***

# その他
NODE_ENV=development
```

**重要**: Claude Codeを使用する場合、`ANTHROPIC_API_KEY`の設定は**必須**です。1Passwordまたは手動で設定してください。

## postCreateCommand推奨パターン

**重要**: Claude Codeを使用する場合、すべてのパターンで `/usr/local/bin/setup-claude.sh` の実行が**必須**です。

### Node.jsプロジェクト

```json
{
  "postCreateCommand": "npm ci && npm run prepare && /usr/local/bin/setup-claude.sh"
}
```

### モノレポ構成

```json
{
  "postCreateCommand": "cd <project-dir> && npm ci && npm run prepare && /usr/local/bin/setup-claude.sh || true"
}
```

**注意**: `|| true` はnpmコマンド失敗時も継続するため、setup-claude.shは確実に実行されます。

### インフラプロジェクト

```json
{
  "postCreateCommand": "bash scripts/setup.sh && /usr/local/bin/setup-claude.sh"
}
```

### Claude Code専用（最小構成）

```json
{
  "postCreateCommand": "/usr/local/bin/setup-claude.sh"
}
```

## カスタマイズ設定（VSCode）

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "redhat.vscode-yaml",
        "eamodio.gitlens",
        "github.vscode-github-actions"
      ],
      "settings": {
        "npm.packageManager": "pnpm"
      }
    }
  }
}
```

## ベストプラクティス

### 1. バージョン管理

- **ベースイメージ**: セマンティックバージョニング（例: `1.13.1`）を明示
- **Features**: `latest`使用は最小限に、安定性重視の場合はバージョン固定
- **更新頻度**: 四半期ごとにベースイメージ見直し

### 2. パフォーマンス最適化

```json
{
  "mounts": [
    "source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"
  ]
}
```

- `node_modules`をボリュームマウントして高速化

### 3. セキュリティ

- 機密情報は`.devcontainer.env`または1Passwordで管理
- `.devcontainer.env`は`.gitignore`に追加必須
- `runArgs`での環境変数直接埋め込みは禁止

### 4. チーム協調

```json
{
  "name": "<Project Name> Development",
  "remoteUser": "vscode"
}
```

- プロジェクト名を明示してコンテナ識別性向上

## 移行ガイド

### 古いバージョンからの更新手順

1. **ベースイメージ更新**

   ```json
   - "image": "ghcr.io/keito4/config-base:1.0.40"
   + "image": "ghcr.io/keito4/config-base:1.13.1"
   ```

2. **非推奨Feature削除**
   - 重複するFeature（config-baseに既に含まれるもの）を削除

3. **mounts標準化**
   - 上記の標準mounts設定を適用

4. **動作確認**

   ```bash
   # コンテナリビルド
   Cmd/Ctrl + Shift + P → "Dev Containers: Rebuild Container"

   # 初期化コマンド実行確認
   # postCreateCommandが正常完了することを確認
   ```

## トラブルシューティング

### よくある問題

1. **Claude Codeが起動しない**
   - `.codex`と`.claude`のマウントを確認
   - `ANTHROPIC_API_KEY`が`.devcontainer.env`に設定されているか確認
   - `setup-claude.sh`が実行されているか確認: `ls -la /usr/local/bin/setup-claude.sh`
   - コンテナ再ビルド: Cmd/Ctrl + Shift + P → "Dev Containers: Rebuild Container"

2. **Claude Code認証エラー**
   - `ANTHROPIC_API_KEY`の値を確認
   - 1Passwordから最新のAPIキーを取得: `OP_ACCOUNT=your.1password.com bash script/setup-env.sh`
   - 環境変数が正しく読み込まれているか確認: `echo $ANTHROPIC_API_KEY`

3. **`.codex`や`.claude`の設定が反映されない**
   - ホスト側でディレクトリが存在するか確認: `ls -la ~/.codex ~/.claude`
   - ホスト側でディレクトリ作成: `mkdir -p ~/.codex ~/.claude`
   - マウント設定がdevcontainer.jsonに正しく記載されているか確認
   - コンテナ再起動後も反映されない場合は、コンテナ再ビルド

4. **postCreateCommandが失敗する**
   - `|| true`を末尾に追加して継続実行
   - スクリプトの実行権限確認: `chmod +x scripts/*.sh`
   - ログを確認: コンテナ起動ログでsetup-claude.shのエラーメッセージを確認

5. **mountsでPermission Denied**
   - ホスト側でディレクトリ事前作成: `mkdir -p ~/.codex ~/.claude`
   - ディレクトリのパーミッション確認: `ls -la ~/ | grep -E "codex|claude"`

6. **Featuresのインストールが遅い**
   - 不要なFeatureを削除
   - ベースイメージに含まれるものは重複指定しない

## 参考リンク

### DevContainer関連

- [DevContainers公式ドキュメント](https://containers.dev/)
- [config-base最新リリース](https://github.com/keito4/config/pkgs/container/config-base)
- [DevContainer Features検索](https://containers.dev/features)

### Claude Code関連

- [Claude Code公式ドキュメント](https://docs.anthropic.com/claude/docs/claude-code)
- [Claude API Documentation](https://docs.anthropic.com/)
- 本リポジトリのClaude設定: [.claude/](./.claude/) および [.codex/](./.codex/)

---

**更新日**: 2025-12-30
**バージョン**: 1.0.0
**メンテナ**: keito4
