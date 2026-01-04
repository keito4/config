# DevContainer 再起動後の確認チェックリスト

DevContainerを再起動した後に確認すべき項目をまとめたチェックリストです。

## 🔧 基本環境の確認

### Node.js環境

```bash
# Node.jsバージョン確認（期待値: v24.1.0 or v22.14.0）
node --version

# npmバージョン確認（期待値: 11.x.x）
npm --version

# グローバルパッケージの確認
npm list -g --depth=0
```

**確認ポイント:**

- [ ] Node.jsが期待されるバージョンで動作している
- [ ] npmが正しくインストールされている
- [ ] 必要なグローバルパッケージがインストールされている

### Git設定

```bash
# Git設定確認
git config --list

# ユーザー情報確認
git config user.name
git config user.email
git config user.signingkey
```

**確認ポイント:**

- [ ] Gitユーザー名が設定されている
- [ ] Gitメールアドレスが設定されている
- [ ] Git署名キーが設定されている（必要な場合）

### Docker確認

```bash
# Dockerバージョン確認
docker --version

# Docker動作確認
docker ps
```

**確認ポイント:**

- [ ] Dockerが正しくインストールされている
- [ ] Dockerコマンドが実行可能

## 🔍 LSP (Language Server Protocol) の確認

### Language Serverのインストール確認

```bash
# TypeScript Language Server
npx typescript-language-server --version

# Bash Language Server
npx bash-language-server --version

# YAML Language Server
npx yaml-language-server --version

# すべてのグローバルパッケージを確認
npm list -g | grep -E "typescript|bash-language|yaml-language|vscode-langservers"
```

**確認ポイント:**

- [ ] `typescript-language-server` がインストールされている
- [ ] `bash-language-server` がインストールされている
- [ ] `yaml-language-server` がインストールされている
- [ ] `vscode-langservers-extracted` がインストールされている
- [ ] `typescript` パッケージがインストールされている

### LSP設定ファイルの確認

```bash
# LSP設定ファイルの存在確認
ls -la .claude-plugin/plugin.json

# LSP設定ファイルの内容確認
cat .claude-plugin/plugin.json
```

**確認ポイント:**

- [ ] `.claude-plugin/plugin.json` が存在する
- [ ] JSONが正しくフォーマットされている
- [ ] 4つのLanguage Server設定が含まれている（typescript, bash, json, yaml）

### Claude Code LSP機能の確認

**手動テスト:**

1. **TypeScript/JavaScriptファイルで確認**
   - [ ] `.js` または `.ts` ファイルを開く
   - [ ] 変数にカーソルを合わせて型情報が表示されるか
   - [ ] 関数名の上でGo to Definitionが動作するか
   - [ ] オートコンプリートが表示されるか

2. **Bashスクリプトで確認**
   - [ ] `.sh` ファイルを開く
   - [ ] 構文エラーが検出されるか
   - [ ] コマンドのオートコンプリートが動作するか

3. **JSONファイルで確認**
   - [ ] `package.json` または `.json` ファイルを開く
   - [ ] スキーマ検証が動作するか
   - [ ] 構文エラーが検出されるか

4. **YAMLファイルで確認**
   - [ ] `.yml` ファイルを開く（例: `.github/workflows/*.yml`）
   - [ ] インデントエラーが検出されるか
   - [ ] 構文エラーが検出されるか

## 🔐 環境変数とクレデンシャルの確認

### 環境変数の確認

```bash
# 重要な環境変数の確認（値は表示しない）
env | grep -E "OPENAI_API_KEY|AWS_|CLAUDE_CODE" | sed 's/=.*/=***/'

# DevContainer環境ファイルの確認
ls -la ~/.devcontainer.env

# MCP設定ファイルの確認
ls -la .mcp.json
```

**確認ポイント:**

- [ ] `OPENAI_API_KEY` が設定されている
- [ ] `AWS_ACCESS_KEY_ID` が設定されている（必要な場合）
- [ ] `AWS_SECRET_ACCESS_KEY` が設定されている（必要な場合）
- [ ] `~/.devcontainer.env` が存在し、権限が600
- [ ] `.mcp.json` が存在し、権限が600

### 1Password CLI確認

```bash
# 1Password CLIバージョン確認
op --version

# 1Passwordサインイン状態確認
op whoami
```

**確認ポイント:**

- [ ] 1Password CLIがインストールされている
- [ ] 1Passwordにサインインしている

## 🛠️ 開発ツールの確認

### Claude Code確認

```bash
# Claude Codeバージョン確認
claude --version

# Claude Code設定確認
ls -la ~/.claude/settings.local.json
```

**確認ポイント:**

- [ ] Claude Codeが最新バージョン（2.0.76+）
- [ ] `settings.local.json` が存在する
- [ ] Hooksが正しく設定されている

### Husky & Git Hooks確認

```bash
# Huskyディレクトリ確認
ls -la .husky/

# pre-commitフック確認
cat .husky/pre-commit
```

**確認ポイント:**

- [ ] `.husky/` ディレクトリが存在する
- [ ] `pre-commit` フックが実行可能
- [ ] `commit-msg` フックが実行可能

### 品質チェックツールの確認

```bash
# ESLint確認
npx eslint --version

# Prettier確認
npx prettier --version

# Jest確認
npx jest --version

# ShellCheck確認
shellcheck --version
```

**確認ポイント:**

- [ ] ESLintが動作する
- [ ] Prettierが動作する
- [ ] Jestが動作する
- [ ] ShellCheckが動作する（オプション）

## 📦 プロジェクト依存関係の確認

### npm依存関係のインストール

```bash
# 依存関係のインストール状態確認
npm list --depth=0

# 依存関係の整合性チェック
npm audit
```

**確認ポイント:**

- [ ] すべての依存関係がインストールされている
- [ ] 脆弱性がない、または軽微なもののみ
- [ ] `node_modules/` が存在する

## 🧪 テストとビルドの確認

### テスト実行

```bash
# ユニットテスト実行
npm test

# フォーマットチェック
npm run format:check

# Lintチェック
npm run lint
```

**確認ポイント:**

- [ ] すべてのテストが通過する
- [ ] フォーマットチェックが通過する
- [ ] Lintチェックが通過する

## 🚀 CI/CD確認

### GitHub Actions設定確認

```bash
# ワークフローファイルの確認
ls -la .github/workflows/

# act（ローカルCI）の確認
act -l
```

**確認ポイント:**

- [ ] 必要なワークフローファイルが存在する
- [ ] `act` コマンドが利用可能（オプション）

## 📝 追加確認事項

### Claude Code専用機能

- [ ] `/repo-maintenance` コマンドが実行可能
- [ ] カスタムコマンド（`.claude/commands/`）が読み込まれている
- [ ] MCPサーバー（Playwright, o3など）が利用可能

### DevContainer固有

- [ ] ポート転送が正しく設定されている
- [ ] VS Code拡張機能がインストールされている
- [ ] ターミナルのデフォルトシェルが正しい（bash/zsh）

## ⚠️ トラブルシューティング

### LSPが動作しない場合

```bash
# Language Serverを手動でインストール
npm install -g typescript-language-server typescript bash-language-server vscode-langservers-extracted yaml-language-server

# Claude Codeを再起動
# VS Code/Cursorを再起動
```

### 環境変数が読み込まれない場合

```bash
# 環境変数を再生成
bash script/setup-env.sh
bash script/setup-mcp.sh

# DevContainerを完全に再ビルド
# VS Code: "Dev Containers: Rebuild Container"
```

### Git Hooksが動作しない場合

```bash
# Huskyを再インストール
npm run prepare

# Hooksファイルの実行権限確認
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg
```

## 📊 完了確認

すべてのチェック項目が完了したら、以下のコマンドで最終確認を実行:

```bash
# リポジトリメンテナンス実行
/repo-maintenance

# または手動で各種チェック
npm run format:check && npm run lint && npm test
```

---

**最終更新**: 2026-01-04
**対象バージョン**: Claude Code 2.0.76+, DevContainer config-base 1.42.0+
