# Project Initialization

このプロジェクトではDevContainerを使用した開発環境を推奨しています。必要に応じて以下の設定を調整してください。

## 推奨開発環境

### DevContainerの使用

このプロジェクトは`.devcontainer/devcontainer.json`に定義されたDevContainerで開発することを前提としています。

すでに初期化されており、このコマンドが実行されている場合には、以下の内容を踏まえプロジェクト特有のfeaturesを追加/その他の設定の追加をしてください。
プロジェクトの実際の要件を確認して、必要なfeaturesのみを含むように設定してください。

#### 推奨されるFeatures

- **Node.js & pnpm**: プロジェクトのパッケージ管理
- **GitHub CLI (gh)**: PR作成やGitHub操作
- **Git**: バージョン管理
- **Terraform**: インフラ管理
- **Google Cloud CLI**: GCP操作
- **AWS CLI**: AWS操作
- **kubectl**: Kubernetes操作
- **act**: GitHub Actionsのローカル実行
- **Homebrew**: 追加パッケージの管理
- **jq-likes**: JSON/YAML処理ツール
- **1Password CLI**: セキュアな認証情報管理

### DevContainerのカスタマイズ

プロジェクト固有の要件がある場合は、`.devcontainer/devcontainer.json`の`features`セクションを編集してください：

```json
"features": {
    // 既存のfeatures...
    // 新しいfeatureを追加
    "ghcr.io/devcontainers/features/python:1": {
        "version": "3.11"
    }
}
```

## プロジェクト固有の設定

### postCreateCommand

コンテナ作成後に実行される処理：

```bash
npm ci && npm run prepare
```

これによりHuskyなどのGit hooksが自動的にセットアップされます。

### マウント設定

ホストマシンの以下のディレクトリがコンテナにマウントされます：

- `~/.claude`: Claude設定
- `~/.cursor`: Cursor設定
- `~/.claude.json`: Claude設定ファイル
- `~/.gitconfig`: Git設定
- `~/.gitignore`: Git ignore設定
- `~/.config/gh/hosts.yml`: GitHub CLIの設定

## 推奨Git設定

### Commitlint設定（日本語対応）

プロジェクトで日本語のコミットメッセージを使用する場合、`commitlint.config.js`に以下の設定を推奨します：

```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [0], // 日本語対応のため無効化
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'scope-empty': [0]
  }
};
```

この設定により、日本語のコミットメッセージでも`subject-case`エラーが発生しなくなります。

### Conventional Commits

以下の形式でコミットメッセージを記述します：

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **type**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`など
- **scope**: 変更の影響範囲（オプション）
- **subject**: 変更内容の要約（日本語可）
- **body**: 詳細な説明（オプション）
- **footer**: Breaking Changeやissue参照（オプション）
