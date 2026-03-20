# Skills・Commands・Hooks 一覧

---

## A. 外部スキル定義（`skills.txt`）

DevContainer ビルド時に `npx skills add` でインストールされるスキル。

| カテゴリ           | リポジトリ                                               | 用途                                          |
| ------------------ | -------------------------------------------------------- | --------------------------------------------- |
| **React**          | `facebook/react@fix`                                     | React 公式スキル                              |
|                    | `millionco/react-doctor`                                 | React コードベース診断・修正                  |
| **Vercel Agent**   | `vercel-labs/agent-skills`                               | React/Next.js ベストプラクティス              |
|                    | `vercel-labs/agent-skills@vercel-composition-patterns`   | コンポジションパターン                        |
| **Supabase**       | `supabase/agent-skills`                                  | Supabase 開発ベストプラクティス               |
|                    | `supabase/agent-skills@supabase-postgres-best-practices` | Postgres ベストプラクティス                   |
| **Vercel Skills**  | `vercel-labs/skills`                                     | スキルプラットフォーム                        |
|                    | `vercel-labs/skills@find-skills`                         | スキル検索・発見                              |
| **Browser**        | `vercel-labs/agent-browser`                              | ブラウザ自動化（Plugin 併用）                 |
| **Anthropic**      | `anthropics/skills@skill-creator`                        | スキル作成支援                                |
| **Sentry**         | `getsentry/skills@skill-scanner`                         | Sentry スキルスキャナー                       |
| **Office/Finance** | `claude-office-skills/skills@excel-automation`           | Excel 自動化                                  |
|                    | `claude-office-skills/skills@stock-analysis`             | 株式分析                                      |
| **Testing**        | `sickn33/antigravity-awesome-skills@playwright-skill`    | Playwright E2E テスト                         |
| **Context7**       | `intellectronica/agent-skills`                           | ライブラリ最新ドキュメント取得（Plugin 併用） |

---

## B. インストール済み Agent Skills（`.agents/skills/`）

ローカルにインストール済みのスキル（ルール群を含む）。

| スキル                        | ルール数 | 説明                                                  |
| ----------------------------- | -------- | ----------------------------------------------------- |
| `vercel-composition-patterns` | 8        | compound components、boolean prop 排除、React 19 対応 |
| `vercel-react-best-practices` | 50+      | レンダリング、バンドル、非同期、SSR、re-render 最適化 |
| `vercel-react-native-skills`  | 30+      | リスト性能、アニメーション、ナビゲーション、UI        |
| `web-design-guidelines`       | —        | Web Interface Guidelines 準拠レビュー                 |

---

## C. 自動適用スキル（`.claude/skills/*.md`）

PR 作成後等に自動トリガーされるスキル。

| スキル          | トリガー                           | 説明                               |
| --------------- | ---------------------------------- | ---------------------------------- |
| `ci-check`      | PR 作成後                          | CI 結果監視、失敗時修正            |
| `codex-review`  | PR 作成後（Codex CLI 利用可能時）  | OpenAI Codex によるコードレビュー  |
| `gemini-review` | PR 作成後（Gemini CLI 利用可能時） | Google Gemini によるコードレビュー |

---

## D. スラッシュコマンド（`.claude/commands/`）

### Git 操作

| コマンド         | 説明                           |
| ---------------- | ------------------------------ |
| `git-sync`       | Git 同期                       |
| `branch-cleanup` | 不要ブランチ削除               |
| `create-pr`      | ベースブランチ最新化 + PR 作成 |

### CI/CD

| コマンド         | 説明                   |
| ---------------- | ---------------------- |
| `setup-ci`       | CI/CD ワークフロー構築 |
| `update-actions` | GitHub Actions 更新    |

### 品質チェック

| コマンド                   | 説明                         |
| -------------------------- | ---------------------------- |
| `pre-pr-checklist`         | PR 前チェックリスト          |
| `code-complexity-check`    | コード複雑度検証             |
| `security-credential-scan` | 認証情報漏洩チェック         |
| `security-review`          | セキュリティ改善提案         |
| `similarity-analysis`      | コード類似度分析（重複検出） |
| `test-coverage-trend`      | テストカバレッジ推移         |

### 環境管理

| コマンド                 | 説明                      |
| ------------------------ | ------------------------- |
| `container-health`       | コンテナ健全性チェック    |
| `devcontainer-checklist` | DevContainer 再起動後確認 |
| `create-codespace`       | Codespace 作成            |
| `codespaces-secrets`     | Codespaces Secrets 管理   |

### セットアップ

| コマンド                | 説明                                     |
| ----------------------- | ---------------------------------------- |
| `setup-new-repo`        | 新リポジトリ構築（DevContainer + CI/CD） |
| `setup-husky`           | Husky + lint-staged + commitlint 構築    |
| `setup-team-protection` | リポジトリ保護設定                       |
| `setup-tests`           | テスト基盤構築（Next.js 向け）           |

### Config 同期

| コマンド                       | 説明                                  |
| ------------------------------ | ------------------------------------- |
| `config-base-sync-check`       | config-base イメージバージョン確認    |
| `config-base-sync-update`      | config-base 最新化 + PR 作成          |
| `config-contribution-discover` | リポジトリの有用機能発見 → Issue 起票 |
| `sync-settings`                | Claude/Codex 設定の DevContainer 同期 |

### メンテナンス

| コマンド                  | 説明                     |
| ------------------------- | ------------------------ |
| `repo-maintenance`        | 全ヘルスチェック一括実行 |
| `dependency-health-check` | 依存関係健全性チェック   |
| `changelog-generator`     | CHANGELOG 生成           |
| `update-claude-code`      | Claude Code 更新         |

---

## E. Hooks（`.claude/hooks/`）

| フック                        | イベント    | 説明                                 |
| ----------------------------- | ----------- | ------------------------------------ |
| `block_git_no_verify.py`      | PreToolUse  | `--no-verify` / `HUSKY=0` をブロック |
| `block_dangerous_commands.py` | PreToolUse  | 危険コマンド実行を防止               |
| `pre_git_quality_gates.py`    | PreToolUse  | Git 操作前に Quality Gates 自動実行  |
| `post_git_push_ci.py`         | PostToolUse | push 後に CI 状態を監視              |
| `post_pr_ci_watch.py`         | PostToolUse | PR 作成後に CI 監視                  |
| `post_pr_ai_review.py`        | PostToolUse | PR 作成後に AI レビュー実行          |
| `pre_exit_plan_ai_review.py`  | PreToolUse  | Plan 終了前に AI レビュー            |
