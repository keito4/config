# Claude Code Hooks

このディレクトリには、Claude Codeの動作をカスタマイズするためのHooksスクリプトが格納されています。

## 概要

Hooksは、Claude Codeの特定のイベント（ツール実行前後、タスク完了時など）に自動的に実行されるスクリプトです。これにより、品質チェック、通知、自動化などを実現できます。

## 利用可能なHooks

### 1. `block_git_no_verify.py`

**目的**: `git commit --no-verify` や `HUSKY=0` の使用をブロックし、必ずGit Hooksを実行させる

**トリガー**: `PreToolUse(Bash)`

**動作**:

- `--no-verify` フラグを検出してブロック
- `HUSKY=0` 環境変数を検出してブロック
- 違反が見つかった場合、exit code 2でツール実行を阻止

**設定例**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "comment": "Block git --no-verify and HUSKY=0",
        "matcher": "tool_name == 'Bash'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/block_git_no_verify.py"
          }
        ]
      }
    ]
  }
}
```

### 2. `pre_git_quality_gates.py`

**目的**: Git操作（commit/push）の前にQuality Gatesを実行し、品質基準を満たさない変更のコミット/プッシュを防止

**トリガー**: `PreToolUse(Bash)` で `git commit` または `git push` を検出

**実行されるチェック**:

1. **Format Check** (`npm run format:check`) - コードフォーマットの検証
2. **Lint** (`npm run lint`) - コード品質の検証
3. **Test** (`npm run test`) - ユニットテストの実行
4. **ShellCheck** (`npm run shellcheck`) - シェルスクリプトの検証
5. **Security Credential Scan** (`./script/security-credential-scan.sh --strict`) - 認証情報の漏洩チェック
6. **Code Complexity Check** (`./script/code-complexity-check.sh --strict`) - コード複雑度の検証

**動作**:

- すべてのチェックに合格した場合のみ、Git操作を許可
- 1つでも失敗した場合、exit code 2でツール実行を阻止
- 失敗したチェックの詳細を標準エラー出力に表示

**設定例**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "comment": "Run Quality Gates before git commit/push",
        "matcher": "tool_name == 'Bash'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/pre_git_quality_gates.py"
          }
        ]
      }
    ]
  }
}
```

## Hooksの設定方法

### DevContainer環境（v1.61.0以降）

**v1.61.0以降のDevContainerイメージでは、Hooksはデフォルトで有効化されています。**

DevContainerを使用している場合、以下のHooksが自動的に設定されます：

- `block_git_no_verify.py` - `--no-verify` のブロック
- `pre_git_quality_gates.py` - Git操作前の品質チェック
- `post_git_push_ci.py` - push後のCI監視
- `post_pr_ai_review.py` - PR作成後のAIレビュー
- `pre_exit_plan_ai_review.py` - プランモード終了前のレビュー

これらは `/home/vscode/.claude/settings.json` に設定されており、追加の設定なしで動作します。

### 手動設定（DevContainer以外の環境）

DevContainer以外の環境では、`.claude/settings.local.json` ファイルに `hooks` フィールドを追加します：

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PreToolUse": [
      {
        "comment": "Block git --no-verify and HUSKY=0",
        "matcher": "tool_name == 'Bash'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/block_git_no_verify.py"
          }
        ]
      },
      {
        "comment": "Run Quality Gates before git commit/push",
        "matcher": "tool_name == 'Bash'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/pre_git_quality_gates.py"
          }
        ]
      }
    ]
  }
}
```

### ステップ2: Hookスクリプトに実行権限を付与

```bash
chmod +x .claude/hooks/*.py
```

### ステップ3: Claude Codeを再起動

設定変更を反映させるため、Claude Codeを再起動します。

## トラブルシューティング

### Hookが実行されない

1. `settings.local.json` の構文が正しいか確認
2. Hookスクリプトに実行権限があるか確認（`ls -l .claude/hooks/`）
3. Pythonがインストールされているか確認（`python3 --version`）

### Quality Gatesで意図せずブロックされる

以下のいずれかの対処を行います：

1. **修正してコミット**: エラーメッセージに従って問題を修正
2. **特定のチェックをスキップ**: 一時的に `pre_git_quality_gates.py` の該当チェックをコメントアウト
3. **Hookを無効化**: `settings.local.json` から該当のHook設定を削除

### タイムアウトエラー

テストやビルドに時間がかかる場合、`pre_git_quality_gates.py` の `timeout` 値を増やします：

```python
result = subprocess.run(
    check["command"],
    timeout=600  # 10分に変更
)
```

### 3. `post_git_push_ci.py`

**目的**: git push後にGitHub Actions CIの状態を監視し、結果を報告

**トリガー**: `PostToolUse(Bash)` で `git push` の成功を検出

**動作**:

- `git push` 成功後に自動実行
- GitHub Actions ワークフローの起動を確認
- CIの実行状態を監視（最大5分）
- 成功/失敗の結果を報告
- ブロックはしない（結果を表示のみ）

**前提条件**:

- GitHub CLI (`gh`) がインストール済み
- GitHub Actions ワークフローが設定済み

**設定例**:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool_name == 'Bash'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/post_git_push_ci.py"
          }
        ]
      }
    ]
  }
}
```

### 4. `post_pr_ai_review.py`

**目的**: PR作成後にAI（Codex + Gemini）による自動コードレビューを実行

**トリガー**: `PostToolUse(Bash)` で `gh pr create` の成功を検出

**動作**:

- `gh pr create` 成功後に自動実行
- インストールされているAIツール（Codex、Gemini）でレビューを実行
- 各AIがコード変更をレビュー（正確性、パフォーマンス、セキュリティ、保守性）
- verdict（"patch is correct" / "patch is incorrect"）と信頼度スコアを出力
- ブロックはしない（レビュー結果を表示のみ）

**前提条件**:

- Codex CLI（`npm install -g @openai/codex`）またはGemini CLI（`npm install -g @google/gemini-cli`）がインストール済み
- 両方インストールされていれば両方でレビューを実行
- どちらも未インストールの場合は自動スキップ

**設定例**:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool_name == 'Bash'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/post_pr_ai_review.py"
          }
        ]
      }
    ]
  }
}
```

### 5. `pre_exit_plan_ai_review.py`

**目的**: プラン作成後、ExitPlanMode実行前にAI（Codex + Gemini）によるプランレビューを実行

**トリガー**: `PreToolUse(ExitPlanMode)`

**動作**:

- ExitPlanMode実行前に自動発火
- 最新のプランファイル（`~/.claude/plans/*.md`）を検出
- インストールされているAIツールでプランをレビュー（完全性、技術的実現可能性、リスク、依存関係）
- いずれかのAIが "plan needs revision" と判定した場合は exit code 2 でブロック
- いずれかのAIが "plan is ready" と判定した場合は続行を許可

**前提条件**:

- Codex CLIまたはGemini CLIがインストール済み
- プランファイルが `~/.claude/plans/` に存在

**設定例**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "tool_name == 'ExitPlanMode'",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/pre_exit_plan_ai_review.py"
          }
        ]
      }
    ]
  }
}
```

## カスタムHooksの作成

新しいHookスクリプトを作成する場合の基本構造：

```python
#!/usr/bin/env python3
import sys
import json

# Read input from Claude
data = json.load(sys.stdin)
tool_input = data.get("tool_input", {}) or {}

# Your hook logic here
# ...

# Exit codes:
# 0 = Allow tool execution
# 2 = Block tool execution with error message
sys.exit(0)
```

## 参考資料

- [Claude Code Hooks ドキュメント](https://docs.anthropic.com/claude-code/hooks)
- [settings.local.json.template](./../settings.local.json.template)
