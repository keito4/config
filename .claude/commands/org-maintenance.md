---
description: Organization-wide maintenance - health checks and updates across all repositories
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(node:*), Bash(jq:*), Bash(find:*), Bash(test:*), Bash(ls:*), Bash(grep:*), Bash(cat:*), Bash(echo:*), Bash(date:*), Bash(curl:*), Task, Skill
argument-hint: '[--org ORG] [--mode full|quick|check-only] [--filter PATTERN] [--create-prs]'
---

# Organization Maintenance Workflow

組織配下の全リポジトリに対して包括的なメンテナンスを実行します。
各リポジトリの健全性を一括チェックし、レポートを生成します。

## Overview

以下のカテゴリを全リポジトリ横断で実行します：

1. **Inventory** - リポジトリの棚卸しと分類
2. **Health Check** - 各リポジトリの健全性チェック
3. **Security** - 組織全体のセキュリティ状況
4. **Standardization** - 設定の標準化状況
5. **Actions** - 修正アクションの実行

## Execution Modes

| Mode       | 説明                               | 実行内容                 |
| ---------- | ---------------------------------- | ------------------------ |
| full       | 全リポジトリの更新とチェックを実行 | チェック + 修正 + PR作成 |
| quick      | 重要なチェックのみ実行（変更なし） | チェックのみ             |
| check-only | 状態確認のみ（変更なし）           | 読み取り専用             |

## Step 1: Parse Arguments and Initialize

引数から設定を読み取る：

- `--org ORG`: 対象 GitHub Organization（デフォルト: リポジトリオーナーから自動検出）
- `--mode MODE`: 実行モード（デフォルト: `full`）
- `--filter PATTERN`: リポジトリ名のフィルタ（glob パターン）
- `--create-prs`: 修正が必要な場合に各リポジトリで PR を作成
- `--skip-archived`: アーカイブされたリポジトリをスキップ（デフォルト: true）
- `--min-activity DAYS`: 指定日数以内に更新されたリポジトリのみ対象（デフォルト: 90）

デフォルト設定:

```
ORG=<auto-detect>
MODE=full
FILTER=*
CREATE_PRS=false
SKIP_ARCHIVED=true
MIN_ACTIVITY=90
```

初期化メッセージを表示:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 Organization Maintenance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Organization: {ORG}
Mode: {MODE}
Filter: {FILTER}
Create PRs: {CREATE_PRS}

Starting organization-wide maintenance...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Inventory - リポジトリの棚卸し

### 2.1 リポジトリ一覧の取得

```bash
gh repo list "$ORG" \
  --json name,isArchived,pushedAt,isPrivate,defaultBranchRef,languages,hasIssuesEnabled \
  --limit 100 \
  --jq '.[] | select(.isArchived == false)'
```

### 2.2 アクティビティによるフィルタリング

MIN_ACTIVITY 日以内に更新されたリポジトリのみを対象にする:

```bash
CUTOFF_DATE=$(date -u -v-${MIN_ACTIVITY}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
              date -u -d "${MIN_ACTIVITY} days ago" +%Y-%m-%dT%H:%M:%SZ)
```

### 2.3 リポジトリの分類

各リポジトリを以下のカテゴリに分類:

| カテゴリ           | 判定基準                                    |
| ------------------ | ------------------------------------------- |
| **Application**    | package.json + src/ or app/ が存在          |
| **Infrastructure** | terraform/ or .tf ファイルが存在            |
| **Library**        | package.json + main/exports フィールドあり  |
| **Config**         | .devcontainer/ or .github/workflows/ が主体 |
| **Other**          | 上記に該当しない                            |

**結果:**

```
📦 Repository Inventory
├── Total: 25 repositories
├── Active (90d): 12 repositories
├── Archived: 3 repositories (skipped)
└── Categories:
    ├── Application: 8
    ├── Infrastructure: 2
    ├── Library: 1
    └── Config: 1
```

## Step 3: Health Check - 各リポジトリの健全性

各アクティブリポジトリに対して以下をチェック（GitHub API 経由、クローン不要）:

### 3.1 DevContainer 設定チェック

```bash
for repo in $REPOS; do
  # devcontainer.json の存在確認
  DEVCONTAINER=$(gh api "repos/$ORG/$repo/contents/.devcontainer/devcontainer.json" \
    --jq '.content' 2>/dev/null | base64 -d 2>/dev/null)

  if [ -n "$DEVCONTAINER" ]; then
    # config-base イメージのバージョン確認
    IMAGE_VERSION=$(echo "$DEVCONTAINER" | grep -o 'config-base:[v0-9.]*' | head -1)
    echo "$repo: $IMAGE_VERSION"
  else
    echo "$repo: DevContainer 未設定"
  fi
done
```

### 3.2 CI/CD 設定チェック

```bash
for repo in $REPOS; do
  WORKFLOWS=$(gh api "repos/$ORG/$repo/contents/.github/workflows" \
    --jq '.[].name' 2>/dev/null)

  # 必須ワークフローの存在確認
  HAS_CI=$(echo "$WORKFLOWS" | grep -c "ci.yml")
  HAS_SECURITY=$(echo "$WORKFLOWS" | grep -c "security.yml")
  HAS_CLAUDE=$(echo "$WORKFLOWS" | grep -c "claude.yml")
done
```

### 3.3 ブランチ保護チェック

```bash
for repo in $REPOS; do
  PROTECTION=$(gh api "repos/$ORG/$repo/branches/main/protection" 2>/dev/null)
  if [ $? -eq 0 ]; then
    REVIEWS=$(echo "$PROTECTION" | jq '.required_pull_request_reviews.required_approving_review_count // 0')
    STATUS_CHECKS=$(echo "$PROTECTION" | jq '.required_status_checks != null')
    echo "$repo: reviews=$REVIEWS, status_checks=$STATUS_CHECKS"
  else
    echo "$repo: ⚠️ ブランチ保護なし"
  fi
done
```

### 3.4 依存関係の脆弱性チェック

```bash
for repo in $REPOS; do
  ALERTS=$(gh api "repos/$ORG/$repo/dependabot/alerts?state=open&severity=critical,high" \
    --jq 'length' 2>/dev/null || echo "N/A")
  echo "$repo: open alerts=$ALERTS"
done
```

### 3.5 標準ファイル存在チェック

各リポジトリで以下のファイルの存在を確認:

| ファイル                           | 確認方法                                                            |
| ---------------------------------- | ------------------------------------------------------------------- |
| `CLAUDE.md` or `AGENTS.md`         | `gh api repos/$ORG/$repo/contents/CLAUDE.md`                        |
| `.github/pull_request_template.md` | `gh api repos/$ORG/$repo/contents/.github/pull_request_template.md` |
| `.github/ISSUE_TEMPLATE/`          | `gh api repos/$ORG/$repo/contents/.github/ISSUE_TEMPLATE`           |
| `SECURITY.md`                      | `gh api repos/$ORG/$repo/contents/SECURITY.md`                      |
| `.github/dependabot.yml`           | `gh api repos/$ORG/$repo/contents/.github/dependabot.yml`           |
| `.editorconfig`                    | `gh api repos/$ORG/$repo/contents/.editorconfig`                    |

### 3.6 GitHub Actions コスト概算

```bash
# 直近30日のワークフロー実行統計
for repo in $REPOS; do
  THIRTY_DAYS_AGO=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
                    date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)

  RUNS=$(gh api "repos/$ORG/$repo/actions/runs?created=>$THIRTY_DAYS_AGO" \
    --jq '.total_count' 2>/dev/null || echo "0")

  echo "$repo: $RUNS runs (30d)"
done
```

**結果:**

リポジトリごとの健全性スコアを算出（0-100）:

| 項目           | 重み | 100点の条件                       |
| -------------- | ---- | --------------------------------- |
| DevContainer   | 15   | config-base 最新版使用            |
| CI/CD          | 20   | ci.yml + security.yml 存在        |
| ブランチ保護   | 20   | レビュー必須 + ステータスチェック |
| 脆弱性         | 20   | critical/high アラート 0件        |
| 標準ファイル   | 15   | 全ファイル存在                    |
| Actions コスト | 10   | 月間実行数が適正範囲              |

## Step 4: Security - 組織全体のセキュリティ

### 4.1 Dependabot アラートサマリ

```bash
TOTAL_CRITICAL=0
TOTAL_HIGH=0

for repo in $REPOS; do
  CRITICAL=$(gh api "repos/$ORG/$repo/dependabot/alerts?state=open&severity=critical" \
    --jq 'length' 2>/dev/null || echo "0")
  HIGH=$(gh api "repos/$ORG/$repo/dependabot/alerts?state=open&severity=high" \
    --jq 'length' 2>/dev/null || echo "0")

  TOTAL_CRITICAL=$((TOTAL_CRITICAL + CRITICAL))
  TOTAL_HIGH=$((TOTAL_HIGH + HIGH))

  [ "$CRITICAL" -gt 0 ] && echo "🔴 $repo: CRITICAL=$CRITICAL"
  [ "$HIGH" -gt 0 ] && echo "🟡 $repo: HIGH=$HIGH"
done

echo "組織全体: CRITICAL=$TOTAL_CRITICAL, HIGH=$TOTAL_HIGH"
```

### 4.2 シークレットスキャンアラート

```bash
for repo in $REPOS; do
  SECRET_ALERTS=$(gh api "repos/$ORG/$repo/secret-scanning/alerts?state=open" \
    --jq 'length' 2>/dev/null || echo "N/A")
  [ "$SECRET_ALERTS" != "0" ] && [ "$SECRET_ALERTS" != "N/A" ] && \
    echo "🔴 $repo: シークレット漏洩 $SECRET_ALERTS 件"
done
```

### 4.3 組織セキュリティ設定

```bash
# 2FA 必須化の確認
ORG_SETTINGS=$(gh api "orgs/$ORG" --jq '{two_factor: .two_factor_requirement_enabled}' 2>/dev/null)
echo "2FA 必須: $(echo "$ORG_SETTINGS" | jq -r '.two_factor')"
```

## Step 5: Standardization - 設定の標準化

### 5.1 config-base バージョン統一状況

全リポジトリの config-base バージョンを比較:

```
config-base バージョン分布:
├── v1.96.0 (最新): 5 repos ✅
├── v1.95.0: 3 repos ⚠️
├── v1.90.0: 1 repo ⚠️
└── 未使用: 3 repos
```

### 5.2 GitHub Actions バージョン統一状況

主要アクションのバージョン分布を確認:

```
actions/checkout バージョン:
├── v4: 10 repos ✅
├── v3: 2 repos ⚠️ (更新推奨)
```

### 5.3 CLAUDE.md / AGENTS.md 統一状況

```
CLAUDE.md 状況:
├── AGENTS.md symlink: 3 repos ✅
├── 通常ファイル: 5 repos ⚠️
├── 未設定: 4 repos ❌
```

## Step 6: Actions - 修正アクションの実行 (full mode only)

### 6.1 優先度の決定

検出された問題を優先度で分類:

| 優先度      | 条件                               | アクション                 |
| ----------- | ---------------------------------- | -------------------------- |
| 🔴 Critical | シークレット漏洩、CRITICAL 脆弱性  | 即時対応 Issue 作成        |
| 🟡 High     | ブランチ保護なし、HIGH 脆弱性      | Issue 作成                 |
| 🟢 Medium   | 古い config-base、標準ファイル不足 | PR 作成（--create-prs 時） |
| ⚪ Low      | Actions バージョン旧、コスト最適化 | レポートのみ               |

### 6.2 Issue の自動作成（Critical/High）

```bash
for issue in $CRITICAL_ISSUES; do
  REPO=$(echo "$issue" | jq -r '.repo')
  TITLE=$(echo "$issue" | jq -r '.title')
  BODY=$(echo "$issue" | jq -r '.body')

  # 重複チェック
  EXISTING=$(gh issue list --repo "$ORG/$REPO" --state open \
    --search "$TITLE" --json number --jq '.[0].number' 2>/dev/null)

  if [ -z "$EXISTING" ]; then
    gh issue create --repo "$ORG/$REPO" \
      --title "$TITLE" \
      --label "security,P0: Critical" \
      --body "$BODY"
  fi
done
```

### 6.3 config-base 更新 PR の作成（--create-prs 時）

古い config-base を使用しているリポジトリに対して更新 PR を作成:

```bash
for repo in $OUTDATED_REPOS; do
  # リポジトリをクローン
  TMPDIR=$(mktemp -d)
  gh repo clone "$ORG/$repo" "$TMPDIR" -- --depth 1

  cd "$TMPDIR"
  git checkout -b chore/update-config-base

  # devcontainer.json のバージョンを更新
  # （実際の更新ロジックは /config-base-sync-update に委譲）

  git add .devcontainer/
  git commit -m "chore: config-base を $LATEST_VERSION に更新"
  git push -u origin chore/update-config-base

  gh pr create \
    --title "chore: config-base を $LATEST_VERSION に更新" \
    --body "org-maintenance による自動更新"

  cd -
  rm -rf "$TMPDIR"
done
```

## Step 7: Generate Organization Summary Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Organization Maintenance Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Organization: {ORG}
Date: {DATE}
Repositories Checked: {COUNT}

## Inventory
├── Total: {TOTAL} repositories
├── Active: {ACTIVE} (last {MIN_ACTIVITY} days)
├── Archived: {ARCHIVED} (skipped)
└── Categories: App={APP}, Infra={INFRA}, Lib={LIB}, Config={CFG}

## Health Scores
├── 🟢 90-100: {COUNT_GREEN} repos
├── 🟡 70-89:  {COUNT_YELLOW} repos
├── 🔴 0-69:   {COUNT_RED} repos
└── Average: {AVG_SCORE}/100

## Top Issues
| Repo | Score | Issues |
| --- | --- | --- |
| repo-a | 45/100 | ブランチ保護なし, CRITICAL 脆弱性 2件 |
| repo-b | 65/100 | config-base 旧バージョン, CI 未設定 |

## Security Overview
├── Dependabot: CRITICAL={CRIT}, HIGH={HIGH}
├── Secret Scanning: {SECRET_ALERTS} alerts
└── 2FA: {2FA_STATUS}

## Standardization
├── config-base 最新: {LATEST_COUNT}/{ACTIVE} repos
├── CLAUDE.md symlink: {SYMLINK_COUNT}/{ACTIVE} repos
├── PR Template: {PR_TMPL_COUNT}/{ACTIVE} repos
└── Branch Protection: {PROTECTED_COUNT}/{ACTIVE} repos

## Actions Taken
├── Issues Created: {ISSUES_CREATED}
├── PRs Created: {PRS_CREATED}
└── Alerts: {ALERTS_SENT}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Detailed Repository Scores

| Repo | Score | DevContainer | CI/CD | Protection | Vulns | Files | Cost |
| --- | --- | --- | --- | --- | --- | --- | --- |
| config | 95 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| app-a | 70 | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ✅ |
| app-b | 45 | ❌ | ⚠️ | ❌ | 🔴 | ❌ | ⚠️ |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Action Items (Priority Order)

### 🔴 Immediate
1. {repo}: {issue}
   Fix: {recommendation}

### 🟡 Soon
2. {repo}: {issue}
   Run: /config-base-sync-update

### 🟢 Recommended
3. {repo}: {issue}
   Run: /repo-maintenance

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Organization Maintenance Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:
1. Address 🔴 Critical issues immediately
2. Plan 🟡 High priority items for this sprint
3. Schedule /repo-maintenance for low-scoring repositories

Run regularly:
  /org-maintenance --mode quick    # Weekly quick check
  /org-maintenance --mode full     # Monthly full maintenance
```

## Step 8: Per-Repository Detail (Optional)

`--verbose` フラグが指定された場合、各リポジトリの詳細レポートも出力:

```
━━━ {REPO_NAME} (Score: {SCORE}/100) ━━━
├── DevContainer: {STATUS} ({VERSION})
├── CI/CD: {WORKFLOWS_LIST}
├── Branch Protection: {DETAILS}
├── Vulnerabilities: CRITICAL={C} HIGH={H} MEDIUM={M}
├── Standard Files: {MISSING_LIST}
├── Actions (30d): {RUN_COUNT} runs
└── Recommendation: {ACTION}
```

## Error Handling

- GitHub API レート制限に注意（リポジトリ数が多い場合は間隔を空ける）
- API 権限エラーは警告として記録し、スキップして継続
- 各リポジトリの処理は独立しており、1つの失敗が他に影響しない

## Related Commands

| コマンド                    | 関係                                                             |
| --------------------------- | ---------------------------------------------------------------- |
| `/repo-maintenance`         | 個別リポジトリのメンテナンス（org-maintenance から呼び出し可能） |
| `/setup-team-protection`    | ブランチ保護の設定                                               |
| `/config-base-sync-update`  | DevContainer の更新                                              |
| `/dependency-health-check`  | 依存関係の健全性チェック                                         |
| `/security-credential-scan` | 認証情報のスキャン                                               |

## Notes

- GitHub API のレート制限: 認証済みで 5,000 req/h
- 大規模組織（50+ repos）では `--filter` で対象を絞ることを推奨
- `--min-activity 30` で直近1ヶ月にアクティブなリポジトリのみに絞れる
- 結果は標準出力に表示（ファイル保存が必要な場合はリダイレクト）
