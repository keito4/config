---
description: Discover useful features in current repository and create issues for config repository
allowed-tools: Read, Bash(git:*), Bash(gh:*), Bash(find:*), Bash(ls:*), Bash(cat:*), Bash(grep:*), Bash(jq:*), Bash(wc:*), Bash(head:*), Bash(test:*)
argument-hint: [--category <category>] [--dry-run]
---

# Config Contribution Discovery

このコマンドは `config-base-sync-update` の逆機能を提供します。
現在のリポジトリから便利な機能や設定を探索し、keito4/config リポジトリへの貢献候補としてissueを自動作成します。

## Usage Examples

```bash
# 全カテゴリをdry-runでスキャン
claude /config-contribution-discover --dry-run

# Claude Commandsのみ探索してissue作成
claude /config-contribution-discover --category claude-commands

# 環境変数でconfig repositoryのパスを指定
CONFIG_REPO_PATH=~/my-config claude /config-contribution-discover

# 複数回実行しても重複issueは作成されない
claude /config-contribution-discover
```

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

3. GitHubトークンがkeito4/configへのアクセス権限を持つか確認:

   ```bash
   gh repo view keito4/config --json name -q '.name' 2>/dev/null || {
     echo "Error: GitHub token lacks access to keito4/config repository"
     exit 1
   }
   ```

4. 現在のリポジトリ名を取得:

   ```bash
   git remote get-url origin
   ```

## Step 3: Load Config Repository Reference

configリポジトリの既存設定を取得して比較基準とする。

### キャッシュロジック

1. キャッシュディレクトリを確認:

   ```bash
   CACHE_DIR="$HOME/.cache/claude/config-repo"
   CACHE_AGE_HOURS=24
   ```

2. configリポジトリのパスを特定:
   - 環境変数 `CONFIG_REPO_PATH` が設定されていれば使用
   - なければ `~/develop/github.com/keito4/config` を試行
   - キャッシュが24時間以内に存在すれば `$CACHE_DIR` を使用
   - それもなければ shallow clone:

     ```bash
     git clone --depth 1 --single-branch \
       https://github.com/keito4/config.git \
       "$CACHE_DIR"
     ```

3. 代替手段（高速）: GitHub APIを使用:

   ```bash
   gh api repos/keito4/config/contents/.devcontainer/devcontainer.json \
     -q '.content' | base64 -d
   ```

以下のファイルを読み込んで既存の機能リストを作成:

```text
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

### カテゴリ別エラーハンドリング

各カテゴリで以下のエラーを個別処理:

- **FileNotFound**: スキップしてログに記録（警告レベル）
- **ParseError** (JSON/YAML): 警告を表示して次へ
- **PermissionDenied**: エラー報告してスキップ
- **NetworkError** (GitHub API): リトライ3回後に失敗

エラー蓄積:

```bash
ERRORS=()
scan_category "devcontainer" || ERRORS+=("devcontainer: $?")
# 最後にエラーサマリーを表示
```

### セキュリティフィルタリング

以下のファイル・パターンは候補から自動除外:

- `.env*`, `*.env`
- `credentials.json`, `secrets.yaml`, `*.pem`, `*.key`
- `secrets.`, `AWS_`, `DATABASE_URL` を含む環境変数
- `.git/`, `node_modules/`, `vendor/`

### 4.1: DevContainer Features

現在のリポジトリの `.devcontainer/devcontainer.json` を読み込み:

- `features` セクションの各featureを抽出
- configリポジトリにないfeaturesを検出
- 各featureの用途を推定（feature名から）

報告形式:

```text
📦 DevContainer Features
- ghcr.io/custom/feature:1 → 新規候補
- ghcr.io/existing/feature:2 → 既存（スキップ）
```

### 4.2: GitHub Actions Workflows

`.github/workflows/*.yml` をスキャン:

- 各ワークフローの名前と目的を抽出
- configリポジトリにない汎用的なワークフローを検出
- プロジェクト固有のワークフローは除外

#### 汎用性判定基準

**汎用的（候補に含める）**:

- ファイル名: `ci.yml`, `lint.yml`, `test.yml`, `security.yml`, `dependabot.yml`
- トリガー: `push`, `pull_request`, `schedule` のみ
- 外部公開可能なアクション（`actions/*`, `github/*`）のみ使用
- 環境変数に機密情報を直接参照していない

**プロジェクト固有（除外）**:

- ファイル名に `deploy-`, `release-`, プロジェクト名を含む
- `env:` セクションに `secrets.`, `AWS_`, `DATABASE_URL` を含む
- `uses:` で社内プライベートアクションを参照
- 特定のクラウドプロバイダーにハードコード依存

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

#### 汎用性判定基準

**汎用的（候補に含める）**:

- ファイル名: `setup*.sh`, `install*.sh`, `lint*.sh`, `format*.sh`, `test*.sh`
- 他のプロジェクトでも使用可能な汎用ツールラッパー
- 環境非依存（特定パスやURLをハードコードしていない）
- ドキュメント（コメント）付き

**プロジェクト固有（除外）**:

- ビルド成果物生成スクリプト
- 特定インフラへのデプロイスクリプト
- アプリケーション固有のユーティリティ
- プロジェクト名やドメインがハードコードされている

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

### スコアリング計算式

```text
Score = (Genericity × 0.4) + (Documentation × 0.3) + (TrackRecord × 0.3)

各要素の値:
- Genericity: 0.0 (プロジェクト固有) ~ 1.0 (完全に汎用)
- Documentation: 0.0 (ドキュメントなし) ~ 1.0 (包括的なドキュメント)
- TrackRecord: 0.0 (未使用) ~ 1.0 (本番実績あり)

判定閾値:
- High: Score ≥ 0.7
- Medium: 0.4 ≤ Score < 0.7
- Low: Score < 0.4
```

### 評価基準詳細

| 基準                               | 重み | 評価方法                                       |
| ---------------------------------- | ---- | ---------------------------------------------- |
| 汎用性（他プロジェクトでも使える） | 0.4  | プロジェクト固有の参照がないか確認             |
| 重複なし（configにない）           | 必須 | 既存機能リストと照合                           |
| ドキュメント化されている           | 0.3  | description, コメント, README の有無           |
| 実績あり（使用中）                 | 0.3  | git log でコミット履歴を確認、最終更新日を評価 |

スコアを計算:

- 高 (≥0.7): 即座に採用検討
- 中 (0.4-0.7): 検討価値あり
- 低 (<0.4): 条件付きで検討

## Step 6: Generate Discovery Report

発見した候補をカテゴリ別にレポート:

```text
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
   📊 Score: {score}

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

```text
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

エラーサマリー形式:

```text
⚠️ Warnings during scan:
- DevContainer: File not found (skipped)
- MCP Servers: .mcp.json parse error (skipped)
- Workflows: 2 files skipped due to parse errors
```

## Configuration

`.claude/config-contribution.local.md` でカスタマイズ可能。

### ファイルの作成方法

このファイルはオプションで、プロジェクトルートの `.claude/` ディレクトリに作成します。
`.gitignore` に追加することを推奨（個人設定のため）。

```bash
# .gitignore に追加
.claude/*.local.md
```

### 設定例

```yaml
---
excludeCategories:
  - vscode # VS Code設定をスキップ
excludePatterns:
  - '**/test/**' # テスト関連を除外
  - '**/fixtures/**' # テストフィクスチャを除外
minPriority: medium # medium以上のみissue作成
autoLabel: true # 自動ラベル付け
targetRepo: keito4/config # issue作成先（デフォルト: keito4/config）
---
```

### 設定項目

| 項目              | 型       | デフォルト      | 説明                             |
| ----------------- | -------- | --------------- | -------------------------------- |
| excludeCategories | string[] | []              | 除外するカテゴリ                 |
| excludePatterns   | string[] | []              | 除外するファイルパターン         |
| minPriority       | string   | "low"           | issue作成の最低優先度            |
| autoLabel         | boolean  | true            | 自動ラベル付けの有効/無効        |
| targetRepo        | string   | "keito4/config" | issue作成先リポジトリ            |
| cacheHours        | number   | 24              | configリポジトリのキャッシュ時間 |

---

**Progress Reporting**: 各ステップ完了時に進捗を報告

- ✅ Step N: [完了]
- 🔍 Step N: [探索中...]
- ⚠️ Step N: [警告あり]
- ❌ Step N: [エラー]
