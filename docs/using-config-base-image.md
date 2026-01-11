# config-base イメージの使用方法

## 概要

`ghcr.io/keito4/config-base` イメージは、Claude Code の完全なセットアップを含む DevContainer イメージです。新しいリポジトリでこのイメージを使用することで、以下がすぐに利用可能になります：

- Claude Code CLI と設定
- 事前インストールされたプラグイン
- カスタムコマンド（`/config-base-sync-check`, `/security-credential-scan` など）
- カスタムエージェント（DDD, パフォーマンス分析など）
- Git hooks（Quality Gates）
- 開発ツール（Node.js, pnpm, Rust, terraform, aws-cli など）

## 最小構成（マウントなし）

新しいリポジトリで最小限の設定で使用する場合：

```json
// .devcontainer/devcontainer.json
{
  "name": "My Project",
  "image": "ghcr.io/keito4/config-base:1.43.0",
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  }
}
```

この構成では、イメージに含まれているすべての設定がそのまま利用できます。

### 利用可能なコマンド

```bash
# Claude Code コマンド
claude --help

# カスタムコマンド
/config-base-sync-check      # イメージバージョン確認
/security-credential-scan    # 認証情報スキャン
/code-complexity-check       # コード複雑度チェック
/dependency-health-check     # 依存関係ヘルスチェック
/pre-pr-checklist           # PR前チェックリスト
# その他多数...
```

### プラグイン

以下のプラグインが事前インストールされています：

- `commit-commands@claude-plugins-official`
- `hookify@claude-plugins-official`
- `plugin-dev@claude-plugins-official`
- `frontend-design@claude-plugins-official`
- `typescript-lsp@claude-plugins-official`
- `code-refactoring@claude-code-workflows`
- `code-review@claude-plugins-official`
- `code-review-ai@claude-code-workflows`
- `kubernetes-operations@claude-code-workflows`
- `javascript-typescript@claude-code-workflows`
- `playwright-skill@playwright-skill`

## 推奨構成（ホスト設定の永続化）

プラグインの追加インストールや設定のカスタマイズを永続化したい場合：

```json
// .devcontainer/devcontainer.json
{
  "name": "My Project",
  "image": "ghcr.io/keito4/config-base:1.43.0",
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  },
  "initializeCommand": "mkdir -p ~/.claude",
  "mounts": ["source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"],
  "postCreateCommand": "/usr/local/bin/setup-claude.sh"
}
```

この構成では：

- ホストの `~/.claude` をマウントして設定を永続化
- `setup-claude.sh` でイメージの設定をホスト側にコピー
- 追加のプラグインインストールや設定変更が保持される

## プロジェクト固有の設定を追加

プロジェクト固有のコマンドやプラグインを追加する場合：

### 1. リポジトリに `.claude/` ディレクトリを作成

```bash
mkdir -p .claude/commands
mkdir -p .claude/plugins
```

### 2. プロジェクト固有のコマンドを追加

```markdown
<!-- .claude/commands/my-custom-command.md -->

# My Custom Command

プロジェクト固有のコマンド説明...
```

### 3. プロジェクト固有のプラグインを追加

```txt
# .claude/plugins/plugins.txt
# プロジェクト固有のプラグイン
my-plugin@marketplace
```

### 4. `devcontainer.json` を更新

```json
{
  "name": "My Project",
  "image": "ghcr.io/keito4/config-base:1.43.0",
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  },
  "initializeCommand": "mkdir -p ~/.claude",
  "mounts": ["source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"],
  "postCreateCommand": "/usr/local/bin/setup-claude.sh"
}
```

`setup-claude.sh` は以下を自動的に行います：

- リポジトリの `.claude/commands/` を `~/.claude/commands/` にコピー
- リポジトリの `.claude/plugins/plugins.txt` からプラグインをインストール

## イメージのビルドとリリース

このリポジトリでイメージをビルドする場合：

```bash
# ローカルビルド（認証情報を使用）
DOCKER_BUILDKIT=1 docker build \
  --secret id=claude_credentials,src=$HOME/.claude/.credentials.json \
  -t ghcr.io/keito4/config-base:local \
  -f .devcontainer/Dockerfile \
  .

# GitHub Actions でのビルド（自動）
# main ブランチへのプッシュで自動的にビルド・リリース
git push origin main
```

## トラブルシューティング

### プラグインがインストールされていない

イメージビルド時に認証情報がない場合、プラグインのインストールがスキップされます。コンテナ起動後に手動でインストールしてください：

```bash
claude plugin install <plugin>@<marketplace>
```

### hooks が動作しない

`setup-claude.sh` を実行してhookifyパッチを適用してください：

```bash
/usr/local/bin/setup-claude.sh
```

### 設定が反映されない

マウント設定により、ホストの `~/.claude` がイメージの内容を上書きしている可能性があります。`postCreateCommand` で `setup-claude.sh` を実行することで、イメージの設定をホスト側にコピーできます。

## 参考情報

- [Claude Code ドキュメント](https://github.com/anthropics/claude-code)
- [DevContainers 仕様](https://containers.dev/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
