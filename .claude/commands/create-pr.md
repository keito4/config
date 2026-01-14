---
description: Create PR with latest base branch changes merged
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(find:*), Bash(ls:*)
argument-hint: [--base BRANCH] [--title TITLE] [--draft]
---

# Create PR Workflow

## Overview

このコマンドは最新のベースブランチから変更を取り込み、PRを作成します。

## 前提条件

- Git リポジトリ内で実行
- gh CLI がインストール済み
- リモートリポジトリにプッシュ権限がある
- 現在のブランチがフィーチャーブランチである

## Step 1: Parse Arguments

引数から設定を読み取る：

- `--base BRANCH`: ベースブランチを指定（デフォルト: main）
- `--title TITLE`: PR タイトルを指定（省略時は最新コミットメッセージから生成）
- `--draft`: ドラフトPRとして作成

引数がない場合はデフォルト設定を使用。

## Step 2: Validate Current State

現在の状態を確認：

```bash
# 現在のブランチを確認
git branch --show-current

# Uncommitted changes を確認
git status --porcelain
```

### 検証項目

1. **ブランチチェック**
   - 現在のブランチがベースブランチではないこと
   - フィーチャーブランチであること

2. **変更チェック**
   - Uncommitted changes がないこと
   - ある場合は警告を表示し、確認を求める

## Step 3: Fetch and Merge Latest Base Branch

最新のベースブランチを取得してマージ：

```bash
# 最新のベースブランチを取得
git fetch origin ${BASE_BRANCH}

# ベースブランチとのマージベースを確認
git merge-base HEAD origin/${BASE_BRANCH}

# ベースブランチをマージ
git merge origin/${BASE_BRANCH} --no-edit
```

### コンフリクト処理

コンフリクトが発生した場合：

1. コンフリクトファイルをリストアップ
2. ユーザーに通知
3. 解決方法を提案：
   - 自動解決可能な場合（同一ファイル）: 自動解決
   - 手動解決が必要な場合: ガイダンスを表示して終了

### 自動解決ロジック

```bash
# コンフリクトファイルを確認
git ls-files -u | awk '{print $4}' | sort -u

# 各ファイルについて、両バージョンが同一かチェック
for file in ${CONFLICT_FILES}; do
  if git diff HEAD:$file origin/${BASE_BRANCH}:$file > /dev/null 2>&1; then
    # 同一の場合: origin/main のバージョンを使用
    git checkout origin/${BASE_BRANCH} -- $file
    git add $file
  else
    # 異なる場合: 手動解決が必要
    echo "Manual resolution required for: $file"
  fi
done
```

### マージコミット

コンフリクト解決後、マージコミットを作成：

```bash
git commit -m "feat: Merge latest ${BASE_BRANCH} branch updates

${BASE_BRANCH}ブランチの最新の変更を取り込みました。

## コンフリクト解決
${RESOLVED_FILES}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Step 4: Generate PR Title and Body

PR タイトルと本文を生成：

### タイトル生成

`--title` が指定されている場合はそれを使用。
指定されていない場合は、最新のコミットメッセージから生成：

```bash
# 最新のコミットメッセージを取得
git log -1 --format=%s

# Conventional Commits 形式から抽出
# 例: "feat: Add new feature" -> "Add new feature"
```

### 本文生成

```bash
# ベースブランチからの差分コミットをリストアップ
git log origin/${BASE_BRANCH}..HEAD --format="%h %s"

# 変更ファイル数を取得
git diff origin/${BASE_BRANCH}..HEAD --stat
```

本文テンプレート：

```markdown
## 概要

${DESCRIPTION}

## 変更内容

${COMMIT_LIST}

## 変更統計

- 変更ファイル数: X 件
- 追加行数: Y 行
- 削除行数: Z 行

## テスト

- ✅ pre-commit フック: Format, Lint, Test 通過
- ✅ コンフリクト解決: 完了
- ✅ 最新の${BASE_BRANCH}ブランチとマージ済み

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Step 5: Push to Remote

リモートブランチにプッシュ：

```bash
# 現在のブランチをリモートにプッシュ
git push -u origin $(git branch --show-current)
```

### エラー処理

- リモートブランチが既に存在する場合: force pushを確認
- プッシュに失敗した場合: エラー内容を表示して終了

## Step 6: Create Pull Request

gh CLI を使用してPRを作成：

```bash
gh pr create \
  --base ${BASE_BRANCH} \
  --title "${PR_TITLE}" \
  --body "${PR_BODY}" \
  ${DRAFT_FLAG}
```

### オプション

- `${DRAFT_FLAG}`: `--draft` が指定されている場合は `--draft` を追加

### PR作成後

PR URLを返却：

```
✅ Pull Request created successfully!

PR URL: https://github.com/owner/repo/pull/123

次のステップ:
1. PR の内容を確認
2. CI チェックの結果を確認
3. レビューを依頼
4. 必要に応じて修正
```

## Step 7: Final Report

完了レポートを表示：

```
✅ PR creation complete!

ブランチ: ${CURRENT_BRANCH}
ベース: ${BASE_BRANCH}
タイトル: ${PR_TITLE}
ドラフト: ${IS_DRAFT}

PR URL: ${PR_URL}

変更内容:
- コミット数: X 件
- 変更ファイル数: Y 件
- マージコミット: ${MERGE_COMMIT_HASH}

次のステップ:
1. CI チェックの結果を確認
2. コードレビューを依頼
3. フィードバックに対応
4. マージ準備完了後、レビュアーに通知
```

## PR作成後のフォローアップ（Skills）

PR作成完了後、以下のskillsが自動的に適用されます。

### 1. Codex Review（`.claude/skills/codex-review.md`）

Codex CLIがインストール済みの場合、OpenAI Codexによるコードレビューを実行します。

- verdictが"patch is incorrect"の場合は指摘事項を修正
- 修正後、再度Codexレビューを実行

### 2. CI Check（`.claude/skills/ci-check.md`）

CIの結果を確認し、失敗している場合は修正します。

- CIが緑になるまでPRを放置しない
- 修正可能な問題は自分のブランチで解決する
- 解決不能な場合は原因と状況を明記してレビュアーに報告

---

## Progress Reporting

各ステップの進捗を報告：

- ✅ Step N: [完了した操作]
- 🔄 Step N: [実行中の操作]
- ❌ Step N: [失敗 - 理由]

## Error Handling

エラー発生時：

1. 具体的なエラー内容を報告
2. 原因を説明
3. 修正方法を提案
4. 必要に応じてロールバック手順を提供

## Notes

- **ベースブランチの取り込み**: 常に最新のベースブランチをマージしてからPRを作成
- **コンフリクト自動解決**: 同一ファイルの場合のみ自動解決、それ以外は手動解決を要求
- **Conventional Commits**: コミットメッセージとPRタイトルは Conventional Commits 形式を推奨
- **ドラフトPR**: 作業途中の場合は `--draft` オプションを使用
- **Force Push**: リモートブランチが既に存在する場合、force push は慎重に実行
