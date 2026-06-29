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

### 2. `pre_git_quality_gates.py`

**目的**: Git操作（commit/push）の前にQuality Gatesを実行し、品質基準を満たさない変更のコミット/プッシュを防止

**トリガー**: `PreToolUse(Bash)` で `git commit` または `git push` を検出

**自動検出されるチェック**:

| チェック     | 検出するスクリプト名             |
| ------------ | -------------------------------- |
| Format Check | `format:check`                   |
| Lint         | `lint`, `lint:check`             |
| Test         | `test`, `test:unit`              |
| Type Check   | `typecheck`, `type-check`, `tsc` |
| ShellCheck   | `shellcheck`                     |

**対応パッケージマネージャー**: npm / pnpm / yarn / bun（ロックファイルから自動判定）

### 3. `post_git_push_ci.py`

**目的**: git push後にGitHub Actions CIの状態を監視し、結果を報告

**トリガー**: `PostToolUse(Bash)` で `git push` の成功を検出

**動作**:

- `git push` 成功後に自動実行
- GitHub Actions ワークフローの起動を確認
- CIの実行状態を監視（最大5分）
- 成功/失敗の結果を報告（ブロックはしない）

### 4. `post_pr_ai_review.py`

**目的**: PR作成後にAI（Codex + Gemini）による自動コードレビューを実行

**トリガー**: `PostToolUse(Bash)` で `gh pr create` の成功を検出

**前提条件**: Codex CLI または Gemini CLI がインストール済み

### 5. `post_pr_ci_watch.py`

**目的**: PR作成後にGitHub Actions CIの状態を監視し、結果を報告

**トリガー**: `PostToolUse(Bash)` で `gh pr create` の成功を検出

**動作**:

- PRのCIチェック状態を15秒ごとにポーリング（最大10分）
- 全チェック完了または失敗を検出したら報告（ブロックはしない）

### 6. `pre_exit_plan_ai_review.py`

**目的**: プラン作成後、ExitPlanMode実行前にAI（Codex + Gemini）によるプランレビューを実行

**トリガー**: `PreToolUse(ExitPlanMode)`

**動作**:

- ExitPlanMode実行前に自動発火
- 最新のプランファイルを検出し、AIでレビュー
- いずれかのAIが "plan needs revision" と判定した場合は exit code 2 でブロック

### 7. `post_commit_adr_reminder.py`

**目的**: git commit後にアーキテクチャ関連の変更を検出し、ADR作成をリマインド

**トリガー**: `PostToolUse(Bash)` で `git commit` を検出

**検出するアーキテクチャシグナル**:

| シグナル             | 対象ファイル                            |
| -------------------- | --------------------------------------- |
| 依存関係の変更       | `package.json`                          |
| Linter/Formatter設定 | `biome.json`, `.eslintrc`, `oxlint`     |
| TypeScript設定       | `tsconfig*.json`                        |
| ハーネス/Hook設定    | `lefthook.yml`, `.claude/settings.json` |
| コンテナ設定         | `Dockerfile`, `docker-compose*`         |
| CI/CD                | `.github/workflows/`                    |

**動作**: シグナル検出時にリマインドメッセージを表示（ブロックはしない）

### 8. `block_config_edit.py`

**目的**: リンター・フォーマッター設定ファイルの編集をブロックし、エラー回避のための設定緩和を防止

**トリガー**: `PreToolUse(Edit / Write)`

**保護対象ファイル**:

| ツール         | 対象ファイル                         |
| -------------- | ------------------------------------ |
| ESLint         | `.eslintrc*`, `eslint.config.*`      |
| Biome          | `biome.json`, `biome.jsonc`          |
| Prettier       | `.prettierrc*`, `prettier.config.*`  |
| TypeScript     | `tsconfig.json`                      |
| Ruff           | `ruff.toml`                          |
| Husky/Lefthook | `lefthook.yml`, `lefthook-local.yml` |
| golangci-lint  | `.golangci.yml`                      |
| SwiftLint      | `.swiftlint.yml`                     |
| ShellCheck     | `.shellcheckrc`                      |
| Pre-commit     | `.pre-commit-config.yaml`            |
| Oxlint         | `.oxlintrc.json`                     |

**動作**: ファイルのバセネームを確認し、保護対象に一致すれば exit code 2 でブロック

### 9. `block_dangerous_commands.py`

**目的**: 破壊的なコマンドを検出してブロック（bash -c などのラッパーによるバイパスも防止）

**トリガー**: `PreToolUse(Bash)`

**検出カテゴリ**:

| カテゴリ            | 代表的なパターン                                        |
| ------------------- | ------------------------------------------------------- |
| Git 破壊操作        | `git push --force`, `git reset --hard`, `git clean -f`  |
| chmod 危険設定      | `chmod 777`                                             |
| rm 破壊操作         | `rm -rf`                                                |
| Docker 破壊操作     | `docker system prune`, `docker run --privileged`        |
| Kubernetes 破壊操作 | `kubectl delete`, `kubectl scale --replicas=0`          |
| Terraform 破壊操作  | `terraform destroy`, `terraform apply -auto-approve`    |
| AWS 破壊操作        | `aws ec2 terminate-instances`, `aws s3 rm --recursive`  |
| GCP 破壊操作        | `gcloud projects delete`, `gcloud sql instances delete` |

**実装の特徴**:

- コマンド全体を正規化・小文字化してから検査（`bash -c '...'` ラッパーも対象）
- クォート内文字列を空白に置換してからパターンマッチ（クォートされたセパレータによるバイパスを防止）
- フラグのワイルドカードは `[^|&;<>]*` で単一コマンド境界内に限定（チェーンコマンドでの誤検知を防止）

### 10. `block_inline_secrets.py`

**目的**: コマンドにインライン埋め込みされた実際の認証情報を検出してブロック

**トリガー**: `PreToolUse(Bash)`

**背景**: Claude Code は承認されたコマンドを `settings.local.json` に権限ルールとして永続化する。コマンドに実際の秘密情報がインライン埋め込みされていると、git 履歴への漏洩リスクが生じる。

**検出するパターン**:

| パターン | ラベル |
| ---------------------------------------- | ---------------------------- | ------------------- | --- | ---- | ----------- | ---------------- |
| `(AKIA                                   | ASIA)[0-9A-Z]{16}` | AWS アクセスキー ID |
| `aws_secret_access_key=...` | AWS シークレットアクセスキー |
| `ghp_...` / `gho_...` / `github_pat_...` | GitHub トークン（3種） |
| `sk-ant-...` | Anthropic API キー |
| `sk-proj-...` / `sk-...` | OpenAI キー |
| `xox[baprs]-...` | Slack トークン |
| `[sr]k\_(live                            | test)\_...` | Stripe キー |
| `lin_api_...` | Linear API キー |
| `AIza...` | Google API キー |
| `glpat-...` | GitLab PAT |
| `dp.(pt                                  | st                           | sa                  | ct  | scim | audit)....` | Doppler トークン |
| `-----BEGIN ... PRIVATE KEY-----` | 秘密鍵 |

**動作**:

- Supabase デモ用公開 JWT（`supabase start` 標準トークン）は誤検知除外
- `$GH_TOKEN` のような変数参照は検知しない（リテラル値のみ対象）
- 検出時は環境変数またはシークレットマネージャーの使用を促すメッセージを表示

### 11. `post_edit_auto_lint.py`

**目的**: ファイル編集後に自動フォーマット＋リントを実行し、残った違反をエージェントにフィードバック

**トリガー**: `PostToolUse(Edit / Write)`

**対応言語とツール**:

| 言語                    | フォーマッター                    | リンター   |
| ----------------------- | --------------------------------- | ---------- |
| TypeScript / JavaScript | biome / prettier (フォールバック) | oxlint     |
| Python                  | ruff format                       | ruff check |
| Shell                   | —                                 | shellcheck |

**動作**:

- Phase 1: 自動修正（サイレント実行）
- Phase 2: 残った違反を収集し `additionalContext` として返す
- 違反がゼロの場合は出力なし（"0 warnings and 0 errors" 等を自動フィルタ）

### 12. `stop_test_verification.py`

**目的**: エージェントが完了を宣言する前に、テストスイートを自動実行して品質を担保

**トリガー**: `Stop`（エージェント完了前）

**動作**:

- `STOP_HOOK_ACTIVE` 環境変数で再帰実行を防止
- Git 変更がない場合はスキップ（新規セッションでの空実行を防止）
- `package.json` の `test` または `test:unit` スクリプトを自動検出
- テストが失敗した場合: 失敗ログの末尾30行を `additionalContext` で返し修正を促す
- タイムアウト: 5分

## Hooksの設定方法

### ステップ1: settings.local.json に設定を追加

`.claude/settings.local.json` ファイルに `hooks` フィールドを追加します：

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
