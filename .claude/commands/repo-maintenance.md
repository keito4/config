---
description: Comprehensive repository maintenance - run all health checks and updates
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(node:*), Bash(jq:*), Bash(find:*), Bash(test:*), Bash(ls:*), Bash(grep:*), Bash(cat:*), Bash(echo:*), Bash(date:*), Bash(curl:*), Task, Skill
argument-hint: '[--mode full|quick|check-only] [--skip CATEGORY] [--create-pr]'
---

# Repository Maintenance Workflow

このコマンドはリポジトリの包括的なメンテナンスを実行し、初期化や機能追加された内容を取り込みます。

## Overview

以下のカテゴリのチェック・更新を順次実行します：

1. **Environment** - 開発環境の健全性と更新
2. **Setup** - CI/CD およびリポジトリ保護の設定
3. **Cleanup** - リポジトリのクリーンアップ
4. **Discovery** - 新機能の発見と取り込み

## Execution Modes

| Mode       | 説明                               | 実行内容                         |
| ---------- | ---------------------------------- | -------------------------------- |
| full       | 全カテゴリの更新とチェックを実行   | 更新 + チェック + クリーンアップ |
| quick      | 重要なチェックのみ実行（更新なし） | チェックのみ                     |
| check-only | 状態確認のみ（変更なし）           | 読み取り専用のチェック           |

## Step 1: Parse Arguments and Initialize

引数から設定を読み取る：

- `--mode MODE`: 実行モード（デフォルト: `full`）
- `--skip CATEGORY`: スキップするカテゴリ（カンマ区切りで複数指定可）
- `--create-pr`: 更新があった場合にPRを作成

デフォルト設定:

```
MODE=full
SKIP_CATEGORIES=[]
CREATE_PR=false
```

初期化メッセージを表示:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Repository Maintenance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mode: {MODE}
Skip: {SKIP_CATEGORIES or "None"}
Create PR: {CREATE_PR}

Starting comprehensive maintenance...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Environment Category

### 2.1 Container Health Check

コンテナ環境の健全性を確認：

実行内容:

- 必須ツールの存在確認（git, node, npm, docker）
- Claude Code ツールの確認（claude）
- 開発ツールの確認（eslint, prettier）
- バージョン検証

これは `/container-health` コマンドと同等の処理を実行します。

結果を記録:

- ✅ すべて正常
- ⚠️ 一部に問題あり（詳細をリスト）
- ❌ 重大な問題あり（詳細をリスト）

### 2.2 DevContainer Version Check

config-base イメージのバージョンを確認：

1. `.devcontainer/devcontainer.json` から現在のバージョンを取得
2. GitHub API から最新バージョンを取得
3. バージョンを比較

```bash
gh api repos/keito4/config/releases/latest --jq '.tag_name'
```

結果:

- ✅ 最新バージョン使用中
- ⚠️ 更新可能: v{current} → v{latest}

### 2.3 DevContainer Update (full mode only)

MODE が `full` かつ更新がある場合:

`/config-base-sync-update` コマンドを実行するか確認してから実行。

**Note**: このステップは対話的確認を行う。自動実行の場合は `--yes` フラグで確認をスキップ。

### 2.4 Claude Code Update Check

npm/global.json の Claude Code バージョンを確認：

```bash
npm view @anthropic-ai/claude-code version
```

結果:

- ✅ 最新バージョン
- ⚠️ 更新可能

MODE が `full` の場合は `/update-claude-code` コマンドを実行。

### 2.5 GitHub Actions Version Check

GitHub Actions のバージョンを確認・更新：

```bash
npm run update:actions
```

または一括更新（npm + Claude Code + Actions）:

```bash
npm run update:all
npm run update:all -- --skip-libs --skip-claude  # Actions のみ
```

結果:

- ✅ 全アクション最新
- ⚠️ 更新可能なアクションあり

MODE が `full` の場合は `/update-actions` コマンドを実行。

### 2.6 Claude Settings Sync Check (full mode only)

このリポジトリが config リポジトリの場合のみ実行:

`/sync-claude-settings` の実行を確認。

### 2.7 Claude Code LSP Setup Check

Claude Code の LSP（Language Server Protocol）サポートの設定状況を確認：

**LSP とは:**
コード補完、定義ジャンプ、参照検索などのコード解析機能を提供するプロトコル。
Claude Code v2.0.74+ でサポートされています。

**確認項目:**

1. `.claude-plugin/plugin.json` の存在確認
2. LSP サーバ設定の確認
3. 必要な言語サーバのインストール状況確認

**対応言語:**

- TypeScript/JavaScript
- Python
- Go
- Rust
- PHP

**設定例（TypeScript）:**

```json
{
  "name": "project-lsp",
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "extensionToLanguage": {
        ".ts": "typescript",
        ".tsx": "typescriptreact",
        ".js": "javascript",
        ".jsx": "javascriptreact"
      }
    }
  }
}
```

**必要な言語サーバ（グローバルインストール）:**

```bash
# TypeScript/JavaScript
npm install -g typescript-language-server typescript

# Python
pip install python-lsp-server

# Go
go install golang.org/x/tools/gopls@latest

# Rust
rustup component add rust-analyzer
```

**環境変数:**

Claude Code 起動時に `ENABLE_LSP_TOOL=1` を設定：

```bash
ENABLE_LSP_TOOL=1 npx @anthropic-ai/claude-code@stable
```

**結果:**

- ✅ LSP 設定済み（対応言語をリスト表示）
- ⚠️ LSP 未設定 → セットアップを提案
- 📝 未インストールの言語サーバをリスト表示

**MODE が `full` の場合:**

プロジェクトで使用されている言語を検出し、適切な LSP 設定を提案・適用：

1. `package.json` → TypeScript/JavaScript
2. `requirements.txt` / `pyproject.toml` → Python
3. `go.mod` → Go
4. `Cargo.toml` → Rust
5. `composer.json` → PHP

**参考:**

- [Claude Code LSP 設定ガイド](https://blog.lai.so/claude-code-lsp/)
- [公式プラグイン](https://github.com/anthropics/claude-plugins-official)

### 2.8 Codespaces Secrets Sync Check

GitHub Codespaces を使用する場合のシークレット紐付け状況を確認：

**確認項目:**

1. `script/codespaces-secrets.sh` の存在確認
2. 現在のリポジトリがシークレットに紐付けられているか確認
3. 設定ファイルとの差分確認

**実行コマンド:**

```bash
# スクリプトの存在確認
test -f ./script/codespaces-secrets.sh && echo "available" || echo "not_available"

# 差分確認（スクリプトが存在する場合）
./script/codespaces-secrets.sh diff
```

**結果:**

- ✅ Codespaces シークレット同期済み
- ⚠️ 未紐付けのシークレットあり → 同期を提案
- ⏭️ スキップ（Codespaces未使用）

**MODE が `full` かつ差分がある場合:**

```bash
./script/codespaces-secrets.sh sync
```

これは `/codespaces-secrets sync` コマンドと同等の処理を実行します。

**Note**: Codespacesを使用していない場合は自動的にスキップされます。

## Step 3: Setup Category

### 3.1 Team Protection Setup (full mode only)

GitHub リポジトリの保護ルールを確認・設定：

実行内容:

- ブランチ保護ルールの確認
- 必須ステータスチェックの設定
- レビュー要件の設定
- Dependabot、脆弱性アラートの有効化

これは `/setup-team-protection` コマンドと同等の処理を実行します。

結果:

- ✅ 保護ルール設定済み
- ⚠️ 未設定の保護ルールあり（詳細をリスト）
- 🔧 設定を適用

### 3.2 Husky Setup Check

Git hooks（pre-commit）の設定状況を確認：

実行内容:

- Husky のインストール状況確認
- pre-commit フックの存在確認
- commitlint の設定確認
- lint-staged の設定確認

これは `/setup-husky` コマンドと同等の処理を実行します。

結果:

- ✅ Husky 設定済み
- ⚠️ Husky 未設定 → セットアップを提案
- 📝 設定内容: pre-commit, commit-msg

### 3.3 Pre-PR Checklist Validation

PR 作成前のチェック項目を検証：

実行内容:

- lint、format、test の実行可否確認
- CI ワークフローの存在確認
- PR テンプレートの存在確認

これは `/pre-pr-checklist` コマンドの設定確認と同等の処理を実行します。

結果:

- ✅ すべてのチェック項目が設定済み
- ⚠️ 不足している項目あり（詳細をリスト）

### 3.4 CLAUDE.md Symlink Check

CLAUDE.md が AGENTS.md へのシンボリックリンクであることを確認：

**背景:**
多くの AI コーディングエージェント（Codex、Gemini CLI など）は `AGENTS.md` を参照し、
Claude Code は `CLAUDE.md` を参照します。`AGENTS.md` を主ファイルとし、
`CLAUDE.md` をシンボリックリンクとして管理することで、両方のエージェントが同じ設定を参照できます。

**確認項目:**

1. `AGENTS.md` の存在確認（主ファイル）
2. `CLAUDE.md` がシンボリックリンクかどうか確認
3. リンク先が `AGENTS.md` であることを確認

**実行コマンド:**

```bash
# シンボリックリンク確認
if [ -L "CLAUDE.md" ]; then
  target=$(readlink CLAUDE.md)
  if [ "$target" = "AGENTS.md" ]; then
    echo "✅ CLAUDE.md -> AGENTS.md"
  else
    echo "⚠️ CLAUDE.md -> $target (expected: AGENTS.md)"
  fi
elif [ -f "CLAUDE.md" ]; then
  echo "⚠️ CLAUDE.md is a regular file (should be symlink to AGENTS.md)"
else
  echo "❌ CLAUDE.md not found"
fi
```

**結果:**

- ✅ CLAUDE.md は AGENTS.md へのシンボリックリンク
- ⚠️ CLAUDE.md は通常ファイル → シンボリックリンク化を提案
- ⚠️ CLAUDE.md のリンク先が異なる → 修正を提案
- ❌ CLAUDE.md が存在しない → 作成を提案

**MODE が `full` かつシンボリックリンクでない場合:**

```bash
# AGENTS.md が存在しない場合は CLAUDE.md を AGENTS.md にリネーム
if [ -f "CLAUDE.md" ] && [ ! -L "CLAUDE.md" ] && [ ! -f "AGENTS.md" ]; then
  mv CLAUDE.md AGENTS.md
  ln -s AGENTS.md CLAUDE.md
  echo "✅ CLAUDE.md を AGENTS.md へのシンボリックリンクに変換しました"
fi

# 両方が通常ファイルの場合はマージを提案
if [ -f "CLAUDE.md" ] && [ ! -L "CLAUDE.md" ] && [ -f "AGENTS.md" ]; then
  echo "⚠️ AGENTS.md と CLAUDE.md が両方存在します"
  echo "   手動でマージしてからシンボリックリンクを作成してください"
fi
```

### 3.5 CI/CD Setup Check (full mode only)

CI/CD ワークフローの設定状況を確認：

実行内容:

- GitHub Actions ワークフローの存在確認
- 必須ジョブ（lint, test, build）の確認
- セキュリティスキャンの設定確認
- Claude Code Review の統合確認

これは `/setup-ci --dry-run` コマンドと同等の処理を実行します。

結果:

- ✅ CI/CD 設定済み
- ⚠️ CI/CD 未設定または不完全 → セットアップを提案
- 📝 推奨レベル: standard または comprehensive

MODE が `full` かつ CI/CD が未設定の場合:

`/setup-ci` コマンドの実行を提案。

## Step 4: Cleanup Category

### 4.1 Branch Cleanup

ブランチの状態を確認：

実行内容:

- マージ済みブランチの検出
- 古いブランチ（30日以上）の検出
- 削除されたリモートブランチの検出

これは `/branch-cleanup --dry-run` コマンドと同等の処理を実行します。

結果:

- 🗑️ 削除候補: X ブランチ
  - マージ済み: Y
  - 古いブランチ: Z

MODE が `full` の場合:

- 対話的に削除を確認
- または `--yes` フラグで自動削除

### 4.2 Git Repository Cleanup

Git リポジトリのクリーンアップ：

```bash
git gc --auto
git prune
```

## Step 5: Discovery Category (full mode only)

### 5.1 Config Contribution Discovery

config リポジトリから取り込み可能な新機能を発見：

実行内容:

- 新しいコマンドの検出
- 新しいワークフローの検出
- 推奨設定の更新確認

これは `/config-contribution-discover` コマンドと同等の処理を実行します。

結果:

- 🆕 新機能: X 件
- 📝 更新推奨: Y 件

### 5.2 推奨パッケージ監査

プロジェクト種別を自動検出し、推奨スタックとの差分を確認する。

#### プロジェクト種別の検出

以下の順序でプロジェクト種別を判定：

```bash
# Next.js プロジェクト
if grep -q '"next"' package.json 2>/dev/null; then
  PROJECT_TYPE="nextjs"
# React + Vite SPA
elif grep -q '"vite"' package.json 2>/dev/null && grep -q '"react"' package.json 2>/dev/null; then
  PROJECT_TYPE="spa-react"
else
  PROJECT_TYPE="unknown"
fi
```

#### Next.js 推奨パッケージ

| カテゴリ               | パッケージ               | 確認方法                                                      |
| ---------------------- | ------------------------ | ------------------------------------------------------------- |
| ロギング               | `@vercel/logger`         | `jq '.dependencies["@vercel/logger"]' package.json`           |
| エラー監視             | `@sentry/nextjs`         | `jq '.dependencies["@sentry/nextjs"]' package.json`           |
| バリデーション         | `zod`                    | `jq '.dependencies.zod' package.json`                         |
| 型安全な環境変数       | `@t3-oss/env-nextjs`     | `jq '.dependencies["@t3-oss/env-nextjs"]' package.json`       |
| フォーム管理           | `react-hook-form`        | `jq '.dependencies["react-hook-form"]' package.json`          |
| フォームバリデーション | `@hookform/resolvers`    | `jq '.dependencies["@hookform/resolvers"]' package.json`      |
| アクセシビリティE2E    | `@axe-core/playwright`   | `jq '.devDependencies["@axe-core/playwright"]' package.json`  |
| アクセシビリティUnit   | `jest-axe`               | `jq '.devDependencies["jest-axe"]' package.json`              |
| バンドル分析           | `@next/bundle-analyzer`  | `jq '.devDependencies["@next/bundle-analyzer"]' package.json` |
| アナリティクス         | `@vercel/analytics`      | `jq '.dependencies["@vercel/analytics"]' package.json`        |
| パフォーマンス計測     | `@vercel/speed-insights` | `jq '.dependencies["@vercel/speed-insights"]' package.json`   |
| Lint/Format            | `@biomejs/biome`         | `jq '.devDependencies["@biomejs/biome"]' package.json`        |
| 未使用コード検出       | `knip`                   | `jq '.devDependencies.knip' package.json`                     |

#### SPA (React + Vite) 推奨パッケージ

| カテゴリ       | パッケージ               | 確認方法                                                       |
| -------------- | ------------------------ | -------------------------------------------------------------- |
| Lint/Format    | `@biomejs/biome`         | `jq '.devDependencies["@biomejs/biome"]' package.json`         |
| テスト         | `vitest`                 | `jq '.devDependencies.vitest' package.json`                    |
| カバレッジ     | `@vitest/coverage-v8`    | `jq '.devDependencies["@vitest/coverage-v8"]' package.json`    |
| コンポーネント | `@testing-library/react` | `jq '.devDependencies["@testing-library/react"]' package.json` |

#### 実行ロジック

```bash
MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
  installed=$(jq -r --arg p "$pkg" '.dependencies[$p] // .devDependencies[$p] // "null"' package.json)
  if [ "$installed" = "null" ]; then
    MISSING_PACKAGES+=("$pkg")
  fi
done
```

#### 結果

- ✅ 推奨パッケージ: すべてインストール済み
- ⚠️ 未導入パッケージ: X 件（インストールコマンドをリスト表示）
- ⏭️ スキップ（`package.json` なし / プロジェクト種別不明）

**未導入パッケージがある場合の出力例:**

```
⚠️ 推奨パッケージが未導入です (Next.js)

未導入:
  - @vercel/logger      (ロギング)
  - @sentry/nextjs      (エラー監視)
  - knip                (未使用コード検出)

インストールコマンド:
  npm install @vercel/logger @sentry/nextjs
  npm install -D knip

詳細: docs/setup/web-app-nextjs.md
```

**MODE が `full` の場合:**

インストールを確認してから実行：

```bash
# 確認後に実行
npm install @vercel/logger @sentry/nextjs
npm install -D @biomejs/biome knip
```

## Step 6: Generate Summary Report

全ステップの結果をまとめたレポートを生成：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Maintenance Summary Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Environment (1/4)
├── Container Health: ✅ Healthy (Score: 95/100)
├── DevContainer: ⚠️ Update available (v1.13.1 → v1.15.0)
├── Claude Code: ✅ Up to date
├── GitHub Actions: ✅ All actions up to date
├── Claude Settings: ✅ Synced
├── Claude Code LSP: ⚠️ Not configured (TypeScript detected)
└── Codespaces Secrets: ✅ Synced (or ⏭️ Skipped)

## Setup (2/4)
├── Team Protection: ✅ Branch protection enabled
├── Husky: ✅ Git hooks configured
├── Pre-PR Checklist: ✅ CI workflow exists
├── CLAUDE.md: ✅ Symlink to AGENTS.md
└── CI/CD: ✅ Standard level configured

## Cleanup (3/4)
├── Branches: 🗑️ 8 merged branches can be deleted
└── Git GC: ✅ Repository optimized

## Discovery (4/4)
├── New Features: 🆕 2 new commands available
└── Package Audit: ⚠️ 3 recommended packages missing (Next.js)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Overall Health Score: 82/100

## Action Items (Priority Order)

### 🔴 Immediate (Setup)
1. Configure branch protection rules
   Run: /setup-team-protection
2. Setup Git hooks (Husky)
   Run: /setup-husky
3. Setup CI/CD workflows
   Run: /setup-ci

### 🟡 Soon (Updates)
4. Update DevContainer to v1.15.0
   Run: /config-base-sync-update

### 🟢 Recommended (Maintenance)
5. Delete 8 merged branches
   Run: /branch-cleanup
6. Review 2 new config features
   Run: /config-contribution-discover
7. Install 3 missing recommended packages (Next.js)
   Run: npm install @vercel/logger @sentry/nextjs && npm install -D knip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 7: Create PR (Optional)

`--create-pr` が指定されており、かつ変更がある場合：

### 7.1 Check for Changes

```bash
git status --porcelain
```

変更がない場合:

- "No changes to commit. Skipping PR creation."
- 終了

### 7.2 Create Branch

```bash
git checkout -b maintenance/$(date +%Y%m%d)
```

### 7.3 Commit Changes

```bash
git add -A
git commit -m "chore: repository maintenance $(date +%Y-%m-%d)

## Changes
- [List of changes from each category]

## Health Score
- Before: X/100
- After: Y/100

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 7.4 Push and Create PR

```bash
git push -u origin maintenance/$(date +%Y%m%d)

gh pr create \
  --base main \
  --title "chore: Repository maintenance $(date +%Y-%m-%d)" \
  --body "$(cat <<'EOF'
## Summary

Automated repository maintenance performed on $(date +%Y-%m-%d).

## Changes

### Environment
- [List changes]

### Setup
- [List changes]

### Cleanup
- [List changes]

### Discovery
- [List changes]

## Health Score
- Before: X/100
- After: Y/100

## Checklist
- [ ] CI passes
- [ ] No breaking changes
- [ ] Review action items

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Step 8: Final Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Repository Maintenance Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mode: {MODE}
Duration: {elapsed_time}
Health Score: {score}/100

Categories Processed:
✅ Environment: {status}
✅ Setup: {status}
✅ Cleanup: {status}
✅ Discovery: {status}

{if PR created}
PR Created: {PR_URL}
{endif}

Next Steps:
1. Review the summary report above
2. Address action items by priority
3. {if PR created} Review and merge the PR {endif}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run this command regularly to maintain repository health:
  /repo-maintenance --mode quick    # Quick daily check
  /repo-maintenance --mode full     # Weekly full maintenance
```

---

## Progress Reporting

各ステップの進捗を報告：

- ✅ Step N: [完了した操作]
- 🔄 Step N: [実行中の操作]
- ⏭️ Step N: [スキップ（理由）]
- ❌ Step N: [失敗 - 理由]

## Error Handling

エラー発生時：

1. 具体的なエラー内容を報告
2. 可能な限り次のステップに進む（致命的エラー以外）
3. 最終レポートにエラーを含める
4. 修正方法を提案

## Related Commands

このコマンドは以下のコマンドを内部的に呼び出します：

| カテゴリ    | コマンド                        | 説明                          |
| ----------- | ------------------------------- | ----------------------------- |
| Environment | `/container-health`             | コンテナ健全性                |
| Environment | `/config-base-sync-check`       | DevContainer バージョン       |
| Environment | `/config-base-sync-update`      | DevContainer 更新             |
| Environment | `/update-claude-code`           | Claude Code 更新              |
| Environment | `/update-actions`               | GitHub Actions バージョン更新 |
| Environment | `/sync-claude-settings`         | Claude 設定同期               |
| Environment | (Claude Code LSP setup)         | LSP 設定                      |
| Environment | `/codespaces-secrets`           | Codespaces シークレット同期   |
| Setup       | `/setup-team-protection`        | GitHub保護ルール設定          |
| Setup       | `/setup-husky`                  | Git hooks設定                 |
| Setup       | `/pre-pr-checklist`             | PR前チェックリスト            |
| Setup       | (CLAUDE.md symlink check)       | CLAUDE.md シンボリックリンク  |
| Setup       | `/setup-ci`                     | CI/CDワークフロー設定         |
| Cleanup     | `/branch-cleanup`               | ブランチクリーンアップ        |
| Discovery   | `/config-contribution-discover` | 新機能発見                    |
| Discovery   | (Package Audit)                 | 推奨パッケージ監査            |
