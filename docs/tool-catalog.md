# Tool Catalog

環境×ツールのマトリクスを一覧化し、各リポジトリのツール構成を可視化する。

## 1. ツール管理の4レイヤー構造

```
Layer 4: macOS ローカル (Nix + Homebrew cask)
    ├─ CLI ツール (Nix)、GUI アプリ (Homebrew cask)、VS Code 拡張
Layer 3: プロジェクト依存 (package.json / pubspec.yaml / build.gradle)
    ├─ フレームワーク、テストライブラリ、リンター
Layer 2: DevContainer Features (devcontainer.json)
    ├─ クラウド CLI、追加ランタイム、インフラツール
Layer 1: ベースイメージ (ghcr.io/keito4/config-base)
    └─ Node.js, Python, AI CLI, Language Servers
```

| レイヤー             | 管理場所                            | 更新頻度          | 影響範囲     |
| -------------------- | ----------------------------------- | ----------------- | ------------ |
| L1: ベースイメージ   | `config/.devcontainer/Dockerfile`   | リリース時        | 全リポジトリ |
| L2: Features         | 各 `devcontainer.json`              | リポ個別          | 当該リポのみ |
| L3: プロジェクト依存 | `package.json` 等                   | 開発中随時        | 当該リポのみ |
| L4: macOS ローカル   | `nix/` + `nix/modules/homebrew.nix` | `make nix-switch` | ローカルのみ |

## 2. ベースイメージ (`config-base`) に含まれるツール

### 2.1 ランタイム

| ツール   | バージョン      | 用途                       |
| -------- | --------------- | -------------------------- |
| Node.js  | 24.14.1         | JavaScript/TypeScript 実行 |
| Python 3 | apt 管理        | スクリプト、AI ツール      |
| pnpm     | 10.33.0         | パッケージマネージャ       |
| npm      | see global.json | パッケージマネージャ       |
| corepack | see global.json | パッケージマネージャ切替   |

> **Note**: Rust ツールチェインは [ADR #0003](adr/0003-remove-rust-from-base-image.md) によりベースイメージから削除。ビルド時間短縮（約20分削減）のため、`similarity-ts` は `/similarity-analysis` コマンドの初回実行時にオンデマンドインストールされる。

### 2.2 AI CLI ツール

| ツール                            | バージョン管理            | 用途                |
| --------------------------------- | ------------------------- | ------------------- |
| Claude Code                       | native installer (2.1.92) | AI コーディング支援 |
| Codex (`@openai/codex`)           | see global.json           | OpenAI Codex CLI    |
| Gemini CLI (`@google/gemini-cli`) | see global.json           | Google Gemini CLI   |
| Happy Coder                       | see global.json           | AI コーディング     |
| Cursor                            | curl installer            | AI エディタ CLI     |

#### 設定ファイルの場所

| ツール     | 設定ファイル              | 形式 | 内容                       |
| ---------- | ------------------------- | ---- | -------------------------- |
| Claude     | `~/.claude/settings.json` | JSON | commands, hooks, skills    |
| Codex      | `~/.codex/config.toml`    | TOML | MCP サーバー、機能フラグ   |
| Gemini CLI | `~/.gemini/settings.json` | JSON | MCP サーバー               |
| Cursor     | `~/.cursor/mcp.json`      | JSON | MCP サーバー、カスタム設定 |

> 設定は `script/export.sh` / `script/import.sh` で一括管理可能。

### 2.3 ユーティリティ

| ツール          | バージョン      | 用途                                             |
| --------------- | --------------- | ------------------------------------------------ |
| shellcheck      | apt 管理        | シェルスクリプト検証                             |
| GitHub CLI (gh) | 2.89.0          | GitHub 操作                                      |
| Doppler CLI     | 3.75.3          | シークレット管理                                 |
| similarity-ts   | オンデマンド    | コード類似度分析（初回実行時に自動インストール） |
| eslint          | npm global      | JavaScript リンター                              |
| Supabase CLI    | pnpm global     | Supabase 操作                                    |
| Vercel CLI      | see global.json | Vercel デプロイ                                  |
| n8n             | see global.json | ワークフロー自動化                               |
| pm2             | see global.json | プロセスマネージャ                               |
| difit           | see global.json | AI diff レビューツール                           |
| `@antfu/ni`     | see global.json | パッケージマネージャ抽象化 CLI                   |

### 2.4 Language Servers（[`npm/global.json`](../npm/global.json) 参照）

- `typescript` — TypeScript コンパイラ
- `typescript-language-server` — TypeScript LSP
- `bash-language-server` — Bash LSP
- `vscode-langservers-extracted` — HTML/CSS/JSON LSP
- `yaml-language-server` — YAML LSP

### 2.5 MCP / Automation（[`npm/global.json`](../npm/global.json) 参照）

- `mcp-remote` — MCP リモート接続
- `@leonardsellem/n8n-mcp-server` — n8n MCP サーバー

### 2.6 Git / CI 関連（Dockerfile 末尾でインストール、バージョンは [`package.json`](../package.json) 参照）

- `husky` — Git hooks
- `@commitlint/cli` — コミットメッセージ検証
- `@commitlint/config-conventional` — Conventional Commits

## 3. DevContainer Features（config ベースで提供）

`config/.devcontainer/devcontainer.json` に定義されている Features:

| Feature                                | 用途                          |
| -------------------------------------- | ----------------------------- |
| `homebrew-package`                     | Homebrew パッケージマネージャ |
| `jq-likes` (jq/yq)                     | JSON/YAML 処理                |
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

| 種別                  | 注目する依存                                                                                                                                                                                                                                                        |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 共通基盤 (config)     | semantic-release, jest-junit, bats                                                                                                                                                                                                                                  |
| Web アプリ (Next.js)  | `@supabase/ssr`, `@vercel/logger`, `@sentry/nextjs`, `@vercel/analytics`, `@vercel/speed-insights`, Zod 4, `@t3-oss/env-nextjs`, react-hook-form, `@axe-core/playwright`, jest-axe, `@next/bundle-analyzer`, Tailwind CSS 4, Testing Library, Playwright, LangSmith |
| npm ライブラリ (CLI)  | `@notionhq/client`, commander, ts-jest, semantic-release                                                                                                                                                                                                            |
| SPA (React + Vite)    | `@google/genai`, D3.js, React 19, Biome                                                                                                                                                                                                                             |
| デスクトップ拡張 (TS) | lint-staged, monorepo (pnpm workspaces)                                                                                                                                                                                                                             |
| モバイル (Flutter)    | Riverpod, Drift (SQLite), Freezed, go_router                                                                                                                                                                                                                        |

## 5. macOS ローカルツール（Nix + Homebrew cask）

`nix/home/packages.nix` (CLI) + `nix/modules/homebrew.nix` (GUI) で管理。

### 5.1 開発ツール (Nix)

| カテゴリ        | ツール                                      |
| --------------- | ------------------------------------------- |
| 言語/ランタイム | deno, openjdk, pipenv, uv, gcc              |
| VCS/Git         | git, gh, ghq, tig, git-lfs                  |
| ユーティリティ  | jq, fzf, peco, tree, coreutils, trash, gawk |

### 5.2 Cloud / DevOps (Nix)

| ツール                     | 用途               |
| -------------------------- | ------------------ |
| awscli2, aws-sam-cli       | AWS                |
| azure-cli                  | Azure              |
| gcloud-cli (Homebrew cask) | GCP                |
| terraform                  | IaC                |
| kubernetes-helm            | Kubernetes         |
| sops                       | シークレット暗号化 |
| supabase (Homebrew tap)    | BaaS               |

### 5.3 Cask アプリケーション（Homebrew、抜粋）

| カテゴリ     | アプリ                                                   |
| ------------ | -------------------------------------------------------- |
| 開発         | Visual Studio Code, Cursor, TablePlus, OrbStack, Rancher |
| AI           | ChatGPT, Claude                                          |
| 通信         | Slack, Discord, Zoom                                     |
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

## 6. テストツール（templates/testing）

`/setup-tests` コマンドで導入可能な包括的テスト基盤。

### 6.1 テストフレームワーク

| ツール          | バージョン目安 | 用途                       |
| --------------- | -------------- | -------------------------- |
| Jest            | 29.x           | Unit / Component テスト    |
| Playwright      | 1.52.x         | E2E / Visual / A11y テスト |
| Testing Library | 16.x           | コンポーネントテスト       |
| fast-check      | 3.x            | Property-based テスト      |
| Stryker         | 9.x            | Mutation テスト            |
| axe-core        | 4.x            | アクセシビリティ検証       |
| k6 / Artillery  | 最新           | 負荷テスト                 |
| Lighthouse      | 12.x           | Core Web Vitals            |

### 6.2 テストレベル

| レベル        | テスト種別数 | 主な対象                                   |
| ------------- | ------------ | ------------------------------------------ |
| minimal       | 3            | Unit, Component, Snapshot                  |
| standard      | 6            | + Integration, E2E, API                    |
| comprehensive | 9            | + Regression, Smoke, Contract              |
| full          | 13           | + Visual, A11y, Scenario, Property-based   |
| enterprise    | 21           | + Performance, Load, Security, DB, i18n 等 |

> **推奨**: 新規プロジェクトは `standard` レベル（70%+ カバレッジ必須）から開始し、プロダクション前に `comprehensive` へ昇格。

## 7. 所見・改善提案

### 7.1 ベースイメージバージョンの乖離

4 リポジトリ（npm ライブラリ、SPA、モバイル Flutter、モバイル Android）が **1.0.13** のまま。
最新は **1.97.0** であり、AI CLI やセキュリティパッチが大幅に遅れている。

> **推奨**: `/config-base-sync-update` コマンドで一括更新、または Dependabot/Renovate で自動化。

### 7.2 Features の重複

Web アプリ、デスクトップ拡張で `pnpm`, `gh`, `jq` などベースイメージに含まれるツールを Features で再インストールしている。
ベースイメージ更新後は Features の棚卸しが必要。

### 7.3 テスト未設定のリポジトリ

| 種別                  | 状態                                           |
| --------------------- | ---------------------------------------------- |
| SPA (React + Vite)    | Unit / E2E ともに未設定                        |
| デスクトップ拡張 (TS) | テストスクリプトなし（Raycast 固有の制約あり） |
| モバイル (Android)    | テスト未設定                                   |

> **推奨**: `/setup-tests` コマンドで包括的なテスト基盤を導入。21種類のテスト（Unit, Component, E2E, Regression, Visual, A11y, Performance 等）を5段階のレベルで段階的に追加可能。詳細は [templates/testing/README.md](../templates/testing/README.md) を参照。

### 7.4 リンター/フォーマッター未設定

SPA (React + Vite) とモバイル (Android) は lint / format スクリプトが未定義。
コード品質の最低保証が欠けている。

### 7.5 パッケージ管理の棚卸し

macOS パッケージは Nix (`nix/home/packages.nix`) で宣言的に管理。
不要パッケージの混入を防ぐため、定期的な棚卸しが必要。

> **推奨**: 四半期ごとに `nix/home/packages.nix` を見直し、不要パッケージを削除。`nix-collect-garbage` で未使用ストアを回収。

### 7.6 Git hooks の統一

共通基盤、Web アプリ、npm ライブラリは husky + commitlint を使用しているが、
SPA、モバイル (Flutter/Android) では Git hooks が未設定。

> **推奨**: `/setup-husky` コマンドで Conventional Commits を全リポに展開。
