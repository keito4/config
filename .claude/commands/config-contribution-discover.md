---
description: Discover useful features in current repository and create issues for config repository
allowed-tools: Read, Bash(git:*), Bash(gh:*), Bash(find:*), Bash(ls:*), Bash(cat:*), Bash(grep:*), Bash(jq:*), Bash(wc:*), Bash(head:*), Bash(test:*)
argument-hint: [--category <category>] [--dry-run]
---

# Config Contribution Discovery

このコマンドは `config-base-sync-update` の逆機能を提供します。
現在のリポジトリから便利な機能や設定を探索し、keito4/config リポジトリへの貢献候補としてissueを自動作成します。

## Step 1: Parse Arguments

引数を解析:

- `--category <category>`: 特定のカテゴリのみ探索（省略時は全カテゴリ）
  - `devcontainer`: DevContainer設定
  - `workflows`: GitHub Actions
  - `claude-commands`: Claude Codeコマンド
  - `claude-agents`: Claude Codeエージェント
  - `claude-hooks`: Claude Codeフック
  - `mcp`: MCPサーバー設定
  - `scripts`: シェルスクリプト
  - `vscode`: VS Code設定
  - `tools`: 開発ツール設定
- `--dry-run`: issueを作成せず、発見した候補のみ表示

## Step 2: Verify Environment

1. 現在のディレクトリがgitリポジトリか確認:

   ```bash
   git rev-parse --is-inside-work-tree
   ```

2. GitHub CLIが認証されているか確認:

   ```bash
   gh auth status
   ```

3. 現在のリポジトリ名を取得:
   ```bash
   git remote get-url origin
   ```

## Step 3: Load Config Repository Reference

configリポジトリの既存設定を取得して比較基準とする。

configリポジトリのパスを特定:

- 環境変数 `CONFIG_REPO_PATH` が設定されていれば使用
- なければ `~/develop/github.com/keito4/config` を試行
- それもなければ一時的にclone

以下のファイルを読み込んで既存の機能リストを作成:

```
.devcontainer/devcontainer.json → 既存のfeatures
.github/workflows/ → 既存のワークフロー
.claude/commands/ → 既存のコマンド
.claude/agents/ → 既存のエージェント
.claude/hooks/ → 既存のフック
.mcp.json → 既存のMCPサーバー
script/ → 既存のスクリプト
```

## Step 4: Discover Features by Category

各カテゴリで探索を実行:

### 4.1: DevContainer Features

現在のリポジトリの `.devcontainer/devcontainer.json` を読み込み:

- `features` セクションの各featureを抽出
- configリポジトリにないfeaturesを検出
- 各featureの用途を推定（feature名から）

報告形式:

```
📦 DevContainer Features
- ghcr.io/custom/feature:1 → 新規候補
- ghcr.io/existing/feature:2 → 既存（スキップ）
```

### 4.2: GitHub Actions Workflows

`.github/workflows/*.yml` をスキャン:

- 各ワークフローの名前と目的を抽出
- configリポジトリにない汎用的なワークフローを検出
- プロジェクト固有のワークフローは除外

検出基準:

- CI/CD関連（汎用的）
- セキュリティスキャン
- 依存関係更新
- リリース自動化
- ドキュメント生成

### 4.3: Claude Commands

`.claude/commands/*.md` をスキャン:

- 各コマンドの説明（description）を抽出
- configリポジトリにないコマンドを検出
- 汎用性の高いコマンドを優先

### 4.4: Claude Agents

`.claude/agents/*.md` をスキャン:

- 各エージェントの説明を抽出
- configリポジトリにないエージェントを検出

### 4.5: Claude Hooks

`.claude/hooks/` をスキャン:

- フック設定を抽出
- 汎用的なフックを検出

### 4.6: MCP Servers

`.mcp.json` を読み込み:

- 設定されているMCPサーバーを抽出
- configリポジトリにないサーバーを検出

### 4.7: Shell Scripts

`script/` または `scripts/` をスキャン:

- 汎用的なユーティリティスクリプトを検出
- プロジェクト固有のスクリプトは除外

検出基準:

- セットアップスクリプト
- CI/CDヘルパー
- 開発ツールスクリプト

### 4.8: VS Code Settings

`.vscode/settings.json` を読み込み:

- 有用な設定を検出
- configリポジトリの推奨設定と比較

### 4.9: Tool Configurations

以下のファイルをスキャン:

- `.eslintrc*` / `eslint.config.*`
- `.prettierrc*` / `prettier.config.*`
- `tsconfig.json`
- `.editorconfig`
- `commitlint.config.*`
- `jest.config.*`
- `vitest.config.*`

有用な設定パターンを検出。

## Step 5: Analyze and Score Candidates

各候補を以下の基準で評価:

| 基準                               | 重み |
| ---------------------------------- | ---- |
| 汎用性（他プロジェクトでも使える） | 高   |
| 重複なし（configにない）           | 必須 |
| ドキュメント化されている           | 中   |
| 実績あり（使用中）                 | 中   |
| メンテナンス性                     | 低   |

スコアを計算:

- 高: 即座に採用検討
- 中: 検討価値あり
- 低: 条件付きで検討

## Step 6: Generate Discovery Report

発見した候補をカテゴリ別にレポート:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Config Contribution Discovery Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Repository: {repo-name}
📅 Date: {date}
🔍 Categories scanned: {categories}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌟 High Priority Candidates ({count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [{category}] {name}
   📝 {description}
   📁 Source: {file-path}
   💡 Reason: {why-useful}

2. ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Medium Priority Candidates ({count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏳ Low Priority Candidates ({count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total candidates: {total}
- High priority: {high-count}
- Medium priority: {medium-count}
- Low priority: {low-count}

Already in config: {existing-count} (skipped)
```

## Step 7: Create Issues (if not --dry-run)

`--dry-run` が指定されていない場合、High Priority候補についてissueを作成:

各候補について:

```bash
gh issue create \
  --repo keito4/config \
  --title "feat: Add {category} - {name}" \
  --body "$(cat <<'EOF'
## Summary

{description}

## Source

- **Repository**: {source-repo}
- **File**: {file-path}
- **Category**: {category}

## Details

{detailed-description}

## Proposed Changes

{what-to-add}

## Benefits

- {benefit-1}
- {benefit-2}

## Priority

{priority} - {reason}

---

🤖 Auto-discovered by `config-contribution-discover` command
EOF
)" \
  --label "enhancement" \
  --label "auto-discovered"
```

作成したissue URLを記録。

## Step 8: Final Report

最終サマリーを表示:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Discovery Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Scanned: {categories-count} categories
📋 Found: {total-candidates} candidates
📝 Issues created: {issues-count}

Created Issues:
{for each issue}
- #{issue-number}: {title}
  {issue-url}
{end for}

{if --dry-run}
ℹ️  Dry run mode - no issues were created
Run without --dry-run to create issues
{end if}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Review created issues in keito4/config
2. Prioritize based on team needs
3. Create PRs to add approved features
4. Run this command periodically to discover new features
```

---

## Error Handling

各ステップでエラーが発生した場合:

1. エラーメッセージを表示
2. 可能であれば次のカテゴリに進む
3. 最終レポートでエラーをまとめて報告

## Configuration

`.claude/config-contribution.local.md` でカスタマイズ可能:

```yaml
---
excludeCategories:
  - vscode # VS Code設定をスキップ
excludePatterns:
  - '**/test/**' # テスト関連を除外
minPriority: medium # medium以上のみissue作成
autoLabel: true # 自動ラベル付け
---
```

---

**Progress Reporting**: 各ステップ完了時に進捗を報告

- ✅ Step N: [完了]
- 🔍 Step N: [探索中...]
- ⚠️ Step N: [警告あり]
- ❌ Step N: [エラー]
