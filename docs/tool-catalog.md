# Tool Catalog

環境×ツールのマトリクスを一覧化し、各リポジトリのツール構成を可視化する。

## 1. ツール管理の4レイヤー構造

```
Layer 4: macOS ローカル (Brewfile)
    ├─ GUI アプリ、OS レベルの CLI、VS Code 拡張
Layer 3: プロジェクト依存 (package.json / pubspec.yaml / build.gradle)
    ├─ フレームワーク、テストライブラリ、リンター
Layer 2: DevContainer Features (devcontainer.json)
    ├─ クラウド CLI、追加ランタイム、インフラツール
Layer 1: ベースイメージ (ghcr.io/keito4/config-base)
    └─ Node.js, Rust, Python, AI CLI, Language Servers
```

| レイヤー             | 管理場所                          | 更新頻度   | 影響範囲     |
| -------------------- | --------------------------------- | ---------- | ------------ |
| L1: ベースイメージ   | `config/.devcontainer/Dockerfile` | リリース時 | 全リポジトリ |
| L2: Features         | 各 `devcontainer.json`            | リポ個別   | 当該リポのみ |
| L3: プロジェクト依存 | `package.json` 等                 | 開発中随時 | 当該リポのみ |
| L4: macOS ローカル   | `brew/MacOSBrewfile`              | 手動       | ローカルのみ |

## 2. ベースイメージ (`config-base`) に含まれるツール

### 2.1 ランタイム

| ツール        | バージョン            | 用途                       |
| ------------- | --------------------- | -------------------------- |
| Node.js       | 22.14.0               | JavaScript/TypeScript 実行 |
| Rust (stable) | rustup 管理           | CLI ツールビルド           |
| Python 3      | apt 管理              | スクリプト、AI ツール      |
| pnpm          | npm 経由で最新        | パッケージマネージャ       |
| npm           | 11.10.0 (global.json) | パッケージマネージャ       |
| corepack      | 0.34.6 (global.json)  | パッケージマネージャ切替   |

### 2.2 AI CLI ツール

| ツール                            | バージョン管理            | 用途                |
| --------------------------------- | ------------------------- | ------------------- |
| Claude Code                       | native installer (2.1.42) | AI コーディング支援 |
| Codex (`@openai/codex`)           | 0.101.0 (global.json)     | OpenAI Codex CLI    |
| Gemini CLI (`@google/gemini-cli`) | 0.28.2 (global.json)      | Google Gemini CLI   |
| Happy Coder                       | 0.13.0 (global.json)      | AI コーディング     |
| Cursor                            | curl installer            | AI エディタ CLI     |

### 2.3 ユーティリティ

| ツール        | バージョン            | 用途                 |
| ------------- | --------------------- | -------------------- |
| shellcheck    | apt 管理              | シェルスクリプト検証 |
| Doppler CLI   | 3.75.2                | シークレット管理     |
| similarity-ts | cargo install         | コード類似度分析     |
| eslint        | npm global            | JavaScript リンター  |
| Supabase CLI  | pnpm global           | Supabase 操作        |
| Vercel CLI    | 50.17.1 (global.json) | Vercel デプロイ      |
| n8n           | 2.7.5 (global.json)   | ワークフロー自動化   |
| pm2           | 6.0.14 (global.json)  | プロセスマネージャ   |

### 2.4 Language Servers（global.json）

| パッケージ                   | バージョン | 対象言語              |
| ---------------------------- | ---------- | --------------------- |
| typescript                   | 5.9.3      | TypeScript コンパイラ |
| typescript-language-server   | 5.1.3      | TypeScript LSP        |
| bash-language-server         | 5.6.0      | Bash LSP              |
| vscode-langservers-extracted | 4.10.0     | HTML/CSS/JSON LSP     |
| yaml-language-server         | 1.19.2     | YAML LSP              |

### 2.5 MCP / Automation

| パッケージ                      | バージョン | 用途             |
| ------------------------------- | ---------- | ---------------- |
| mcp-remote                      | 0.1.38     | MCP リモート接続 |
| `@leonardsellem/n8n-mcp-server` | 0.1.8      | n8n MCP サーバー |

### 2.6 Git / CI 関連（Dockerfile 末尾でインストール）

| パッケージ                        | バージョン | 用途                   |
| --------------------------------- | ---------- | ---------------------- |
| husky                             | 9.1.7      | Git hooks              |
| `@commitlint/cli`                 | 20.4.1     | コミットメッセージ検証 |
| `@commitlint/config-conventional` | 20.4.1     | Conventional Commits   |

## 3. DevContainer Features（config ベースで提供）

`config/.devcontainer/devcontainer.json` に定義されている Features:

| Feature                                | 用途                          |
| -------------------------------------- | ----------------------------- |
| `homebrew-package`                     | Homebrew パッケージマネージャ |
| `jq-likes` (jq/yq)                     | JSON/YAML 処理                |
| `node` (+ pnpm latest)                 | Node.js（追加バージョン）     |
| `1password`                            | シークレット管理              |
| `github-cli`                           | GitHub CLI (`gh`)             |
| `git`                                  | Git（最新版）                 |
| `terraform`                            | IaC                           |
| `google-cloud-cli`                     | GCP CLI                       |
| `aws-cli`                              | AWS CLI                       |
| `kubectl-helm-minikube` (kubectl 1.28) | Kubernetes 操作               |
| `act`                                  | GitHub Actions ローカル実行   |
| `deno`                                 | Deno ランタイム               |
| `docker-in-docker` (moby + compose v2) | Docker-in-Docker              |
| `playwright`                           | ブラウザ自動テスト            |
| `supabase-cli`                         | Supabase CLI                  |

> **Codespaces 用** (`codespaces/devcontainer.json`) は上記 + `sshd` Feature を追加。

## 4. リポジトリ×ツール マトリクス

### 4.1 DevContainer 利用リポジトリ

|                        | 共通基盤 (config)  | Web アプリ (Next.js)                          | npm ライブラリ (CLI) | SPA (React + Vite) | デスクトップ拡張 (TS) | モバイル (Flutter)     | モバイル (Android) |
| ---------------------- | ------------------ | --------------------------------------------- | -------------------- | ------------------ | --------------------- | ---------------------- | ------------------ |
| **ベースイメージ ver** | ローカルビルド     | 1.54.0                                        | 1.0.13               | 1.0.13             | 1.58.0                | 1.0.13                 | 1.0.13             |
| **言語**               | JS/Shell           | TypeScript                                    | TypeScript           | TypeScript         | TypeScript            | Dart/Flutter           | Kotlin             |
| **フレームワーク**     | -                  | Next.js 15                                    | - (CLI)              | React 19 + Vite    | Raycast API           | Flutter 3.27           | Jetpack Compose    |
| **PKG マネージャ**     | npm                | npm                                           | pnpm                 | npm                | pnpm                  | pub                    | Gradle             |
| **テスト (Unit)**      | Jest + BATS        | Jest                                          | Jest                 | -                  | -                     | flutter_test + mockito | -                  |
| **テスト (E2E)**       | -                  | Playwright                                    | -                    | -                  | -                     | Patrol                 | -                  |
| **リンター**           | ESLint             | ESLint + next lint                            | ESLint               | -                  | -                     | very_good_analysis     | -                  |
| **フォーマッター**     | Prettier           | Prettier                                      | Prettier             | -                  | Prettier              | dart format            | -                  |
| **Git hooks**          | husky + commitlint | husky + commitlint                            | husky                | -                  | husky + commitlint    | -                      | -                  |
| **CI/CD**              | GitHub Actions     | GitHub Actions                                | GitHub Actions       | -                  | GitHub Actions        | GitHub Actions         | -                  |
| **追加 Features**      | 全 Features        | git, pnpm, gh, jq, supabase, dind, playwright | node(20), gh         | -                  | gh, dind, pnpm, jq    | flutter, java(17)      | java(17) + gradle  |

### 4.2 主要な追加依存（注目ポイント）

| 種別                  | 注目する依存                                                                   |
| --------------------- | ------------------------------------------------------------------------------ |
| 共通基盤 (config)     | semantic-release, jest-junit, bats                                             |
| Web アプリ (Next.js)  | `@supabase/ssr`, Tailwind CSS 4, Zod 4, Testing Library, Playwright, LangSmith |
| npm ライブラリ (CLI)  | `@notionhq/client`, commander, ts-jest, semantic-release                       |
| SPA (React + Vite)    | `@google/genai`, D3.js, React 19                                               |
| デスクトップ拡張 (TS) | lint-staged, monorepo (pnpm workspaces)                                        |
| モバイル (Flutter)    | Riverpod, Drift (SQLite), Freezed, go_router                                   |

## 5. macOS ローカルツール（Brewfile）

`brew/MacOSBrewfile` より抽出。

### 5.1 開発ツール (brew)

| カテゴリ        | ツール                                      |
| --------------- | ------------------------------------------- |
| 言語/ランタイム | node, deno, php, openjdk, pipenv, uv        |
| VCS/Git         | git, gh, ghq, tig                           |
| ユーティリティ  | jq, fzf, peco, tree, coreutils, trash, gawk |

### 5.2 Cloud / DevOps (brew)

| ツール                            | 用途               |
| --------------------------------- | ------------------ |
| awscli, aws-sam-cli, aws-sso-util | AWS                |
| azure-cli                         | Azure              |
| gcloud-cli (cask)                 | GCP                |
| terraform, tfenv                  | IaC                |
| helm                              | Kubernetes         |
| docker                            | コンテナ           |
| sops                              | シークレット暗号化 |
| supabase                          | BaaS               |

### 5.3 Cask アプリケーション（抜粋）

| カテゴリ     | アプリ                                                   |
| ------------ | -------------------------------------------------------- |
| 開発         | Visual Studio Code, Cursor, TablePlus, OrbStack, Rancher |
| AI           | ChatGPT, Claude                                          |
| 通信         | Slack, Discord, Mattermost, Zoom                         |
| 生産性       | Notion, Raycast, Alfred, BetterTouchTool, Karabiner      |
| セキュリティ | 1Password, 1Password CLI, Tailscale                      |
| ブラウザ     | Arc                                                      |

### 5.4 VS Code 拡張機能（抜粋・カテゴリ別）

| カテゴリ | 拡張機能                                                                                       |
| -------- | ---------------------------------------------------------------------------------------------- |
| AI       | `anthropic.claude-code`, `github.copilot`, `github.copilot-chat`, `openai.chatgpt`             |
| 言語     | `dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`, `denoland.vscode-deno`, `prisma.prisma`    |
| インフラ | `4ops.terraform`, `ms-kubernetes-tools.vscode-kubernetes-tools`, `ms-azuretools.vscode-docker` |
| Remote   | `ms-vscode-remote.remote-containers`, `ms-vscode-remote.remote-ssh`, `github.codespaces`       |
| Python   | `ms-python.python`, `ms-python.vscode-pylance`, `ms-python.isort`                              |
| Ruby     | `shopify.ruby-lsp`, `rebornix.ruby`                                                            |

## 6. 所見・改善提案

### 6.1 ベースイメージバージョンの乖離

4 リポジトリ（npm ライブラリ、SPA、モバイル Flutter、モバイル Android）が **1.0.13** のまま。
最新は **1.58.0+** であり、AI CLI やセキュリティパッチが大幅に遅れている。

> **推奨**: `/config-base-sync-update` コマンドで一括更新、または Dependabot/Renovate で自動化。

### 6.2 Features の重複

Web アプリ、デスクトップ拡張で `pnpm`, `gh`, `jq` などベースイメージに含まれるツールを Features で再インストールしている。
ベースイメージ更新後は Features の棚卸しが必要。

### 6.3 テスト未設定のリポジトリ

| 種別                  | 状態                                           |
| --------------------- | ---------------------------------------------- |
| SPA (React + Vite)    | Unit / E2E ともに未設定                        |
| デスクトップ拡張 (TS) | テストスクリプトなし（Raycast 固有の制約あり） |
| モバイル (Android)    | テスト未設定                                   |

> **推奨**: TDD ベースライン（70%+ カバレッジ）に合わせ、最低限 Unit テストを追加。

### 6.4 リンター/フォーマッター未設定

SPA (React + Vite) とモバイル (Android) は lint / format スクリプトが未定義。
コード品質の最低保証が欠けている。

### 6.5 Brewfile の肥大化

`MacOSBrewfile` は **232 行**に達しており、使用頻度の低いツールが混在。
`categories.json` による分類は存在するが、定期的な棚卸しルールがない。

> **推奨**: 四半期ごとに `brew uses --installed` で利用状況を確認し、不要パッケージを削除。

### 6.6 Git hooks の統一

共通基盤、Web アプリ、npm ライブラリは husky + commitlint を使用しているが、
SPA、モバイル (Flutter/Android) では Git hooks が未設定。

> **推奨**: `/setup-husky` コマンドで Conventional Commits を全リポに展開。
