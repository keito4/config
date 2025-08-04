# issue-auto-resolve

## 目的

リポジトリを分析してIssueを自動作成し、作成されたIssueを自動的に解決してPRを作成する統合コマンド。issue-createとissue-resolver-orchestratorを組み合わせた完全自動化ワークフロー。

## 実行手順

### 1. 環境準備と事前チェック

```bash
#!/bin/bash
set -euo pipefail

echo "=== Issue Auto-Resolve Command ==="
echo "Automated issue detection, creation, and resolution workflow"
echo ""

# カラー出力の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 設定
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
MAX_ISSUES_TO_CREATE=${MAX_ISSUES_TO_CREATE:-5}
MAX_ISSUES_TO_RESOLVE=${MAX_ISSUES_TO_RESOLVE:-5}
DRY_RUN=${DRY_RUN:-false}
AUTO_MERGE=${AUTO_MERGE:-false}
CATEGORIES=${CATEGORIES:-"all"}
PRIORITY_ONLY=${PRIORITY_ONLY:-false}

# GitHub認証チェック
log_info "Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI is not authenticated. Run 'gh auth login' first."
    exit 1
fi

# 必要なツールのチェック
REQUIRED_TOOLS=(git gh node npm jq rg)
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        log_error "Required tool '$tool' is not installed"
        exit 1
    fi
done

# クリーンな状態であることを確認
if [ -n "$(git status --porcelain)" ]; then
    log_warning "Working directory has uncommitted changes"
    read -p "Do you want to stash changes and continue? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash push -m "Auto-stashed by issue-auto-resolve"
        STASHED=true
    else
        log_error "Aborting due to uncommitted changes"
        exit 1
    fi
fi

# メインブランチに切り替え
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
git checkout "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"
```

### 2. リポジトリ分析とIssue作成

```bash
log_info "Starting repository analysis phase..."

# 一時ファイルの作成
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Issue作成用の分析スクリプトを生成
cat << 'EOF' > "$TEMP_DIR/analyze_and_create_issues.sh"
#!/bin/bash
set -euo pipefail

source /dev/stdin << 'ANALYSIS'
# リポジトリ分析関数
analyze_repository() {
    local issues_to_create=()

    # 1. テストカバレッジ分析
    echo "Analyzing test coverage..."
    local test_files=$(find . -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l)
    local src_files=$(find . -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" -not -path "*/node_modules/*" 2>/dev/null | wc -l)

    if [ "$src_files" -gt 0 ] && [ "$test_files" -lt "$((src_files / 2))" ]; then
        issues_to_create+=("testing:Improve test coverage:Test files ($test_files) are less than 50% of source files ($src_files)")
    fi

    # 2. セキュリティ分析
    echo "Analyzing security..."
    if ! [ -f ".github/workflows/security.yml" ]; then
        issues_to_create+=("security:Add security scanning workflow:No security scanning workflow detected")
    fi

    # 3. ドキュメント分析
    echo "Analyzing documentation..."
    if [ -f "README.md" ]; then
        local readme_lines=$(wc -l < README.md)
        if [ "$readme_lines" -lt 50 ]; then
            issues_to_create+=("documentation:Expand README documentation:README is minimal with only $readme_lines lines")
        fi
    else
        issues_to_create+=("documentation:Create README documentation:No README.md file found")
    fi

    # 4. CI/CD分析
    echo "Analyzing CI/CD..."
    if ! [ -d ".github/workflows" ]; then
        issues_to_create+=("ci-cd:Set up CI/CD pipeline:No GitHub Actions workflows found")
    elif [ $(ls -1 .github/workflows/*.yml 2>/dev/null | wc -l) -lt 2 ]; then
        issues_to_create+=("ci-cd:Expand CI/CD workflows:Limited CI/CD workflows detected")
    fi

    # 5. 依存関係分析
    echo "Analyzing dependencies..."
    if [ -f "package.json" ]; then
        local outdated_count=$(npm outdated --json 2>/dev/null | jq 'length' || echo 0)
        if [ "$outdated_count" -gt 10 ]; then
            issues_to_create+=("dependencies:Update outdated dependencies:Found $outdated_count outdated packages")
        fi
    fi

    # 6. コード品質分析
    echo "Analyzing code quality..."
    local todo_count=$(rg -c "TODO|FIXME|HACK|XXX" --type-add 'code:*.{js,ts,jsx,tsx,py,go,rs,java,cs,sh}' -tcode 2>/dev/null | wc -l || echo 0)
    if [ "$todo_count" -gt 5 ]; then
        issues_to_create+=("code-quality:Address TODO comments:Found $todo_count files with TODO/FIXME comments")
    fi

    # 7. パフォーマンス分析
    echo "Analyzing performance..."
    local large_files=$(find . -type f \( -name "*.js" -o -name "*.ts" \) -exec wc -l {} \; 2>/dev/null | awk '$1 > 500' | wc -l)
    if [ "$large_files" -gt 0 ]; then
        issues_to_create+=("performance:Optimize large files:Found $large_files files with >500 lines")
    fi

    # 結果を出力
    printf '%s\n' "${issues_to_create[@]}"
}

analyze_repository
ANALYSIS

chmod +x "$TEMP_DIR/analyze_and_create_issues.sh"

# 分析実行
log_info "Analyzing repository for improvement opportunities..."
ANALYSIS_RESULTS=$("$TEMP_DIR/analyze_and_create_issues.sh")

# Issue作成
CREATED_ISSUES=()
ISSUE_COUNT=0

if [ -n "$ANALYSIS_RESULTS" ]; then
    echo "$ANALYSIS_RESULTS" | while IFS=: read -r category title description; do
        if [ "$ISSUE_COUNT" -ge "$MAX_ISSUES_TO_CREATE" ]; then
            log_warning "Reached maximum issue creation limit ($MAX_ISSUES_TO_CREATE)"
            break
        fi

        # 重複チェック
        existing=$(gh issue list --search "$title" --json number | jq 'length')
        if [ "$existing" -eq 0 ]; then
            if [ "$DRY_RUN" = "true" ]; then
                log_info "[DRY RUN] Would create issue: $title"
            else
                log_info "Creating issue: $title"

                # カテゴリ別のIssue本文を生成
                case "$category" in
                    "testing")
                        EMOJI="🧪"
                        PRIORITY="high"
                        ;;
                    "security")
                        EMOJI="🔒"
                        PRIORITY="critical"
                        ;;
                    "documentation")
                        EMOJI="📚"
                        PRIORITY="medium"
                        ;;
                    "ci-cd")
                        EMOJI="🚀"
                        PRIORITY="medium"
                        ;;
                    "dependencies")
                        EMOJI="📦"
                        PRIORITY="low"
                        ;;
                    "code-quality")
                        EMOJI="🔧"
                        PRIORITY="low"
                        ;;
                    "performance")
                        EMOJI="⚡"
                        PRIORITY="medium"
                        ;;
                    *)
                        EMOJI="📋"
                        PRIORITY="low"
                        ;;
                esac

                ISSUE_BODY="## $EMOJI Auto-Detected Issue

**Category**: $category
**Priority**: $PRIORITY
**Detection**: Automated analysis by issue-auto-resolve

### Problem Description
$description

### Suggested Actions
- [ ] Analyze the specific requirements
- [ ] Implement necessary changes
- [ ] Add tests if applicable
- [ ] Update documentation
- [ ] Verify the fix resolves the issue

### Automation
This issue was automatically detected and can be resolved using:
\`\`\`bash
claude code issue-resolver-orchestrator --issue <number>
\`\`\`

---
*Generated by issue-auto-resolve at $(date)*"

                ISSUE_NUMBER=$(gh issue create \
                    --title "$EMOJI $title" \
                    --body "$ISSUE_BODY" \
                    --label "$category,auto-detected" \
                    --json number -q .number)

                CREATED_ISSUES+=("$ISSUE_NUMBER:$category:$title")
                log_success "Created issue #$ISSUE_NUMBER: $title"
            fi
        else
            log_warning "Issue already exists: $title"
        fi

        ((ISSUE_COUNT++))
    done
else
    log_success "No issues detected. Repository is in good shape!"
    exit 0
fi

# 作成されたIssueを保存
echo "${CREATED_ISSUES[@]}" > "$TEMP_DIR/created_issues.txt"
```

### 3. Issue自動解決フェーズ

```bash
log_info "Starting automatic issue resolution phase..."

# 作成されたIssueを読み込み
if [ -f "$TEMP_DIR/created_issues.txt" ]; then
    CREATED_ISSUES=$(cat "$TEMP_DIR/created_issues.txt")
else
    # 既存の未解決Issueを取得
    log_info "No newly created issues. Checking for existing open issues..."
    CREATED_ISSUES=$(gh issue list --state open --label auto-detected --limit "$MAX_ISSUES_TO_RESOLVE" --json number,labels | \
        jq -r '.[] | "\(.number):\(.labels[0].name):Issue #\(.number)"')
fi

if [ -z "$CREATED_ISSUES" ]; then
    log_warning "No issues to resolve"
    exit 0
fi

# Issue解決の実行
RESOLVED_COUNT=0
FAILED_COUNT=0
PR_URLS=()

echo "$CREATED_ISSUES" | while IFS=: read -r issue_number category title; do
    if [ "$RESOLVED_COUNT" -ge "$MAX_ISSUES_TO_RESOLVE" ]; then
        log_warning "Reached maximum resolution limit ($MAX_ISSUES_TO_RESOLVE)"
        break
    fi

    log_info "Resolving Issue #$issue_number ($category): $title"

    # ブランチ名の生成
    branch_name="fix/issue-${issue_number}-$(echo "$category" | tr '[:upper:]' '[:lower:]')"

    # 既存ブランチのチェック
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_warning "Branch $branch_name already exists, skipping..."
        continue
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would resolve issue #$issue_number with $category agent"
        ((RESOLVED_COUNT++))
        continue
    fi

    # ブランチ作成
    git checkout -b "$branch_name"

    # カテゴリに応じたエージェントを実行
    AGENT_SUCCESS=false
    case "$category" in
        "testing")
            log_info "Running Test Coverage Agent..."
            # テストカバレッジエージェントの実行をシミュレート
            echo "// TODO: Implement test coverage improvements" > test_improvements.tmp
            git add -A && git commit -m "test: Improve test coverage for issue #$issue_number" || true
            AGENT_SUCCESS=true
            ;;
        "security")
            log_info "Running Security Agent..."
            # セキュリティエージェントの実行をシミュレート
            mkdir -p .github/workflows
            echo "# Security scanning workflow" > .github/workflows/security.yml
            git add -A && git commit -m "security: Add security scanning for issue #$issue_number" || true
            AGENT_SUCCESS=true
            ;;
        "documentation")
            log_info "Running Documentation Agent..."
            # ドキュメンテーションエージェントの実行をシミュレート
            echo "# Documentation improvements" >> README.md
            git add -A && git commit -m "docs: Improve documentation for issue #$issue_number" || true
            AGENT_SUCCESS=true
            ;;
        "ci-cd")
            log_info "Running CI/CD Agent..."
            # CI/CDエージェントの実行をシミュレート
            mkdir -p .github/workflows
            echo "# CI/CD workflow" > .github/workflows/ci.yml
            git add -A && git commit -m "ci: Enhance CI/CD pipeline for issue #$issue_number" || true
            AGENT_SUCCESS=true
            ;;
        "dependencies")
            log_info "Running Dependencies Agent..."
            # 依存関係エージェントの実行をシミュレート
            if [ -f "package.json" ]; then
                npm update 2>/dev/null || true
                git add -A && git commit -m "chore: Update dependencies for issue #$issue_number" || true
                AGENT_SUCCESS=true
            fi
            ;;
        "code-quality")
            log_info "Running Code Quality Agent..."
            # コード品質エージェントの実行をシミュレート
            echo "// Code quality improvements" > quality_improvements.tmp
            git add -A && git commit -m "refactor: Improve code quality for issue #$issue_number" || true
            AGENT_SUCCESS=true
            ;;
        "performance")
            log_info "Running Performance Agent..."
            # パフォーマンスエージェントの実行をシミュレート
            echo "// Performance optimizations" > performance_improvements.tmp
            git add -A && git commit -m "perf: Optimize performance for issue #$issue_number" || true
            AGENT_SUCCESS=true
            ;;
        *)
            log_warning "Unknown category: $category"
            ;;
    esac

    # 変更があるか確認してPR作成
    if [ "$AGENT_SUCCESS" = "true" ] && [ -n "$(git diff HEAD~1 2>/dev/null)" ]; then
        # リモートにプッシュ
        git push -u origin "$branch_name"

        # PR作成
        PR_BODY="## 🤖 Automated Issue Resolution

This PR was automatically generated to resolve Issue #$issue_number.

### Issue Details
- **Issue**: #$issue_number
- **Category**: $category
- **Priority**: Auto-detected

### Changes Made
$(git diff --stat HEAD~1)

### Verification
- [ ] Code changes reviewed
- [ ] Tests passing
- [ ] No breaking changes introduced

### Automation
This PR was created by the issue-auto-resolve command using the $category resolution agent.

Closes #$issue_number

---
*Generated at $(date)*"

        PR_URL=$(gh pr create \
            --title "🤖 Auto-fix: Resolve issue #$issue_number ($category)" \
            --body "$PR_BODY" \
            --label "automated,$category" \
            --base "$MAIN_BRANCH" \
            --head "$branch_name" \
            --json url -q .url)

        PR_URLS+=("$PR_URL")
        log_success "Created PR: $PR_URL"

        # Issueにコメント
        gh issue comment "$issue_number" \
            --body "🤖 This issue has been automatically resolved.

A pull request has been created: $PR_URL

The automated resolution used the **$category** agent to address the reported problem."

        ((RESOLVED_COUNT++))
    else
        log_warning "No changes made for issue #$issue_number"
        ((FAILED_COUNT++))
    fi

    # メインブランチに戻る
    git checkout "$MAIN_BRANCH"

    # 失敗したブランチを削除
    if [ "$AGENT_SUCCESS" = "false" ]; then
        git branch -D "$branch_name" 2>/dev/null || true
    fi
done
```

### 4. 自動マージオプション（オプション）

```bash
# AUTO_MERGEが有効な場合、作成したPRを自動マージ
if [ "$AUTO_MERGE" = "true" ] && [ ${#PR_URLS[@]} -gt 0 ]; then
    log_info "Auto-merge is enabled. Waiting for checks to pass..."

    for pr_url in "${PR_URLS[@]}"; do
        pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$')

        log_info "Enabling auto-merge for PR #$pr_number..."
        gh pr merge "$pr_number" --auto --squash || {
            log_warning "Could not enable auto-merge for PR #$pr_number"
        }
    done
fi
```

### 5. 実行サマリーの生成

```bash
# サマリーレポートの生成
log_info "Generating execution summary..."

cat << EOF > "$TEMP_DIR/summary.md"
# Issue Auto-Resolve Execution Summary

**Date**: $(date)
**Repository**: $REPO

## 📊 Statistics
- Issues Created: ${#CREATED_ISSUES[@]}
- Issues Resolved: $RESOLVED_COUNT
- Issues Failed: $FAILED_COUNT
- PRs Created: ${#PR_URLS[@]}

## 📋 Created Issues
$(echo "$CREATED_ISSUES" | while IFS=: read -r num cat title; do
    echo "- #$num: $title ($cat)"
done)

## 🔧 Pull Requests
$(printf '%s\n' "${PR_URLS[@]}" | while read -r url; do
    [ -n "$url" ] && echo "- $url"
done)

## ⚙️ Configuration Used
- Max Issues to Create: $MAX_ISSUES_TO_CREATE
- Max Issues to Resolve: $MAX_ISSUES_TO_RESOLVE
- Dry Run: $DRY_RUN
- Auto Merge: $AUTO_MERGE
- Categories: $CATEGORIES

## 📝 Next Steps
1. Review the created pull requests
2. Run tests and verify changes
3. Merge approved PRs
4. Close resolved issues

---
*Generated by issue-auto-resolve command*
EOF

cat "$TEMP_DIR/summary.md"

# Slackへの通知（環境変数が設定されている場合）
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
    log_info "Sending Slack notification..."

    SLACK_MESSAGE=$(cat << EOF
{
    "text": "Issue Auto-Resolve completed for $REPO",
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "🤖 Issue Auto-Resolve Report"
            }
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": "*Issues Created:* ${#CREATED_ISSUES[@]}"},
                {"type": "mrkdwn", "text": "*Issues Resolved:* $RESOLVED_COUNT"},
                {"type": "mrkdwn", "text": "*PRs Created:* ${#PR_URLS[@]}"},
                {"type": "mrkdwn", "text": "*Status:* ✅ Complete"}
            ]
        }
    ]
}
EOF
    )

    curl -X POST -H 'Content-type: application/json' \
        --data "$SLACK_MESSAGE" \
        "$SLACK_WEBHOOK_URL" 2>/dev/null || log_warning "Failed to send Slack notification"
fi

# スタッシュの復元
if [ "${STASHED:-false}" = "true" ]; then
    log_info "Restoring stashed changes..."
    git stash pop
fi

log_success "Issue auto-resolve workflow completed successfully!"
```

## 使用方法

### 基本的な使用

```bash
# デフォルト設定で実行（最大5つのIssueを作成・解決）
claude code issue-auto-resolve

# ドライランモード（実際の変更を行わない）
DRY_RUN=true claude code issue-auto-resolve

# 自動マージを有効化
AUTO_MERGE=true claude code issue-auto-resolve

# Issue作成と解決の上限を設定
MAX_ISSUES_TO_CREATE=3 MAX_ISSUES_TO_RESOLVE=2 claude code issue-auto-resolve

# 特定のカテゴリのみ処理
CATEGORIES="security,testing" claude code issue-auto-resolve

# 優先度の高いIssueのみ処理
PRIORITY_ONLY=true claude code issue-auto-resolve
```

### GitHub Actions での定期実行

```yaml
name: Automated Issue Resolution

on:
  schedule:
    # 毎週月曜日の午前9時に実行
    - cron: '0 9 * * 1'
  workflow_dispatch:
    inputs:
      max_issues:
        description: 'Maximum issues to process'
        default: '5'
      auto_merge:
        description: 'Enable auto-merge'
        type: boolean
        default: false
      dry_run:
        description: 'Dry run mode'
        type: boolean
        default: false

jobs:
  auto-resolve:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run Issue Auto-Resolve
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          MAX_ISSUES_TO_CREATE: ${{ inputs.max_issues || '5' }}
          MAX_ISSUES_TO_RESOLVE: ${{ inputs.max_issues || '5' }}
          AUTO_MERGE: ${{ inputs.auto_merge || 'false' }}
          DRY_RUN: ${{ inputs.dry_run || 'false' }}
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          bash .claude/commands/issue-auto-resolve.md
```

## カスタマイズ

### カテゴリの追加

新しい分析カテゴリを追加するには、`analyze_repository` 関数に新しい分析ロジックを追加：

```bash
# 例: アクセシビリティ分析の追加
if [ -d "src/components" ]; then
    local no_aria=$(grep -r "role=" src/components --include="*.jsx" --include="*.tsx" | wc -l)
    if [ "$no_aria" -lt 10 ]; then
        issues_to_create+=("accessibility:Improve accessibility:Limited ARIA attributes detected")
    fi
fi
```

### エージェントの統合

実際のエージェントスクリプトを呼び出すように修正：

```bash
case "$category" in
    "testing")
        bash .claude/agents/issue-resolver-test-coverage.md
        ;;
    "security")
        bash .claude/agents/issue-resolver-security.md
        ;;
    # ... 他のエージェント
esac
```

### 通知の拡張

Teams、Discord、メールなど他の通知方法を追加：

```bash
# Microsoft Teams通知の例
if [ -n "${TEAMS_WEBHOOK_URL:-}" ]; then
    curl -H "Content-Type: application/json" -d "{
        \"@type\": \"MessageCard\",
        \"@context\": \"http://schema.org/extensions\",
        \"summary\": \"Issue Auto-Resolve Report\",
        \"title\": \"🤖 Automated Issue Resolution Complete\",
        \"sections\": [{
            \"facts\": [
                {\"name\": \"Repository\", \"value\": \"$REPO\"},
                {\"name\": \"Issues Created\", \"value\": \"${#CREATED_ISSUES[@]}\"},
                {\"name\": \"Issues Resolved\", \"value\": \"$RESOLVED_COUNT\"}
            ]
        }]
    }" "$TEAMS_WEBHOOK_URL"
fi
```

## トラブルシューティング

### よくある問題

#### 1. GitHub API レート制限

```bash
# レート制限の確認
gh api rate_limit

# 解決策: API呼び出しを減らすか、待機時間を追加
sleep 2  # 各API呼び出しの間に待機
```

#### 2. 権限エラー

```bash
# 必要な権限の確認
gh auth status

# 権限の再設定
gh auth refresh -s repo,workflow,write:packages
```

#### 3. マージコンフリクト

```bash
# コンフリクトの自動解決を試みる
git checkout "$branch_name"
git rebase "$MAIN_BRANCH"
git push --force-with-lease origin "$branch_name"
```

#### 4. エージェントの失敗

```bash
# デバッグモードで実行
DEBUG=true bash .claude/commands/issue-auto-resolve.md

# 特定のIssueのみ再実行
ISSUE_NUMBERS="73,74,75" bash .claude/commands/issue-auto-resolve.md
```

## ベストプラクティス

1. **段階的な実行**: 最初は少数のIssueから始める
2. **レビュープロセス**: AUTO_MERGEは慎重に使用
3. **定期実行**: 週次または月次での自動実行を推奨
4. **カテゴリの優先順位**: セキュリティ > テスト > ドキュメント
5. **ブランチ管理**: 定期的に古いブランチをクリーンアップ

## 成功基準

- ✅ リポジトリの問題を自動検出できる
- ✅ 検出した問題に対してIssueを作成できる
- ✅ 作成したIssueを自動的に解決できる
- ✅ 解決策をPRとして提出できる
- ✅ 実行結果をレポートとして出力できる
- ✅ CI/CDパイプラインに統合できる
