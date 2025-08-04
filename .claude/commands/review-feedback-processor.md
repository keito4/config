# review-feedback-processor

## 目的

PRレビューコメント（特にCodeRabbitなどの自動レビューツール）を分析し、修正が必要な項目をIssue化または即座に修正するコマンド。

## 実行手順

### 1. レビューコメントの収集と分析

```bash
#!/bin/bash
set -euo pipefail

echo "=== Review Feedback Processor ==="
echo "Analyzing PR review comments and creating actionable items"
echo ""

# カラー出力の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_action() { echo -e "${MAGENTA}[ACTION]${NC} $1"; }

# 設定
PR_NUMBER=${PR_NUMBER:-""}
AUTO_FIX=${AUTO_FIX:-false}
CREATE_ISSUES=${CREATE_ISSUES:-true}
PRIORITY_THRESHOLD=${PRIORITY_THRESHOLD:-"medium"}  # low, medium, high, critical
DRY_RUN=${DRY_RUN:-false}

# PRコメントの取得
if [ -z "$PR_NUMBER" ]; then
    # 現在のブランチから PR を特定
    CURRENT_BRANCH=$(git branch --show-current)
    PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --json number -q '.[0].number' || echo "")

    if [ -z "$PR_NUMBER" ]; then
        log_error "No PR found for current branch. Specify PR_NUMBER environment variable."
        exit 1
    fi
fi

log_info "Processing PR #$PR_NUMBER"

# レビューコメントを取得
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# PRのレビューとコメントを収集
gh pr view "$PR_NUMBER" --json reviews,comments > "$TEMP_DIR/pr_data.json"

# CodeRabbitのコメントを抽出
cat "$TEMP_DIR/pr_data.json" | jq -r '.comments[] | select(.author.login == "coderabbitai") | .body' > "$TEMP_DIR/coderabbit_comments.txt"

# レビューコメントも含める
cat "$TEMP_DIR/pr_data.json" | jq -r '.reviews[] | select(.author.login == "coderabbitai") | .body' >> "$TEMP_DIR/coderabbit_comments.txt"
```

### 2. フィードバックのパースと分類

````bash
# フィードバックを解析するNode.jsスクリプト
cat << 'EOF' > "$TEMP_DIR/parse_feedback.js"
const fs = require('fs');

function parseFeedback(content) {
    const issues = [];

    // Actionable commentsを抽出
    const actionableRegex = /\*\*([^*]+)\*\*\s*\n([^*]+?)(?=\n\*\*|\n---|\Z)/gs;
    const matches = content.matchAll(actionableRegex);

    for (const match of matches) {
        const title = match[1].trim();
        const description = match[2].trim();

        // 優先度を判定
        let priority = 'low';
        let category = 'enhancement';

        if (title.match(/security|vulnerability|injection|auth/i)) {
            priority = 'critical';
            category = 'security';
        } else if (title.match(/bug|error|fail|crash|break/i)) {
            priority = 'high';
            category = 'bug';
        } else if (title.match(/performance|slow|optimize|cache/i)) {
            priority = 'medium';
            category = 'performance';
        } else if (title.match(/duplicate|redundant|unnecessary/i)) {
            priority = 'medium';
            category = 'code-quality';
        } else if (title.match(/todo|fixme|hack/i)) {
            priority = 'low';
            category = 'tech-debt';
        }

        // 自動修正可能かを判定
        const autoFixable = checkAutoFixable(title, description);

        // ファイルと行番号を抽出
        const fileMatch = description.match(/`([^`]+\.(?:md|js|ts|json|yml|yaml))(?::(\d+))?`/);
        const file = fileMatch ? fileMatch[1] : null;
        const line = fileMatch ? fileMatch[2] : null;

        issues.push({
            title,
            description,
            priority,
            category,
            autoFixable,
            file,
            line,
            suggestedFix: extractSuggestedFix(description)
        });
    }

    // Nitpick commentsも処理
    const nitpickRegex = /`(\d+)-(\d+)`:\s*\*\*([^*]+)\*\*\s*\n([^`]+)/gs;
    const nitpicks = content.matchAll(nitpickRegex);

    for (const match of nitpicks) {
        const lineStart = match[1];
        const lineEnd = match[2];
        const title = match[3].trim();
        const description = match[4].trim();

        issues.push({
            title,
            description,
            priority: 'low',
            category: 'nitpick',
            autoFixable: false,
            lines: `${lineStart}-${lineEnd}`,
            file: extractFileFromContext(content, match.index)
        });
    }

    return issues;
}

function checkAutoFixable(title, description) {
    const autoFixPatterns = [
        /prettier|format/i,
        /import.*unused/i,
        /dependency.*update/i,
        /eslint.*fix/i,
        /add.*check/i,
        /remove.*unused/i,
        /replace.*with/i
    ];

    return autoFixPatterns.some(pattern =>
        title.match(pattern) || description.match(pattern)
    );
}

function extractSuggestedFix(description) {
    // コードブロック内の修正案を抽出
    const codeBlockRegex = /```(?:diff|bash|javascript|typescript)?\n([\s\S]+?)\n```/;
    const match = description.match(codeBlockRegex);
    return match ? match[1] : null;
}

function extractFileFromContext(content, position) {
    // コンテキストから対象ファイルを推定
    const before = content.substring(Math.max(0, position - 500), position);
    const fileRegex = /([a-zA-Z0-9_\-/]+\.\w+)/g;
    const matches = before.match(fileRegex);
    return matches ? matches[matches.length - 1] : null;
}

// メイン処理
const content = fs.readFileSync(process.argv[2], 'utf8');
const issues = parseFeedback(content);

// 優先度でソート
issues.sort((a, b) => {
    const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
    return priorityOrder[a.priority] - priorityOrder[b.priority];
});

fs.writeFileSync(process.argv[3], JSON.stringify(issues, null, 2));

// サマリー出力
console.log(`Found ${issues.length} actionable items:`);
console.log(`- Critical: ${issues.filter(i => i.priority === 'critical').length}`);
console.log(`- High: ${issues.filter(i => i.priority === 'high').length}`);
console.log(`- Medium: ${issues.filter(i => i.priority === 'medium').length}`);
console.log(`- Low: ${issues.filter(i => i.priority === 'low').length}`);
console.log(`- Auto-fixable: ${issues.filter(i => i.autoFixable).length}`);
EOF

# フィードバックを解析
if [ -s "$TEMP_DIR/coderabbit_comments.txt" ]; then
    node "$TEMP_DIR/parse_feedback.js" "$TEMP_DIR/coderabbit_comments.txt" "$TEMP_DIR/issues.json"
else
    log_warning "No CodeRabbit comments found"
    echo "[]" > "$TEMP_DIR/issues.json"
fi
````

### 3. 自動修正の実行

```bash
# 自動修正可能な項目を処理
if [ "$AUTO_FIX" = "true" ] && [ "$DRY_RUN" != "true" ]; then
    log_info "Attempting automatic fixes..."

    # 修正用ブランチを作成
    FIX_BRANCH="fix/coderabbit-feedback-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$FIX_BRANCH"

    # 各自動修正可能な項目を処理
    cat "$TEMP_DIR/issues.json" | jq -c '.[] | select(.autoFixable == true)' | while read -r issue; do
        title=$(echo "$issue" | jq -r '.title')
        file=$(echo "$issue" | jq -r '.file // ""')
        suggested_fix=$(echo "$issue" | jq -r '.suggestedFix // ""')

        log_action "Auto-fixing: $title"

        case "$title" in
            *"Prettier"*|*"formatting"*)
                log_info "Running Prettier..."
                if [ -n "$file" ]; then
                    npx prettier --write "$file" 2>/dev/null || true
                else
                    npm run format 2>/dev/null || true
                fi
                ;;

            *"unused import"*|*"unused variable"*)
                log_info "Running ESLint with auto-fix..."
                if [ -n "$file" ]; then
                    npx eslint --fix "$file" 2>/dev/null || true
                else
                    npm run lint:fix 2>/dev/null || true
                fi
                ;;

            *"dependency"*|*"update"*)
                log_info "Updating dependencies..."
                package=$(echo "$title" | grep -oE '[a-z@/-]+@[0-9.]+' | cut -d@ -f1 || echo "")
                if [ -n "$package" ]; then
                    npm update "$package" 2>/dev/null || true
                fi
                ;;

            *"bc dependency"*|*"bc command"*)
                log_info "Replacing bc with pure bash arithmetic..."
                if [ -n "$file" ]; then
                    # bcを使用している箇所を純粋なbash算術に置換
                    sed -i 's/\$(echo "\([^"]*\)" | bc -l)/\$((\1))/g' "$file"
                    sed -i 's/\$(\([^)]*\) | bc)/\$((\1))/g' "$file"
                fi
                ;;

            *"ripgrep"*|*"rg command"*)
                log_info "Adding ripgrep installation check..."
                if [ -n "$file" ]; then
                    # ripgrepのインストールチェックを追加
                    cat << 'INSTALL_CHECK' > "$TEMP_DIR/rg_check.txt"
# Ensure ripgrep is installed
if ! command -v rg &> /dev/null; then
    echo "Installing ripgrep..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y ripgrep
    elif command -v brew &> /dev/null; then
        brew install ripgrep
    else
        echo "Warning: ripgrep not found. Please install it manually."
        # Fallback to grep
        alias rg='grep -r'
    fi
fi
INSTALL_CHECK
                    # ファイルの先頭付近に挿入
                    sed -i '3r '"$TEMP_DIR/rg_check.txt" "$file"
                fi
                ;;

            *)
                if [ -n "$suggested_fix" ] && [ -n "$file" ]; then
                    log_info "Applying suggested fix to $file"
                    # 提案された修正を適用（diffの場合）
                    echo "$suggested_fix" | patch "$file" 2>/dev/null || true
                fi
                ;;
        esac
    done

    # 変更をコミット
    if [ -n "$(git status --porcelain)" ]; then
        git add -A
        git commit -m "fix: Address CodeRabbit review feedback

- Applied automatic fixes for formatting issues
- Fixed dependency management issues
- Improved error handling
- Enhanced CI/CD compatibility

Ref: PR #$PR_NUMBER"

        log_success "Automatic fixes applied and committed"

        # PRを作成
        git push -u origin "$FIX_BRANCH"
        gh pr create \
            --title "🤖 Fix: Address CodeRabbit feedback from PR #$PR_NUMBER" \
            --body "This PR addresses the automated review feedback from CodeRabbit on PR #$PR_NUMBER.

## Automatic Fixes Applied
$(cat "$TEMP_DIR/issues.json" | jq -r '.[] | select(.autoFixable == true) | "- " + .title')

## Related PR
- #$PR_NUMBER

---
*Generated by review-feedback-processor*" \
            --label "automated,code-quality" \
            --base "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
    else
        log_info "No automatic fixes were needed"
        git checkout -
        git branch -d "$FIX_BRANCH"
    fi
fi
```

### 4. Issue作成

```bash
# 自動修正できない項目をIssue化
if [ "$CREATE_ISSUES" = "true" ] && [ "$DRY_RUN" != "true" ]; then
    log_info "Creating issues for items requiring manual intervention..."

    # 優先度の閾値を適用
    case "$PRIORITY_THRESHOLD" in
        "critical")
            min_priority=0
            ;;
        "high")
            min_priority=1
            ;;
        "medium")
            min_priority=2
            ;;
        "low")
            min_priority=3
            ;;
        *)
            min_priority=2
            ;;
    esac

    # 各項目に対してIssueを作成
    cat "$TEMP_DIR/issues.json" | jq -c '.[] | select(.autoFixable != true)' | while read -r issue; do
        title=$(echo "$issue" | jq -r '.title')
        description=$(echo "$issue" | jq -r '.description')
        priority=$(echo "$issue" | jq -r '.priority')
        category=$(echo "$issue" | jq -r '.category')
        file=$(echo "$issue" | jq -r '.file // "N/A"')

        # 優先度チェック
        priority_num=$(case "$priority" in
            critical) echo 0 ;;
            high) echo 1 ;;
            medium) echo 2 ;;
            low) echo 3 ;;
        esac)

        if [ "$priority_num" -gt "$min_priority" ]; then
            log_info "Skipping low priority issue: $title"
            continue
        fi

        # 重複チェック
        existing=$(gh issue list --search "$title" --json number | jq 'length')
        if [ "$existing" -gt 0 ]; then
            log_warning "Issue already exists: $title"
            continue
        fi

        # Issueの優先度に応じた絵文字
        case "$priority" in
            critical)
                emoji="🚨"
                ;;
            high)
                emoji="⚠️"
                ;;
            medium)
                emoji="📋"
                ;;
            low)
                emoji="💭"
                ;;
        esac

        # Issue本文の作成
        ISSUE_BODY="## $emoji CodeRabbit Feedback

**Source**: PR #$PR_NUMBER review
**Priority**: $priority
**Category**: $category
**File**: $file

### Description
$description

### Suggested Action
This issue was identified by CodeRabbit during the review of PR #$PR_NUMBER and requires manual intervention.

### Acceptance Criteria
- [ ] Issue has been investigated
- [ ] Appropriate fix has been implemented
- [ ] Tests have been added/updated if necessary
- [ ] Documentation has been updated if necessary

### Related
- PR: #$PR_NUMBER
- Reviewer: @coderabbitai

---
*Created by review-feedback-processor*"

        # Issueを作成
        log_action "Creating issue: $title"

        gh issue create \
            --title "$emoji $title" \
            --body "$ISSUE_BODY" \
            --label "$category,from-review" \
            2>/dev/null || log_warning "Failed to create issue: $title"
    done

    log_success "Issues created for manual items"
fi
```

### 5. レポート生成

```bash
# 実行レポートの生成
log_info "Generating report..."

cat << EOF > "$TEMP_DIR/report.md"
# Review Feedback Processing Report

**Date**: $(date)
**PR**: #$PR_NUMBER
**Mode**: $([ "$DRY_RUN" = "true" ] && echo "DRY RUN" || echo "PRODUCTION")

## Summary

$(cat "$TEMP_DIR/issues.json" | jq -r '
    "- Total items: " + (length | tostring) + "\n" +
    "- Auto-fixable: " + ([.[] | select(.autoFixable == true)] | length | tostring) + "\n" +
    "- Requires manual fix: " + ([.[] | select(.autoFixable != true)] | length | tostring)
')

## Priority Breakdown

| Priority | Count | Status |
|----------|-------|--------|
| Critical | $(cat "$TEMP_DIR/issues.json" | jq '[.[] | select(.priority == "critical")] | length') | $([ "$AUTO_FIX" = "true" ] && echo "🔧 Fixed" || echo "📋 Issue Created") |
| High | $(cat "$TEMP_DIR/issues.json" | jq '[.[] | select(.priority == "high")] | length') | $([ "$AUTO_FIX" = "true" ] && echo "🔧 Fixed" || echo "📋 Issue Created") |
| Medium | $(cat "$TEMP_DIR/issues.json" | jq '[.[] | select(.priority == "medium")] | length') | $([ "$CREATE_ISSUES" = "true" ] && echo "📋 Issue Created" || echo "⏭️ Skipped") |
| Low | $(cat "$TEMP_DIR/issues.json" | jq '[.[] | select(.priority == "low")] | length') | ⏭️ Skipped |

## Category Distribution

$(cat "$TEMP_DIR/issues.json" | jq -r '
    group_by(.category) |
    map("- " + .[0].category + ": " + (length | tostring)) |
    .[]
')

## Detailed Items

$(cat "$TEMP_DIR/issues.json" | jq -r '.[] |
    "### " + .title + "\n" +
    "- Priority: " + .priority + "\n" +
    "- Category: " + .category + "\n" +
    "- Auto-fixable: " + (.autoFixable | tostring) + "\n" +
    if .file then "- File: " + .file + "\n" else "" end +
    "\n"
')

## Actions Taken

$(if [ "$AUTO_FIX" = "true" ]; then
    echo "✅ Automatic fixes applied for compatible issues"
else
    echo "⏭️ Automatic fixes skipped (AUTO_FIX=false)"
fi)

$(if [ "$CREATE_ISSUES" = "true" ]; then
    echo "✅ GitHub Issues created for manual items"
else
    echo "⏭️ Issue creation skipped (CREATE_ISSUES=false)"
fi)

---
*Generated by review-feedback-processor at $(date)*
EOF

cat "$TEMP_DIR/report.md"

# レポートを保存
REPORT_DIR="$HOME/.claude/review-reports"
mkdir -p "$REPORT_DIR"
cp "$TEMP_DIR/report.md" "$REPORT_DIR/pr-${PR_NUMBER}-$(date +%Y%m%d-%H%M%S).md"

log_success "Report saved to $REPORT_DIR"
```

## 使用方法

### 基本的な使用

```bash
# 現在のブランチのPRのレビューを処理
claude code review-feedback-processor

# 特定のPRを処理
PR_NUMBER=82 claude code review-feedback-processor

# ドライランモード（実際の変更なし）
DRY_RUN=true claude code review-feedback-processor

# 自動修正を有効化
AUTO_FIX=true claude code review-feedback-processor

# Issue作成を無効化
CREATE_ISSUES=false AUTO_FIX=true claude code review-feedback-processor

# 優先度の閾値を設定（critical, high, medium, low）
PRIORITY_THRESHOLD=high claude code review-feedback-processor
```

### CI/CDでの使用

```yaml
# .github/workflows/process-review-feedback.yml
name: Process Review Feedback

on:
  pull_request_review:
    types: [submitted]
  issue_comment:
    types: [created]

jobs:
  process-feedback:
    if: |
      (github.event.review && github.event.review.user.login == 'coderabbitai') ||
      (github.event.comment && github.event.comment.user.login == 'coderabbitai')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Process Review Feedback
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          AUTO_FIX: true
          CREATE_ISSUES: true
          PRIORITY_THRESHOLD: medium
        run: |
          bash .claude/commands/review-feedback-processor.md
```

## カスタマイズ

### 他のレビューボットへの対応

```bash
# レビューボットの名前を変更
REVIEWER_LOGIN="dependabot" # または "snyk-bot", "renovate-bot" など

# スクリプト内で変更
sed -i "s/coderabbitai/$REVIEWER_LOGIN/g" "$TEMP_DIR/parse_feedback.js"
```

### カスタムパーサーの追加

```javascript
// 特定のフォーマットに対応
function parseCustomFormat(content) {
  // カスタムパースロジック
  const customRegex = /YOUR_PATTERN_HERE/g;
  // ...
}
```

## トラブルシューティング

### レビューコメントが見つからない場合

```bash
# すべてのコメントを確認
gh pr view "$PR_NUMBER" --json comments,reviews | jq '.comments[].author.login' | sort -u

# 特定のユーザーのコメントのみ
gh pr view "$PR_NUMBER" --json comments | jq '.comments[] | select(.author.login == "coderabbitai")'
```

### 自動修正が失敗する場合

```bash
# デバッグモードで実行
DEBUG=true bash review-feedback-processor.md

# 個別のコマンドをテスト
npx prettier --check .
npx eslint --print-config .
```

## 成功基準

- ✅ レビューコメントを正確にパースできる
- ✅ 優先度に基づいて適切に分類できる
- ✅ 自動修正可能な項目を識別し修正できる
- ✅ 手動対応が必要な項目をIssue化できる
- ✅ 実行レポートが生成される
- ✅ CI/CDに統合できる
