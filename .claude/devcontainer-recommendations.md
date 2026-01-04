# DevContainer 推奨設定ガイド

## 目的

Elu-co-jp配下の全リポジトリで統一されたDevContainer環境を提供し、開発者体験を向上させる。

**重要**: 本ガイドの推奨設定は、**Claude Code（AI開発アシスタント）が基本的に動作すること**を前提としています。すべての設定例は、Claude Code環境での動作を保証します。

## ベースイメージ

```json
{
  "image": "ghcr.io/keito4/config-base:1.43.0"
}
```

**最新バージョン**: 1.43.0
**推奨バージョン**: 1.43.0+（安定版として広く採用）

## Claude Code動作のための必須設定

Claude Code（AI開発アシスタント）を動作させるための最小限の設定です。

### 1. ベースイメージ

```json
{
  "image": "ghcr.io/keito4/config-base:1.43.0"
}
```

- config-baseイメージには`@anthropic-ai/claude-code` CLIが既にインストール済み
- バージョン1.43.0以降を推奨

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

### 5. MCP (Model Context Protocol) 設定

Claude CodeでMCPサーバーを利用する場合、`.mcp.json`の配置とマウントが必要です。

**推奨配置**: `.claude/.mcp.json`（Claude Codeが優先的に読み込む場所）

#### `.mcp.json`の生成方法

```bash
# postCreateCommandで自動生成（推奨）
bash script/setup-mcp.sh
```

`setup-mcp.sh`は以下を実行：

- `credentials/mcp.env`から環境変数を読み込み
- `.mcp.json.template`から`.mcp.json`を生成
- ワークスペースルート（`/workspaces/<project>/.mcp.json`）に配置

#### MCP設定例（`.mcp.json`）

```json
{
  "mcpServers": {
    "o3": {
      "type": "stdio",
      "command": "npx",
      "args": ["o3-search-mcp"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}"
      }
    },
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {}
    }
  }
}
```

#### 必須環境変数（`.devcontainer.env`）

```bash
OPENAI_API_KEY=***  # o3 MCP用
```

#### ⚠️ 重要な注意事項

1. **セキュリティ**:
   - `.mcp.json`は`.gitignore`に追加必須
   - API KEYは環境変数テンプレート（`${OPENAI_API_KEY}`）を使用
   - 平文でのAPI KEY保存は避ける

2. **配置場所の優先順位**:
   - Claude Codeは以下の順で`.mcp.json`を探索：
     1. `.claude/.mcp.json`（推奨）
     2. `~/.claude/.mcp.json`（グローバル）
     3. ワークスペースルート（バージョン依存）

#### MCP対応のpostCreateCommand

```json
{
  "postCreateCommand": "bash script/setup-env.sh && bash script/setup-mcp.sh && /usr/local/bin/setup-claude.sh"
}
```

### Claude Code最小構成例

```json
{
  "name": "Project Name",
  "image": "ghcr.io/keito4/config-base:1.43.0",
  "mounts": [
    "source=${localEnv:HOME}/.codex,target=/home/vscode/.codex,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"
  ],
  "postCreateCommand": "bash script/setup-env.sh && bash script/setup-mcp.sh && /usr/local/bin/setup-claude.sh",
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

**主要機能**:

- DevContainer内から`docker`コマンドを実行可能
- Docker Composeワークフローのテスト
- コンテナイメージのビルドとテスト
- マルチコンテナアプリケーションのデバッグ

**主なユースケース**:

1. **コンテナ化アプリのテスト**: Docker Composeで完全なスタックをテスト
2. **CI/CD開発**: GitHub Actionsを`act`でローカルテスト
3. **イメージビルド**: カスタムDockerイメージをローカルビルド
4. **マルチコンテナデバッグ**: コンテナに依存するサービスのデバッグ

**使用を推奨する場合**:

- ✅ Dockerイメージをビルドするプロジェクト
- ✅ Docker Composeを使用するプロジェクト
- ✅ GitHub Actionsワークフローをローカルでテストしたい
- ✅ コンテナベースのE2Eテストを実行する

**使用を避けるべき場合**:

- ❌ Dockerを全く使わないプロジェクト
- ❌ パフォーマンスが最重要（ネイティブDockerより遅い）
- ❌ セキュリティ要件が厳しい環境（特権コンテナモードが必要）
- ❌ リソースが限られた環境（追加のメモリ/CPU使用）

**セキュリティ考慮事項**:

- ⚠️ 特権コンテナモードが必要（`--privileged`）
- ⚠️ ホストのDockerデーモンへのアクセス権限
- ⚠️ 本番環境での使用は推奨しない

**パフォーマンス考慮事項**:

- ネイティブDockerと比較して若干のオーバーヘッド
- 追加のメモリとCPUリソースを消費
- I/O操作が多い場合は特に影響が大きい

**代替アプローチ**:

ホストのDockerソケットをマウントする方法（より軽量だがセキュリティリスクあり）:

```json
{
  "mounts": ["source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"]
}
```

**推奨設定**:

- Docker Compose v2を使用（`dockerDashComposeVersion: "v2"`）
- Mobyを有効化（`moby: true`）
- VS Code + GitHub Codespacesの両方で動作

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

#### pnpmパッケージマネージャー

pnpmを使用する場合、以下の2つの設定方法があります:

##### 推奨: 独立したpnpm Feature

```json
{
  "ghcr.io/devcontainers-extra/features/pnpm:2": {
    "version": "latest"
  }
}
```

##### 利点

- pnpmバージョン管理が明確で独立
- node Featureとの依存関係を分離
- 最新のpnpm機能を即座に利用可能
- より柔軟なバージョン管理
- pnpmのみが必要なプロジェクトでも使用可能

##### 使用を推奨する場合

- ✅ pnpmをパッケージマネージャーとして使用するプロジェクト
- ✅ pnpmのバージョンを明示的に管理したい場合
- ✅ Node.jsバージョンとpnpmバージョンを独立して管理したい場合
- ✅ monorepo構成でworkspace機能を活用する場合

##### 代替: node:1のpnpmVersionオプション

```json
{
  "ghcr.io/devcontainers/features/node:1": {
    "version": "20",
    "pnpmVersion": "latest"
  }
}
```

##### この方法の特徴

- Node.jsインストールと同時にpnpmをセットアップ
- シンプルな設定で済む
- pnpmバージョンはNode.js Featureに依存

##### 推奨アプローチ

独立した`pnpm:2` Featureを使用することで、Node.jsとpnpmのバージョン管理を分離し、より明確で保守しやすい構成が可能になります。特にpnpmのバージョン管理を厳密に行いたい場合や、Node.jsのバージョンを変更してもpnpmバージョンは固定したい場合に有効です。

### Supabaseプロジェクト

```json
{
  "ghcr.io/devcontainers-extra/features/supabase-cli": {}
}
```

**バージョン**: latest（デフォルト）

**利点**:

- **データベースマイグレーション**: `supabase db push`、`supabase db diff`でスキーマ管理
- **型生成**: `supabase gen types typescript`でTypeScript型を自動生成
- **ローカル開発環境**: `supabase start`でローカルSupabaseスタックを起動
- **Edge Functions開発**: `supabase functions serve`でローカルテスト
- **リモート管理**: `supabase link`でプロジェクトと連携

**必須ケース**:

- ✅ `supabase/config.toml`が存在するプロジェクト
- ✅ Supabaseをバックエンドとして使用するプロジェクト
- ✅ データベーススキーマのバージョン管理が必要な場合
- ✅ Supabase Edge Functionsを開発する場合

**推奨設定**:

プロジェクトルートに`supabase/config.toml`が存在する場合、このFeatureを追加することを強く推奨します。

**関連Feature**:

Supabase Edge Functionsを開発する場合、Deno Runtimeとの併用を推奨:

```json
{
  "ghcr.io/devcontainers-extra/features/supabase-cli": {},
  "ghcr.io/devcontainers-community/features/deno:1": {}
}
```

**参考リンク**:

- [Supabase CLI公式ドキュメント](https://supabase.com/docs/guides/cli)
- [DevContainer Feature](https://github.com/devcontainers-extra/features/tree/main/src/supabase-cli)

### Deno Runtime（Edge Functions開発）

```json
{
  "ghcr.io/devcontainers-community/features/deno:1": {}
}
```

**バージョン**: 1 (最新のメジャーバージョン)

**利点**:

- **TypeScriptファーストサポート**: 設定不要でTypeScriptを直接実行可能
- **Supabase Edge Functions対応**: Supabase Edge Functionsの開発環境として必須
- **組み込みツールチェーン**: `deno fmt`（フォーマッター）、`deno lint`（リンター）、`deno test`（テストランナー）が標準搭載
- **セキュアデフォルト**: 権限システムによりファイルシステムやネットワークアクセスを明示的に許可
- **モダンエコシステム**: JSR (JavaScript Registry) との統合

**必須ケース**:

- Supabase Edge Functionsの開発
- DenoベースのWebアプリケーション
- TypeScript/JavaScriptのモダンランタイム環境が必要な場合

**参考リンク**:

- [Deno DevContainer Feature](https://github.com/devcontainers-community/features/tree/main/src/deno)
- [Deno公式ドキュメント](https://deno.com/)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

### E2Eテスト環境

```json
{
  "ghcr.io/schlich/devcontainer-features/playwright:0": {}
}
```

- 利用率: 75% (6/8)
- 用途: ブラウザ自動テスト、E2Eテスト実行環境

**主要機能**:

- Playwright本体とブラウザ（Chromium、Firefox、WebKit）の自動インストール
- ヘッドレスブラウザ実行環境の構築
- E2Eテストに必要な依存ライブラリの自動セットアップ
- CI/CD環境との一貫性確保

**主なユースケース**:

1. **E2Eテストの実装**: ブラウザを使った統合テストの作成と実行
2. **UIテストの自動化**: フロントエンド機能の自動テスト
3. **クロスブラウザテスト**: 複数ブラウザでの動作確認
4. **スクリーンショット/ビデオ録画**: テスト実行時の視覚的記録

**使用を推奨する場合**:

- ✅ Playwrightを使用したE2Eテストがあるプロジェクト
- ✅ `playwright.config.ts`が存在するプロジェクト
- ✅ ブラウザベースのUIテストを実行する必要がある
- ✅ CI/CD環境との一貫性を保ちたい

**使用を避けるべき場合**:

- ❌ E2Eテストがないプロジェクト
- ❌ バックエンドのみのプロジェクト
- ❌ 他のE2Eテストツール（Cypress、Seleniumなど）を使用している

**パフォーマンス考慮事項**:

- ブラウザバイナリのインストールに時間とストレージを使用
- 初回ビルド時に数百MBのダウンロードが発生
- ヘッドレスモードでの実行を推奨（リソース効率化）

**CI/CD統合**:

GitHub ActionsなどのCI環境でも同じPlaywright設定を使用することで、ローカルとCI環境の一貫性を保証できます。

**推奨設定**:

最新バージョンのPlaywrightを使用し、ブラウザの自動アップデートを有効にする（デフォルト設定）。

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

### common-utils with Zsh（開発者体験向上）

```json
{
  "ghcr.io/devcontainers/features/common-utils:2": {
    "configureZshAsDefaultShell": true
  }
}
```

**機能概要**:

- **Zsh**: モダンで機能豊富なシェル
- **Oh-My-Zsh**: 人気のZsh設定フレームワーク
- **共通CLIツール**: curl, wget, git など
- **ビルドツール**: gcc, make など

**Zshの利点**:

- ✅ スマートなタブ補完（Bashより高機能）
- ✅ 豊富なプラグインエコシステム（Oh-My-Zsh）
- ✅ カスタマイズ可能なプロンプト
- ✅ 改善されたコマンド履歴検索
- ✅ Gitステータスのプロンプト表示

**考慮事項**:

- 学習コストあり（Bashに慣れた開発者向け）
- ほとんどのBashスクリプトはZshでも動作（一部互換性差異あり）
- 起動が若干遅い（実用上は無視できるレベル）

**Bash派の代替設定**:

```json
{
  "ghcr.io/devcontainers/features/common-utils:2": {}
}
```

Zshを無効にする場合は`configureZshAsDefaultShell`オプションを省略します。

**推奨環境変数**（Zsh使用時）:

```json
{
  "remoteEnv": {
    "SHELL": "/bin/zsh"
  }
}
```

**利用シーン**:

- 開発者の生産性向上を重視するプロジェクト
- ターミナル操作が多いプロジェクト
- チーム全体で統一されたシェル環境を提供したい場合

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

- **ベースイメージ**: セマンティックバージョニング（例: `1.43.0`）を明示
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
   + "image": "ghcr.io/keito4/config-base:1.43.0"
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

7. **MCPサーバーが動作しない**
   - `.mcp.json`の存在確認:
     ```bash
     ls -la /workspaces/<project>/.mcp.json
     ls -la ~/.claude/.mcp.json
     ```
   - `.mcp.json`が生成されない場合:
     - `credentials/mcp.env`が存在するか確認
     - `script/setup-env.sh`を先に実行
     - 手動で実行: `bash script/setup-mcp.sh`
   - 環境変数が展開されているか確認:
     ```bash
     cat .mcp.json | grep OPENAI_API_KEY
     # ${OPENAI_API_KEY}が残っている場合は未展開
     ```
   - 推奨: `.mcp.json`を`.claude/.mcp.json`にコピー:
     ```bash
     mkdir -p ~/.claude
     cp .mcp.json ~/.claude/.mcp.json
     ```

8. **o3 MCP（OpenAI検索）が使えない**
   - `OPENAI_API_KEY`の設定確認:
     ```bash
     echo $OPENAI_API_KEY
     ```
   - `credentials/mcp.env`に`OPENAI_API_KEY`が含まれているか確認
   - 1Passwordから取得:
     ```bash
     OP_ACCOUNT=your.1password.com bash script/setup-env.sh
     ```
   - `.mcp.json`を再生成:
     ```bash
     bash script/setup-mcp.sh
     ```

9. **Playwright MCPが動作しない**
   - Node.jsとnpxが利用可能か確認:
     ```bash
     node --version
     npx --version
     ```
   - Playwrightパッケージをグローバルインストール:
     ```bash
     npm install -g @playwright/mcp@latest
     ```
   - ブラウザのインストール:
     ```bash
     npx playwright install
     ```

## 参考リンク

### DevContainer関連

- [DevContainers公式ドキュメント](https://containers.dev/)
- [config-base最新リリース](https://github.com/keito4/config/pkgs/container/config-base)
- [DevContainer Features検索](https://containers.dev/features)

### Claude Code関連

- [Claude Code公式ドキュメント](https://docs.anthropic.com/claude/docs/claude-code)
- [Claude API Documentation](https://docs.anthropic.com/)
- 本リポジトリのClaude設定: [.claude/](./.claude/) および [.codex/](./.codex/)

### MCP (Model Context Protocol) 関連

- [MCP公式ドキュメント](https://modelcontextprotocol.io/)
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
- [o3 Search MCP](https://www.npmjs.com/package/o3-search-mcp)
- 本リポジトリのMCP設定: [.mcp.json.template](./.mcp.json.template) および [credentials/templates/mcp.env.template](./credentials/templates/mcp.env.template)

---

**更新日**: 2025-12-30
**バージョン**: 1.0.0
**メンテナ**: keito4
