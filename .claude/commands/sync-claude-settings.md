---
description: Sync Claude settings from Elu-co-jp projects to DevContainer configuration
allowed-tools: Read, Write, Edit, Bash(find:*), Bash(ls:*), Bash(git:*), Bash(gh:*), Bash(cat:*)
argument-hint: [--create-pr] [--base-path PATH]
---

# Claude Settings Sync Workflow

## Overview

このコマンドは Elu-co-jp 配下の全プロジェクトから `.claude/settings.local.json` を収集し、
共通設定を抽出して `.devcontainer/claude-settings.json` に反映させます。

## 前提条件

- ベースパス（`/Users/keito4/develop/github.com/Elu-co-jp`）は既に存在すると仮定
- 環境確認は不要で、直接ファイル検索から開始
- Node.js, npm, git, gh コマンドは既にインストール済みと仮定

## Step 1: Parse Arguments

引数から設定を読み取る：

- `--create-pr`: PR を自動作成する（デフォルト: false）
- `--base-path PATH`: カスタムベースパス（デフォルト: `/Users/keito4/develop/github.com/Elu-co-jp`）

引数がない場合はデフォルト設定を使用。

## Step 2: Find settings.local.json Files

指定されたベースパス配下で `settings.local.json` ファイルを検索（node_modules を除外）：

```bash
find ${BASE_PATH} -name "settings.local.json" -type f 2>/dev/null | grep -v node_modules
```

見つかったファイル数を報告：

- 0件の場合: 警告を表示して終了
- 1件以上: node_modules 内のファイルを除外してから次のステップへ進む

## Step 3: Read and Parse Settings Files

各 `settings.local.json` ファイルを読み込み：

1. ファイルパスとリポジトリ名を記録
2. JSON として解析
3. `permissions.allow`, `permissions.deny`, `permissions.ask` を抽出
4. セキュリティ配慮：
   - APIキー、トークン、パスワードを含むコマンドを除外（SUPABASE_SERVICE_ROLE_KEY, AWS_ACCESS_KEY_ID など）
   - 特定のプロジェクトパスを含む Read パーミッションを除外（`Read(//workspaces/specific-project/**)`）
5. エラーがあればスキップして次へ（エラー内容は記録）

読み込み結果を報告：

- 成功: X 件
- 失敗: Y 件（ファイルパスと理由を列挙）
- 除外: Z 件（セキュリティ上の理由）

## Step 4: Analyze Common Patterns

収集した設定から共通パターンを抽出：

### Allow リスト分析

1. 全ファイルで出現頻度をカウント
2. 50% 以上のリポジトリで使用されている許可設定を「共通設定」として識別
3. カテゴリ別に分類：
   - WebFetch ドメイン
   - MCP ツール
   - Bash コマンド（カテゴリ別）
   - Read パーミッション
   - Skill パーミッション

### Deny リスト分析

1. いずれかのリポジトリで deny されているコマンドをすべて収集
2. 破壊的コマンドとして重複排除

### 統計レポート

以下の情報を表示：

- 収集元リポジトリ数
- 共通設定項目数
- カテゴリ別の内訳
- 新規追加候補
- 削除候補（現在の設定にあるが共通設定にない項目）

## Step 5: Check Git Status

変更を加える前に Git の状態を確認：

```bash
git status --porcelain
```

Uncommitted changes がある場合：

- 警告を表示
- `--create-pr` が指定されている場合は終了
- 指定されていない場合は続行（ローカル編集のみ）

## Step 6: Update DevContainer Settings

`.devcontainer/claude-settings.json` を更新：

### 更新方針

1. **$schema**: 追加（存在しない場合）
2. **permissions.allow**:
   - 共通設定を先頭に配置
   - カテゴリ別にソート（WebFetch, MCP, Bash, Read, Skill の順）
   - 既存の設定は保持（重複排除）
   - 削除候補は残す（手動削除を推奨）
3. **permissions.deny**:
   - すべての破壊的コマンドをマージ
   - 重複排除してソート
4. **permissions.ask**:
   - 空配列を保持

### 更新実行

Edit ツールを使用して `.devcontainer/claude-settings.json` を更新。

## Step 7: Generate Change Summary

変更内容のサマリーを生成：

```markdown
## 変更サマリー

### 追加された許可設定 (X 件)

- WebFetch ドメイン: Y 件
- Bash コマンド: Z 件
- その他: W 件

### 追加された拒否設定 (X 件)

- Supabase: Y 件
- Git: Z 件
- インフラ: W 件

### 統計

- 収集元リポジトリ: N 件
- 共通設定抽出: M 件
```

## Step 8: Commit and Create PR (Optional)

`--create-pr` が指定されている場合のみ実行：

### ブランチ作成

```bash
git checkout -b feat/sync-claude-settings-$(date +%Y%m%d)
```

既存ブランチがある場合はエラーで終了。

### 変更をコミット

```bash
git add .devcontainer/claude-settings.json
git commit -m "feat: Sync Claude settings from Elu-co-jp projects

Elu-co-jp 配下の全プロジェクトから settings.local.json を収集し、
共通設定を抽出して DevContainer 設定に反映しました。

## 収集元
- リポジトリ数: N 件
- 共通設定: M 件

## 主な変更
- WebFetch ドメイン: X 件追加
- Bash コマンド許可: Y 件追加
- 破壊的コマンド拒否: Z 件追加

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### PR 作成

```bash
git push -u origin feat/sync-claude-settings-$(date +%Y%m%d)

gh pr create \
  --base main \
  --title "feat: Sync Claude settings from Elu-co-jp projects" \
  --body "$(cat <<'EOF'
## 概要

Elu-co-jp 配下の全プロジェクトから `.claude/settings.local.json` を収集し、
共通設定を抽出して DevContainer 設定に反映しました。

## 収集元

- リポジトリ数: N 件
- 共通設定: M 件

## 変更内容

### 追加された許可設定
- WebFetch ドメイン: X 件
- Bash コマンド: Y 件
- MCP ツール: Z 件

### 追加された拒否設定
- 破壊的 Supabase コマンド
- 破壊的 Git コマンド
- 破壊的インフラコマンド

## セキュリティチェック

✅ すべての追加項目を確認済み
- 汎用的なコマンドパターンのみ
- APIキー、トークン、パスワードなどの秘匿情報は含まれていません
- プロジェクト固有の情報は除外済み

## 影響範囲

- DevContainer イメージをビルドする全プロジェクト
- 次回の DevContainer イメージビルド時から有効化

## テスト

- ✅ pre-commit フック: Format, Lint, Test 通過
- ✅ 秘匿情報チェック: 問題なし

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PR URL を報告。

## Step 9: Final Report

完了レポートを表示：

```
✅ Claude settings sync complete!

収集元リポジトリ: N 件
共通設定抽出: M 件
更新ファイル: .devcontainer/claude-settings.json

変更内容:
- 許可設定追加: X 件
- 拒否設定追加: Y 件

セキュリティチェック:
- ✅ 秘匿情報: なし
- ✅ プロジェクト固有情報: 除外済み

PR: {PR-URL または "ローカル更新のみ"}

次のステップ:
1. 変更内容を確認
2. 必要に応じて手動調整
3. PR をレビュー・マージ（PR作成時）
```

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
4. 実行を停止（以降のステップは実行しない）

## Notes

- `settings.local.json` は Git 管理外のため、ローカル環境でのみ収集可能
- 収集したファイルは一時的にメモリに保持し、ファイルシステムには保存しない
- セキュリティ上の理由から、APIキーやトークンを含む設定は除外する
- 破壊的コマンドは deny リストに追加することで、誤実行を防止
