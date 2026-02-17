---
description: Setup new repository with DevContainer, CI/CD, and development tools from config template
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(cat:*), Bash(test:*), Task, Glob, Grep
argument-hint: '<TARGET_DIR> [--minimal] [--no-devcontainer] [--no-codespaces] [--no-protection] [--license MIT|Apache-2.0] [--no-install]'
---

# New Repository Setup Command

新しいリポジトリにDevContainer、CI/CD、開発ツールをセットアップします。

## Overview

以下をセットアップします：

1. **Git初期化** - リポジトリの初期化
2. **DevContainer** - `.devcontainer/` と `.vscode/` 設定（Codespaces 対応含む）
3. **Git設定** - commitlint, `.gitignore`
4. **GitHub Actions** - CI, Claude Code, Security, Code Review workflow, Issue/PRテンプレート
5. **Claude Code Hooks** - `.claude/hooks/` と `.claude/settings.json`
6. **開発ツール** - ESLint, Prettier, Jest, Husky, lint-staged, `.node-version`
7. **ドキュメント** - README.md, CLAUDE.md, SECURITY.md
8. **依存関係インストール & Husky フック** - npm install, commit-msg / pre-commit / pre-push
9. **Codespaces シークレット** - リポジトリへのシークレット紐付け
10. **ブランチ保護 & リポジトリ設定** - main ブランチ保護、セキュリティ設定

## Step 1: Parse Arguments

引数から設定を読み取る：

- `TARGET_DIR`: 新規リポジトリのパス（必須）
- `--minimal`: GitHub Actionsをスキップ
- `--no-devcontainer`: DevContainer設定をスキップ
- `--no-codespaces`: Codespacesシークレット紐付けをスキップ
- `--no-protection`: ブランチ保護・リポジトリ設定をスキップ
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

DevContainer設定をプロジェクトに合わせて新規作成する。ローカル用と Codespaces 用の2つを作成する。

### 5.1 `.devcontainer/devcontainer.json`（ローカル用）を作成

ローカル DevContainer 用。Codespaces 固有設定（`secrets`, `codespaces` カスタマイゼーション）は含めない。

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
    }
  }
}
```

### 5.2 `.devcontainer/codespaces/devcontainer.json`（Codespaces 用）を作成

GitHub Codespaces 用。`secrets`, `codespaces` カスタマイゼーション、`sshd` feature を含める。

```json
{
  "name": "{project-name} (Codespaces)",
  "image": "ghcr.io/keito4/config-base:latest",
  "features": {
    "ghcr.io/devcontainers/features/sshd:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
    // プロジェクトに必要な追加 features をここに記載
  },
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  },
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      // ローカル用と同じ extensions / settings
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

**重要**: 2つの devcontainer.json を常にセットで作成する。

### 5.3 `.vscode/` 設定を作成

```bash
mkdir -p TARGET_DIR/.vscode
```

- `extensions.json`: 推奨拡張機能
- `settings.json`: エディタ設定（formatOnSave, ESLint, Prettier）

### DevContainer 設定内容

- `ghcr.io/keito4/config-base:latest` ベースイメージ
- Node.js 22+
- 推奨VS Code拡張機能
- ローカル用: 軽量構成
- Codespaces 用: sshd, secrets, codespaces カスタマイゼーション
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
cp CONFIG_REPO/.github/workflows/claude.yml TARGET_DIR/.github/workflows/
cp CONFIG_REPO/.github/workflows/security.yml TARGET_DIR/.github/workflows/
cp CONFIG_REPO/.github/workflows/claude-code-review.yml TARGET_DIR/.github/workflows/

mkdir -p TARGET_DIR/.github/ISSUE_TEMPLATE
cp -r CONFIG_REPO/.github/ISSUE_TEMPLATE/* TARGET_DIR/.github/ISSUE_TEMPLATE/

cp CONFIG_REPO/.github/PULL_REQUEST_TEMPLATE.md TARGET_DIR/.github/
```

### 7.1 Claude Code workflow

`claude.yml` は `@claude` メンションで Claude Code を自動起動する workflow。
CI workflow と合わせて必ずコピーする。

**前提**: リポジトリの Secrets に `CLAUDE_CODE_OAUTH_TOKEN` の設定が必要。

### 7.2 Security workflow

`security.yml` はセキュリティ関連の自動チェック（依存脆弱性スキャン等）を実行する workflow。

**前提**: リポジトリの Secrets に `SLACK_CI_CHANNEL_ID`, `SLACK_BOT_TOKEN` の設定が必要。

### 7.3 Claude Code Review workflow

`claude-code-review.yml` は PR に対して Claude による自動コードレビューを実行する workflow。

## Step 8: Setup Claude Code Hooks

Claude Code の品質ゲートフックをセットアップする。

### 8.1 hooks ディレクトリ作成とファイルコピー

```bash
mkdir -p TARGET_DIR/.claude/hooks
cp CONFIG_REPO/.claude/hooks/block_git_no_verify.py TARGET_DIR/.claude/hooks/
cp CONFIG_REPO/.claude/hooks/pre_git_quality_gates.py TARGET_DIR/.claude/hooks/
cp CONFIG_REPO/.claude/hooks/post_git_push_ci.py TARGET_DIR/.claude/hooks/
```

### 8.2 `.claude/settings.json` 作成

hooks セクションのみ含める。permissions セクションはプロジェクト固有のため含めない（ユーザーが後から設定）。

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'cd \"$(git rev-parse --show-toplevel 2>/dev/null || echo .)\" && python3 .claude/hooks/block_git_no_verify.py'"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'cd \"$(git rev-parse --show-toplevel 2>/dev/null || echo .)\" && python3 .claude/hooks/pre_git_quality_gates.py'"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'cd \"$(git rev-parse --show-toplevel 2>/dev/null || echo .)\" && python3 .claude/hooks/post_git_push_ci.py'"
          }
        ]
      }
    ]
  }
}
```

## Step 9: Setup Development Tools

### 9.1 package.json 作成

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
    "typecheck": "tsc --noEmit",
    "prepare": "husky"
  },
  "devDependencies": {
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0",
    "eslint": "^9.0.0",
    "husky": "^9.0.0",
    "jest": "^29.0.0",
    "lint-staged": "^15.0.0",
    "prettier": "^3.0.0"
  }
}
```

### 9.2 設定ファイルをコピー

```bash
cp CONFIG_REPO/eslint.config.mjs TARGET_DIR/
cp CONFIG_REPO/.prettierrc TARGET_DIR/
cp CONFIG_REPO/jest.config.js TARGET_DIR/
```

### 9.3 ESLint 複雑度ルールを強化

コピーした `eslint.config.mjs` の `files: ['**/*.{js,jsx}']` ブロック内の `rules` で、`complexity` と `max-depth` を `warn` から `error` に変更する。

Edit を使用して以下のルールを変更：

- `complexity: ['warn', { max: 15 }]` → `complexity: ['error', 10]`
- `'max-depth': ['warn', 4]` → `'max-depth': ['error', 4]`

### 9.4 `.node-version` ファイル作成

```
22
```

### 9.5 `lint-staged.config.js` 作成

```js
module.exports = {
  '*.{ts,tsx,js,jsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml,css}': ['prettier --write'],
};
```

## Step 10: Create Documentation

### 10.1 README.md

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

### 10.2 CLAUDE.md

```bash
cp CONFIG_REPO/.claude/CLAUDE.md TARGET_DIR/
```

### 10.3 SECURITY.md

セキュリティポリシーを作成。

## Step 11: Install Dependencies & Setup Husky Hooks (unless --no-install)

```bash
cd TARGET_DIR
npm install
npx husky init
```

### 11.1 Husky フック作成

Husky v9+ では `.husky.sh` ヘッダは不要。フックは plain shell script として動作する。

```bash
echo 'npx commitlint --edit "$1"' > .husky/commit-msg
echo 'npx lint-staged' > .husky/pre-commit
echo 'npm run typecheck && npm run lint && npm run test' > .husky/pre-push
```

## Step 12: Add to Codespaces Secrets (Default)

Codespaces でリポジトリを使用できるように、シークレットの紐付けをデフォルトで実行する。
`--no-codespaces` オプションが指定された場合のみスキップ。

### 12.1: Check if codespaces-secrets.sh is available

```bash
test -f CONFIG_REPO/script/codespaces-secrets.sh && echo "available" || echo "not_available"
```

### 12.2: Add repository to Codespaces secrets

```bash
# リポジトリをシークレット管理対象に追加
CONFIG_REPO/script/codespaces-secrets.sh repos add {owner}/{repo-name}

# 全シークレットに紐付け
CONFIG_REPO/script/codespaces-secrets.sh sync
```

### 12.3: Verify setup

```bash
# 紐付け状態を確認
CONFIG_REPO/script/codespaces-secrets.sh list
```

シークレットスクリプトが利用できない場合は、手動設定のガイドを表示する。

## Step 13: Branch Protection & Repository Settings (unless --no-protection)

リモートリポジトリが存在する場合、ブランチ保護とリポジトリ設定を自動適用する。
リモートが設定されていない場合はスキップし、Summary の Next Steps に手動設定のガイドを表示する。

### 13.1: リモートリポジトリの存在確認

```bash
# リモートが設定されているか確認
git -C TARGET_DIR remote get-url origin 2>/dev/null
```

リモートが存在しない場合はこのステップ全体をスキップする。

### 13.2: リポジトリ設定を更新

```bash
gh api repos/{owner}/{repo} --method PATCH --input - <<'EOF'
{
  "delete_branch_on_merge": true,
  "allow_auto_merge": false,
  "allow_merge_commit": true,
  "allow_squash_merge": true,
  "allow_rebase_merge": false,
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
EOF
```

設定内容：

- マージ後ブランチ自動削除: 有効
- 自動マージ: 無効
- マージ方法: Merge commit + Squash merge（Rebase 無効）
- Secret scanning: 有効
- Push protection: 有効

### 13.3: main ブランチ保護ルールを設定

```bash
gh api repos/{owner}/{repo}/branches/main/protection --method PUT --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Quality Gate"]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "enforce_admins": false,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": false
}
EOF
```

設定内容：

- 直接プッシュ禁止（管理者はバイパス可）
- PR 必須、レビュー承認 1名以上
- 古いレビューの自動却下
- 必須ステータスチェック: Quality Gate
- ブランチ更新必須（strict）
- Force push / ブランチ削除: 禁止

### 13.4: 設定結果を確認

```bash
gh api repos/{owner}/{repo}/branches/main/protection --jq '{
  status_checks: .required_status_checks.contexts,
  reviews: .required_pull_request_reviews.required_approving_review_count,
  force_push: .allow_force_pushes.enabled
}'
```

## Step 14: Generate Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Repository Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Target: {TARGET_DIR}

Files Created:
✅ .devcontainer/ (ローカル + Codespaces)
✅ .vscode/
✅ .github/workflows/ci.yml
✅ .github/workflows/claude.yml
✅ .github/workflows/security.yml
✅ .github/workflows/claude-code-review.yml
✅ .github/ISSUE_TEMPLATE/
✅ .github/PULL_REQUEST_TEMPLATE.md
✅ .claude/hooks/ (3 ファイル)
✅ .claude/settings.json
✅ package.json
✅ eslint.config.mjs
✅ .prettierrc
✅ jest.config.js
✅ commitlint.config.js
✅ .node-version
✅ lint-staged.config.js
✅ .gitignore
✅ .husky/commit-msg
✅ .husky/pre-commit
✅ .husky/pre-push
✅ README.md
✅ CLAUDE.md
✅ SECURITY.md

Repository Settings (if remote exists):
✅ Branch protection (main)
✅ Repository settings (auto-delete branch, secret scanning)
✅ Codespaces secrets

Next Steps:
1. cd {TARGET_DIR}
2. Update README.md with project details
3. Update package.json (name, description)
4. git add . && git commit -m "feat: initial setup"
5. gh repo create (if not yet created)
6. git push -u origin main
7. Set CLAUDE_CODE_OAUTH_TOKEN in repository secrets
8. Set SLACK_CI_CHANNEL_ID in repository secrets (security.yml 用)
9. Set SLACK_BOT_TOKEN in repository secrets (security.yml 用)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Options Summary

| オプション          | 説明                                   | デフォルト |
| ------------------- | -------------------------------------- | ---------- |
| `--minimal`         | GitHub Actionsをスキップ               | false      |
| `--no-devcontainer` | DevContainer設定をスキップ             | false      |
| `--no-codespaces`   | Codespacesシークレット紐付けをスキップ | false      |
| `--no-protection`   | ブランチ保護・リポジトリ設定をスキップ | false      |
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
