---
description: Setup new repository with DevContainer, CI/CD, and development tools from config template
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(cat:*), Bash(test:*), Task, Glob, Grep
argument-hint: '<TARGET_DIR> [--minimal] [--no-devcontainer] [--no-codespaces] [--license MIT|Apache-2.0] [--no-install]'
---

# New Repository Setup Command

新しいリポジトリにDevContainer、CI/CD、開発ツールをセットアップします。

## Overview

以下をセットアップします：

1. **Git初期化** - リポジトリの初期化
2. **DevContainer** - `.devcontainer/` と `.vscode/` 設定（Codespaces 対応含む）
3. **Git設定** - commitlint, `.gitignore`
4. **GitHub Actions** - CI workflow, Issue/PRテンプレート
5. **開発ツール** - ESLint, Prettier, Jest, Husky
6. **ドキュメント** - README.md, CLAUDE.md, SECURITY.md
7. **Codespaces シークレット** - リポジトリへのシークレット紐付け

## Step 1: Parse Arguments

引数から設定を読み取る：

- `TARGET_DIR`: 新規リポジトリのパス（必須）
- `--minimal`: GitHub Actionsをスキップ
- `--no-devcontainer`: DevContainer設定をスキップ
- `--no-codespaces`: Codespacesシークレット紐付けをスキップ
- `--license TYPE`: ライセンス種別（デフォルト: MIT）
- `--no-install`: npm install をスキップ

## Step 2: Validate Target Directory

ターゲットディレクトリを確認：

```bash
# ディレクトリが存在するか確認
ls -la TARGET_DIR 2>/dev/null || echo "Directory will be created"
```

既存のリポジトリがある場合は警告を表示し、上書きの確認を取る。

## Step 3: Get Config Repository Path

このconfigリポジトリのパスを取得：

```bash
# 現在のリポジトリパスを確認
git rev-parse --show-toplevel
```

## Step 4: Initialize Git Repository

```bash
cd TARGET_DIR
git init
```

## Step 5: Create DevContainer Configuration (unless --no-devcontainer)

DevContainer設定をプロジェクトに合わせて新規作成する。configリポジトリからコピーせず、プロジェクト固有の設定を生成する。

### 5.1 `.devcontainer/devcontainer.json` を作成

以下をすべて含める（Codespaces 対応がデフォルト）：

```json
{
  "name": "{project-name}",
  "image": "ghcr.io/keito4/config-base:latest",
  "features": {
    // プロジェクトに必要な追加 features をここに記載
  },
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  },
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-typescript-next"
        // プロジェクトに応じた拡張機能を追加
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": "explicit"
        },
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "files.eol": "\n",
        "files.trimTrailingWhitespace": true,
        "files.insertFinalNewline": true
      }
    },
    "codespaces": {
      "openFiles": ["README.md"]
    }
  },
  "secrets": {
    "ANTHROPIC_API_KEY": {
      "description": "Anthropic API key for Claude Code"
    }
    // プロジェクト固有のシークレットを追加
  }
}
```

**重要**: `codespaces` カスタマイゼーションと `secrets` セクションは常にデフォルトで含める。

### 5.2 `.vscode/` 設定を作成

```bash
mkdir -p TARGET_DIR/.vscode
```

- `extensions.json`: 推奨拡張機能
- `settings.json`: エディタ設定（formatOnSave, ESLint, Prettier）

### DevContainer 設定内容

- `ghcr.io/keito4/config-base:latest` ベースイメージ
- Node.js 22+
- 推奨VS Code拡張機能
- Codespaces 対応（シークレット定義、openFiles）
- `postCreateCommand` による自動依存関係インストール

## Step 6: Setup Git Configuration

### 6.1 Commitlint設定

```bash
cp CONFIG_REPO/git/commitlint.config.js TARGET_DIR/
```

### 6.2 .gitignore作成

以下の内容で `.gitignore` を作成：

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
*.lcov

# Production
build/
dist/
*.tgz

# Misc
.DS_Store
.env
.env.local
.env.*.local

# Logs
logs
*.log
npm-debug.log*

# IDE
.idea/
*.swp
*.swo
*~
.vscode/settings.local.json

# OS
Thumbs.db
```

## Step 7: Copy GitHub Actions (unless --minimal)

```bash
mkdir -p TARGET_DIR/.github/workflows
cp CONFIG_REPO/.github/workflows/ci.yml TARGET_DIR/.github/workflows/

mkdir -p TARGET_DIR/.github/ISSUE_TEMPLATE
cp -r CONFIG_REPO/.github/ISSUE_TEMPLATE/* TARGET_DIR/.github/ISSUE_TEMPLATE/

cp CONFIG_REPO/.github/PULL_REQUEST_TEMPLATE.md TARGET_DIR/.github/
```

## Step 8: Setup Development Tools

### 8.1 package.json 作成

```json
{
  "name": "new-project",
  "version": "1.0.0",
  "description": "New project bootstrapped from config repository",
  "scripts": {
    "lint": "eslint . --ext .js,.ts,.tsx",
    "lint:fix": "npm run lint -- --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "prepare": "husky"
  },
  "devDependencies": {
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0",
    "eslint": "^9.0.0",
    "husky": "^9.0.0",
    "jest": "^29.0.0",
    "prettier": "^3.0.0"
  }
}
```

### 8.2 設定ファイルをコピー

```bash
cp CONFIG_REPO/eslint.config.mjs TARGET_DIR/
cp CONFIG_REPO/.prettierrc TARGET_DIR/
cp CONFIG_REPO/jest.config.js TARGET_DIR/
```

## Step 9: Create Documentation

### 9.1 README.md

プロジェクト名を含むREADMEを作成：

```markdown
# {project-name}

<!-- TODO: Add project description -->

## Features

<!-- TODO: List key features -->

## Getting Started

### Prerequisites

- Node.js 22+
- npm or pnpm

### Installation

\`\`\`bash
npm install
\`\`\`

### Development

\`\`\`bash
npm run dev
\`\`\`

### Testing

\`\`\`bash
npm test
npm run test:coverage
\`\`\`

## Contributing

Please read [CLAUDE.md](./CLAUDE.md) for development guidelines.

## License

This project is licensed under the {LICENSE} License.
```

### 9.2 CLAUDE.md

```bash
cp CONFIG_REPO/.claude/CLAUDE.md TARGET_DIR/
```

### 9.3 SECURITY.md

セキュリティポリシーを作成。

## Step 10: Install Dependencies (unless --no-install)

```bash
cd TARGET_DIR
npm install
npx husky init
```

## Step 11: Add to Codespaces Secrets (Default)

Codespaces でリポジトリを使用できるように、シークレットの紐付けをデフォルトで実行する。
`--no-codespaces` オプションが指定された場合のみスキップ。

### 11.1: Check if codespaces-secrets.sh is available

```bash
test -f CONFIG_REPO/script/codespaces-secrets.sh && echo "available" || echo "not_available"
```

### 11.2: Add repository to Codespaces secrets

```bash
# リポジトリをシークレット管理対象に追加
CONFIG_REPO/script/codespaces-secrets.sh repos add {owner}/{repo-name}

# 全シークレットに紐付け
CONFIG_REPO/script/codespaces-secrets.sh sync
```

### 11.3: Verify setup

```bash
# 紐付け状態を確認
CONFIG_REPO/script/codespaces-secrets.sh list
```

シークレットスクリプトが利用できない場合は、手動設定のガイドを表示する。

## Step 12: Generate Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Repository Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Target: {TARGET_DIR}

Files Created:
✅ .devcontainer/
✅ .vscode/
✅ .github/workflows/ci.yml
✅ .github/ISSUE_TEMPLATE/
✅ .github/PULL_REQUEST_TEMPLATE.md
✅ package.json
✅ eslint.config.mjs
✅ .prettierrc
✅ jest.config.js
✅ commitlint.config.js
✅ .gitignore
✅ README.md
✅ CLAUDE.md
✅ SECURITY.md

Next Steps:
1. cd {TARGET_DIR}
2. Update README.md with project details
3. Update package.json (name, description)
4. git add . && git commit -m "chore: initial setup"
5. gh repo create (optional)
6. git push -u origin main
7. Add to Codespaces secrets (if using GitHub Codespaces):
   - Run: ./script/codespaces-secrets.sh repos add {owner}/{repo-name}
   - Run: ./script/codespaces-secrets.sh sync

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Options Summary

| オプション          | 説明                                   | デフォルト |
| ------------------- | -------------------------------------- | ---------- |
| `--minimal`         | GitHub Actionsをスキップ               | false      |
| `--no-devcontainer` | DevContainer設定をスキップ             | false      |
| `--no-codespaces`   | Codespacesシークレット紐付けをスキップ | false      |
| `--license TYPE`    | ライセンス種別                         | MIT        |
| `--no-install`      | npm installをスキップ                  | false      |

## Related Commands

| コマンド                   | 説明                           |
| -------------------------- | ------------------------------ |
| `/setup-ci`                | CI/CDワークフローの詳細設定    |
| `/setup-husky`             | Husky + lint-staged の詳細設定 |
| `/setup-team-protection`   | ブランチ保護ルールの設定       |
| `/config-base-sync-update` | DevContainerを最新に更新       |

## Error Handling

エラー発生時：

1. 具体的なエラー内容を報告
2. 手動での修正方法を提案
3. 部分的な成功でも適用可能な変更は適用
