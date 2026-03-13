---
description: Comprehensive repository maintenance - run all health checks and updates
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(node:*), Bash(jq:*), Bash(find:*), Bash(test:*), Bash(ls:*), Bash(grep:*), Bash(cat:*), Bash(echo:*), Bash(date:*), Bash(curl:*), Task, Skill
argument-hint: '[--mode full|quick|check-only] [--skip CATEGORY] [--create-pr]'
---

# Repository Maintenance Workflow

このコマンドはリポジトリの包括的なメンテナンスを実行し、初期化や機能追加された内容を取り込みます。

## Overview

以下のカテゴリのチェック・更新を順次実行します：

1. **Environment** - 開発環境の健全性と更新
2. **Setup** - CI/CD およびリポジトリ保護の設定
3. **Cleanup** - リポジトリのクリーンアップ
4. **Discovery** - 新機能の発見と取り込み

## Execution Modes

| Mode       | 説明                               | 実行内容                         |
| ---------- | ---------------------------------- | -------------------------------- |
| full       | 全カテゴリの更新とチェックを実行   | 更新 + チェック + クリーンアップ |
| quick      | 重要なチェックのみ実行（更新なし） | チェックのみ                     |
| check-only | 状態確認のみ（変更なし）           | 読み取り専用のチェック           |

## Step 1: Parse Arguments and Initialize

引数から設定を読み取る：

- `--mode MODE`: 実行モード（デフォルト: `full`）
- `--skip CATEGORY`: スキップするカテゴリ（カンマ区切りで複数指定可）
- `--create-pr`: 更新があった場合にPRを作成

デフォルト設定:

```
MODE=full
SKIP_CATEGORIES=[]
CREATE_PR=false
```

初期化メッセージを表示:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Repository Maintenance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mode: {MODE}
Skip: {SKIP_CATEGORIES or "None"}
Create PR: {CREATE_PR}

Starting comprehensive maintenance...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Environment Category

### 2.1 Container Health Check

コンテナ環境の健全性を確認：

実行内容:

- 必須ツールの存在確認（git, node, npm, docker）
- Claude Code ツールの確認（claude）
- 開発ツールの確認（eslint, prettier）
- バージョン検証

これは `/container-health` コマンドと同等の処理を実行します。

結果を記録:

- ✅ すべて正常
- ⚠️ 一部に問題あり（詳細をリスト）
- ❌ 重大な問題あり（詳細をリスト）

### 2.2 DevContainer Version Check

config-base イメージのバージョンを確認：

1. `.devcontainer/devcontainer.json` から現在のバージョンを取得
2. GitHub API から最新バージョンを取得
3. バージョンを比較

```bash
gh api repos/keito4/config/releases/latest --jq '.tag_name'
```

結果:

- ✅ 最新バージョン使用中
- ⚠️ 更新可能: v{current} → v{latest}

### 2.3 DevContainer Update (full mode only)

MODE が `full` かつ更新がある場合:

`/config-base-sync-update` コマンドを実行するか確認してから実行。

**Note**: このステップは対話的確認を行う。自動実行の場合は `--yes` フラグで確認をスキップ。

### 2.4 Claude Code Update Check

npm/global.json の Claude Code バージョンを確認：

```bash
npm view @anthropic-ai/claude-code version
```

結果:

- ✅ 最新バージョン
- ⚠️ 更新可能

MODE が `full` の場合は `/update-claude-code` コマンドを実行。

### 2.5 GitHub Actions Version Check

GitHub Actions のバージョンを確認・更新：

```bash
npm run update:actions
```

または一括更新（npm + Claude Code + Actions）:

```bash
npm run update:all
npm run update:all -- --skip-libs --skip-claude  # Actions のみ
```

結果:

- ✅ 全アクション最新
- ⚠️ 更新可能なアクションあり

MODE が `full` の場合は `/update-actions` コマンドを実行。

### 2.6 Claude Settings Sync Check (full mode only)

このリポジトリが config リポジトリの場合のみ実行:

`/sync-claude-settings` の実行を確認。

### 2.7 Claude Code LSP Setup Check

Claude Code の LSP（Language Server Protocol）サポートの設定状況を確認：

**LSP とは:**
コード補完、定義ジャンプ、参照検索などのコード解析機能を提供するプロトコル。
Claude Code v2.0.74+ でサポートされています。

**確認項目:**

1. `.claude-plugin/plugin.json` の存在確認
2. LSP サーバ設定の確認
3. 必要な言語サーバのインストール状況確認

**対応言語:**

- TypeScript/JavaScript
- Python
- Go
- Rust
- PHP

**設定例（TypeScript）:**

```json
{
  "name": "project-lsp",
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "extensionToLanguage": {
        ".ts": "typescript",
        ".tsx": "typescriptreact",
        ".js": "javascript",
        ".jsx": "javascriptreact"
      }
    }
  }
}
```

**必要な言語サーバ（グローバルインストール）:**

```bash
# TypeScript/JavaScript
npm install -g typescript-language-server typescript

# Python
pip install python-lsp-server

# Go
go install golang.org/x/tools/gopls@latest

# Rust
rustup component add rust-analyzer
```

**環境変数:**

Claude Code 起動時に `ENABLE_LSP_TOOL=1` を設定：

```bash
ENABLE_LSP_TOOL=1 npx @anthropic-ai/claude-code@stable
```

**結果:**

- ✅ LSP 設定済み（対応言語をリスト表示）
- ⚠️ LSP 未設定 → セットアップを提案
- 📝 未インストールの言語サーバをリスト表示

**MODE が `full` の場合:**

プロジェクトで使用されている言語を検出し、適切な LSP 設定を提案・適用：

1. `package.json` → TypeScript/JavaScript
2. `requirements.txt` / `pyproject.toml` → Python
3. `go.mod` → Go
4. `Cargo.toml` → Rust
5. `composer.json` → PHP

**参考:**

- [Claude Code LSP 設定ガイド](https://blog.lai.so/claude-code-lsp/)
- [公式プラグイン](https://github.com/anthropics/claude-plugins-official)

### 2.8 Codespaces Secrets Sync Check

GitHub Codespaces を使用する場合のシークレット紐付け状況を確認：

**確認項目:**

1. `script/codespaces-secrets.sh` の存在確認
2. 現在のリポジトリがシークレットに紐付けられているか確認
3. 設定ファイルとの差分確認

**実行コマンド:**

```bash
# スクリプトの存在確認
test -f ./script/codespaces-secrets.sh && echo "available" || echo "not_available"

# 差分確認（スクリプトが存在する場合）
./script/codespaces-secrets.sh diff
```

**結果:**

- ✅ Codespaces シークレット同期済み
- ⚠️ 未紐付けのシークレットあり → 同期を提案
- ⏭️ スキップ（Codespaces未使用）

**MODE が `full` かつ差分がある場合:**

```bash
./script/codespaces-secrets.sh sync
```

これは `/codespaces-secrets sync` コマンドと同等の処理を実行します。

**Note**: Codespacesを使用していない場合は自動的にスキップされます。

## Step 3: Setup Category

### 3.1 Team Protection Setup (full mode only)

GitHub リポジトリの保護ルールを確認・設定：

実行内容:

- ブランチ保護ルールの確認
- 必須ステータスチェックの設定
- レビュー要件の設定
- Dependabot、脆弱性アラートの有効化

これは `/setup-team-protection` コマンドと同等の処理を実行します。

結果:

- ✅ 保護ルール設定済み
- ⚠️ 未設定の保護ルールあり（詳細をリスト）
- 🔧 設定を適用

### 3.2 Husky Setup Check

Git hooks（pre-commit）の設定状況を確認：

実行内容:

- Husky のインストール状況確認
- pre-commit フックの存在確認
- commitlint の設定確認
- lint-staged の設定確認

これは `/setup-husky` コマンドと同等の処理を実行します。

結果:

- ✅ Husky 設定済み
- ⚠️ Husky 未設定 → セットアップを提案
- 📝 設定内容: pre-commit, commit-msg

### 3.2.1 Husky hooksPath Validation

`core.hooksPath` が正常な値かどうか確認・修正：

**確認ロジック:**

```bash
HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || echo "")
VALID_PATHS=(".husky" ".husky/_")

is_valid=false
for valid in "${VALID_PATHS[@]}"; do
  [ "$HOOKS_PATH" = "$valid" ] && is_valid=true && break
done
```

**結果パターン:**

| 状態                       | 対応                            |
| -------------------------- | ------------------------------- |
| `.husky` または `.husky/_` | ✅ 正常                         |
| 空（未設定）               | ✅ デフォルト動作のためスキップ |
| それ以外（壊れたパス）     | ⚠️ → full mode で自動修正       |

**壊れたパスの例（実際に発生したケース）:**

- `--version/_` → git が `sh --version/_/pre-commit` を実行しフックが一切動作しない

**MODE が `full` かつ修正が必要な場合:**

```bash
echo "⚠️ core.hooksPath が不正です: '$HOOKS_PATH'"

# .husky/ が存在すれば .husky に修正
if [ -d ".husky" ]; then
  git config core.hooksPath ".husky"
  echo "🔧 core.hooksPath を '.husky' に修正しました"
else
  echo "❌ .husky ディレクトリが存在しないため自動修正できません"
fi
```

**結果:**

- ✅ core.hooksPath が正常（`.husky` または `.husky/_`）
- ✅ core.hooksPath 未設定（デフォルト動作）
- 🔧 core.hooksPath を修正しました（壊れたパス → `.husky`）
- ❌ .husky ディレクトリ不在のため手動対応が必要

### 3.2.2 Husky v8 → v9 Migration Check

`.husky/_` 経由のフック実行（husky v8 スタイル）を v9 スタイルへ移行提案：

**確認ロジック:**

```bash
HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || echo "")
IS_V8_STYLE=false
[ "$HOOKS_PATH" = ".husky/_" ] && IS_V8_STYLE=true
```

**v8 と v9 の違い:**

| 項目       | v8 スタイル                                  | v9 スタイル                    |
| ---------- | -------------------------------------------- | ------------------------------ |
| hooksPath  | `.husky/_`                                   | `.husky`                       |
| フック実行 | `_/h` 経由で `.husky/pre-commit` を呼ぶ      | `.husky/pre-commit` を直接実行 |
| 旧 shebang | `. "$(dirname -- "$0")/_/husky.sh"` 行が必要 | 不要（素のシェルスクリプト）   |

**結果パターン:**

| 状態                        | 対応                                 |
| --------------------------- | ------------------------------------ |
| `core.hooksPath = .husky`   | ✅ v9スタイル済み                    |
| `core.hooksPath = .husky/_` | ⚠️ v8スタイル → full mode で移行提案 |
| 未設定                      | ✅ スキップ                          |

**MODE が `full` かつ v8 スタイルの場合:**

```bash
# 1. hooksPath を v9 スタイルに更新
git config core.hooksPath ".husky"

# 2. 各フックファイルから旧 shebang を削除（存在する場合）
for hook in .husky/pre-commit .husky/pre-push .husky/commit-msg; do
  [ ! -f "$hook" ] && continue
  if grep -q "_/husky.sh" "$hook"; then
    # 旧 husky v8 の source 行を削除
    grep -v "_/husky.sh" "$hook" > "$hook.tmp" && mv "$hook.tmp" "$hook"
    # #!/usr/bin/env sh を #!/bin/sh に統一
    sed -i "" "s|#!/usr/bin/env sh|#!/bin/sh|" "$hook"
    chmod +x "$hook"
    echo "🔧 $hook から旧 shebang を削除しました"
  fi
done
```

**結果:**

- ✅ v9スタイル（`.husky`）で設定済み
- 🔧 v8 → v9 へ移行しました（hooksPath 更新 + 旧 shebang 削除）
- ✅ スキップ（hooksPath 未設定）

### 3.2.3 Check-file-length Setup Check

pre-commit フックに `check-file-length` が含まれているか確認・追加：

**確認ロジック:**

```bash
PRECOMMIT=".husky/pre-commit"
SCRIPT_DEST="script/check-file-length.sh"
SCRIPT_SRC_DEVCONTAINER="/usr/local/script/check-file-length.sh"
SCRIPT_RAW_URL="https://raw.githubusercontent.com/keito4/config/main/script/check-file-length.sh"

has_precommit=false
has_file_length=false

[ -f "$PRECOMMIT" ] && has_precommit=true
grep -q "check-file-length" "$PRECOMMIT" 2>/dev/null && has_file_length=true
```

**結果パターン:**

| 状態                                     | 対応                          |
| ---------------------------------------- | ----------------------------- |
| pre-commit あり + check-file-length あり | ✅ スキップ                   |
| pre-commit あり + check-file-length なし | ⚠️ → full mode で自動追加     |
| pre-commit なし                          | ⏭️ Husky 未設定のためスキップ |

**MODE が `full` かつ追加が必要な場合の実行内容:**

1. スクリプトを取得（優先順位順）:

```bash
mkdir -p script
if [ -f "$SCRIPT_SRC_DEVCONTAINER" ]; then
  # DevContainer 環境: コンテナ内スクリプトをコピー
  cp "$SCRIPT_SRC_DEVCONTAINER" "$SCRIPT_DEST"
elif [ ! -f "$SCRIPT_DEST" ]; then
  # ローカル環境: GitHub から取得
  curl -fsSL "$SCRIPT_RAW_URL" -o "$SCRIPT_DEST"
fi
chmod +x "$SCRIPT_DEST"
```

2. pre-commit フックに追記:

```bash
# すでに lint-staged を呼んでいる行の後に追加
echo "" >> "$PRECOMMIT"
echo "# check-file-length" >> "$PRECOMMIT"
echo "bash script/check-file-length.sh" >> "$PRECOMMIT"
```

3. `.filelengthignore` がなければテンプレートから生成:

```bash
IGNORE_TEMPLATE="/usr/local/share/config-templates/.filelengthignore.template"
if [ ! -f ".filelengthignore" ]; then
  if [ -f "$IGNORE_TEMPLATE" ]; then
    cp "$IGNORE_TEMPLATE" .filelengthignore
  else
    cat > .filelengthignore << 'EOF'
# 自動生成ファイル
**/*.generated.*
**/database.types.ts
EOF
  fi
fi
```

**結果:**

- ✅ check-file-length が pre-commit に設定済み
- 🔧 check-file-length を pre-commit に追加しました
- ⏭️ Husky 未設定のためスキップ

### 3.3 Pre-PR Checklist Validation

PR 作成前のチェック項目を検証：

実行内容:

- lint、format、test の実行可否確認
- CI ワークフローの存在確認
- PR テンプレートの存在確認

これは `/pre-pr-checklist` コマンドの設定確認と同等の処理を実行します。

結果:

- ✅ すべてのチェック項目が設定済み
- ⚠️ 不足している項目あり（詳細をリスト）

### 3.4 CLAUDE.md Symlink Check

CLAUDE.md が AGENTS.md へのシンボリックリンクであることを確認：

**背景:**
多くの AI コーディングエージェント（Codex、Gemini CLI など）は `AGENTS.md` を参照し、
Claude Code は `CLAUDE.md` を参照します。`AGENTS.md` を主ファイルとし、
`CLAUDE.md` をシンボリックリンクとして管理することで、両方のエージェントが同じ設定を参照できます。

**確認項目:**

1. `AGENTS.md` の存在確認（主ファイル）
2. `CLAUDE.md` がシンボリックリンクかどうか確認
3. リンク先が `AGENTS.md` であることを確認

**実行コマンド:**

```bash
# シンボリックリンク確認
if [ -L "CLAUDE.md" ]; then
  target=$(readlink CLAUDE.md)
  if [ "$target" = "AGENTS.md" ]; then
    echo "✅ CLAUDE.md -> AGENTS.md"
  else
    echo "⚠️ CLAUDE.md -> $target (expected: AGENTS.md)"
  fi
elif [ -f "CLAUDE.md" ]; then
  echo "⚠️ CLAUDE.md is a regular file (should be symlink to AGENTS.md)"
else
  echo "❌ CLAUDE.md not found"
fi
```

**結果:**

- ✅ CLAUDE.md は AGENTS.md へのシンボリックリンク
- ⚠️ CLAUDE.md は通常ファイル → シンボリックリンク化を提案
- ⚠️ CLAUDE.md のリンク先が異なる → 修正を提案
- ❌ CLAUDE.md が存在しない → 作成を提案

**MODE が `full` かつシンボリックリンクでない場合:**

```bash
# AGENTS.md が存在しない場合は CLAUDE.md を AGENTS.md にリネーム
if [ -f "CLAUDE.md" ] && [ ! -L "CLAUDE.md" ] && [ ! -f "AGENTS.md" ]; then
  mv CLAUDE.md AGENTS.md
  ln -s AGENTS.md CLAUDE.md
  echo "✅ CLAUDE.md を AGENTS.md へのシンボリックリンクに変換しました"
fi

# 両方が通常ファイルの場合はマージを提案
if [ -f "CLAUDE.md" ] && [ ! -L "CLAUDE.md" ] && [ -f "AGENTS.md" ]; then
  echo "⚠️ AGENTS.md と CLAUDE.md が両方存在します"
  echo "   手動でマージしてからシンボリックリンクを作成してください"
fi
```

### 3.5 CI/CD Setup Check (full mode only)

CI/CD ワークフローの設定状況を確認：

実行内容:

- GitHub Actions ワークフローの存在確認
- 必須ジョブ（lint, test, build）の確認
- セキュリティスキャンの設定確認
- Claude Code Review の統合確認

これは `/setup-ci --dry-run` コマンドと同等の処理を実行します。

結果:

- ✅ CI/CD 設定済み
- ⚠️ CI/CD 未設定または不完全 → セットアップを提案
- 📝 推奨レベル: standard または comprehensive

MODE が `full` かつ CI/CD が未設定の場合:

`/setup-ci` コマンドの実行を提案。

### 3.6 GitHub Actions Cost Optimization Check

GitHub Actions のコスト最適化のため、全ワークフローの設定を確認：

#### 3.6.1 全ワークフロー共通チェック

**確認対象:** `.github/workflows/*.yml` 全ファイル

**チェック項目:**

| #   | チェック                          | 推奨値                                     | コスト影響                       |
| --- | --------------------------------- | ------------------------------------------ | -------------------------------- |
| 1   | `concurrency` 設定の有無          | 設定あり                                   | 重複実行防止                     |
| 2   | `cancel-in-progress`              | `true`（CI系）                             | 古い実行の即時キャンセル         |
| 3   | Draft PR のスキップ               | `github.event.pull_request.draft == false` | Draft中の不要実行防止            |
| 4   | `timeout-minutes` の設定          | 明示的に設定（デフォルト360分は危険）      | 暴走ジョブ防止                   |
| 5   | `paths` / `paths-ignore` フィルタ | コード変更に関係ないファイルを除外         | 不要実行の抑制                   |
| 6   | Dependabot PR の除外/制限         | bot除外 or 実行制限                        | 大量の依存更新PRでの過剰実行防止 |

**確認ロジック:**

```bash
ISSUES=()

for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  CONTENT=$(cat "$workflow")

  # concurrency 設定チェック
  if ! echo "$CONTENT" | grep -q "concurrency:"; then
    ISSUES+=("$BASENAME: concurrency 未設定（重複実行の可能性あり）")
  fi

  # timeout-minutes チェック
  if ! echo "$CONTENT" | grep -q "timeout-minutes:"; then
    ISSUES+=("$BASENAME: timeout-minutes 未設定（デフォルト360分で課金される可能性あり）")
  fi

  # PR トリガーでの Draft スキップチェック
  if echo "$CONTENT" | grep -q "pull_request:" && ! echo "$CONTENT" | grep -q "draft"; then
    ISSUES+=("$BASENAME: pull_request トリガーあり、Draft PR スキップ未設定")
  fi

  # paths フィルタの推奨（CI/テスト系ワークフロー）
  if echo "$CONTENT" | grep -qE "(npm test|npm run test|vitest|jest|pytest)" && \
     ! echo "$CONTENT" | grep -q "paths:"; then
    ISSUES+=("$BASENAME: テスト実行あり、paths フィルタ未設定（README変更等でもテスト実行される）")
  fi
done
```

#### 3.6.2 Claude ワークフロー固有チェック

**確認対象:**

- `.github/workflows/claude.yml`
- `.github/workflows/claude-code-review.yml`

**チェック項目:**

| #   | チェック                                       | 推奨値                                   | コスト影響                     |
| --- | ---------------------------------------------- | ---------------------------------------- | ------------------------------ |
| 1   | `claude.yml` の `cancel-in-progress`           | `true`                                   | 重複実行防止（**最大の効果**） |
| 2   | `claude.yml` の issues トリガー                | `[opened]` のみ                          | `assigned` での不要起動防止    |
| 3   | `claude.yml` の bot 除外                       | `github-actions[bot]`, `dependabot[bot]` | bot連鎖防止                    |
| 4   | `claude.yml` の timeout                        | `20` 分以下                              | 長時間実行抑制                 |
| 5   | `claude-code-review.yml` の `synchronize` 除外 | `[opened, ready_for_review]`             | push毎のレビュー実行防止       |
| 6   | Copilot code review との重複                   | どちらか1つに統一                        | AIレビュー重複防止             |

```bash
# claude.yml のチェック
if [ -f ".github/workflows/claude.yml" ]; then
  CLAUDE_YML=$(cat .github/workflows/claude.yml)

  if echo "$CLAUDE_YML" | grep -q "cancel-in-progress: false"; then
    ISSUES+=("claude.yml: cancel-in-progress が false（推奨: true）")
  fi

  if echo "$CLAUDE_YML" | grep -q "assigned"; then
    ISSUES+=("claude.yml: issues トリガーに assigned が含まれている（推奨: opened のみ）")
  fi

  if ! echo "$CLAUDE_YML" | grep -q "github-actions\[bot\]"; then
    ISSUES+=("claude.yml: bot ユーザー除外が未設定")
  fi

  if ! echo "$CLAUDE_YML" | grep -q "draft"; then
    ISSUES+=("claude.yml: Draft PR スキップが未設定")
  fi

  TIMEOUT=$(echo "$CLAUDE_YML" | grep "timeout-minutes:" | head -1 | grep -o '[0-9]*')
  if [ -n "$TIMEOUT" ] && [ "$TIMEOUT" -gt 20 ]; then
    ISSUES+=("claude.yml: timeout が ${TIMEOUT}分（推奨: 20分以下）")
  fi
fi

# claude-code-review.yml のチェック
if [ -f ".github/workflows/claude-code-review.yml" ]; then
  REVIEW_YML=$(cat .github/workflows/claude-code-review.yml)

  if echo "$REVIEW_YML" | grep -q "synchronize"; then
    ISSUES+=("claude-code-review.yml: synchronize トリガーが有効（push毎にレビュー実行される）")
  fi
fi
```

#### 3.6.3 CI/CD ワークフロー固有チェック

**確認対象:** テスト・ビルド・デプロイ系ワークフロー

**チェック項目:**

| #   | チェック             | 推奨値                                                   | コスト影響                       |
| --- | -------------------- | -------------------------------------------------------- | -------------------------------- |
| 1   | `paths` フィルタ     | ソースコード変更時のみ実行                               | ドキュメント変更での不要実行防止 |
| 2   | キャッシュ設定       | `actions/cache` or `actions/setup-node` の cache         | ビルド時間短縮                   |
| 3   | マトリクスの最適化   | 必要最小限の組み合わせ                                   | 並列ジョブ数の削減               |
| 4   | Dependabot PR の制限 | `if: github.actor != 'dependabot[bot]'` (高コストジョブ) | 依存更新での過剰実行防止         |

```bash
for workflow in .github/workflows/ci*.yml .github/workflows/test*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  CONTENT=$(cat "$workflow")

  # キャッシュ設定チェック
  if echo "$CONTENT" | grep -qE "(npm ci|npm install|pnpm install)" && \
     ! echo "$CONTENT" | grep -qE "(actions/cache|cache:|actions/setup-node.*cache)"; then
    ISSUES+=("$BASENAME: パッケージインストールあり、キャッシュ未設定（ビルド時間増加）")
  fi

  # paths フィルタチェック（CI系）
  if echo "$CONTENT" | grep -q "pull_request:" && ! echo "$CONTENT" | grep -q "paths"; then
    ISSUES+=("$BASENAME: paths フィルタ未設定（推奨: src/ 等のコード変更のみトリガー）")
  fi
done
```

#### 3.6.4 セキュリティワークフローの重複チェック

同一リポジトリに重複するセキュリティスキャンがないか確認：

```bash
SECURITY_WORKFLOWS=()

# CodeQL チェック
ls .github/workflows/*.yml 2>/dev/null | while read -r f; do
  if grep -q "codeql" "$f" 2>/dev/null; then
    SECURITY_WORKFLOWS+=("$(basename "$f"):CodeQL")
  fi
  if grep -q "Security Scan\|security-scan\|trivy\|snyk" "$f" 2>/dev/null; then
    SECURITY_WORKFLOWS+=("$(basename "$f"):SecurityScan")
  fi
done

# AI レビューの重複チェック
AI_REVIEWS=0
[ -f ".github/workflows/claude-code-review.yml" ] && AI_REVIEWS=$((AI_REVIEWS + 1))
# Copilot code review は dynamic workflow なので GitHub 設定で確認
gh api repos/{owner}/{repo}/actions/workflows --jq '.workflows[] | select(.name | test("Copilot code review"))' 2>/dev/null && AI_REVIEWS=$((AI_REVIEWS + 1))

if [ "$AI_REVIEWS" -gt 1 ]; then
  ISSUES+=("AIレビューが複数有効（Claude Code Review + Copilot）。どちらか1つに統一推奨")
fi
```

**結果パターン:**

| 状態          | 対応                                        |
| ------------- | ------------------------------------------- |
| 全チェック OK | ✅ GitHub Actions 最適化済み                |
| 問題あり      | ⚠️ コスト最適化の余地あり（問題リスト表示） |

**MODE が `full` かつ問題がある場合:**

Claude 関連ワークフローは keito4/config のテンプレートと比較し、差分を自動適用するかユーザーに確認。
その他のワークフローは推奨設定をリスト表示し、個別に適用するか確認。

```bash
# config リポジトリの最新テンプレートを取得
TEMPLATE_CLAUDE=$(curl -fsSL "https://raw.githubusercontent.com/keito4/config/main/.github/workflows/claude.yml")
TEMPLATE_REVIEW=$(curl -fsSL "https://raw.githubusercontent.com/keito4/config/main/.github/workflows/claude-code-review.yml")

# 差分がある場合はテンプレートで上書きを提案
```

**結果:**

- ✅ GitHub Actions 最適化済み
- 🔧 ワークフローを最適化しました（変更リスト表示）
- ⏭️ スキップ（GitHub Actions 未使用）

**背景:**
Elu-co-jp org で Claude Code ワークフローの過剰実行（1日64回等）や
CI/CDの非効率な設定がActions費用の最大要因（推定 $400+/3ヶ月）であったことから、
このチェックをデフォルトで実行し、全リポジトリのコスト最適化を推奨する。

#### 3.6.5 Actions Artifact 保持期間チェック

Actions で生成される Artifact のストレージ保持期間を確認：

**背景:**
GitHub Actions の Artifact はデフォルトで **90日間** 保持され、ストレージ課金の対象となる。
多くの場合、Artifact は CI 結果の確認が終われば不要であり、30日以下で十分。

**チェック項目:**

| #   | チェック                               | 推奨値                    | コスト影響         |
| --- | -------------------------------------- | ------------------------- | ------------------ |
| 1   | ワークフロー内の `retention-days` 設定 | 明示的に `7`〜`30` 日     | ストレージ課金削減 |
| 2   | `actions/upload-artifact` の使用箇所   | retention-days を必ず指定 | 90日保持の防止     |

**確認ロジック:**

```bash
ISSUES=()

for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  CONTENT=$(cat "$workflow")

  # upload-artifact を使用しているか確認
  if echo "$CONTENT" | grep -q "actions/upload-artifact"; then
    # retention-days が設定されているか確認
    if ! echo "$CONTENT" | grep -q "retention-days:"; then
      ISSUES+=("$BASENAME: upload-artifact 使用あり、retention-days 未設定（デフォルト90日保持）")
    else
      # 設定値を確認
      RETENTION=$(echo "$CONTENT" | grep "retention-days:" | head -1 | grep -o '[0-9]*')
      if [ -n "$RETENTION" ] && [ "$RETENTION" -gt 30 ]; then
        ISSUES+=("$BASENAME: retention-days が ${RETENTION}日（推奨: 30日以下）")
      fi
    fi
  fi
done
```

**MODE が `full` かつ問題がある場合:**

upload-artifact ステップに `retention-days: 7` を追加するか、リポジトリ設定でデフォルト保持期間を変更：

```bash
# リポジトリの Artifact 保持期間をAPIで確認
RETENTION=$(gh api repos/{owner}/{repo}/actions/cache/usage-policy --jq '.actions_cache_usage_limit_in_gb' 2>/dev/null)

# GitHub UI で設定変更を推奨:
# Settings → Actions → General → Artifact and log retention → 7 days
```

**結果:**

- ✅ Artifact 保持期間: 適切に設定済み
- ⚠️ retention-days 未設定の upload-artifact あり（リスト表示）
- ⏭️ スキップ（upload-artifact 未使用）

#### 3.6.6 未使用ワークフロー検出

存在するが長期間実行されていない、または無効化すべきワークフローを検出：

**背景:**
使われなくなったワークフローが残存していると、意図しないタイミングでトリガーされ、
不要な Actions 課金が発生する。特に `schedule` や `push` でトリガーされるワークフローは
忘れられたまま定期実行され続けるリスクがある。

**チェック項目:**

| #   | チェック                          | 判定基準            | 対応                 |
| --- | --------------------------------- | ------------------- | -------------------- |
| 1   | 30日以上実行のないワークフロー    | 最終実行日 > 30日前 | 無効化を提案         |
| 2   | `schedule` トリガーのワークフロー | cron 設定の確認     | 本当に必要か確認     |
| 3   | 失敗し続けているワークフロー      | 直近5回が全て失敗   | 修正 or 無効化を提案 |

**確認ロジック:**

```bash
ISSUES=()
THIRTY_DAYS_AGO=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# 全ワークフローの最終実行日を確認
gh api "repos/$REPO/actions/workflows" --jq '.workflows[] | select(.state == "active") | {id, name, path}' | while read -r line; do
  WORKFLOW_ID=$(echo "$line" | jq -r '.id')
  WORKFLOW_NAME=$(echo "$line" | jq -r '.name')
  WORKFLOW_PATH=$(echo "$line" | jq -r '.path')

  # dynamic ワークフロー（Copilot, Dependabot等）はスキップ
  if echo "$WORKFLOW_PATH" | grep -q "^dynamic/"; then
    continue
  fi

  # 最新の実行を取得
  LATEST_RUN=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=1" --jq '.workflow_runs[0]' 2>/dev/null)

  if [ -z "$LATEST_RUN" ] || [ "$LATEST_RUN" = "null" ]; then
    ISSUES+=("$WORKFLOW_NAME: 実行履歴なし（不要なら削除推奨）")
    continue
  fi

  LAST_RUN_DATE=$(echo "$LATEST_RUN" | jq -r '.created_at')

  # 30日以上実行されていない
  if [[ "$LAST_RUN_DATE" < "$THIRTY_DAYS_AGO" ]]; then
    ISSUES+=("$WORKFLOW_NAME: 最終実行 $LAST_RUN_DATE（30日以上未実行、無効化を検討）")
  fi

  # 直近5回の実行結果を確認
  RECENT_CONCLUSIONS=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=5" \
    --jq '[.workflow_runs[].conclusion] | map(select(. != null))' 2>/dev/null)

  ALL_FAILED=$(echo "$RECENT_CONCLUSIONS" | jq 'all(. == "failure")' 2>/dev/null)
  if [ "$ALL_FAILED" = "true" ]; then
    ISSUES+=("$WORKFLOW_NAME: 直近5回すべて失敗（修正 or 無効化が必要）")
  fi
done

# schedule トリガーのワークフロー一覧
for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  if grep -q "schedule:" "$workflow"; then
    CRON=$(grep -A1 "schedule:" "$workflow" | grep "cron:" | head -1 | sed 's/.*cron: *//')
    ISSUES+=("INFO: $BASENAME: schedule トリガーあり（$CRON）— 定期実行が必要か確認")
  fi
done
```

**MODE が `full` かつ問題がある場合:**

未使用ワークフローの無効化をユーザーに確認してから実行：

```bash
# ワークフローを無効化
gh api -X PUT "repos/$REPO/actions/workflows/$WORKFLOW_ID/disable"
```

**結果:**

- ✅ 全ワークフローがアクティブに使用されている
- ⚠️ 未使用ワークフロー: X 件（リスト表示）
- ⚠️ 常時失敗ワークフロー: X 件（リスト表示）
- 📝 schedule ワークフロー: X 件（要確認リスト表示）

#### 3.6.7 Actions Runner サイズチェック

不必要に高スペックな Runner の使用を検出：

**背景:**
GitHub-hosted Runner は種類により単価が異なる。Linux 2-core（`ubuntu-latest`）は $0.008/分だが、
Large Runner（8-core）は $0.032/分、Windows は $0.016/分と2〜4倍の課金となる。
必要以上のスペックを使用するとコストが膨らむ。

**Runner 単価一覧:**

| Runner                   | 単価/分 | 倍率 |
| ------------------------ | ------- | ---- |
| `ubuntu-latest` (2-core) | $0.008  | 1x   |
| `ubuntu-latest-4-core`   | $0.016  | 2x   |
| `ubuntu-latest-8-core`   | $0.032  | 4x   |
| `ubuntu-latest-16-core`  | $0.064  | 8x   |
| `windows-latest`         | $0.016  | 2x   |
| `macos-latest`           | $0.08   | 10x  |

**チェック項目:**

| #   | チェック                       | 推奨                              | コスト影響       |
| --- | ------------------------------ | --------------------------------- | ---------------- |
| 1   | `runs-on` で Large Runner 使用 | 本当に必要か確認                  | 2〜8倍のコスト差 |
| 2   | `runs-on: windows-latest`      | Linux で代替可能か確認            | 2倍のコスト差    |
| 3   | `runs-on: macos-latest`        | iOS/macOS ビルド以外は Linux 推奨 | 10倍のコスト差   |

**確認ロジック:**

```bash
ISSUES=()

for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  CONTENT=$(cat "$workflow")

  # Large Runner の検出
  if echo "$CONTENT" | grep -qE "runs-on:.*(-[0-9]+-core|xlarge|2xlarge|4xlarge)"; then
    RUNNERS=$(echo "$CONTENT" | grep -oE "runs-on:.*" | sort -u)
    ISSUES+=("$BASENAME: Large Runner 使用（$RUNNERS）— 本当に必要か確認")
  fi

  # Windows Runner の検出
  if echo "$CONTENT" | grep -q "runs-on:.*windows"; then
    ISSUES+=("$BASENAME: Windows Runner 使用（$0.016/分、Linux の2倍）— Linux で代替可能か確認")
  fi

  # macOS Runner の検出
  if echo "$CONTENT" | grep -q "runs-on:.*macos"; then
    ISSUES+=("$BASENAME: macOS Runner 使用（$0.08/分、Linux の10倍）— iOS/macOS ビルド以外なら Linux 推奨")
  fi
done
```

**結果:**

- ✅ 全ワークフローが標準 Runner（ubuntu-latest）を使用
- ⚠️ 高コスト Runner 使用: X 件（リスト表示・代替案提示）
- 📝 Windows/macOS Runner: X 件（用途が適切か確認推奨）

### 3.7 Renovate / Dependabot 設定チェック

依存関係の自動更新設定を確認：

**確認ロジック:**

```bash
HAS_RENOVATE=false
HAS_DEPENDABOT=false

[ -f ".github/renovate.json" ] || [ -f ".github/renovate.json5" ] || \
  [ -f "renovate.json" ] || [ -f "renovate.json5" ] && HAS_RENOVATE=true

[ -f ".github/dependabot.yml" ] || [ -f ".github/dependabot.yaml" ] && HAS_DEPENDABOT=true
```

**結果パターン:**

| 状態                                  | 対応                                    |
| ------------------------------------- | --------------------------------------- |
| Renovate または Dependabot が設定済み | ✅ スキップ                             |
| どちらも未設定                        | ⚠️ → full mode でテンプレート生成を提案 |

**MODE が `full` かつ未設定の場合:**

Renovate の最小構成テンプレートを生成：

```bash
mkdir -p .github
cat > .github/renovate.json << 'EOF'
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 9am on Monday"],
  "automerge": false,
  "labels": ["dependencies"],
  "packageRules": [
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    }
  ]
}
EOF
echo "🔧 .github/renovate.json を生成しました"
echo "   GitHub Apps で Renovate をインストールしてください:"
echo "   https://github.com/apps/renovate"
```

**結果:**

- ✅ Renovate / Dependabot 設定済み
- 🔧 .github/renovate.json を生成しました
- ⏭️ スキップ（`package.json` なし）

### 3.8 commitlint 設定チェック

コミットメッセージの品質管理設定を確認：

**確認ロジック:**

```bash
HAS_COMMITLINT=false
HAS_COMMITMSG_HOOK=false

# commitlint 設定ファイルの確認
for f in commitlint.config.js commitlint.config.ts commitlint.config.mjs \
          commitlint.config.cjs .commitlintrc.js .commitlintrc.json \
          .commitlintrc.yml .commitlintrc.yaml; do
  [ -f "$f" ] && HAS_COMMITLINT=true && break
done

# Husky commit-msg フックの確認
grep -q "commitlint" .husky/commit-msg 2>/dev/null && HAS_COMMITMSG_HOOK=true
```

**結果パターン:**

| 状態                                        | 対応                                    |
| ------------------------------------------- | --------------------------------------- |
| commitlint 設定あり + commit-msg フックあり | ✅ 設定済み                             |
| commitlint 設定あり + commit-msg フックなし | ⚠️ フック未設定                         |
| commitlint 設定なし                         | ⚠️ → full mode で `/setup-husky` を提案 |

**結果:**

- ✅ commitlint 設定済み（commit-msg フック連携）
- ⚠️ commitlint 設定あり、commit-msg フック未設定 → `/setup-husky` で追加を提案
- ⚠️ commitlint 未設定 → `/setup-husky` でセットアップを提案
- ⏭️ スキップ（Husky 未設定）

### 3.9 .editorconfig 設定チェック

エディタ間のコーディングスタイル一貫性を確認：

**確認ロジック:**

```bash
HAS_EDITORCONFIG=false
[ -f ".editorconfig" ] && HAS_EDITORCONFIG=true
```

**MODE が `full` かつ未設定の場合:**

標準テンプレートを生成：

```bash
cat > .editorconfig << 'EOF'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
EOF
echo "🔧 .editorconfig を生成しました"
```

**結果:**

- ✅ .editorconfig 設定済み
- 🔧 .editorconfig を生成しました
- ⏭️ スキップ（`check-only` モード）

### 3.10 package.json scripts 標準チェック

Quality Gates で必要なスクリプトが揃っているか確認：

**必須スクリプト一覧:**

| スクリプト                      | 目的                 | Quality Gate での使用 |
| ------------------------------- | -------------------- | --------------------- |
| `dev`                           | 開発サーバー起動     | -                     |
| `build`                         | プロダクションビルド | CI/CD                 |
| `test` または `test:unit`       | ユニットテスト       | pre-commit / CI       |
| `lint` または `lint:check`      | Lint チェック        | pre-commit / CI       |
| `format:check`                  | フォーマットチェック | pre-commit / CI       |
| `typecheck` または `type-check` | 型チェック           | CI                    |

**確認ロジック:**

```bash
MISSING_SCRIPTS=()
SCRIPTS=$(jq -r '.scripts | keys[]' package.json 2>/dev/null)

check_script() {
  local name="$1"
  shift
  for alias in "$@"; do
    echo "$SCRIPTS" | grep -qx "$alias" && return 0
  done
  MISSING_SCRIPTS+=("$name")
}

check_script "test"        "test" "test:unit"
# Biome プロジェクトは "check" スクリプトで lint + format を統合する場合がある
check_script "lint"        "lint" "lint:check"
check_script "format:check" "format:check"
check_script "typecheck"   "typecheck" "type-check" "tsc"
```

**結果:**

- ✅ 必須スクリプト: すべて定義済み
- ⚠️ 未定義スクリプト: X 件（リスト表示）
- ⏭️ スキップ（`package.json` なし）

## Step 4: Cleanup Category

### 4.1 Branch Cleanup

ブランチの状態を確認：

実行内容:

- マージ済みブランチの検出
- 古いブランチ（30日以上）の検出
- 削除されたリモートブランチの検出

これは `/branch-cleanup --dry-run` コマンドと同等の処理を実行します。

結果:

- 🗑️ 削除候補: X ブランチ
  - マージ済み: Y
  - 古いブランチ: Z

MODE が `full` の場合:

- 対話的に削除を確認
- または `--yes` フラグで自動削除

### 4.2 Git Repository Cleanup

Git リポジトリのクリーンアップ：

```bash
git gc --auto
git prune
```

## Step 5: Discovery Category (full mode only)

### 5.1 Config Contribution Discovery

config リポジトリから取り込み可能な新機能を発見：

実行内容:

- 新しいコマンドの検出
- 新しいワークフローの検出
- 推奨設定の更新確認

これは `/config-contribution-discover` コマンドと同等の処理を実行します。

結果:

- 🆕 新機能: X 件
- 📝 更新推奨: Y 件

### 5.2 推奨パッケージ監査

プロジェクト種別を自動検出し、推奨スタックとの差分を確認する。

#### プロジェクト種別の検出

以下の順序でプロジェクト種別を判定：

```bash
# Next.js プロジェクト
if grep -q '"next"' package.json 2>/dev/null; then
  PROJECT_TYPE="nextjs"
# React + Vite SPA
elif grep -q '"vite"' package.json 2>/dev/null && grep -q '"react"' package.json 2>/dev/null; then
  PROJECT_TYPE="spa-react"
else
  PROJECT_TYPE="unknown"
fi
```

#### Next.js 推奨パッケージ

| カテゴリ               | パッケージ               | 確認方法                                                      |
| ---------------------- | ------------------------ | ------------------------------------------------------------- |
| ロギング               | `@vercel/logger`         | `jq '.dependencies["@vercel/logger"]' package.json`           |
| エラー監視             | `@sentry/nextjs`         | `jq '.dependencies["@sentry/nextjs"]' package.json`           |
| バリデーション         | `zod`                    | `jq '.dependencies.zod' package.json`                         |
| 型安全な環境変数       | `@t3-oss/env-nextjs`     | `jq '.dependencies["@t3-oss/env-nextjs"]' package.json`       |
| フォーム管理           | `react-hook-form`        | `jq '.dependencies["react-hook-form"]' package.json`          |
| フォームバリデーション | `@hookform/resolvers`    | `jq '.dependencies["@hookform/resolvers"]' package.json`      |
| アクセシビリティE2E    | `@axe-core/playwright`   | `jq '.devDependencies["@axe-core/playwright"]' package.json`  |
| アクセシビリティUnit   | `jest-axe`               | `jq '.devDependencies["jest-axe"]' package.json`              |
| バンドル分析           | `@next/bundle-analyzer`  | `jq '.devDependencies["@next/bundle-analyzer"]' package.json` |
| アナリティクス         | `@vercel/analytics`      | `jq '.dependencies["@vercel/analytics"]' package.json`        |
| パフォーマンス計測     | `@vercel/speed-insights` | `jq '.dependencies["@vercel/speed-insights"]' package.json`   |
| Lint/Format            | `@biomejs/biome`         | `jq '.devDependencies["@biomejs/biome"]' package.json`        |
| 未使用コード検出       | `knip`                   | `jq '.devDependencies.knip' package.json`                     |

#### SPA (React + Vite) 推奨パッケージ

| カテゴリ       | パッケージ               | 確認方法                                                       |
| -------------- | ------------------------ | -------------------------------------------------------------- |
| Lint/Format    | `@biomejs/biome`         | `jq '.devDependencies["@biomejs/biome"]' package.json`         |
| テスト         | `vitest`                 | `jq '.devDependencies.vitest' package.json`                    |
| カバレッジ     | `@vitest/coverage-v8`    | `jq '.devDependencies["@vitest/coverage-v8"]' package.json`    |
| コンポーネント | `@testing-library/react` | `jq '.devDependencies["@testing-library/react"]' package.json` |

#### 実行ロジック

```bash
MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
  installed=$(jq -r --arg p "$pkg" '.dependencies[$p] // .devDependencies[$p] // "null"' package.json)
  if [ "$installed" = "null" ]; then
    MISSING_PACKAGES+=("$pkg")
  fi
done
```

#### 結果

- ✅ 推奨パッケージ: すべてインストール済み
- ⚠️ 未導入パッケージ: X 件（インストールコマンドをリスト表示）
- ⏭️ スキップ（`package.json` なし / プロジェクト種別不明）

**パッケージマネージャーの自動検出（`ni` 対応）:**

`ni`（antfu/ni）がインストール済みの場合は優先使用し、ロックファイルから自動判定：

```bash
# パッケージマネージャーの検出
detect_pm() {
  if command -v ni >/dev/null 2>&1; then
    echo "ni"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    echo "bun"
  else
    echo "npm"
  fi
}

PM=$(detect_pm)
case "$PM" in
  ni)   INSTALL="ni"; INSTALL_DEV="ni -D" ;;
  pnpm) INSTALL="pnpm add"; INSTALL_DEV="pnpm add -D" ;;
  yarn) INSTALL="yarn add"; INSTALL_DEV="yarn add -D" ;;
  bun)  INSTALL="bun add"; INSTALL_DEV="bun add -D" ;;
  *)    INSTALL="npm install"; INSTALL_DEV="npm install -D" ;;
esac
```

**未導入パッケージがある場合の出力例:**

```
⚠️ 推奨パッケージが未導入です (Next.js)

未導入:
  - @vercel/logger      (ロギング)
  - @sentry/nextjs      (エラー監視)
  - knip                (未使用コード検出)

インストールコマンド:
  ni @vercel/logger @sentry/nextjs    # ni が利用可能な場合
  ni -D knip

詳細: docs/setup/web-app-nextjs.md
```

**MODE が `full` の場合:**

インストールを確認してから実行：

```bash
# 確認後に実行（パッケージマネージャーは自動検出）
$INSTALL @vercel/logger @sentry/nextjs
$INSTALL_DEV @biomejs/biome knip
```

## Step 6: Generate Summary Report

全ステップの結果をまとめたレポートを生成：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Maintenance Summary Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Environment (1/4)
├── Container Health: ✅ Healthy (Score: 95/100)
├── DevContainer: ⚠️ Update available (v1.13.1 → v1.15.0)
├── Claude Code: ✅ Up to date
├── GitHub Actions: ✅ All actions up to date
├── Claude Settings: ✅ Synced
├── Claude Code LSP: ⚠️ Not configured (TypeScript detected)
└── Codespaces Secrets: ✅ Synced (or ⏭️ Skipped)

## Setup (2/4)
├── Team Protection: ✅ Branch protection enabled
├── Husky: ✅ Git hooks configured\n├── hooksPath: ✅ Valid (.husky) (or 🔧 Fixed / ❌ Manual required)\n├── Husky v8→v9: ✅ v9スタイル済み (or 🔧 移行しました / ✅ スキップ)
├── check-file-length: ✅ Configured in pre-commit (or 🔧 Added / ⏭️ Skipped)
├── Renovate/Dependabot: ✅ Auto-update configured (or 🔧 renovate.json generated / ⏭️ Skipped)
├── commitlint: ✅ Configured with commit-msg hook (or ⚠️ Hook missing / ⚠️ Not configured)
├── .editorconfig: ✅ Configured (or 🔧 Generated)
├── scripts: ✅ All standard scripts defined (or ⚠️ Missing: test, lint)
├── Pre-PR Checklist: ✅ CI workflow exists
├── CLAUDE.md: ✅ Symlink to AGENTS.md
├── CI/CD: ✅ Standard level configured
├── Actions Cost: ✅ Optimized (or ⚠️ X issues found)
│   ├── Artifact Retention: ✅ (or ⚠️ 90-day default detected)
│   ├── Unused Workflows: ✅ (or ⚠️ X stale workflows)
│   └── Runner Size: ✅ (or ⚠️ High-cost runners detected)
├── Renovate/Dependabot: ✅ Auto-update configured

## Cleanup (3/4)
├── Branches: 🗑️ 8 merged branches can be deleted
└── Git GC: ✅ Repository optimized

## Discovery (4/4)
├── New Features: 🆕 2 new commands available
└── Package Audit: ⚠️ 3 recommended packages missing (Next.js)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Overall Health Score: 82/100

## Action Items (Priority Order)

### 🔴 Immediate (Setup)
1. Configure branch protection rules
   Run: /setup-team-protection
2. Setup Git hooks (Husky)
   Run: /setup-husky
3. Setup CI/CD workflows
   Run: /setup-ci

### 🟡 Soon (Updates)
4. Update DevContainer to v1.15.0
   Run: /config-base-sync-update

### 🟢 Recommended (Maintenance)
5. Delete 8 merged branches
   Run: /branch-cleanup
6. Review 2 new config features
   Run: /config-contribution-discover
7. Install 3 missing recommended packages (Next.js)
   Run: npm install @vercel/logger @sentry/nextjs && npm install -D knip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 7: Create PR (Optional)

`--create-pr` が指定されており、かつ変更がある場合：

### 7.1 Check for Changes

```bash
git status --porcelain
```

変更がない場合:

- "No changes to commit. Skipping PR creation."
- 終了

### 7.2 Create Branch

```bash
git checkout -b maintenance/$(date +%Y%m%d)
```

### 7.3 Commit Changes

```bash
git add -A
git commit -m "chore: repository maintenance $(date +%Y-%m-%d)

## Changes
- [List of changes from each category]

## Health Score
- Before: X/100
- After: Y/100

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 7.4 Push and Create PR

```bash
git push -u origin maintenance/$(date +%Y%m%d)

gh pr create \
  --base main \
  --title "chore: Repository maintenance $(date +%Y-%m-%d)" \
  --body "$(cat <<'EOF'
## Summary

Automated repository maintenance performed on $(date +%Y-%m-%d).

## Changes

### Environment
- [List changes]

### Setup
- [List changes]

### Cleanup
- [List changes]

### Discovery
- [List changes]

## Health Score
- Before: X/100
- After: Y/100

## Checklist
- [ ] CI passes
- [ ] No breaking changes
- [ ] Review action items

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Step 7.5: CI Monitoring (Automatic)

PR作成後、自動的にCIステータスを監視します。

### 自動監視の仕組み

`.claude/hooks/post_pr_ci_watch.py` フックにより、`gh pr create` 実行後に自動的にCIを監視:

1. PR作成成功を検出
2. CIチェック状態を15秒ごとにポーリング
3. 最大10分間監視
4. 結果を報告

### 監視結果

| 状態           | 出力                           | 対応                              |
| -------------- | ------------------------------ | --------------------------------- |
| 全チェック成功 | ✅ 全CIチェック成功！          | マージ可能                        |
| チェック失敗   | ❌ CIチェック失敗 + 失敗リスト | このブランチで修正                |
| タイムアウト   | ⏰ CI監視タイムアウト          | `gh pr checks --watch` で手動確認 |
| チェックなし   | ⚠️ CIチェックが見つかりません  | CI未設定の可能性                  |

### 手動確認コマンド

```bash
# CIステータスを確認
gh pr checks

# リアルタイム監視
gh pr checks --watch

# 失敗したチェックの詳細
gh run view <run-id> --log-failed
```

### CI失敗時の対応

1. 失敗したチェックを特定
2. このブランチで修正
3. コミット＆プッシュ
4. CIが再実行されることを確認
5. CIが緑になるまで繰り返す

**原則**: CIが緑になるまでPRを放置しない

## Step 8: Final Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Repository Maintenance Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mode: {MODE}
Duration: {elapsed_time}
Health Score: {score}/100

Categories Processed:
✅ Environment: {status}
✅ Setup: {status}
✅ Cleanup: {status}
✅ Discovery: {status}

{if PR created}
PR Created: {PR_URL}
{endif}

Next Steps:
1. Review the summary report above
2. Address action items by priority
3. {if PR created} Review and merge the PR {endif}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run this command regularly to maintain repository health:
  /repo-maintenance --mode quick    # Quick daily check
  /repo-maintenance --mode full     # Weekly full maintenance
```

---

## Progress Reporting

各ステップの進捗を報告：

- ✅ Step N: [完了した操作]
- 🔄 Step N: [実行中の操作]
- ⏭️ Step N: [スキップ（理由）]
- ❌ Step N: [失敗 - 理由]

## Error Handling

エラー発生時：

1. 具体的なエラー内容を報告
2. 可能な限り次のステップに進む（致命的エラー以外）
3. 最終レポートにエラーを含める
4. 修正方法を提案

## Related Commands

このコマンドは以下のコマンドを内部的に呼び出します：

| カテゴリ    | コマンド                        | 説明                          |
| ----------- | ------------------------------- | ----------------------------- |
| Environment | `/container-health`             | コンテナ健全性                |
| Environment | `/config-base-sync-check`       | DevContainer バージョン       |
| Environment | `/config-base-sync-update`      | DevContainer 更新             |
| Environment | `/update-claude-code`           | Claude Code 更新              |
| Environment | `/update-actions`               | GitHub Actions バージョン更新 |
| Environment | `/sync-claude-settings`         | Claude 設定同期               |
| Environment | (Claude Code LSP setup)         | LSP 設定                      |
| Environment | `/codespaces-secrets`           | Codespaces シークレット同期   |
| Setup       | `/setup-team-protection`        | GitHub保護ルール設定          |
| Setup       | `/setup-husky`                  | Git hooks設定                 |
| Setup       | (check-file-length auto-setup)  | ファイル行数チェック追加      |
| Setup       | `/pre-pr-checklist`             | PR前チェックリスト            |
| Setup       | (CLAUDE.md symlink check)       | CLAUDE.md シンボリックリンク  |
| Setup       | `/setup-ci`                     | CI/CDワークフロー設定         |
| Setup       | (Actions Cost Optimization)     | GitHub Actions コスト最適化   |
| Setup       | (Renovate/Dependabot check)     | 依存関係自動更新設定          |
| Setup       | (commitlint check)              | コミットメッセージ品質管理    |
| Setup       | (editorconfig check)            | エディタスタイル設定          |
| Setup       | (scripts standard check)        | package.json scripts 標準確認 |
| Cleanup     | `/branch-cleanup`               | ブランチクリーンアップ        |
| Discovery   | `/config-contribution-discover` | 新機能発見                    |
| Discovery   | (Package Audit + ni support)    | 推奨パッケージ監査            |
| PR          | (post_pr_ci_watch.py hook)      | PR作成後のCI自動監視          |
