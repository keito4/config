---
description: Setup comprehensive CI/CD workflows for your repository
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(pnpm:*), Bash(node:*), Bash(ls:*), Bash(cat:*), Bash(find:*), Bash(test:*), Bash(mkdir:*), Task, Glob, Grep
argument-hint: '[--type nextjs|nodejs|terraform|monorepo] [--level minimal|standard|comprehensive] [--dry-run]'
---

# CI/CD Setup Command

リポジトリに適切なCI/CDワークフローをセットアップします。プロジェクトタイプを自動検出し、推奨ワークフローを提案・適用します。

## Overview

以下のCI/CDコンポーネントを設定します：

1. **Quality Gates** - Lint, Format, Type Check
2. **Testing** - Unit Test, Coverage, E2E
3. **Security** - Audit, SAST, License Check
4. **Build & Deploy** - Build, Staging, Production
5. **AI Integration** - Claude Code Review

## Step 1: Parse Arguments

引数から設定を読み取る：

- `--type TYPE`: プロジェクトタイプ（自動検出可能）
  - `nextjs`: Next.js アプリケーション
  - `nodejs`: Node.js パッケージ/アプリケーション
  - `terraform`: Terraform インフラ
  - `monorepo`: モノレポ構成
- `--level LEVEL`: CI レベル（デフォルト: `standard`）
  - `minimal`: 最小限（Lint + Build）
  - `standard`: 標準（Lint + Test + Build + Security）
  - `comprehensive`: 包括的（全機能 + E2E + Deploy）
- `--dry-run`: 変更を適用せず、差分のみ表示

## Step 2: Detect Project Type

プロジェクトタイプを自動検出：

```bash
# ファイル存在確認
ls -la package.json next.config.* tsconfig.json pnpm-workspace.yaml *.tf 2>/dev/null
```

### 検出ルール

| 条件                                      | タイプ     |
| ----------------------------------------- | ---------- |
| `next.config.*` が存在                    | nextjs     |
| `pnpm-workspace.yaml` または `lerna.json` | monorepo   |
| `*.tf` ファイルが存在                     | terraform  |
| `package.json` のみ存在                   | nodejs     |
| 上記以外                                  | 不明（確認 |

検出結果を表示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Project Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: {detected_type}
Package Manager: {npm|pnpm|yarn}
Language: {TypeScript|JavaScript}
Framework: {Next.js|Express|None}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 3: Check Existing CI

既存のCI設定を確認：

```bash
ls -la .github/workflows/*.yml 2>/dev/null
```

### 既存ワークフローの分析

各ワークフローファイルを読み取り、以下を確認：

- トリガー条件（push, PR, schedule）
- ジョブ一覧（lint, test, build, deploy等）
- 使用ツール（ESLint, Prettier, Jest等）
- カバレッジ設定

結果を表示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Existing CI Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflows found: X files

| File           | Jobs                    | Triggers        |
| -------------- | ----------------------- | --------------- |
| ci.yml         | lint, test, build       | push, PR        |
| security.yml   | audit, sast             | schedule        |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 4: Generate Recommendations

プロジェクトタイプとレベルに基づいて推奨設定を生成：

### 4.1 Next.js プロジェクト

#### Minimal Level

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run build
```

#### Standard Level

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci

      - name: Format Check
        run: npm run format:check

      - name: Lint
        run: npm run lint

      - name: Type Check
        run: npm run type-check

  test:
    runs-on: ubuntu-latest
    needs: quality
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci

      - name: Run Tests
        run: npm test -- --coverage

      - name: Upload Coverage
        uses: codecov/codecov-action@v6
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: false

  build:
    runs-on: ubuntu-latest
    needs: [quality, test]
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run build

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: Security Audit
        run: npm audit --audit-level=high
        continue-on-error: true
```

#### Comprehensive Level

Standard Level に加えて以下を追加：

```yaml
# .github/workflows/ci.yml (追加ジョブ)
e2e:
  runs-on: ubuntu-latest
  needs: build
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
      with:
        node-version: '22'
        cache: 'npm'
    - run: npm ci
    - name: Install Playwright
      run: npx playwright install --with-deps chromium
    - name: Run E2E Tests
      run: npm run test:e2e
    - uses: actions/upload-artifact@v7
      if: failure()
      with:
        name: playwright-report
        path: playwright-report/
```

```yaml
# .github/workflows/security.yml
name: Security

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: npm audit
        run: npm audit --audit-level=high
      - name: License Check
        run: npx license-checker --summary --failOn "GPL;AGPL"

  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v6
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3
```

```yaml
# .github/workflows/claude-code-review.yml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # CIが完了しているかチェック
  check-ci-status:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    outputs:
      ci_passed: ${{ steps.check.outputs.ci_passed }}
    permissions:
      contents: read
      pull-requests: read
      checks: read
    steps:
      - name: Wait for CI and check status
        id: check
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          PR_NUMBER="${{ github.event.pull_request.number }}"
          REPO="${{ github.repository }}"
          HEAD_SHA="${{ github.event.pull_request.head.sha }}"

          echo "Waiting for CI to complete for PR #$PR_NUMBER (SHA: $HEAD_SHA)"

          # ポーリング設定
          MAX_WAIT_TIME=900  # 15分（秒）
          POLL_INTERVAL=30   # 30秒
          ELAPSED_TIME=0

          while [ $ELAPSED_TIME -lt $MAX_WAIT_TIME ]; do
            echo "⏱️  Elapsed time: ${ELAPSED_TIME}s / ${MAX_WAIT_TIME}s"

            # Check Runsを取得（CI workflowのみ）
            CHECK_RUNS=$(gh api repos/$REPO/commits/$HEAD_SHA/check-runs \
              --jq '.check_runs[] | select(.name != "check-ci-status" and .name != "claude-review") | {name, status, conclusion}')

            echo "Check Runs:"
            echo "$CHECK_RUNS" | jq -r '"\(.name): \(.status) - \(.conclusion)"'

            # 必須チェック: Quality Gate
            QUALITY_GATE=$(echo "$CHECK_RUNS" | jq -r 'select(.name == "Quality Gate")')

            if [ -z "$QUALITY_GATE" ]; then
              if [ $ELAPSED_TIME -ge 120 ]; then
                echo "ci_passed=true" >> $GITHUB_OUTPUT
                echo "✅ CI workflow skipped by path filters"
                exit 0
              fi
              echo "⏳ Quality Gate check has not started yet, waiting..."
              sleep $POLL_INTERVAL
              ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
              continue
            fi

            QUALITY_GATE_STATUS=$(echo "$QUALITY_GATE" | jq -r '.status')
            QUALITY_GATE_CONCLUSION=$(echo "$QUALITY_GATE" | jq -r '.conclusion')

            if [ "$QUALITY_GATE_STATUS" != "completed" ]; then
              echo "⏳ Quality Gate is still running: $QUALITY_GATE_STATUS, waiting..."
              sleep $POLL_INTERVAL
              ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
              continue
            fi

            if [ "$QUALITY_GATE_CONCLUSION" != "success" ]; then
              echo "ci_passed=false" >> $GITHUB_OUTPUT
              echo "❌ Quality Gate failed with conclusion: $QUALITY_GATE_CONCLUSION"
              exit 0
            fi

            echo "ci_passed=true" >> $GITHUB_OUTPUT
            echo "✅ All CI checks passed"
            exit 0
          done

          echo "ci_passed=false" >> $GITHUB_OUTPUT
          echo "⏱️ Timeout: CI did not complete within ${MAX_WAIT_TIME}s"
          exit 0

  claude-review:
    # CIが成功した場合のみ実行（Dependabotはシークレットにアクセスできないためスキップ）
    if: needs.check-ci-status.outputs.ci_passed == 'true' && github.actor != 'dependabot[bot]'
    needs: [check-ci-status]
    runs-on: ubuntu-latest
    timeout-minutes: 20
    continue-on-error: true # ワークフローファイル変更時の初回PR用
    permissions:
      contents: read
      pull-requests: read
      issues: read
      id-token: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 1

      - name: Run Claude Code Review
        id: claude-review
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
            Be constructive and helpful in your feedback.

            Use `gh pr comment` with your Bash tool to leave your review as a comment on the PR.

          claude_args: '--allowed-tools "Bash(gh issue view:*),Bash(gh search:*),Bash(gh issue list:*),Bash(gh pr comment:*),Bash(gh pr diff:*),Bash(gh pr view:*),Bash(gh pr list:*)"'
```

### 4.2 Node.js パッケージ

#### Standard Level

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
      - name: Upload Coverage
        if: matrix.node-version == 22
        uses: codecov/codecov-action@v6

  release:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: Semantic Release
        run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 4.3 Terraform プロジェクト

#### Standard Level

```yaml
# .github/workflows/terraform-pr.yml
name: Terraform PR

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-*.yml'

permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: hashicorp/setup-terraform@v4
        with:
          terraform_version: '1.9'

      - name: Terraform fmt
        run: terraform fmt -check -recursive
        working-directory: terraform

      - name: Terraform init
        run: terraform init -backend=false
        working-directory: terraform

      - name: Terraform validate
        run: terraform validate
        working-directory: terraform

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform
          output_format: sarif
          output_file_path: results.sarif
      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: results.sarif

  plan:
    runs-on: ubuntu-latest
    needs: [validate, security]
    steps:
      - uses: actions/checkout@v6
      - uses: hashicorp/setup-terraform@v4

      - name: Terraform init
        run: terraform init
        working-directory: terraform

      - name: Terraform plan
        id: plan
        run: terraform plan -no-color -out=tfplan
        working-directory: terraform

      - name: Comment PR
        uses: actions/github-script@v9
        with:
          script: |
            const output = `#### Terraform Plan
            \`\`\`
            ${{ steps.plan.outputs.stdout }}
            \`\`\`
            `;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });
```

### 4.4 モノレポ

#### Standard Level

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.filter.outputs.changes }}
    steps:
      - uses: actions/checkout@v6
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            package-a:
              - 'packages/package-a/**'
            package-b:
              - 'packages/package-b/**'

  test:
    runs-on: ubuntu-latest
    needs: detect-changes
    if: needs.detect-changes.outputs.packages != '[]'
    strategy:
      matrix:
        package: ${{ fromJson(needs.detect-changes.outputs.packages) }}
    steps:
      - uses: actions/checkout@v6
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter ${{ matrix.package }} run lint
      - run: pnpm --filter ${{ matrix.package }} run test
      - run: pnpm --filter ${{ matrix.package }} run build

  release:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - name: Release
        run: pnpm run release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Step 5: Show Gap Analysis

現在の設定と推奨設定の差分を表示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Gap Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Component        | Current | Recommended | Status |
| ---------------- | ------- | ----------- | ------ |
| Lint             | ✅      | ✅          | OK     |
| Format Check     | ❌      | ✅          | MISSING |
| Type Check       | ✅      | ✅          | OK     |
| Unit Tests       | ⚠️      | ✅          | PARTIAL (no coverage) |
| E2E Tests        | ❌      | ✅          | MISSING |
| Security Audit   | ❌      | ✅          | MISSING |
| License Check    | ❌      | ✅          | MISSING |
| CodeQL SAST      | ❌      | ✅          | MISSING |
| Claude Review    | ✅      | ✅          | OK     |
| Sched Maint      | ❌      | ✅          | MISSING |
| Concurrency      | ❌      | ✅          | MISSING |

Missing components: 6
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 6: Apply Changes (if not --dry-run)

ユーザーに確認後、以下を実行：

### 6.1 Create Workflow Directory

```bash
mkdir -p .github/workflows
```

### 6.2 Write Workflow Files

推奨ワークフローファイルを作成/更新：

- `.github/workflows/ci.yml`
- `.github/workflows/security.yml` (comprehensive)
- `.github/workflows/claude-code-review.yml` (comprehensive)
- `.github/workflows/scheduled-maintenance.yml` (standard+) — `templates/workflows/scheduled-maintenance.yml` をコピー

### 6.3 Update package.json Scripts

必要なnpmスクリプトが不足している場合は追加を提案：

```json
{
  "scripts": {
    "format:check": "prettier --check .",
    "type-check": "tsc --noEmit",
    "test:e2e": "playwright test"
  }
}
```

### 6.4 Create PR Template

```bash
mkdir -p .github
```

`.github/pull_request_template.md` を作成：

```markdown
## Summary

<!-- Brief description of changes -->

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Test Plan

<!-- How were these changes tested? -->

## Checklist

- [ ] Tests pass locally
- [ ] Code follows project style guidelines
- [ ] Documentation updated if needed
```

## Step 7: Generate Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CI Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project Type: {type}
CI Level: {level}

Files Created/Updated:
✅ .github/workflows/ci.yml
✅ .github/workflows/security.yml
✅ .github/workflows/claude-code-review.yml
✅ .github/pull_request_template.md

Next Steps:
1. Review the generated workflow files
2. Configure required secrets:
   - CODECOV_TOKEN (for coverage reports)
   - ANTHROPIC_API_KEY (for Claude reviews)
3. Push changes and verify CI runs
4. Adjust thresholds as needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Required Secrets

レベルに応じて必要なSecrets：

| Secret                  | Level         | Purpose               |
| ----------------------- | ------------- | --------------------- |
| CLAUDE_CODE_OAUTH_TOKEN | standard+     | Scheduled Maintenance |
| CODECOV_TOKEN           | standard+     | Coverage reports      |
| ANTHROPIC_API_KEY       | comprehensive | Claude Code Review    |
| NPM_TOKEN               | release       | npm publish           |
| VERCEL_TOKEN            | deploy        | Vercel deployment     |
| AWS_ACCESS_KEY_ID       | deploy        | AWS deployment        |

## CI Level Comparison

| Feature                 | Minimal | Standard | Comprehensive |
| ----------------------- | :-----: | :------: | :-----------: |
| Lint                    |   ✅    |    ✅    |      ✅       |
| Format Check            |   ❌    |    ✅    |      ✅       |
| Type Check              |   ✅    |    ✅    |      ✅       |
| Build                   |   ✅    |    ✅    |      ✅       |
| Unit Tests              |   ❌    |    ✅    |      ✅       |
| Coverage Reports        |   ❌    |    ✅    |      ✅       |
| Security Audit          |   ❌    |    ✅    |      ✅       |
| License Check           |   ❌    |    ❌    |      ✅       |
| CodeQL SAST             |   ❌    |    ❌    |      ✅       |
| E2E Tests               |   ❌    |    ❌    |      ✅       |
| Claude Code Review      |   ❌    |    ❌    |      ✅       |
| Scheduled Maintenance   |   ❌    |    ✅    |      ✅       |
| Scheduled Security Scan |   ❌    |    ❌    |      ✅       |
| Concurrency Control     |   ❌    |    ✅    |      ✅       |
| PR Templates            |   ❌    |    ✅    |      ✅       |

## Related Commands

| コマンド                    | 説明                    |
| --------------------------- | ----------------------- |
| `/setup-team-protection`    | GitHub ブランチ保護設定 |
| `/setup-husky`              | ローカル Git hooks 設定 |
| `/pre-pr-checklist`         | PR 作成前チェック       |
| `/security-credential-scan` | 認証情報スキャン        |

## Project Type Guides

プロジェクト種別に応じた詳細なセットアップガイドは [docs/setup/](../../docs/setup/README.md) を参照してください。
CI/CD 設定、共通パターン、品質ゲートなどの包括的な情報が含まれています。

## Error Handling

エラー発生時：

1. 具体的なエラー内容を報告
2. 手動での修正方法を提案
3. 部分的な成功でも適用可能な変更は適用
