# Claude Settings ファイルの役割

## ファイル一覧

| ファイル                     | 用途                        | 配置先                                                     |
| ---------------------------- | --------------------------- | ---------------------------------------------------------- |
| `claude-settings.json`       | CI/GitHub Actions 用        | `.claude/settings.json` として DevContainer にコピー       |
| `claude-settings.local.json` | DevContainer ローカル開発用 | `.claude/settings.local.json` として DevContainer にコピー |

## 主な差分

### `claude-settings.json`（CI 用）

- **権限モデル**: `allow` / `deny` / `ask` の3層で制御
- **追加の WebFetch ドメイン**: `assemblyai.com`, `ai-sdk.dev`, `vercel.com`, `speechmatics.com`, `sentry.io`
- **追加の Bash 許可**: `cat`, `head`, `for/while/if` 制御構文, `wc`, `xargs`, `jq`, `perl`, `tsx`, `nodemon`, `tsc`, `python`, `deno --version`, `npm --version`, `npm test`, `tsc --build`, `npx tsup`, `vitest list`, `brew list`, `sqlite3`, `afplay`, `op`（1Password CLI）
- **追加の Git 許可**: `git status`, `git diff`, `git clean`
- **追加の GH CLI 許可**: `gh issue list`, `gh issue view`, `gh issue close`, `gh repo view`
- **Supabase MCP**: `search_docs`, `get_logs`, `mcp__supabase__*` 系も許可
- **追加の Cloud 許可**: `vercel project ls`
- **Hooks パス**: `/home/vscode/.claude/hooks/` の絶対パス（コンテナ内配置想定）
- **追加 Hooks**: `pre_exit_plan_ai_review.py`（ExitPlanMode matcher）
- **Skill 許可**: `vercel:logs`
- **Read 許可**: `.codex/**`, `.claude/plugins/**`

### `claude-settings.local.json`（DevContainer ローカル用）

- **権限モデル**: `allow` / `deny` のみ（`ask` は空配列）
- **defaultMode**: `acceptEdits`（ローカル開発の効率重視）
- **enableAllProjectMcpServers**: `true`
- **enabledMcpjsonServers**: `["playwright"]`
- **enabledPlugins**: `kubernetes-operations@claude-code-workflows`
- **Hooks パス**: `.claude/hooks/` の相対パス（ワークスペースルート基準）
- **追加 Bash 許可**: `mise` 関連, `setup-claude.sh`, `claude` CLI 自体
- **Read 許可**: `/home/vscode/.codex/**`
- **Skill 許可**: `config-base-sync-update`
- **CI 用の `ask` 項目が `deny` に昇格**: Supabase の `db push`, `migration squash/repair`, `db reset` がローカルでは deny

## 設計意図

- **CI 環境**: 最小権限の原則に従い、明示的に `ask` 層で人間の確認を挟む操作を定義
- **ローカル開発**: 開発効率のため `acceptEdits` モードをデフォルトとし、破壊的操作は `deny` で完全ブロック
- **Hooks**: CI 用は絶対パス、ローカル用は相対パスで、同一のスクリプトを参照
