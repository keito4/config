# Project Initialization

このプロジェクトではDevContainerを使用した開発環境を推奨しています。必要に応じて以下の設定を調整してください。

## 推奨開発環境

### DevContainerの使用

このプロジェクトは`.devcontainer/devcontainer.json`に定義されたDevContainerで開発することを前提としています。

すでに初期化されており、このコマンドが実行されている場合には、以下の内容を踏まえプロジェクト特有のfeaturesを追加/その他の設定の追加をしてください。
プロジェクトの実際の要件を確認して、必要なfeaturesのみを含むように設定してください。

#### 推奨されるFeatures

- **Node.js**: フロントエンド開発
- **pnpm**: パッケージ管理("ghcr.io/devcontainers-extra/features/pnpm:2")
- **GitHub CLI (gh)**: PR作成やGitHub操作
- **Git**: バージョン管理
- **Terraform**: インフラ管理
- **Google Cloud CLI**: GCP操作
- **AWS CLI**: AWS操作
- **kubectl**: Kubernetes操作
- **act**: GitHub Actionsのローカル実行
- **Homebrew**: 追加パッケージの管理
- **jq-likes**: JSON/YAML処理ツール("ghcr.io/eitsupi/devcontainer-features/jq-likes:2")
- **1Password CLI**: セキュアな認証情報管理

https://containers.dev/features

上記で存在の確認をしてから導入するようにしてください。

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

## 品質管理設定

### ESLint/Prettier設定

コードの品質と一貫性を保つため、以下の設定を推奨します：

#### `.eslintrc.js`
```javascript
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier'
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  rules: {
    // プロジェクト固有のルールを追加
  }
};
```

#### `.prettierrc`
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 120
}
```

### Husky設定

Git hooksを自動化するため、以下の設定を推奨します：

```bash
npx husky add .husky/pre-commit "npm run lint"
npx husky add .husky/commit-msg "npx commitlint --edit $1"
```

### GitHub Actions設定

CI/CDパイプラインの基本設定例：

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main, master]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run test
      - run: npm run build
```

### package.json scripts

基本的なnpmスクリプトの推奨設定：

```json
{
  "scripts": {
    "dev": "開発サーバー起動コマンド",
    "build": "ビルドコマンド",
    "test": "テスト実行コマンド",
    "lint": "eslint . --ext .js,.jsx,.ts,.tsx",
    "lint:fix": "npm run lint -- --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "type-check": "tsc --noEmit",
    "prepare": "husky install"
  }
}
```

### .gitignore推奨設定

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
.nyc_output/

# Production
build/
dist/
out/

# Misc
.DS_Store
*.local
.env*.local

# Debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json
.idea/
*.swp
*.swo

# TypeScript
*.tsbuildinfo
```

### VSCode推奨設定

`.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

`.vscode/extensions.json`:
```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-typescript-next"
  ]
}
```

### mounts推奨設定

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.cursor,target=/home/vscode/.cursor,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.claude/.credentials.json,target=/home/vscode/.claude/.credentials.json,type=bind,consistency=cached"
  ]
}
```
