# 推奨CI/CDセットアップガイド

このコマンドは、Elu-co-jp 組織で使用されている推奨CI/CD構成をリポジトリに適用するための包括的なガイドです。

## 概要

このガイドでは、以下の要素を含む完全なCI/CDパイプラインの構築を支援します:

1. **基本品質チェック**: Lint、フォーマット、型チェック、複雑度分析
2. **テスト & カバレッジ**: ユニットテスト、E2Eテスト (70%+ カバレッジ要件)
3. **セキュリティスキャン**: 依存関係の脆弱性、SAST、ライセンス準拠
4. **Claude統合**: AIアシストコードレビュー
5. **リリース自動化**: セマンティックバージョニング、リリースノート生成

---

## 前提条件

このガイドを実行する前に、以下を確認してください:

- Node.js 20.x がインストールされている
- リポジトリが GitHub 上にホストされている
- package.json が存在する
- 必要な npm scripts が定義されている (または作成する準備がある)

---

## ステップ1: リポジトリ構造の確認

まず、現在のリポジトリ構造を確認します:

```bash
# プロジェクトルートでの確認
ls -la
cat package.json | jq '.scripts'
```

### 必要なディレクトリ構造

```
project-root/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── claude-code-review.yml
│       ├── security.yml
│       └── release.yml (オプション)
├── next/ (Next.jsプロジェクトの場合)
│   ├── package.json
│   └── ...
├── package.json
└── ...
```

---

## ステップ2: 必要な npm scripts の確認と作成

以下の npm scripts が必要です。存在しない場合は追加してください:

### ルート package.json

```json
{
  "scripts": {
    "prepare": "husky",
    "build": "cd next && npm run build",
    "lint": "cd next && npm run lint",
    "type-check": "cd next && npm run type-check",
    "test": "cd next && npm run test",
    "ci:test": "cd next && npm run ci:test",
    "format:check": "cd next && npm run format:check"
  }
}
```

### Next.js package.json (next/package.json)

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint .",
    "lint:strict": "eslint . --max-warnings 0",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "type-check": "tsc --noEmit",
    "test": "vitest",
    "test:e2e": "playwright test",
    "ci:test": "vitest run --coverage",
    "complexity:check": "npx complexity-report --format json --output complexity.json src/"
  }
}
```

### 確認コマンド

```bash
# ルートディレクトリで確認
npm run build --dry-run
npm run lint --dry-run
npm run type-check --dry-run
npm run test --dry-run
```

---

## ステップ3: 基本CI ワークフロー (.github/workflows/ci.yml)

### 最小構成版 (シンプルなプロジェクト向け)

```yaml
name: CI Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  NODE_VERSION: '20'
  COVERAGE_THRESHOLD: 70

jobs:
  quality:
    name: Quality Checks
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Check Prettier formatting
        run: npm run format:check

      - name: TypeScript type check
        run: npm run type-check

  test:
    name: Unit Tests & Coverage
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: quality

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests with coverage
        run: npm run ci:test

      - name: Check coverage threshold
        run: |
          if [ -f "./coverage/coverage-summary.json" ]; then
            COVERAGE=$(node -e "
              const fs = require('fs');
              const coverage = JSON.parse(fs.readFileSync('./coverage/coverage-summary.json', 'utf8'));
              const total = coverage.total;
              console.log(Math.floor(total.lines.pct));
            ")
            echo "Current coverage: ${COVERAGE}%"
            if [ "$COVERAGE" -lt "${{ env.COVERAGE_THRESHOLD }}" ]; then
              echo "::warning::Test coverage (${COVERAGE}%) is below target (${{ env.COVERAGE_THRESHOLD }}%)"
            fi
          fi

  build:
    name: Build Test
    runs-on: ubuntu-latest
    timeout-minutes: 10
    needs: [quality, test]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build
```

### CI最適化: Path Filters による実行最適化

**目的**: 変更されたファイルに応じて必要なジョブのみを実行することで、CIの実行時間を短縮し、コストを削減します。

#### 実装方法

GitHub Actionsの`on.push.paths`と`on.pull_request.paths`フィルター、および`dorny/paths-filter`アクションを組み合わせて使用します。

##### 1. ワークフローレベルでのフィルタリング

ワークフロー全体をスキップするには、`on`セクションで`paths`を指定します:

```yaml
on:
  pull_request:
    paths:
      - '**.js'
      - '**.ts'
      - '**.mjs'
      - '**.cjs'
      - '**.json'
      - '**.sh'
      - '**.bats'
      - '.github/workflows/**'
      - 'package.json'
      - 'package-lock.json'
      - '.eslintrc.*'
      - '.prettierrc.*'
      - 'tsconfig.json'
  push:
    branches: [main, master]
    paths:
      - '**.js'
      - '**.ts'
      # ... 同様のパターン
```

##### 2. ジョブレベルでの細かい制御

各ジョブを変更内容に応じて実行するには、`dorny/paths-filter`を使用します:

```yaml
jobs:
  changes:
    name: Detect Changes
    runs-on: ubuntu-latest
    outputs:
      code: ${{ steps.filter.outputs.code }}
      scripts: ${{ steps.filter.outputs.scripts }}
      workflows: ${{ steps.filter.outputs.workflows }}
      dependencies: ${{ steps.filter.outputs.dependencies }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            code:
              - '**.js'
              - '**.ts'
              - 'src/**'
              - 'test/**/*.test.{js,ts}'
            scripts:
              - '**.sh'
              - 'script/**'
            workflows:
              - '.github/workflows/**'
            dependencies:
              - 'package.json'
              - 'package-lock.json'

  lint:
    needs: changes
    if: needs.changes.outputs.code == 'true' || needs.changes.outputs.dependencies == 'true'
    # ... lintジョブの内容

  test:
    needs: changes
    if: needs.changes.outputs.code == 'true' || needs.changes.outputs.dependencies == 'true'
    # ... testジョブの内容

  actionlint:
    needs: changes
    if: needs.changes.outputs.workflows == 'true'
    # ... actionlintジョブの内容
```

##### 3. Quality Gate での skipped 状態の処理

ジョブがスキップされた場合も成功として扱うように、Quality Gateを更新します:

```yaml
quality-gate:
  needs: [changes, lint, test, integration-test, actionlint]
  if: always()
  steps:
    - name: Verify all checks passed
      run: |
        function check_result() {
          local result=$1
          [[ "$result" == "success" || "$result" == "skipped" ]]
        }

        if ! check_result "${{ needs.lint.result }}"; then
          echo "::error::Lint & Format failed"
          exit 1
        fi
        # ... 他のジョブも同様にチェック
```

#### Path Filters のベストプラクティス

| 対象ワークフロー       | 推奨フィルター                                        | 理由                                     |
| ---------------------- | ----------------------------------------------------- | ---------------------------------------- |
| **CI Pipeline**        | コード、設定ファイル、ワークフロー自体                | ドキュメントのみの変更でテストをスキップ |
| **Docker Image Build** | `.devcontainer/**`, `npm/global.json`, `package.json` | DevContainer関連の変更時のみビルド       |
| **Security Scans**     | コード、依存関係ファイル                              | セキュリティに影響する変更のみスキャン   |
| **Documentation**      | `**.md`, `docs/**`                                    | ドキュメント変更時のみデプロイ           |

#### 効果測定

Path Filtersを導入すると、以下のような効果が期待できます:

- ドキュメントのみの変更: CI実行時間 **90%削減** (10分 → 1分)
- DevContainer変更なし: Docker Image Build **スキップ** (45分 → 0分)
- ワークフローのみの変更: Lint/Test **スキップ**、Actionlintのみ実行

**注意**: mainブランチへのpushでは、すべてのチェックを実行することを推奨します（path filtersを適用しない、または緩めに設定）。

### フル構成版 (Next.js + Supabase プロジェクト向け)

Elu-co-jp リポジトリから参照:

- `/Users/keito4/develop/github.com/Elu-co-jp/cyber_ace_1on1/.github/workflows/ci.yml`

この構成には以下が含まれます:

- GitHub Packages 認証
- Supabase CLI 統合
- DB型生成
- E2E テスト (Critical Path / Full Suite)
- Scenario Flow テスト
- Edge Functions テスト
- PR コメントによるカバレッジレポート

---

## ステップ4: セキュリティスキャン (.github/workflows/security.yml)

### 推奨構成

```yaml
name: Security Scan

on:
  schedule:
    - cron: '0 2 * * *' # 毎日午前2時 (JST 午前11時)
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  NODE_VERSION: '20'

jobs:
  dependency-scan:
    name: Dependency Vulnerability Scan
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: |
          npm audit --audit-level=moderate --json > audit-results.json || true

          CRITICAL=$(cat audit-results.json | jq '.metadata.vulnerabilities.critical // 0')
          HIGH=$(cat audit-results.json | jq '.metadata.vulnerabilities.high // 0')

          echo "Critical: $CRITICAL" >> $GITHUB_STEP_SUMMARY
          echo "High: $HIGH" >> $GITHUB_STEP_SUMMARY

          if [ "$CRITICAL" -gt 0 ]; then
            echo "❌ Critical vulnerabilities found"
            npm audit --audit-level=critical
            exit 1
          fi

  sast-scan:
    name: SAST Scan
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      actions: read
      contents: read
      security-events: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
          queries: security-extended,security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3

  license-check:
    name: License Compliance Check
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install license-checker
        run: npm install -g license-checker

      - name: Check licenses
        run: |
          license-checker --json --out licenses.json

          FORBIDDEN_FOUND=$(cat licenses.json | jq -r 'to_entries[] | select(.value.licenses | type == "string" and (test("GPL|AGPL"))) | .key' || echo "")

          if [ -n "$FORBIDDEN_FOUND" ]; then
            echo "❌ Forbidden licenses found"
            echo "$FORBIDDEN_FOUND"
            exit 1
          fi
```

完全版は以下を参照:

- `/Users/keito4/develop/github.com/Elu-co-jp/cyber_ace_1on1/.github/workflows/security.yml`

---

## ステップ5: Claude統合 (.github/workflows/claude-code-review.yml)

### 推奨構成

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  claude-review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
      issues: read
      id-token: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Run Claude Code Review
        uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          prompt: |
            REPO: ${{ github.repository }}
            PR NUMBER: ${{ github.event.pull_request.number }}

            Please review this pull request and provide feedback on:
            - Code quality and best practices
            - Potential bugs or issues
            - Performance considerations
            - Security concerns
            - Test coverage

            Use the repository's CLAUDE.md for guidance on style and conventions.
            Use `gh pr comment` to leave your review as a comment on the PR.

          claude_args: '--allowed-tools "Bash(gh issue view:*),Bash(gh pr comment:*),Bash(gh pr diff:*),Bash(gh pr view:*)"'
```

---

## ステップ6: GitHub Secrets の設定

以下のシークレットを GitHub リポジトリに設定してください:

### 必須シークレット

| シークレット名            | 用途                  | 取得方法                  |
| ------------------------- | --------------------- | ------------------------- |
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code Review 用 | Claude Code で OAuth 認証 |

### オプショナルシークレット (プロジェクトに応じて)

| シークレット名          | 用途                       | 取得方法                   |
| ----------------------- | -------------------------- | -------------------------- |
| `CODECOV_TOKEN`         | Codecov カバレッジレポート | Codecov アカウントから取得 |
| `SUPABASE_ACCESS_TOKEN` | Supabase CLI 認証          | Supabase ダッシュボード    |
| `SUPABASE_PROJECT_REF`  | Supabase プロジェクト参照  | Supabase プロジェクト設定  |
| `SLACK_WEBHOOK_URL`     | Slack 通知                 | Slack アプリ設定           |

### シークレット設定手順

```bash
# GitHub CLI を使用する場合
gh secret set CLAUDE_CODE_OAUTH_TOKEN

# または GitHub Web UI から:
# Settings → Secrets and variables → Actions → New repository secret
```

---

## ステップ7: Husky Git フックの設定 (オプション)

CI の前段階でローカルチェックを行うため、Husky を設定します:

```bash
# Husky と関連パッケージのインストール
npm install -D husky lint-staged @commitlint/cli @commitlint/config-conventional

# package.json に prepare script を追加
npm pkg set scripts.prepare="husky"

# Husky 初期化
npm run prepare

# Pre-commit フックの追加
npx husky add .husky/pre-commit "npx lint-staged"

# Commit-msg フックの追加
npx husky add .husky/commit-msg "npx commitlint --edit \$1"

# Pre-push フックの追加
npx husky add .husky/pre-push "npm run type-check && npm run test"
```

### .lintstagedrc.json の作成

```json
{
  "**/*.{ts,tsx,js,jsx}": ["eslint --cache --fix", "prettier --write"],
  "**/*.{json,md,css,scss}": ["prettier --write"]
}
```

### .commitlintrc.json の作成

```json
{
  "extends": ["@commitlint/config-conventional"]
}
```

詳細は setup-husky コマンドを参照してください。

---

## ステップ8: 動作確認

すべてのワークフローが正しく設定されたことを確認します:

### ローカルでの確認

```bash
# 依存関係のインストール
npm ci

# 品質チェック
npm run lint
npm run format:check
npm run type-check

# テスト
npm run test

# ビルド
npm run build
```

### CI での確認

1. 新しいブランチを作成

```bash
git checkout -b test/ci-setup
```

2. ダミーの変更をコミット

```bash
echo "# CI Test" >> README.md
git add README.md
git commit -m "test: CI setup verification"
```

3. プルリクエストを作成

```bash
git push -u origin test/ci-setup
gh pr create --fill
```

4. GitHub Actions タブでワークフローの実行を確認

### 確認項目チェックリスト

- [ ] CI ワークフローが正常に実行される
- [ ] Quality checks (lint, format, type-check) が成功する
- [ ] テストが実行され、カバレッジが 70% 以上である
- [ ] ビルドが成功する
- [ ] Claude Code Review がPRにコメントを投稿する
- [ ] セキュリティスキャンが実行される (スケジュール実行も確認)

---

## トラブルシューティング

### npm ci が失敗する

**原因**: package-lock.json が最新でない、または依存関係の問題

**解決策**:

```bash
rm -rf node_modules package-lock.json
npm install
git add package-lock.json
git commit -m "chore: update package-lock.json"
```

### GitHub Packages 認証エラー

**原因**: GitHub Packages への認証が失敗している

**解決策**:
ワークフローに以下を追加:

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: ${{ env.NODE_VERSION }}
    cache: 'npm'
    registry-url: 'https://npm.pkg.github.com'
  env:
    NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

- name: Install dependencies
  run: npm ci
  env:
    NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### カバレッジ閾値エラー

**原因**: テストカバレッジが 70% 未満

**解決策**:

1. テストを追加してカバレッジを向上させる
2. 一時的に閾値を下げる (非推奨):

```yaml
env:
  COVERAGE_THRESHOLD: 60
```

### Claude Code Review が動作しない

**原因**: `CLAUDE_CODE_OAUTH_TOKEN` シークレットが設定されていない

**解決策**:

1. Claude Code で OAuth トークンを取得
2. GitHub リポジトリの Settings → Secrets → Actions で設定
3. ワークフローを再実行

### Supabase 型生成エラー

**原因**: Supabase プロジェクトへの接続エラー

**解決策**:

```yaml
- name: Generate DB types
  run: npm run types:gen || npm run types:sync || true
  continue-on-error: true
```

---

## 参考リソース

### Elu-co-jp リポジトリの実例

1. **cyber_ace_1on1** (フル構成):
   - `.github/workflows/ci.yml` - 包括的なCI/CDパイプライン
   - `.github/workflows/security.yml` - セキュリティスキャン
   - `.github/workflows/claude-code-review.yml` - Claude統合

2. **management_tools** (シンプル構成):
   - `.github/workflows/ci.yml` - 基本的なCI構成

3. **job_description** (最小構成):
   - `.github/workflows/ci.yml` - 最小限の品質チェック

### 関連コマンド

- `setup-husky` - Git フック設定
- `git-sync` - Git 同期コマンド
- `next-security-check` - Next.js セキュリティチェック

### 外部リンク

- [GitHub Actions ドキュメント](https://docs.github.com/actions)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Release](https://semantic-release.gitbook.io/)
- [CodeQL ドキュメント](https://codeql.github.com/docs/)

---

## まとめ

このガイドに従うことで、Elu-co-jp 組織の推奨CI/CD構成を適用できます:

✅ **品質保証**: 自動化されたコード品質チェック
✅ **テストカバレッジ**: 70%+ の高いカバレッジ要件
✅ **セキュリティ**: 包括的な脆弱性スキャン
✅ **AI支援**: Claude によるコードレビュー自動化
✅ **継続的改善**: 定期的なセキュリティスキャンと依存関係更新

質問や問題がある場合は、Elu-co-jp の既存リポジトリを参照するか、チームに問い合わせてください。
