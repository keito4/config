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

### 2.9 GitHub Actions Security Hardening Check

GitHub Actions のサプライチェーン保護状況を確認：

**背景:**
3rd-party actions のタグ参照（`@v4` 等）はタグの付け替えにより悪意あるコードに差し替えられるリスクがある。
GitHub はフル SHA 固定を immutable な使い方として推奨しており、`GITHUB_TOKEN` には least privilege を適用すべきとしている。

**チェック項目:**

| #   | チェック                       | 推奨値                                     | リスク                         |
| --- | ------------------------------ | ------------------------------------------ | ------------------------------ |
| 1   | 3rd-party actions の SHA 固定  | フルSHA（40文字）で参照                    | タグ改ざんによるコード注入     |
| 2   | `GITHUB_TOKEN` の権限制限      | workflow/job レベルで `permissions` を明示 | 過剰権限によるトークン悪用     |
| 3   | 許可 actions の制限            | Repository Settings で制限                 | 任意の actions 実行リスク      |
| 4   | `pull_request_target` の安全性 | 未使用 or secrets 非参照                   | Fork PR 経由のシークレット漏洩 |

**確認ロジック:**

```bash
ISSUES=()

for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  CONTENT=$(cat "$workflow")

  # 1. 3rd-party actions の SHA 固定チェック
  # actions/ と github/ org 以外の actions を検出
  THIRD_PARTY=$(echo "$CONTENT" | grep -oE "uses: [^/]+/[^@]+@[^ ]+" | \
    grep -vE "^uses: (actions|github)/" | \
    grep -vE "@[0-9a-f]{40}")
  if [ -n "$THIRD_PARTY" ]; then
    while IFS= read -r line; do
      ISSUES+=("$BASENAME: SHA未固定の3rd-party action: $line")
    done <<< "$THIRD_PARTY"
  fi

  # 2. GITHUB_TOKEN 権限チェック（top-level permissions の有無）
  if ! echo "$CONTENT" | grep -q "^permissions:"; then
    ISSUES+=("$BASENAME: top-level permissions 未設定（デフォルトは write-all）")
  fi

  # 3. pull_request_target の安全性チェック
  if echo "$CONTENT" | grep -q "pull_request_target:"; then
    if echo "$CONTENT" | grep -qE "(secrets\.|GITHUB_TOKEN)"; then
      ISSUES+=("$BASENAME: pull_request_target + secrets/GITHUB_TOKEN 使用（Fork PR からのシークレット漏洩リスク）")
    fi
  fi
done
```

**リポジトリ設定の確認:**

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# 許可 actions の設定確認
ACTIONS_PERMS=$(gh api "repos/$REPO/actions/permissions" --jq '.allowed_actions' 2>/dev/null)
if [ "$ACTIONS_PERMS" = "all" ]; then
  ISSUES+=("Repository Settings: 全 actions が許可されている（推奨: selected に制限）")
fi

# デフォルト GITHUB_TOKEN 権限の確認
DEFAULT_PERMS=$(gh api "repos/$REPO/actions/permissions/workflow" --jq '.default_workflow_permissions' 2>/dev/null)
if [ "$DEFAULT_PERMS" = "write" ]; then
  ISSUES+=("Repository Settings: GITHUB_TOKEN デフォルト権限が write（推奨: read）")
fi
```

**MODE が `full` かつ問題がある場合:**

- SHA 未固定の actions をリスト表示し、`npx pin-github-action` で固定するコマンドを提示
- top-level `permissions: {}` の追加を提案
- Repository Settings の変更手順を案内

```bash
# SHA 固定のための推奨コマンド
echo "📌 以下のコマンドで actions を SHA 固定できます:"
echo "  npx pin-github-action .github/workflows/$BASENAME"

# GITHUB_TOKEN デフォルト権限の変更
gh api -X PUT "repos/$REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=false
```

**結果:**

- ✅ GitHub Actions セキュリティハードニング: 問題なし
- ⚠️ SHA 未固定の 3rd-party actions: X 件
- ⚠️ permissions 未設定のワークフロー: X 件
- ⚠️ Repository Settings の改善余地あり

## Step 3: Setup Category

### 3.1 Team Protection Setup (full mode only)

GitHub リポジトリの保護ルールを確認・設定：

実行内容:

- ブランチ保護ルールの確認
- 必須ステータスチェックの設定（`Quality Gate` ジョブ）
- レビュー要件の設定
- Dependabot、脆弱性アラートの有効化
- Next.js プロジェクトの場合、`pre-production` / `production` ブランチの保護確認

これは `/setup-team-protection` コマンドと同等の処理を実行します。

**フレームワーク検出による保護ブランチの自動判定:**

```bash
# Next.js プロジェクトかどうかを検出
IS_NEXTJS=false
if [ -f "package.json" ]; then
  if jq -e '.dependencies.next // .devDependencies.next' package.json &>/dev/null; then
    IS_NEXTJS=true
  fi
fi

# Next.js の場合は pre-production / production も保護対象
if [ "$IS_NEXTJS" = true ]; then
  PROTECT_BRANCHES="main,pre-production,production"
  PROTECTION_LEVEL="strict"
else
  PROTECT_BRANCHES="main"
  PROTECTION_LEVEL="standard"
fi
```

結果:

- ✅ 保護ルール設定済み
- ⚠️ 未設定の保護ルールあり（詳細をリスト）
- ⚠️ Next.js プロジェクト: `pre-production` / `production` ブランチ未保護 → strict レベルで保護を提案
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

### 3.3.1 Code Review Rules Check

コードレビュー基準の設定状況を確認：

実行内容:

- `.claude/rules/code-review-standards.md` の存在確認
- `.claude/rules/development-standards.md` の存在確認
- `.claude/rules/git-conventions.md` の存在確認
- config リポジトリのルールファイルとの差分確認（config リポジトリ自身は除く）

結果:

- ✅ すべてのレビュールールが設定済み
- ⚠️ 不足しているルールあり（詳細をリスト）
- 🔄 config リポジトリとの差分あり（更新推奨ファイルをリスト）

MODE が `full` の場合:

- 不足ルールを config リポジトリからコピー
- 差分があるファイルについて更新を提案

```bash
# config リポジトリのパスを取得（このリポジトリ自身なら SKIP）
CONFIG_REPO="$(git -C /path/to/config rev-parse --show-toplevel 2>/dev/null)"

# ルールファイルの存在確認
RULES_DIR=".claude/rules"
REQUIRED_RULES=("code-review-standards.md" "development-standards.md" "git-conventions.md")

for rule in "${REQUIRED_RULES[@]}"; do
  if [ ! -f "${RULES_DIR}/${rule}" ]; then
    echo "⚠️ Missing: ${RULES_DIR}/${rule}"
  fi
done
```

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

### 3.4.1 AGENTS.md Auto-Generated Sections Update

AGENTS.md の `<!-- BEGIN AUTO-GENERATED -->` 〜 `<!-- END AUTO-GENERATED -->` 間を、リポジトリの現在の状態に基づいて再生成する。

**背景:**
AGENTS.md は複数の AI エージェント（Claude, Codex, Gemini CLI 等）が参照する共通の設定ファイル。
プロジェクト構造、利用可能なコマンド、CI/CD ワークフロー、Quality Gates、Hooks の情報を
リポジトリの実態と常に同期させることで、AI エージェントが正確なコンテキストで動作できる。

**スキップ条件:**

```bash
# AGENTS.md が存在しない、またはマーカーがない場合はスキップ
if [ ! -f "AGENTS.md" ] || ! grep -q "BEGIN AUTO-GENERATED" AGENTS.md; then
  echo "⏭️ スキップ（AGENTS.md 未対応）"
fi
```

**自動生成セクションの構成:**

| セクション          | ソース                           | 内容                                               |
| ------------------- | -------------------------------- | -------------------------------------------------- |
| Repository Overview | `package.json`, `.devcontainer/` | Tech stack, パッケージマネージャー, ベースイメージ |
| Project Structure   | トップレベルディレクトリ         | 主要ディレクトリとその役割                         |
| Available Commands  | `.claude/commands/*.md`          | コマンド名と description フロントマター            |
| CI/CD Workflows     | `.github/workflows/*.yml`        | ワークフロー名と目的                               |
| Quality Gates       | `package.json` scripts           | 品質チェックスクリプト一覧                         |
| Hooks               | `.claude/hooks/*.py`             | フックスクリプトとトリガー・目的                   |

**生成ロジック:**

```bash
# 1. コマンド一覧の収集
COMMANDS=""
for cmd in .claude/commands/*.md; do
  [ ! -f "$cmd" ] && continue
  BASENAME=$(basename "$cmd" .md)
  [ "$BASENAME" = "README" ] && continue
  # frontmatter から description を取得
  DESC=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: */, ""); print; exit}' "$cmd")
  [ -z "$DESC" ] && DESC="(no description)"
  COMMANDS="$COMMANDS| \`/$BASENAME\` | $DESC |\n"
done

# 2. ワークフロー一覧の収集
WORKFLOWS=""
for wf in .github/workflows/*.yml; do
  [ ! -f "$wf" ] && continue
  BASENAME=$(basename "$wf")
  NAME=$(grep -m1 '^name:' "$wf" | sed 's/^name: *//' | tr -d "'\"")
  [ -z "$NAME" ] && NAME="(unnamed)"
  WORKFLOWS="$WORKFLOWS| \`$BASENAME\` | $NAME |\n"
done

# 3. Quality Gates スクリプトの収集
SCRIPTS=""
if [ -f "package.json" ]; then
  # format:check, lint, test, shellcheck, typecheck 等を検出
  for key in format:check lint test shellcheck typecheck type-check tsc; do
    val=$(jq -r --arg k "$key" '.scripts[$k] // empty' package.json)
    [ -n "$val" ] && SCRIPTS="$SCRIPTS| \`$key\` | \`$val\` |\n"
  done
fi

# 4. Hooks 一覧の収集
HOOKS=""
for hook in .claude/hooks/*.py; do
  [ ! -f "$hook" ] && continue
  BASENAME=$(basename "$hook")
  HOOKS="$HOOKS| \`$BASENAME\` | ... |\n"
done

# 5. Tech stack の検出
NODE_VER=$(jq -r '.engines.node // empty' package.json 2>/dev/null)
PM="npm"  # ロックファイルから自動判定
[ -f "pnpm-lock.yaml" ] && PM="pnpm"
[ -f "yarn.lock" ] && PM="yarn"
{ [ -f "bun.lockb" ] || [ -f "bun.lock" ]; } && PM="bun"

# 6. トップレベルディレクトリの収集
DIRS=""
for d in */; do
  case "$d" in
    node_modules/|coverage/|.git/|reports/) continue ;;
  esac
  DIRS="$DIRS| \`${d%/}/\` | ... |\n"
done
```

**AGENTS.md の更新:**

マーカー間の内容を新しい自動生成コンテンツで置換する。
静的セクション（Agent Guidelines, Development Standards）は変更しない。

```bash
# マーカー間を置換
# 1. BEGIN マーカーまでの内容を保持
# 2. 新しい自動生成コンテンツを挿入
# 3. END マーカー以降の内容を保持

HEAD=$(sed '/<!-- BEGIN AUTO-GENERATED -->/q' AGENTS.md)
TAIL=$(sed -n '/<!-- END AUTO-GENERATED -->/,$p' AGENTS.md)

# 新しい自動生成コンテンツを組み立て（上記で収集したデータを使用）
AUTO_CONTENT="<!-- This section is auto-generated by /repo-maintenance. Do not edit manually. -->

## Repository Overview
...

## Project Structure
...

## Available Commands
...

## CI/CD Workflows
...

## Quality Gates
...

## Hooks
..."

# ファイルを再構成
echo "$HEAD" > AGENTS.md
echo "$AUTO_CONTENT" >> AGENTS.md
echo "$TAIL" >> AGENTS.md
```

**実行スクリプト:** `script/update-agents-md.sh`

スクリプトが存在しない場合（他リポジトリ）は、以下の優先順でフォールバック取得する:

```bash
SCRIPT="script/update-agents-md.sh"
if [ ! -f "$SCRIPT" ]; then
  CONFIG_LOCAL="$HOME/develop/github.com/keito4/config/script/update-agents-md.sh"
  if [ -f "$CONFIG_LOCAL" ]; then
    SCRIPT="$CONFIG_LOCAL"
  elif [ -f "/usr/local/script/update-agents-md.sh" ]; then
    SCRIPT="/usr/local/script/update-agents-md.sh"
  else
    TMPSCRIPT=$(mktemp /tmp/update-agents-md-XXXXX.sh)
    curl -fsSL "https://raw.githubusercontent.com/keito4/config/main/script/update-agents-md.sh" -o "$TMPSCRIPT"
    chmod +x "$TMPSCRIPT"
    SCRIPT="$TMPSCRIPT"
  fi
fi
```

このスクリプトは以下を自動収集し、マーカー間を置換する:

1. Tech stack（`package.json` の engines、ロックファイルからパッケージマネージャー検出、`nix/flake.nix` の有無）
2. Project Structure（dot ディレクトリ + 通常ディレクトリを列挙し、既知のディレクトリには説明を付与）
3. Available Commands（`.claude/commands/*.md` の frontmatter description を取得）
4. CI/CD Workflows（`.github/workflows/*.yml` の `name:` を取得）
5. Quality Gates（`package.json` scripts から `format:check`, `lint`, `test`, `shellcheck`, `typecheck` 等を検出）
6. Hooks（`.claude/hooks/*.py` のファイル名からトリガーと目的を推定）
7. Development Standards（release-types ルール等の固定セクション）

生成後に Prettier でフォーマットし、冪等性を保証する。

**MODE ごとの動作:**

| MODE       | 動作                                |
| ---------- | ----------------------------------- |
| full       | `bash "$SCRIPT"` を実行し更新を適用 |
| quick      | `bash "$SCRIPT" --check` で差分報告 |
| check-only | `bash "$SCRIPT" --check` で差分報告 |

**結果:**

- ✅ AGENTS.md 自動生成セクション: 最新に更新済み
- 🔧 AGENTS.md 自動生成セクション: 更新しました
- ⏭️ スキップ（AGENTS.md 未対応 / マーカーなし）

### 3.5 CI/CD Setup Check (full mode only)

CI/CD ワークフローの設定状況を確認：

実行内容:

- GitHub Actions ワークフローの存在確認
- 必須ジョブ（Quality Gate による全チェック集約）の確認
- セキュリティスキャンの設定確認
- Claude Code Review の統合確認
- Scheduled Maintenance ワークフローの存在確認

これは `/setup-ci --dry-run` コマンドと同等の処理を実行します。

結果:

- ✅ CI/CD 設定済み
- ⚠️ CI/CD 未設定または不完全 → セットアップを提案
- 📝 推奨レベル: standard または comprehensive

MODE が `full` かつ CI/CD が未設定の場合:

`/setup-ci` コマンドの実行を提案。

### 3.5.0.1 Scheduled Maintenance Workflow Check

定期メンテナンス用ワークフローの存在と設定を確認：

**確認ロジック:**

```bash
SCHED_MAINT=".github/workflows/scheduled-maintenance.yml"
TEMPLATE="templates/workflows/scheduled-maintenance.yml"
TEMPLATE_RAW_URL="https://raw.githubusercontent.com/keito4/config/main/templates/workflows/scheduled-maintenance.yml"

if [ -f "$SCHED_MAINT" ]; then
  echo "scheduled-maintenance.yml: 存在"
else
  echo "scheduled-maintenance.yml: 未配置"
fi
```

**結果パターン:**

| 状態                                  | 対応                                    |
| ------------------------------------- | --------------------------------------- |
| ワークフロー存在 + テンプレートと一致 | ✅ スキップ                             |
| ワークフロー存在 + テンプレートと乖離 | ⚠️ テンプレートとの差分を表示           |
| ワークフロー未配置                    | ⚠️ → full mode でテンプレートからコピー |

**MODE が `full` かつ未配置の場合:**

```bash
mkdir -p .github/workflows

# テンプレート取得（優先順位順）
if [ -f "$TEMPLATE" ]; then
  cp "$TEMPLATE" "$SCHED_MAINT"
elif curl -fsSL "$TEMPLATE_RAW_URL" -o "$SCHED_MAINT" 2>/dev/null; then
  echo "テンプレートを GitHub から取得しました"
else
  echo "テンプレート取得に失敗しました"
fi
```

**前提条件:**

- `CLAUDE_CODE_OAUTH_TOKEN` シークレットがリポジトリに設定されていること
- シークレット未設定の場合は設定手順を案内

**結果:**

- ✅ scheduled-maintenance.yml 設定済み
- 🔧 scheduled-maintenance.yml を配置しました
- ⚠️ `CLAUDE_CODE_OAUTH_TOKEN` シークレットの設定が必要です

### 3.5.1 CI Workflow Template Sync Check

`templates/workflows/` のテンプレートと `.github/workflows/` の実ファイルを比較し、乖離を検出：

**確認ロジック:**

```bash
for f in templates/workflows/*.yml; do
  base=$(basename "$f")
  actual=".github/workflows/$base"
  if [ -f "$actual" ]; then
    if ! diff -q "$f" "$actual" > /dev/null 2>&1; then
      echo "DIFF: $base — テンプレートと実ファイルが乖離"
    fi
  else
    echo "MISS: $base — テンプレートはあるがワークフロー未配置"
  fi
done
```

**結果:**

- ✅ 全テンプレートと一致
- ⚠️ 乖離あり → diff を表示し、テンプレート更新 or ワークフロー更新を提案
- 📝 未配置テンプレートあり → 配置を提案（stale.yml 等はオプションのため確認のみ）

**MODE が `full` の場合:**

乖離しているファイルごとに:

1. `diff templates/workflows/$base .github/workflows/$base` を表示
2. テンプレートを実ファイルに反映するか確認
3. 承認された場合 `cp templates/workflows/$base .github/workflows/$base` を実行

### 3.5.2 CI Workflow Consistency Check

ワークフロー間の設定整合性を検証：

**チェック項目:**

| #   | チェック                               | 確認方法                                                                    | 推奨                           |
| --- | -------------------------------------- | --------------------------------------------------------------------------- | ------------------------------ |
| 1   | Node.js バージョン統一                 | `grep -rh 'node-version' .github/workflows/*.yml` と `.node-version` を比較 | `.node-version` の値と一致     |
| 2   | Actions バージョン統一                 | 同一アクションのバージョンがワークフロー間で一致しているか                  | 全ワークフローで同一バージョン |
| 3   | ジョブ名・ステータスチェック名の一貫性 | Required Status Checks に使われるジョブ名が正しいか                         | `Quality Gate` 等の統一名      |
| 4   | Runner バージョン                      | `runs-on` の値がワークフロー間で一貫しているか                              | `ubuntu-latest` に統一         |

**確認ロジック:**

```bash
# Node.js バージョン整合性
NODE_FILE_VER=$(cat .node-version 2>/dev/null | cut -d. -f1)
WORKFLOW_VERS=$(grep -rh 'node-version' .github/workflows/*.yml \
  | sed "s/.*node-version[: ]*['\"]*//" | sed "s/['\"].*//" | sort -u)
for v in $WORKFLOW_VERS; do
  if [ "$v" != "$NODE_FILE_VER" ] && [ "$v" != "$(cat .node-version)" ]; then
    echo "MISMATCH: workflow uses node $v, .node-version is $(cat .node-version)"
  fi
done

# Actions バージョン統一
grep -rh 'uses:' .github/workflows/*.yml \
  | sed 's/.*uses: *//' | sort | uniq -c | sort -rn \
  | awk '{print $2}' | sed 's/@.*//' | sort -u \
  | while read action; do
    versions=$(grep -rh "uses: *${action}@" .github/workflows/*.yml \
      | sed "s/.*@//" | sort -u)
    count=$(echo "$versions" | wc -l)
    if [ "$count" -gt 1 ]; then
      echo "INCONSISTENT: $action has multiple versions: $(echo $versions | tr '\n' ', ')"
    fi
  done

# Runner バージョン
grep -rh 'runs-on:' .github/workflows/*.yml \
  | sed 's/.*runs-on: *//' | sort | uniq -c | sort -rn
```

**結果:**

- ✅ 全ワークフロー間で一貫性あり
- ⚠️ 不一致あり → 具体的なファイル名・行番号・推奨値を表示

**MODE が `full` の場合:**

不一致ごとに修正を提案し、承認後に自動修正を実行。

### 3.5.3 CI Template Deployment Check (他リポジトリ展開)

config リポジトリのテンプレートが他リポジトリに展開可能か確認：

**確認項目:**

1. `templates/workflows/` 内のテンプレートが self-contained か（外部依存なし）
2. `.github/workflows/templates/` の再利用可能ワークフローが正しく定義されているか
3. `templates/github/` のテンプレート（CODEOWNERS, CONTRIBUTING.md 等）が最新か

**確認ロジック:**

```bash
# 再利用可能ワークフローの定義チェック
for f in .github/workflows/templates/*.yml; do
  if ! grep -q 'workflow_call:' "$f" 2>/dev/null; then
    echo "WARN: $(basename $f) is not a reusable workflow (missing workflow_call trigger)"
  fi
done

# テンプレート内のハードコードされたリポジトリ名チェック
grep -rn 'keito4/config' templates/ | grep -v 'README\|\.md' || echo "OK: no hardcoded repo names"
```

**結果:**

- ✅ テンプレート展開準備完了
- ⚠️ 修正が必要なテンプレートあり

このチェックは情報提供のみで、自動修正は行わない。

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
組織内で Claude Code ワークフローの過剰実行（1日64回等）や
CI/CDの非効率な設定がActions費用の最大要因であったことから、
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

#### 3.6.7 不要ワークフロー削除 (full mode only)

検出された不要ワークフローの削除を提案・実行：

**背景:**
リポジトリの進化に伴い、役割を終えたワークフローや重複するワークフローが残存することがある。
これらは不要な Actions 課金、メンテナンスコスト増加、混乱の原因となる。

**削除候補の判定基準:**

| #   | 判定基準                                 | 対応                     |
| --- | ---------------------------------------- | ------------------------ |
| 1   | 90日以上実行なし + schedule トリガーなし | 削除候補                 |
| 2   | 直近10回すべて失敗                       | 削除候補（修正不可なら） |
| 3   | 同一目的のワークフローが重複             | 統合・削除候補           |
| 4   | deprecated action のみに依存             | 移行 or 削除候補         |
| 5   | config テンプレートに置き換え済み        | 旧ファイル削除候補       |

**確認ロジック:**

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
NINETY_DAYS_AGO=$(date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%SZ)
DELETE_CANDIDATES=()

for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  CONTENT=$(cat "$workflow")

  # 1. API でワークフロー ID を取得
  WORKFLOW_ID=$(gh api "repos/$REPO/actions/workflows" \
    --jq ".workflows[] | select(.path == \".github/workflows/$BASENAME\") | .id" 2>/dev/null)
  [ -z "$WORKFLOW_ID" ] && continue

  # 2. 最新実行日を取得
  LATEST_RUN=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=1" \
    --jq '.workflow_runs[0].created_at' 2>/dev/null)

  # 3. 90日以上未実行 + schedule なし → 削除候補
  if [ -n "$LATEST_RUN" ] && [[ "$LATEST_RUN" < "$NINETY_DAYS_AGO" ]]; then
    if ! echo "$CONTENT" | grep -q "schedule:"; then
      DELETE_CANDIDATES+=("$BASENAME: 90日以上未実行（最終: $LATEST_RUN）")
    fi
  fi

  # 4. 実行履歴なし + 30日以上前にファイル作成 → 削除候補
  if [ -z "$LATEST_RUN" ] || [ "$LATEST_RUN" = "null" ]; then
    DELETE_CANDIDATES+=("$BASENAME: 実行履歴なし")
  fi

  # 5. 直近10回すべて失敗 → 削除候補
  ALL_FAILED=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=10" \
    --jq '[.workflow_runs[].conclusion] | map(select(. != null)) | if length > 0 then all(. == "failure") else false end' 2>/dev/null)
  if [ "$ALL_FAILED" = "true" ]; then
    DELETE_CANDIDATES+=("$BASENAME: 直近10回すべて失敗")
  fi
done

# 6. 重複ワークフロー検出（同一 name: を持つワークフロー）
declare -A WF_NAMES
for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  BASENAME=$(basename "$workflow")
  NAME=$(grep -m1 '^name:' "$workflow" | sed 's/^name: *//' | tr -d "'\"")
  if [ -n "${WF_NAMES[$NAME]}" ]; then
    DELETE_CANDIDATES+=("$BASENAME: '$NAME' が ${WF_NAMES[$NAME]} と重複")
  fi
  WF_NAMES[$NAME]=$BASENAME
done
```

**MODE が `full` かつ削除候補がある場合:**

各候補をユーザーに確認してから削除：

```bash
for candidate in "${DELETE_CANDIDATES[@]}"; do
  FILENAME=$(echo "$candidate" | cut -d: -f1)
  REASON=$(echo "$candidate" | cut -d: -f2-)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "削除候補: $FILENAME"
  echo "理由: $REASON"
  echo ""

  # ワークフロー内容のサマリを表示
  grep -E '^(name:|on:|  schedule:|  push:|  pull_request:)' ".github/workflows/$FILENAME"
  echo ""

  # ユーザー確認後に削除
  # git rm ".github/workflows/$FILENAME"
done
```

**安全策:**

- `schedule` トリガーを持つワークフローは自動削除しない（意図的な定期実行の可能性）
- config テンプレート (`templates/workflows/`) に含まれるワークフローは削除しない
- 削除前に必ずユーザーに確認を求める
- 削除はコミットせず、PR に含めてレビュー可能にする

**結果:**

- ✅ 不要ワークフローなし
- 🗑️ X 件の不要ワークフローを削除しました
- ⚠️ X 件の削除候補あり（手動確認が必要）

#### 3.6.8 Actions Runner サイズチェック

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

### 3.10 Dependabot Auto-merge ワークフローチェック

Dependabot PR の自動処理ワークフローが設定されているか確認：

**確認ロジック:**

```bash
HAS_DEPENDABOT_AUTOMERGE=false
[ -f ".github/workflows/dependabot-auto-merge.yml" ] && HAS_DEPENDABOT_AUTOMERGE=true
```

**結果パターン:**

| 状態                          | 対応                                          |
| ----------------------------- | --------------------------------------------- |
| ワークフローが設定済み        | ✅ スキップ                                   |
| Dependabot 設定あり + WF なし | ⚠️ → full mode でテンプレートからコピーを提案 |
| Dependabot 未使用             | ⏭️ スキップ                                   |

**MODE が `full` かつ未設定の場合:**

```bash
# Dependabot が設定されている場合のみ提案
if [ -f ".github/dependabot.yml" ] || [ -f ".github/dependabot.yaml" ]; then
  TEMPLATE_SRC="/usr/local/share/config-templates/workflows/dependabot-auto-merge.yml"
  TEMPLATE_RAW_URL="https://raw.githubusercontent.com/keito4/config/main/templates/workflows/dependabot-auto-merge.yml"

  mkdir -p .github/workflows
  if [ -f "$TEMPLATE_SRC" ]; then
    cp "$TEMPLATE_SRC" .github/workflows/dependabot-auto-merge.yml
  else
    curl -fsSL "$TEMPLATE_RAW_URL" -o .github/workflows/dependabot-auto-merge.yml
  fi
  echo "🔧 dependabot-auto-merge.yml を追加しました"
fi
```

**結果:**

- ✅ Dependabot Auto-merge 設定済み
- 🔧 dependabot-auto-merge.yml を追加しました
- ⏭️ スキップ（Dependabot 未使用）

### 3.11 Label Sync ワークフローチェック

GitHub ラベルの IaC 管理が設定されているか確認：

**確認ロジック:**

```bash
HAS_LABEL_SYNC=false
HAS_LABELS_YML=false

[ -f ".github/workflows/label-sync.yml" ] && HAS_LABEL_SYNC=true
[ -f ".github/labels.yml" ] && HAS_LABELS_YML=true
```

**結果パターン:**

| 状態                      | 対応                                    |
| ------------------------- | --------------------------------------- |
| WF + labels.yml 両方あり  | ✅ スキップ                             |
| WF あり + labels.yml なし | ⚠️ labels.yml 未定義                    |
| 両方なし                  | ⚠️ → full mode でテンプレート生成を提案 |

**MODE が `full` かつ未設定の場合:**

```bash
TEMPLATE_WF_SRC="/usr/local/share/config-templates/workflows/label-sync.yml"
TEMPLATE_WF_RAW="https://raw.githubusercontent.com/keito4/config/main/templates/workflows/label-sync.yml"
TEMPLATE_LABELS_SRC="/usr/local/share/config-templates/github/labels.yml"
TEMPLATE_LABELS_RAW="https://raw.githubusercontent.com/keito4/config/main/templates/github/labels.yml"

mkdir -p .github/workflows

if [ ! -f ".github/workflows/label-sync.yml" ]; then
  if [ -f "$TEMPLATE_WF_SRC" ]; then
    cp "$TEMPLATE_WF_SRC" .github/workflows/label-sync.yml
  else
    curl -fsSL "$TEMPLATE_WF_RAW" -o .github/workflows/label-sync.yml
  fi
  echo "🔧 label-sync.yml を追加しました"
fi

if [ ! -f ".github/labels.yml" ]; then
  if [ -f "$TEMPLATE_LABELS_SRC" ]; then
    cp "$TEMPLATE_LABELS_SRC" .github/labels.yml
  else
    curl -fsSL "$TEMPLATE_LABELS_RAW" -o .github/labels.yml
  fi
  echo "🔧 labels.yml を追加しました"
fi
```

**結果:**

- ✅ Label Sync 設定済み
- 🔧 label-sync.yml + labels.yml を追加しました
- ⚠️ labels.yml が未定義（ワークフローのみ存在）

### 3.12 pre-commit 設定チェック

pre-commit フレームワークの設定状況を確認：

**確認ロジック:**

```bash
HAS_PRE_COMMIT_CONFIG=false
[ -f ".pre-commit-config.yaml" ] && HAS_PRE_COMMIT_CONFIG=true
```

**結果パターン:**

| 状態     | 対応                                          |
| -------- | --------------------------------------------- |
| 設定済み | ✅ スキップ                                   |
| 未設定   | ⚠️ → full mode でテンプレートからコピーを提案 |

**MODE が `full` かつ未設定の場合:**

プロジェクト種別を判定してテンプレートを選択：

```bash
# テンプレートの選択
if ls *.tf 2>/dev/null || [ -d "terraform" ]; then
  TEMPLATE_NAME="pre-commit-config-terraform.yaml"
else
  TEMPLATE_NAME="pre-commit-config-base.yaml"
fi

TEMPLATE_SRC="/usr/local/share/config-templates/$TEMPLATE_NAME"
TEMPLATE_RAW_URL="https://raw.githubusercontent.com/keito4/config/main/templates/$TEMPLATE_NAME"

if [ -f "$TEMPLATE_SRC" ]; then
  cp "$TEMPLATE_SRC" .pre-commit-config.yaml
else
  curl -fsSL "$TEMPLATE_RAW_URL" -o .pre-commit-config.yaml
fi
echo "🔧 .pre-commit-config.yaml を追加しました（$TEMPLATE_NAME）"
echo "   pre-commit install を実行してください"
```

**結果:**

- ✅ .pre-commit-config.yaml 設定済み
- 🔧 .pre-commit-config.yaml を追加しました（テンプレート名表示）
- ⏭️ スキップ

### 3.13 PR テンプレートチェック

PR テンプレートが設定されているか確認：

**確認ロジック:**

```bash
HAS_PR_TEMPLATE=false
[ -f ".github/pull_request_template.md" ] && HAS_PR_TEMPLATE=true
```

**MODE が `full` かつ未設定の場合:**

```bash
TEMPLATE_SRC="/usr/local/share/config-templates/github/pull_request_template.md"
TEMPLATE_RAW_URL="https://raw.githubusercontent.com/keito4/config/main/templates/github/pull_request_template.md"

mkdir -p .github
if [ -f "$TEMPLATE_SRC" ]; then
  cp "$TEMPLATE_SRC" .github/pull_request_template.md
else
  curl -fsSL "$TEMPLATE_RAW_URL" -o .github/pull_request_template.md
fi
echo "🔧 pull_request_template.md を追加しました"
```

**結果:**

- ✅ PR テンプレート設定済み
- 🔧 pull_request_template.md を追加しました

### 3.14 Issue テンプレートチェック

Issue テンプレートが設定されているか確認：

**確認ロジック:**

```bash
HAS_ISSUE_TEMPLATE=false
[ -d ".github/ISSUE_TEMPLATE" ] && HAS_ISSUE_TEMPLATE=true
```

**MODE が `full` かつ未設定の場合:**

```bash
TEMPLATE_DIR_SRC="/usr/local/share/config-templates/github/ISSUE_TEMPLATE"
TEMPLATE_RAW_BASE="https://raw.githubusercontent.com/keito4/config/main/templates/github/ISSUE_TEMPLATE"

mkdir -p .github/ISSUE_TEMPLATE
for f in bug_report.yml feature_request.yml config.yml; do
  if [ -f "$TEMPLATE_DIR_SRC/$f" ]; then
    cp "$TEMPLATE_DIR_SRC/$f" ".github/ISSUE_TEMPLATE/$f"
  else
    curl -fsSL "$TEMPLATE_RAW_BASE/$f" -o ".github/ISSUE_TEMPLATE/$f"
  fi
done
echo "🔧 Issue テンプレートを追加しました"
```

**結果:**

- ✅ Issue テンプレート設定済み
- 🔧 Issue テンプレートを追加しました（bug_report, feature_request）

### 3.15 CODEOWNERS チェック

CODEOWNERS ファイルが設定されているか確認：

**確認ロジック:**

```bash
HAS_CODEOWNERS=false
[ -f ".github/CODEOWNERS" ] || [ -f "CODEOWNERS" ] || [ -f "docs/CODEOWNERS" ] && HAS_CODEOWNERS=true
```

**結果:**

- ✅ CODEOWNERS 設定済み
- ⚠️ CODEOWNERS 未設定（テンプレート: `templates/github/CODEOWNERS`）

### 3.16 SECURITY.md チェック

セキュリティポリシーが設定されているか確認：

**確認ロジック:**

```bash
HAS_SECURITY=false
[ -f "SECURITY.md" ] || [ -f ".github/SECURITY.md" ] && HAS_SECURITY=true
```

**MODE が `full` かつ未設定の場合:**

```bash
TEMPLATE_SRC="/usr/local/share/config-templates/github/SECURITY.md"
TEMPLATE_RAW_URL="https://raw.githubusercontent.com/keito4/config/main/templates/github/SECURITY.md"

if [ -f "$TEMPLATE_SRC" ]; then
  cp "$TEMPLATE_SRC" SECURITY.md
else
  curl -fsSL "$TEMPLATE_RAW_URL" -o SECURITY.md
fi
echo "🔧 SECURITY.md を追加しました"
```

**結果:**

- ✅ SECURITY.md 設定済み
- 🔧 SECURITY.md を追加しました

### 3.17 package.json scripts 標準チェック

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

### 3.19 Push Protection Check

GitHub Secret Scanning の Push Protection 設定を確認：

**背景:**
Secret Scanning は commit 済みの secrets を検出するが、Push Protection を有効にすることで
push 時点で secrets をブロックできる。事後対応より事前防止が効果的。

**確認ロジック:**

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# Secret scanning の有効確認
SECRET_SCANNING=$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning.status' 2>/dev/null)

# Push protection の有効確認
PUSH_PROTECTION=$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning_push_protection.status' 2>/dev/null)
```

**結果パターン:**

| 状態                                                 | 対応                                         |
| ---------------------------------------------------- | -------------------------------------------- |
| Secret scanning: enabled + Push protection: enabled  | ✅ 設定済み                                  |
| Secret scanning: enabled + Push protection: disabled | ⚠️ → full mode で有効化を提案                |
| Secret scanning: disabled                            | ⚠️ → full mode で両方の有効化を提案          |
| API エラー（権限不足）                               | ⏭️ スキップ（Organization admin 権限が必要） |

**MODE が `full` かつ未設定の場合:**

```bash
# Push protection の有効化
gh api -X PATCH "repos/$REPO" \
  -f "security_and_analysis[secret_scanning][status]=enabled" \
  -f "security_and_analysis[secret_scanning_push_protection][status]=enabled"
echo "🔧 Push Protection を有効化しました"
```

**結果:**

- ✅ Push Protection 有効
- 🔧 Push Protection を有効化しました
- ⚠️ Push Protection 無効（有効化を推奨）
- ⏭️ スキップ（権限不足）

### 3.20 Dependency Review Check

PR で新規追加される依存関係の脆弱性チェック（Dependency Review）を確認：

**背景:**
Dependabot alerts は既存の依存関係の脆弱性を通知するが、Dependency Review は
PR 段階で新規追加・更新される依存関係の脆弱性をブロックできる。
`actions/dependency-review-action` をCI に組み込むことで、脆弱な依存関係のマージを防止する。

**確認ロジック:**

```bash
HAS_DEPENDENCY_REVIEW=false

for workflow in .github/workflows/*.yml; do
  [ ! -f "$workflow" ] && continue
  if grep -q "dependency-review-action" "$workflow" 2>/dev/null; then
    HAS_DEPENDENCY_REVIEW=true
    break
  fi
done
```

**結果パターン:**

| 状態                          | 対応                                |
| ----------------------------- | ----------------------------------- |
| dependency-review-action あり | ✅ 設定済み                         |
| dependency-review-action なし | ⚠️ → full mode で CI への追加を提案 |

**MODE が `full` かつ未設定の場合:**

既存の CI ワークフローに dependency-review job を追加するか、
専用ワークフローの作成を提案：

```yaml
# .github/workflows/dependency-review.yml
name: Dependency Review
on: [pull_request]

permissions:
  contents: read
  pull-requests: write

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: critical
          comment-summary-in-pr: always
```

**結果:**

- ✅ Dependency Review 設定済み
- 🔧 dependency-review.yml を追加しました
- ⚠️ Dependency Review 未設定（追加を推奨）

### 3.21 Deployment Environment Protection Check

GitHub Environments のデプロイ保護設定を確認：

**背景:**
CI の成功と本番反映を分離するため、GitHub Environments に required reviewers を設定し、
production デプロイ前に承認を必須にする。これにより、CI パスだけでは本番にデプロイされない統制が可能。

**確認ロジック:**

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# Environments の取得
ENVIRONMENTS=$(gh api "repos/$REPO/environments" --jq '.environments[]' 2>/dev/null)

if [ -z "$ENVIRONMENTS" ]; then
  echo "⏭️ GitHub Environments 未使用"
else
  # 各環境の保護ルールを確認
  gh api "repos/$REPO/environments" --jq '.environments[] | {name, protection_rules}' 2>/dev/null | while read -r env; do
    ENV_NAME=$(echo "$env" | jq -r '.name')
    HAS_REVIEWERS=$(echo "$env" | jq '.protection_rules[] | select(.type == "required_reviewers")' 2>/dev/null)
    HAS_WAIT_TIMER=$(echo "$env" | jq '.protection_rules[] | select(.type == "wait_timer")' 2>/dev/null)
    HAS_BRANCH_POLICY=$(echo "$env" | jq '.deployment_branch_policy' 2>/dev/null)

    if [ "$ENV_NAME" = "production" ] || [ "$ENV_NAME" = "prod" ]; then
      if [ -z "$HAS_REVIEWERS" ]; then
        ISSUES+=("Environment '$ENV_NAME': required reviewers 未設定（本番デプロイに承認なし）")
      fi
      if [ -z "$HAS_BRANCH_POLICY" ] || [ "$HAS_BRANCH_POLICY" = "null" ]; then
        ISSUES+=("Environment '$ENV_NAME': branch policy 未設定（任意のブランチからデプロイ可能）")
      fi
    fi
  done
fi
```

**チェック項目:**

| #   | チェック                 | 推奨値            | 対象環境             |
| --- | ------------------------ | ----------------- | -------------------- |
| 1   | Required reviewers       | 1名以上           | production / staging |
| 2   | Deployment branch policy | main ブランチのみ | production           |
| 3   | Wait timer               | 任意（5分推奨）   | production           |

**結果パターン:**

| 状態                            | 対応                                     |
| ------------------------------- | ---------------------------------------- |
| production に保護ルール設定済み | ✅ 設定済み                              |
| production に保護ルール未設定   | ⚠️ → full mode で設定手順を案内          |
| Environments 未使用             | ⏭️ スキップ（CD ワークフローがない場合） |

**MODE が `full` かつ問題がある場合:**

```bash
# production 環境に required reviewers を設定（API では制限あり、UI 設定を推奨）
echo "🔧 以下の設定を GitHub UI で実施してください:"
echo "   Settings → Environments → production"
echo "   ✅ Required reviewers: 有効化（レビュアーを指定）"
echo "   ✅ Deployment branches: Selected branches → main のみ"
echo "   ✅ Wait timer: 5 minutes（任意）"
```

**結果:**

- ✅ Deployment Environment 保護設定済み
- ⚠️ production 環境: 保護ルール未設定（設定手順を表示）
- ⏭️ スキップ（GitHub Environments 未使用）

### 3.22 推奨ファイル同期 (Config Template Sync)

config リポジトリ（`keito4/config`）の推奨テンプレートファイルと現在のリポジトリを比較し、差分があれば同期する。

**背景:**
`/setup-new-repo` で初期構築したリポジトリのワークフローやフックは、config リポジトリの更新に追従しない。
このステップにより、推奨設定の変更（例: `cancel-in-progress` の修正）が全リポジトリに反映される。

**前提:** `MODE` は Step 1 で定義済み（`full` / `quick` / `check-only`）。このステップは全モードで実行される。

**スキップ条件:**

```bash
# config リポジトリ自身かどうかを判定
REPO_NAME=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [ "$REPO_NAME" = "keito4/config" ]; then
  echo "⏭️ スキップ（config リポジトリ自身）"
  # このステップを終了
fi

# config-base 管理下かどうかを判定
if [ -f ".devcontainer/devcontainer.json" ]; then
  if ! grep -q "config-base" .devcontainer/devcontainer.json 2>/dev/null; then
    echo "⏭️ スキップ（config 管理外のリポジトリ）"
    # このステップを終了
  fi
fi
```

**同期対象ファイルの分類:**

| カテゴリ     | ファイル                                    | 同期ポリシー                 |
| ------------ | ------------------------------------------- | ---------------------------- |
| マネージド   | `.github/workflows/claude.yml`              | 常に config の最新版で上書き |
| マネージド   | `.github/workflows/claude-code-review.yml`  | 常に config の最新版で上書き |
| マネージド   | `.claude/hooks/block_git_no_verify.py`      | 常に config の最新版で上書き |
| マネージド   | `.claude/hooks/pre_git_quality_gates.py`    | 常に config の最新版で上書き |
| マネージド   | `.claude/hooks/post_git_push_ci.py`         | 常に config の最新版で上書き |
| マネージド   | `.claude/hooks/post_commit_adr_reminder.py` | 常に config の最新版で上書き |
| マネージド   | `.claude/rules/development-standards.md`    | 常に config の最新版で上書き |
| マネージド   | `.claude/rules/git-conventions.md`          | 常に config の最新版で上書き |
| マネージド   | `.claude/rules/release-types.md`            | 常に config の最新版で上書き |
| テンプレート | `.github/workflows/security.yml`            | 差分表示 → 確認後に上書き    |
| テンプレート | `.github/workflows/ci.yml`                  | 差分表示 → 確認後に上書き    |
| テンプレート | `.github/ISSUE_TEMPLATE/*`                  | 欠落ファイルのみ追加         |
| テンプレート | `.github/pull_request_template.md`          | 欠落時のみ追加               |

**マネージドファイル**: config リポジトリが正規のソースであり、プロジェクト側でカスタマイズしない前提のファイル。
**テンプレートファイル**: プロジェクト固有のカスタマイズが入る可能性があるため、差分確認を挟む。

**config リポジトリのソース取得:**

```bash
# config リポジトリのローカルクローンを探す
CONFIG_REPO=""
SEARCH_PATHS=(
  "$HOME/develop/github.com/keito4/config"
  "$HOME/ghq/github.com/keito4/config"
  "$HOME/src/github.com/keito4/config"
)
for path in "${SEARCH_PATHS[@]}"; do
  if [ -d "$path/.github/workflows" ]; then
    CONFIG_REPO="$path"
    break
  fi
done

# ローカルに見つからない場合は GitHub API でフェッチ
TEMP_CONFIG_DIR=""
if [ -z "$CONFIG_REPO" ]; then
  TEMP_CONFIG_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_CONFIG_DIR"' EXIT
  CONFIG_REPO="$TEMP_CONFIG_DIR"
  gh api repos/keito4/config/tarball/main | tar xz -C "$TEMP_CONFIG_DIR" --strip-components=1
fi
```

**マネージドファイルの同期ロジック:**

```bash
MANAGED_FILES=(
  ".github/workflows/claude.yml"
  ".github/workflows/claude-code-review.yml"
  ".claude/hooks/block_git_no_verify.py"
  ".claude/hooks/pre_git_quality_gates.py"
  ".claude/hooks/post_git_push_ci.py"
  ".claude/hooks/post_commit_adr_reminder.py"
  ".claude/rules/development-standards.md"
  ".claude/rules/git-conventions.md"
  ".claude/rules/release-types.md"
)

UPDATED=()
SKIPPED=()

for file in "${MANAGED_FILES[@]}"; do
  SRC="$CONFIG_REPO/$file"
  DST="./$file"

  if [ ! -f "$SRC" ]; then
    continue
  fi

  # ディレクトリが無ければ作成
  mkdir -p "$(dirname "$DST")"

  if [ ! -f "$DST" ]; then
    # ファイルが存在しない → 新規コピー
    cp "$SRC" "$DST"
    UPDATED+=("$file (新規追加)")
  elif ! diff -q "$SRC" "$DST" >/dev/null 2>&1; then
    # 差分あり → 上書き
    diff --color=auto -u "$DST" "$SRC" | head -30
    cp "$SRC" "$DST"
    UPDATED+=("$file (更新)")
  else
    SKIPPED+=("$file (最新)")
  fi
done
```

**テンプレートファイルの同期ロジック:**

```bash
TEMPLATE_FILES=(
  ".github/workflows/security.yml"
  ".github/workflows/ci.yml"
)

for file in "${TEMPLATE_FILES[@]}"; do
  SRC="$CONFIG_REPO/$file"
  DST="./$file"

  if [ ! -f "$SRC" ]; then
    continue
  fi

  mkdir -p "$(dirname "$DST")"

  if [ ! -f "$DST" ]; then
    # 存在しない → コピー
    cp "$SRC" "$DST"
    UPDATED+=("$file (新規追加)")
  elif ! diff -q "$SRC" "$DST" >/dev/null 2>&1; then
    # 差分あり → diff を表示
    echo "📄 $file に差分があります:"
    diff -u "$DST" "$SRC" | head -50
    if [ "$MODE" = "full" ]; then
      # full mode: Claude が diff を確認し、ユーザーに対話的に確認してから上書き
      # ※ このコマンドは Claude Code が実行するため、Claude がユーザーに確認を取る
      cp "$SRC" "$DST"
      UPDATED+=("$file (確認後に更新)")
    else
      # quick / check-only mode: 差分を報告のみ
      UPDATED+=("$file (差分あり・要確認)")
    fi
  else
    SKIPPED+=("$file (最新)")
  fi
done

# Issue/PR テンプレート: 欠落ファイルのみ追加
TEMPLATE_DIRS=(
  ".github/ISSUE_TEMPLATE"
)
for dir in "${TEMPLATE_DIRS[@]}"; do
  SRC_DIR="$CONFIG_REPO/$dir"
  DST_DIR="./$dir"
  if [ -d "$SRC_DIR" ]; then
    mkdir -p "$DST_DIR"
    for src_file in "$SRC_DIR"/*; do
      [ ! -f "$src_file" ] && continue  # 空ディレクトリでの glob 対策
      dst_file="$DST_DIR/$(basename "$src_file")"
      if [ ! -f "$dst_file" ]; then
        cp "$src_file" "$dst_file"
        UPDATED+=("$dir/$(basename "$src_file") (新規追加)")
      fi
    done
  fi
done

# PR テンプレート
PR_TEMPLATE_SRC="$CONFIG_REPO/.github/pull_request_template.md"
PR_TEMPLATE_DST="./.github/pull_request_template.md"
if [ -f "$PR_TEMPLATE_SRC" ] && [ ! -f "$PR_TEMPLATE_DST" ]; then
  mkdir -p .github
  cp "$PR_TEMPLATE_SRC" "$PR_TEMPLATE_DST"
  UPDATED+=(".github/pull_request_template.md (新規追加)")
fi
```

**結果パターン:**

| 状態                 | 出力                                              |
| -------------------- | ------------------------------------------------- |
| 全ファイル最新       | ✅ Config Template Sync: 全ファイル最新           |
| 更新あり             | 🔧 Config Template Sync: X 件更新                 |
| 差分あり（確認待ち） | ⚠️ Config Template Sync: X 件の差分あり（要確認） |
| スキップ             | ⏭️ スキップ（config リポジトリ自身 / 管理外）     |

**結果:**

- ✅ Config Template Sync: 全ファイル最新
- 🔧 Config Template Sync: X 件更新（更新ファイルをリスト表示）
- ⚠️ Config Template Sync: X 件の差分あり（テンプレートファイルの確認待ち）
- ⏭️ スキップ（config リポジトリ自身）

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

### 5.3 Provenance / SBOM Audit

ビルド成果物の出所証明とソフトウェア部品表（SBOM）の状況を確認：

**背景:**
npm package や release artifact を配布するリポジトリでは、Trusted Publishing（OIDC）で長期トークンをなくし、
GitHub の Artifact Attestations で build provenance と integrity guarantees を付けることで、
サプライチェーン攻撃への耐性を高められる。

**適用対象の判定:**

```bash
IS_PUBLISHABLE=false

# npm パッケージとして公開可能か判定
if [ -f "package.json" ]; then
  PRIVATE=$(jq -r '.private // false' package.json)
  if [ "$PRIVATE" != "true" ]; then
    IS_PUBLISHABLE=true
    PUBLISH_TYPE="npm"
  fi
fi

# GitHub Releases を使用しているか判定
RELEASES=$(gh api "repos/$REPO/releases?per_page=1" --jq 'length' 2>/dev/null)
if [ "$RELEASES" -gt 0 ]; then
  IS_PUBLISHABLE=true
  PUBLISH_TYPE="${PUBLISH_TYPE:+$PUBLISH_TYPE+}release"
fi
```

**チェック項目（公開リポジトリのみ）:**

| #   | チェック                       | 推奨値                                    | 効果                 |
| --- | ------------------------------ | ----------------------------------------- | -------------------- |
| 1   | Artifact Attestations          | `actions/attest-build-provenance` を使用  | ビルド出所の証明     |
| 2   | SBOM 生成                      | `actions/dependency-submission-action` 等 | 依存関係の可視化     |
| 3   | npm Trusted Publishing（OIDC） | `id-token: write` + provenance 設定       | 長期トークン不要     |
| 4   | Signed commits / tags          | 署名付きリリースタグ                      | リリースの真正性証明 |

**確認ロジック:**

```bash
ISSUES=()

if [ "$IS_PUBLISHABLE" = "true" ]; then
  # Artifact Attestations の使用確認
  HAS_ATTESTATION=false
  for workflow in .github/workflows/*.yml; do
    [ ! -f "$workflow" ] && continue
    if grep -q "attest-build-provenance\|attestation" "$workflow" 2>/dev/null; then
      HAS_ATTESTATION=true
      break
    fi
  done
  [ "$HAS_ATTESTATION" = "false" ] && \
    ISSUES+=("Artifact Attestations 未設定（ビルド出所証明なし）")

  # SBOM 生成の確認
  HAS_SBOM=false
  for workflow in .github/workflows/*.yml; do
    [ ! -f "$workflow" ] && continue
    if grep -qE "(dependency-submission|sbom|cyclonedx|spdx)" "$workflow" 2>/dev/null; then
      HAS_SBOM=true
      break
    fi
  done
  [ "$HAS_SBOM" = "false" ] && \
    ISSUES+=("SBOM 生成未設定（依存関係の可視化なし）")

  # npm Trusted Publishing の確認
  if echo "$PUBLISH_TYPE" | grep -q "npm"; then
    HAS_PROVENANCE=false
    for workflow in .github/workflows/*.yml; do
      [ ! -f "$workflow" ] && continue
      if grep -q "provenance" "$workflow" 2>/dev/null; then
        HAS_PROVENANCE=true
        break
      fi
    done
    [ "$HAS_PROVENANCE" = "false" ] && \
      ISSUES+=("npm Trusted Publishing 未設定（OIDC による安全な公開が可能）")
  fi
fi
```

**結果パターン:**

| 状態           | 対応                                  |
| -------------- | ------------------------------------- |
| 全項目設定済み | ✅ Provenance / SBOM: 設定済み        |
| 一部未設定     | ⚠️ 改善余地あり（推奨設定リスト表示） |
| 公開対象でない | ⏭️ スキップ（private リポジトリ）     |

**MODE が `full` かつ問題がある場合:**

設定手順と推奨ワークフローのテンプレートを提示：

```bash
echo "📦 Provenance / SBOM の推奨設定:"
echo ""
echo "1. Artifact Attestations:"
echo "   - actions/attest-build-provenance を release ワークフローに追加"
echo "   - permissions: id-token: write, attestations: write"
echo ""
echo "2. SBOM 生成:"
echo "   - anchore/sbom-action または actions/dependency-submission-action を CI に追加"
echo ""
if echo "$PUBLISH_TYPE" | grep -q "npm"; then
  echo "3. npm Trusted Publishing:"
  echo "   - npm に OIDC 設定を追加（npm access → Granular Access Tokens → OIDC）"
  echo "   - ワークフローに provenance: true を設定"
fi
```

**結果:**

- ✅ Provenance / SBOM 設定済み
- ⚠️ Provenance / SBOM 改善余地あり（X 件の推奨設定）
- ⏭️ スキップ（非公開リポジトリ）

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
├── Codespaces Secrets: ✅ Synced (or ⏭️ Skipped)
└── Actions Security: ✅ Hardened (or ⚠️ X issues found)
    ├── SHA Pinning: ✅ (or ⚠️ X unpinned 3rd-party actions)
    ├── GITHUB_TOKEN Perms: ✅ (or ⚠️ X workflows missing permissions)
    └── Repo Settings: ✅ (or ⚠️ Default write / all actions allowed)

## Setup (2/4)
├── Team Protection: ✅ Branch protection enabled
├── Husky: ✅ Git hooks configured\n├── hooksPath: ✅ Valid (.husky) (or 🔧 Fixed / ❌ Manual required)\n├── Husky v8→v9: ✅ v9スタイル済み (or 🔧 移行しました / ✅ スキップ)
├── check-file-length: ✅ Configured in pre-commit (or 🔧 Added / ⏭️ Skipped)
├── Renovate/Dependabot: ✅ Auto-update configured (or 🔧 renovate.json generated / ⏭️ Skipped)
├── Dependabot Auto-merge: ✅ Configured (or 🔧 Added / ⏭️ Skipped)
├── Label Sync: ✅ Configured (or 🔧 Added / ⚠️ labels.yml missing)
├── pre-commit: ✅ Configured (or 🔧 Added / ⏭️ Skipped)
├── PR Template: ✅ Configured (or 🔧 Added)
├── Issue Template: ✅ Configured (or 🔧 Added)
├── CODEOWNERS: ✅ Configured (or ⚠️ Not configured)
├── SECURITY.md: ✅ Configured (or 🔧 Added)
├── commitlint: ✅ Configured with commit-msg hook (or ⚠️ Hook missing / ⚠️ Not configured)
├── .editorconfig: ✅ Configured (or 🔧 Generated)
├── scripts: ✅ All standard scripts defined (or ⚠️ Missing: test, lint)
├── Pre-PR Checklist: ✅ CI workflow exists
├── Code Review Rules: ✅ All rules configured (or ⚠️ Missing rules)
├── CLAUDE.md: ✅ Symlink to AGENTS.md
├── AGENTS.md: ✅ Auto-generated sections up to date (or 🔧 Updated)
├── CI/CD: ✅ Standard level configured
├── CI Template Sync: ✅ All templates match (or ⚠️ N files diverged)
├── CI Consistency: ✅ Node.js/Actions versions consistent (or ⚠️ mismatches found)
├── Actions Cost: ✅ Optimized (or ⚠️ X issues found)
│   ├── Artifact Retention: ✅ (or ⚠️ 90-day default detected)
│   ├── Unused Workflows: ✅ (or ⚠️ X stale workflows)
│   └── Runner Size: ✅ (or ⚠️ High-cost runners detected)
├── Renovate/Dependabot: ✅ Auto-update configured
├── Push Protection: ✅ Enabled (or ⚠️ Disabled)
├── Dependency Review: ✅ Configured (or ⚠️ Not configured)
├── Deploy Env Protection: ✅ Configured (or ⚠️ No reviewers / ⏭️ No environments)
└── Config Template Sync: ✅ All files up to date (or 🔧 X files updated / ⏭️ Skipped)

## Cleanup (3/4)
├── Branches: 🗑️ 8 merged branches can be deleted
└── Git GC: ✅ Repository optimized

## Discovery (4/4)
├── New Features: 🆕 2 new commands available
├── Package Audit: ⚠️ 3 recommended packages missing (Next.js)
└── Provenance/SBOM: ✅ Configured (or ⚠️ Not configured / ⏭️ Private repo)

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

| カテゴリ    | コマンド                        | 説明                               |
| ----------- | ------------------------------- | ---------------------------------- |
| Environment | `/container-health`             | コンテナ健全性                     |
| Environment | `/config-base-sync-check`       | DevContainer バージョン            |
| Environment | `/config-base-sync-update`      | DevContainer 更新                  |
| Environment | `/update-claude-code`           | Claude Code 更新                   |
| Environment | `/update-actions`               | GitHub Actions バージョン更新      |
| Environment | `/sync-claude-settings`         | Claude 設定同期                    |
| Environment | (Claude Code LSP setup)         | LSP 設定                           |
| Environment | `/codespaces-secrets`           | Codespaces シークレット同期        |
| Environment | (Actions Security Hardening)    | Actions SHA固定・権限・制限        |
| Setup       | `/setup-team-protection`        | GitHub保護ルール設定               |
| Setup       | `/setup-husky`                  | Git hooks設定                      |
| Setup       | (check-file-length auto-setup)  | ファイル行数チェック追加           |
| Setup       | `/pre-pr-checklist`             | PR前チェックリスト                 |
| Setup       | (CLAUDE.md symlink check)       | CLAUDE.md シンボリックリンク       |
| Setup       | (AGENTS.md auto-generation)     | AGENTS.md 自動生成セクション更新   |
| Setup       | `/setup-ci`                     | CI/CDワークフロー設定              |
| Setup       | (CI Template Sync)              | テンプレートと実ファイルの乖離検出 |
| Setup       | (CI Consistency)                | ワークフロー間の設定整合性検証     |
| Setup       | (CI Template Deployment)        | 他リポジトリ展開準備状況確認       |
| Setup       | (Actions Cost Optimization)     | GitHub Actions コスト最適化        |
| Setup       | (Renovate/Dependabot check)     | 依存関係自動更新設定               |
| Setup       | (commitlint check)              | コミットメッセージ品質管理         |
| Setup       | (editorconfig check)            | エディタスタイル設定               |
| Setup       | (Dependabot Auto-merge check)   | Dependabot 自動マージ設定          |
| Setup       | (Label Sync check)              | ラベル IaC 管理設定                |
| Setup       | (pre-commit config check)       | pre-commit フレームワーク設定      |
| Setup       | (PR Template check)             | PR テンプレート設定                |
| Setup       | (Issue Template check)          | Issue テンプレート設定             |
| Setup       | (CODEOWNERS check)              | コードオーナー設定                 |
| Setup       | (SECURITY.md check)             | セキュリティポリシー設定           |
| Setup       | (scripts standard check)        | package.json scripts 標準確認      |
| Setup       | (Push Protection check)         | Secret scanning push 防止          |
| Setup       | (Dependency Review check)       | PR 依存関係脆弱性チェック          |
| Setup       | (Deploy Env Protection check)   | デプロイ環境保護ルール             |
| Cleanup     | `/branch-cleanup`               | ブランチクリーンアップ             |
| Discovery   | `/config-contribution-discover` | 新機能発見                         |
| Discovery   | (Package Audit + ni support)    | 推奨パッケージ監査                 |
| Discovery   | (Provenance / SBOM Audit)       | ビルド出所証明・SBOM 監査          |
| PR          | (post_pr_ci_watch.py hook)      | PR作成後のCI自動監視               |
