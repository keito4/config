# issue-review

## 目的

GitHubのIssueを一覧化し、現在のステータスを確認して必要に応じてクローズまたはアップデートを行う。
定期的なIssue棚卸しによって、プロジェクトの健全性を維持する。

## 実行手順

### 1. 全Issueの取得と状態確認

```bash
echo "=== Open Issues ==="
gh issue list --state open --limit 100 --json number,title,state,assignees,labels,createdAt,updatedAt,body | jq -r '.[] | "Issue #\(.number): \(.title)\n  State: \(.state)\n  Assignees: \(.assignees | map(.login) | join(", "))\n  Labels: \(.labels | map(.name) | join(", "))\n  Created: \(.createdAt)\n  Updated: \(.updatedAt)\n  Body: \(.body[:100])...\n"'

echo -e "\n=== Closed Issues (Recent 30) ==="
gh issue list --state closed --limit 30 --json number,title,state,closedAt,labels | jq -r '.[] | "Issue #\(.number): \(.title)\n  Closed: \(.closedAt)\n  Labels: \(.labels | map(.name) | join(", "))\n"'
```

### 2. 古いIssueの特定

```bash
# 30日以上更新されていないIssueを特定
echo "=== Stale Issues (30+ days without update) ==="
gh issue list --state open --limit 100 --json number,title,updatedAt | jq -r --arg date "$(date -d '30 days ago' -Iseconds 2>/dev/null || date -v-30d -Iseconds)" '.[] | select(.updatedAt < $date) | "Issue #\(.number): \(.title)\n  Last updated: \(.updatedAt)"'
```

### 3. 重複・関連Issueの検出

```bash
# タイトルの類似性でグループ化（手動レビューが必要）
echo "=== Potential Duplicate Issues ==="
gh issue list --state open --limit 100 --json number,title | jq -r '.[] | "\(.number):\(.title)"' | sort -t: -k2 | awk -F: '{
    if (prev && match(tolower($2), substr(tolower(prev), 1, 10))) {
        print "Potential duplicate: #" prevnum " and #" $1
        print "  - " prev
        print "  - " $2
    }
    prev=$2; prevnum=$1
}'
```

### 4. ラベル未設定のIssueを検出

```bash
# ラベルが設定されていないIssueを特定
echo "=== Issues without labels ==="
gh issue list --state open --limit 100 --json number,title,labels | jq -r '.[] | select(.labels | length == 0) | "Issue #\(.number): \(.title)"'
```

### 5. アサイン未設定のIssueを検出

```bash
# 担当者が設定されていないIssueを特定
echo "=== Unassigned Issues ==="
gh issue list --state open --limit 100 --json number,title,assignees | jq -r '.[] | select(.assignees | length == 0) | "Issue #\(.number): \(.title)"'
```

### 6. PRとリンクされていないIssueを検出

```bash
# PRとリンクされていないIssueを検出（APIを使用）
echo "=== Issues without linked PRs ==="
for issue_num in $(gh issue list --state open --limit 100 --json number | jq -r '.[].number'); do
    pr_count=$(gh api "/repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/$issue_num/timeline" | jq '[.[] | select(.event == "cross-referenced" and .source.issue.pull_request)] | length')
    if [ "$pr_count" -eq 0 ]; then
        gh issue view "$issue_num" --json number,title | jq -r '"Issue #\(.number): \(.title)"'
    fi
done
```

### 7. 対応アクション実行

```bash
# インタラクティブにIssueの処理を選択
echo "=== Issue Management Actions ==="

# 例: 古いIssueにstaleラベルを追加
read -p "Add 'stale' label to issues older than 30 days? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for issue_num in $(gh issue list --state open --limit 100 --json number,updatedAt | jq -r --arg date "$(date -d '30 days ago' -Iseconds 2>/dev/null || date -v-30d -Iseconds)" '.[] | select(.updatedAt < $date) | .number'); do
        gh issue edit "$issue_num" --add-label "stale"
        echo "Added 'stale' label to issue #$issue_num"
    done
fi

# 例: 重複Issueのクローズ（手動確認後）
echo -e "\nReview the potential duplicates above and close if needed:"
echo "Example: gh issue close <issue-number> --comment 'Duplicate of #<other-issue-number>'"

# 例: ラベル未設定のIssueにデフォルトラベルを追加
read -p "Add 'needs-triage' label to unlabeled issues? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for issue_num in $(gh issue list --state open --limit 100 --json number,labels | jq -r '.[] | select(.labels | length == 0) | .number'); do
        gh issue edit "$issue_num" --add-label "needs-triage"
        echo "Added 'needs-triage' label to issue #$issue_num"
    done
fi
```

### 8. レポート生成

```bash
# Issue管理レポートの生成
echo "=== Issue Management Report ==="
TOTAL_OPEN=$(gh issue list --state open --limit 100 --json number | jq 'length')
TOTAL_CLOSED_THIS_MONTH=$(gh issue list --state closed --limit 100 --json closedAt | jq --arg date "$(date -d '30 days ago' -Iseconds 2>/dev/null || date -v-30d -Iseconds)" '[.[] | select(.closedAt >= $date)] | length')
STALE_COUNT=$(gh issue list --state open --limit 100 --json updatedAt | jq --arg date "$(date -d '30 days ago' -Iseconds 2>/dev/null || date -v-30d -Iseconds)" '[.[] | select(.updatedAt < $date)] | length')
UNLABELED_COUNT=$(gh issue list --state open --limit 100 --json labels | jq '[.[] | select(.labels | length == 0)] | length')
UNASSIGNED_COUNT=$(gh issue list --state open --limit 100 --json assignees | jq '[.[] | select(.assignees | length == 0)] | length')

cat << EOF
Summary Report - $(date)
================================
Total Open Issues: $TOTAL_OPEN
Closed This Month: $TOTAL_CLOSED_THIS_MONTH
Stale Issues (30+ days): $STALE_COUNT
Unlabeled Issues: $UNLABELED_COUNT
Unassigned Issues: $UNASSIGNED_COUNT

Recommended Actions:
$([ $STALE_COUNT -gt 0 ] && echo "- Review and update $STALE_COUNT stale issues")
$([ $UNLABELED_COUNT -gt 0 ] && echo "- Add labels to $UNLABELED_COUNT issues")
$([ $UNASSIGNED_COUNT -gt 0 ] && echo "- Assign owners to $UNASSIGNED_COUNT issues")
EOF
```

## 成功基準

- ✅ すべてのOpen Issueの状態が把握できている
- ✅ 30日以上更新されていないIssueが識別されている
- ✅ ラベル・アサイン未設定のIssueが0件、または適切に処理されている
- ✅ 重複の可能性があるIssueがレビューされている
- ✅ Issue管理レポートが生成されている

## トラブルシューティング

### GitHub CLIが使用できない場合

```bash
# GitHub CLIのインストール
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh -y

# 認証
gh auth login
```

### APIレート制限に達した場合

```bash
# レート制限の確認
gh api rate_limit | jq '.rate'

# 待機時間の計算
RESET_TIME=$(gh api rate_limit | jq -r '.rate.reset')
WAIT_SECONDS=$((RESET_TIME - $(date +%s)))
echo "Rate limit will reset in $((WAIT_SECONDS / 60)) minutes"
```

### jqコマンドが使用できない場合

```bash
# jqのインストール
sudo apt-get update && sudo apt-get install -y jq
# または
brew install jq  # macOS
```

## 自動化オプション

GitHub Actionsで定期実行する場合:

```yaml
# .github/workflows/issue-review.yml
name: Weekly Issue Review
on:
  schedule:
    - cron: '0 9 * * 1'  # 毎週月曜日9時
  workflow_dispatch:

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Issue Review
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          bash .claude/commands/issue-review.md
```
