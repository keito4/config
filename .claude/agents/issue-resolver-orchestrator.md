# Issue Resolver: Orchestrator Agent

## 目的

GitHubのIssueを分析し、適切なIssue Resolverエージェントを選択・実行して、自動的にIssueを解決しPRを作成する統合オーケストレーター。

## 実行手順

### 1. Issueの取得と分析

```bash
#!/bin/bash

echo "=== Issue Resolver Orchestrator ==="
echo "Starting automated issue resolution process..."

# 設定
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
MAX_ISSUES_PER_RUN=5
AGENT_DIR="$(dirname "$0")"

# Open Issueを取得
echo -e "\n📋 Fetching open issues..."
gh issue list --state open --limit $MAX_ISSUES_PER_RUN --json number,title,labels,body > issues.json

# Issue数を確認
ISSUE_COUNT=$(cat issues.json | jq 'length')
echo "Found $ISSUE_COUNT open issues to process"

if [ "$ISSUE_COUNT" -eq 0 ]; then
    echo "✅ No open issues found. Repository is in good state!"
    exit 0
fi
```

### 2. Issueの分類と優先度付け

```bash
# Issueを分類
echo -e "\n🔍 Analyzing and categorizing issues..."

cat << 'EOF' > categorize_issues.js
const fs = require('fs');
const issues = JSON.parse(fs.readFileSync('issues.json', 'utf8'));

const categorizedIssues = {
    security: [],
    testing: [],
    documentation: [],
    dependencies: [],
    codeQuality: [],
    performance: [],
    unknown: []
};

issues.forEach(issue => {
    const title = issue.title.toLowerCase();
    const labels = issue.labels.map(l => l.name.toLowerCase());
    const body = (issue.body || '').toLowerCase();

    // ラベルベースの分類
    if (labels.includes('security') || labels.includes('critical')) {
        categorizedIssues.security.push(issue);
    } else if (labels.includes('testing') || labels.includes('test')) {
        categorizedIssues.testing.push(issue);
    } else if (labels.includes('documentation') || labels.includes('docs')) {
        categorizedIssues.documentation.push(issue);
    } else if (labels.includes('dependencies')) {
        categorizedIssues.dependencies.push(issue);
    } else if (labels.includes('refactoring') || labels.includes('code-quality')) {
        categorizedIssues.codeQuality.push(issue);
    } else if (labels.includes('performance')) {
        categorizedIssues.performance.push(issue);
    }
    // タイトル/本文ベースの分類
    else if (title.includes('security') || body.includes('vulnerability')) {
        categorizedIssues.security.push(issue);
    } else if (title.includes('test') || title.includes('coverage')) {
        categorizedIssues.testing.push(issue);
    } else if (title.includes('doc') || title.includes('readme')) {
        categorizedIssues.documentation.push(issue);
    } else if (title.includes('depend') || title.includes('update')) {
        categorizedIssues.dependencies.push(issue);
    } else if (title.includes('refactor') || title.includes('todo')) {
        categorizedIssues.codeQuality.push(issue);
    } else {
        categorizedIssues.unknown.push(issue);
    }
});

// 優先度順にソート（security > testing > dependencies > codeQuality > documentation > performance > unknown）
const priorityOrder = ['security', 'testing', 'dependencies', 'codeQuality', 'documentation', 'performance', 'unknown'];
const sortedIssues = [];

priorityOrder.forEach(category => {
    categorizedIssues[category].forEach(issue => {
        sortedIssues.push({
            ...issue,
            category,
            priority: priorityOrder.indexOf(category)
        });
    });
});

fs.writeFileSync('categorized_issues.json', JSON.stringify(sortedIssues, null, 2));

// サマリー出力
console.log('Issue Categories:');
Object.entries(categorizedIssues).forEach(([category, issues]) => {
    if (issues.length > 0) {
        console.log(`  ${category}: ${issues.length} issue(s)`);
    }
});
EOF

node categorize_issues.js
```

### 3. 適切なエージェントの選択と実行

```bash
# 各Issueに対して適切なエージェントを実行
echo -e "\n🤖 Processing issues with specialized agents..."

# 実行結果を記録
mkdir -p resolution_logs
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="resolution_logs/run_${TIMESTAMP}.log"

# カテゴリ別にIssueを処理
cat categorized_issues.json | jq -c '.[]' | while read -r issue; do
    issue_number=$(echo "$issue" | jq -r '.number')
    issue_title=$(echo "$issue" | jq -r '.title')
    issue_category=$(echo "$issue" | jq -r '.category')

    echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Processing Issue #$issue_number: $issue_title"
    echo "Category: $issue_category"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # ブランチ作成
    branch_name="fix/issue-${issue_number}-$(echo "$issue_category" | tr '[:upper:]' '[:lower:]')"

    # 既存のブランチをチェック
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "⚠️  Branch $branch_name already exists, skipping..."
        continue
    fi

    git checkout -b "$branch_name"

    # カテゴリに応じたエージェントを実行
    case "$issue_category" in
        "security")
            echo "🔒 Running Security Agent..."
            bash "$AGENT_DIR/issue-resolver-security.md"
            AGENT_EXIT_CODE=$?
            ;;
        "testing")
            echo "🧪 Running Test Coverage Agent..."
            bash "$AGENT_DIR/issue-resolver-test-coverage.md"
            AGENT_EXIT_CODE=$?
            ;;
        "documentation")
            echo "📚 Running Documentation Agent..."
            bash "$AGENT_DIR/issue-resolver-documentation.md"
            AGENT_EXIT_CODE=$?
            ;;
        "dependencies")
            echo "📦 Running Dependencies Agent..."
            bash "$AGENT_DIR/issue-resolver-dependencies.md"
            AGENT_EXIT_CODE=$?
            ;;
        "codeQuality")
            echo "🔧 Running Code Quality Agent..."
            bash "$AGENT_DIR/issue-resolver-code-quality.md"
            AGENT_EXIT_CODE=$?
            ;;
        "performance")
            echo "⚡ Running Performance Agent..."
            # パフォーマンス最適化エージェント（未実装の場合はスキップ）
            echo "Performance agent not yet implemented, skipping..."
            AGENT_EXIT_CODE=1
            ;;
        *)
            echo "❓ Unknown category, attempting generic resolution..."
            # 汎用的な処理
            AGENT_EXIT_CODE=1
            ;;
    esac

    # エージェントの実行結果を確認
    if [ $AGENT_EXIT_CODE -eq 0 ]; then
        echo "✅ Agent completed successfully"

        # 変更があるか確認
        if [ -n "$(git status --porcelain)" ]; then
            # コミットとPR作成
            git add -A
            git commit -m "fix: Resolve issue #$issue_number

$issue_title

Category: $issue_category
Automated resolution by Issue Resolver Orchestrator

Closes #$issue_number"

            git push -u origin "$branch_name"

            # PR作成
            PR_BODY=$(cat << EOF
## 🤖 Automated Issue Resolution

This PR was automatically generated to resolve Issue #$issue_number.

### Issue Details
- **Title**: $issue_title
- **Category**: $issue_category
- **Priority**: $(echo "$issue" | jq -r '.priority')

### Changes Made
$(git diff --stat HEAD~1)

### Verification
- [ ] Code changes reviewed
- [ ] Tests passing
- [ ] No breaking changes introduced

### Notes
This PR was created by the Issue Resolver Orchestrator using the $issue_category agent.

---
*Generated at $(date)*
EOF
)

            gh pr create \
                --title "🤖 Auto-fix: $issue_title (#$issue_number)" \
                --body "$PR_BODY" \
                --label "automated,$issue_category" \
                --assignee "@me"

            echo "✅ PR created successfully"

            # ログに記録
            echo "[$(date)] Successfully resolved Issue #$issue_number" >> "$LOG_FILE"
        else
            echo "ℹ️  No changes needed for this issue"
            git checkout main
            git branch -d "$branch_name"
        fi
    else
        echo "❌ Agent failed or skipped"
        git checkout main
        git branch -D "$branch_name" 2>/dev/null

        # ログに記録
        echo "[$(date)] Failed to resolve Issue #$issue_number" >> "$LOG_FILE"
    fi

    # メインブランチに戻る
    git checkout main
done
```

### 4. 実行状況のレポート生成

```bash
echo -e "\n📊 Generating execution report..."

cat << 'EOF' > generate_report.js
const fs = require('fs');

// 処理結果を集計
const categorizedIssues = JSON.parse(fs.readFileSync('categorized_issues.json', 'utf8'));
const logFile = process.argv[2];
const logContent = fs.readFileSync(logFile, 'utf8');

const successCount = (logContent.match(/Successfully resolved/g) || []).length;
const failCount = (logContent.match(/Failed to resolve/g) || []).length;
const totalProcessed = successCount + failCount;

// PRリストを取得（最新のもの）
const { execSync } = require('child_process');
const recentPRs = execSync('gh pr list --author @me --limit 10 --json number,title,url', { encoding: 'utf8' });
const prs = JSON.parse(recentPRs);

// Slackメッセージ生成
const slackMessage = {
    text: `Issue Resolver Orchestrator - Execution Report`,
    blocks: [
        {
            type: "header",
            text: {
                type: "plain_text",
                text: "🤖 Issue Resolver Report"
            }
        },
        {
            type: "section",
            fields: [
                {
                    type: "mrkdwn",
                    text: `*Total Issues:* ${categorizedIssues.length}`
                },
                {
                    type: "mrkdwn",
                    text: `*Processed:* ${totalProcessed}`
                },
                {
                    type: "mrkdwn",
                    text: `*Success:* ${successCount} ✅`
                },
                {
                    type: "mrkdwn",
                    text: `*Failed:* ${failCount} ❌`
                }
            ]
        },
        {
            type: "section",
            text: {
                type: "mrkdwn",
                text: "*Categories Processed:*\n" +
                    Object.entries(
                        categorizedIssues.reduce((acc, issue) => {
                            acc[issue.category] = (acc[issue.category] || 0) + 1;
                            return acc;
                        }, {})
                    ).map(([cat, count]) => `• ${cat}: ${count}`).join('\n')
            }
        },
        {
            type: "section",
            text: {
                type: "mrkdwn",
                text: "*Recent PRs Created:*\n" +
                    prs.slice(0, 3).map(pr => `• <${pr.url}|#${pr.number}: ${pr.title}>`).join('\n')
            }
        },
        {
            type: "context",
            elements: [
                {
                    type: "mrkdwn",
                    text: `Execution completed at ${new Date().toISOString()}`
                }
            ]
        }
    ]
};

// レポートファイル生成
const report = {
    timestamp: new Date().toISOString(),
    summary: {
        total_issues: categorizedIssues.length,
        processed: totalProcessed,
        successful: successCount,
        failed: failCount,
        success_rate: totalProcessed > 0 ? (successCount / totalProcessed * 100).toFixed(1) + '%' : 'N/A'
    },
    categories: categorizedIssues.reduce((acc, issue) => {
        acc[issue.category] = (acc[issue.category] || 0) + 1;
        return acc;
    }, {}),
    pull_requests: prs.slice(0, 5)
};

fs.writeFileSync('resolution_report.json', JSON.stringify(report, null, 2));
fs.writeFileSync('slack_message.json', JSON.stringify(slackMessage, null, 2));

console.log('\n📊 Execution Summary:');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`Total Issues: ${categorizedIssues.length}`);
console.log(`Processed: ${totalProcessed}`);
console.log(`Successful: ${successCount} (${report.summary.success_rate})`);
console.log(`Failed: ${failCount}`);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
EOF

node generate_report.js "$LOG_FILE"
```

### 5. 通知の送信

```bash
# Slack通知（環境変数にWebhook URLが設定されている場合）
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo -e "\n📮 Sending Slack notification..."
    curl -X POST -H 'Content-type: application/json' \
        --data @slack_message.json \
        "$SLACK_WEBHOOK_URL"
fi

# GitHub Issue にコメント
echo -e "\n💬 Adding comments to processed issues..."
cat categorized_issues.json | jq -r '.[] | .number' | while read -r issue_num; do
    if grep -q "Successfully resolved Issue #$issue_num" "$LOG_FILE"; then
        gh issue comment "$issue_num" \
            --body "🤖 This issue has been automatically resolved by the Issue Resolver Orchestrator. A pull request has been created to address the reported problems."
    fi
done
```

### 6. 定期実行の設定

```bash
# GitHub Actions ワークフローの作成
cat << 'EOF' > .github/workflows/issue-resolver.yml
name: Automated Issue Resolution

on:
  schedule:
    # 毎日午前2時に実行
    - cron: '0 2 * * *'
  workflow_dispatch:
    inputs:
      max_issues:
        description: 'Maximum number of issues to process'
        required: false
        default: '5'
      categories:
        description: 'Comma-separated list of categories to process'
        required: false
        default: 'all'

jobs:
  resolve-issues:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v6
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: |
          npm ci
          npm install -g license-checker depcheck

      - name: Configure Git
        run: |
          git config user.name "Issue Resolver Bot"
          git config user.email "bot@example.com"

      - name: Run Issue Resolver Orchestrator
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          MAX_ISSUES_PER_RUN: ${{ github.event.inputs.max_issues || '5' }}
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          bash .claude/agents/issue-resolver-orchestrator.md

      - name: Upload execution report
        uses: actions/upload-artifact@v7
        with:
          name: resolution-report
          path: |
            resolution_report.json
            resolution_logs/

      - name: Create summary
        if: always()
        run: |
          if [ -f "resolution_report.json" ]; then
            echo "## 🤖 Issue Resolution Summary" >> $GITHUB_STEP_SUMMARY
            echo "" >> $GITHUB_STEP_SUMMARY
            cat resolution_report.json | jq -r '"- Total Issues: \(.summary.total_issues)"' >> $GITHUB_STEP_SUMMARY
            cat resolution_report.json | jq -r '"- Processed: \(.summary.processed)"' >> $GITHUB_STEP_SUMMARY
            cat resolution_report.json | jq -r '"- Success Rate: \(.summary.success_rate)"' >> $GITHUB_STEP_SUMMARY
          fi
EOF
```

### 7. ヘルスチェックとモニタリング

```bash
# システムヘルスチェック
echo -e "\n🏥 Performing health check..."

cat << 'EOF' > health_check.sh
#!/bin/bash

# エージェントの可用性チェック
AGENTS=(
    "issue-resolver-code-quality.md"
    "issue-resolver-test-coverage.md"
    "issue-resolver-security.md"
    "issue-resolver-documentation.md"
    "issue-resolver-dependencies.md"
)

echo "Checking agent availability..."
for agent in "${AGENTS[@]}"; do
    if [ -f "$(dirname "$0")/$agent" ]; then
        echo "  ✅ $agent: Available"
    else
        echo "  ❌ $agent: Missing"
    fi
done

# 依存ツールのチェック
echo -e "\nChecking required tools..."
REQUIRED_TOOLS=(
    "git"
    "gh"
    "node"
    "npm"
    "jq"
    "rg"
)

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "  ✅ $tool: Installed"
    else
        echo "  ❌ $tool: Missing"
    fi
done

# GitHub認証チェック
echo -e "\nChecking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "  ✅ GitHub CLI: Authenticated"
else
    echo "  ❌ GitHub CLI: Not authenticated"
fi
EOF

bash health_check.sh
```

## 成功基準

- ✅ Issueが自動的に分類されている
- ✅ 適切なエージェントが選択・実行されている
- ✅ 解決可能なIssueに対してPRが作成されている
- ✅ 実行レポートが生成されている
- ✅ 定期実行が設定されている
- ✅ 通知が送信されている

## トラブルシューティング

### エージェントが失敗する場合

```bash
# デバッグモードで実行
DEBUG=true bash issue-resolver-orchestrator.md

# 特定のカテゴリのみ処理
CATEGORIES="security,testing" bash issue-resolver-orchestrator.md

# ドライランモード（PRを作成しない）
DRY_RUN=true bash issue-resolver-orchestrator.md
```

### 権限エラーの場合

```bash
# GitHub トークンの権限確認
gh auth status

# 必要な権限:
# - repo (full control)
# - workflow (GitHub Actions)
# - write:packages (if using package registry)
```

### ロールバック

```bash
# 作成されたPRを一括クローズ
gh pr list --author @me --label automated --json number | jq -r '.[].number' | while read -r pr; do
    gh pr close "$pr" --comment "Closing automated PR due to issues"
done

# ブランチの削除
git branch -a | grep "fix/issue-" | xargs -n 1 git branch -D
```
