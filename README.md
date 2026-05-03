# Config Repository

[![CI](https://github.com/keito4/config/actions/workflows/ci.yml/badge.svg)](https://github.com/keito4/config/actions/workflows/ci.yml)
[![Security](https://github.com/keito4/config/actions/workflows/security.yml/badge.svg)](https://github.com/keito4/config/actions/workflows/security.yml)
[![codecov](https://codecov.io/gh/keito4/config/branch/main/graph/badge.svg)](https://codecov.io/gh/keito4/config)

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

```
config/
├── .actrc                          # act（ローカルGitHub Actions実行）設定
├── .claude/                        # Claude Code 設定
│   ├── CLAUDE.md                   # 開発標準・ガイドライン
│   ├── settings.json               # 共有パーミッション・環境変数・フック
│   ├── settings.local.json.template # ユーザー固有設定テンプレート
│   ├── .gitignore
│   ├── devcontainer-recommendations.md
│   ├── agents/                     # 専用エージェント設定
│   │   ├── README.md
│   │   ├── act-local-ci-manager.md
│   │   ├── docs-consistency-checker.md
│   │   ├── issue-resolver-*.md     # Issue解決エージェント群（orchestrator, code-quality, dependencies, documentation, security, test-coverage）
│   │   ├── playwright-test-generator.md
│   │   ├── playwright-test-healer.md
│   │   └── playwright-test-planner.md
│   ├── commands/                   # カスタムスラッシュコマンド
│   │   ├── README.md
│   │   ├── branch-cleanup.md
│   │   ├── changelog-generator.md
│   │   ├── code-complexity-check.md
│   │   ├── codespaces-secrets.md
│   │   ├── config-base-sync-check.md
│   │   ├── config-base-sync-update.md
│   │   ├── config-contribution-discover.md
│   │   ├── container-health.md
│   │   ├── create-codespace.md
│   │   ├── create-pr.md
│   │   ├── dependency-health-check.md
│   │   ├── devcontainer-checklist.md
│   │   ├── git-sync.md
│   │   ├── pre-pr-checklist.md
│   │   ├── repo-maintenance.md
│   │   ├── security-credential-scan.md
│   │   ├── security-review.md
│   │   ├── setup-ci.md
│   │   ├── setup-doppler.md        # Doppler シークレット管理セットアップ
│   │   ├── setup-husky.md
│   │   ├── setup-new-repo.md
│   │   ├── setup-team-protection.md
│   │   ├── setup-tests.md
│   │   ├── similarity-analysis.md
│   │   ├── sync-settings.md
│   │   ├── test-coverage-trend.md
│   │   ├── update-actions.md
│   │   └── update-claude-code.md
│   ├── hooks/                      # イベント駆動の自動化スクリプト
│   │   ├── README.md
│   │   ├── block_config_edit.py    # リンター設定の編集防止
│   │   ├── block_dangerous_commands.py
│   │   ├── block_git_no_verify.py
│   │   ├── common.py               # 共通ユーティリティ
│   │   ├── post_commit_adr_reminder.py # ADR作成リマインダー
│   │   ├── post_edit_auto_lint.py  # ファイル編集後の自動リント
│   │   ├── post_git_push_ci.py
│   │   ├── post_pr_ai_review.py
│   │   ├── post_pr_ci_watch.py
│   │   ├── pre_exit_plan_ai_review.py
│   │   ├── pre_git_quality_gates.py
│   │   └── stop_test_verification.py # 完了前テスト検証
│   ├── plugins/                    # プラグイン設定
│   │   ├── README.md
│   │   ├── config.json
│   │   ├── known_marketplaces.json.template
│   │   └── plugins.txt
│   └── skills/                     # スキル設定
│       ├── README.md
│       ├── ci-check.md
│       ├── codex-review.md
│       ├── gemini-review.md
│       └── skills.txt
├── .claude-plugin/                 # LSP プラグイン設定
│   └── plugin.json
├── .codex/                         # Codex CLI 設定
│   └── config.toml                 # MCP サーバー設定
├── .context/                       # エージェント間共有の中間成果物
│   ├── code-complexity-baseline.json # コード複雑度ベースライン
│   └── complexity-report.md        # コード複雑度レポート
├── .cursor/                        # Cursor エディタ設定
│   └── rules/base.mdc
├── .devcontainer/                  # DevContainer 設定
│   ├── Dockerfile
│   ├── README.md
│   ├── VERSIONING.md
│   ├── devcontainer.json           # ローカル DevContainer 設定
│   ├── claude-settings.json        # DevContainer 用 Claude 共有設定
│   ├── claude-settings.local.json  # DevContainer 用 Claude ローカル設定
│   ├── claude-settings-README.md
│   ├── codespaces/
│   │   └── devcontainer.json       # GitHub Codespaces 用設定
│   └── templates/
│       ├── README.md
│       ├── .filelengthignore.template
│       ├── optional-features.json  # オプション言語サポート
│       └── project-presets.json    # プロジェクトプリセット
├── .gemini/                        # Gemini CLI 設定
│   └── settings.json
├── .github/                        # GitHub 設定
│   ├── pull_request_template.md
│   ├── dependabot.yml
│   ├── labels.yml
│   ├── slack-ci-failure.json
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── actions/
│   │   └── coverage-comment/       # カバレッジコメント用カスタムアクション
│   │       ├── README.md
│   │       ├── action.yml
│   │       └── example-integration.yml
│   └── workflows/                  # GitHub Actions ワークフロー
│       ├── ci.yml                  # CI パイプライン
│       ├── claude.yml              # Claude Code 統合
│       ├── claude-code-review.yml  # Claude コードレビュー
│       ├── container-security.yml  # コンテナセキュリティスキャン
│       ├── coverage-report.yml     # カバレッジレポート
│       ├── dependabot-auto-merge.yml # Dependabot 自動マージ
│       ├── docker-image.yml        # Docker イメージビルド
│       ├── label-sync.yml          # ラベル同期
│       ├── manual-release.yml      # 手動リリース
│       ├── quality-gate-fallback.yml # 品質ゲートフォールバック
│       ├── rebuild-docker-cache.yml # Docker キャッシュ再構築
│       ├── scheduled-maintenance.yml # 定期メンテナンス
│       ├── security.yml            # セキュリティスキャン
│       ├── update-claude-plugins.yml # Claude プラグイン更新
│       ├── update-dev-tools.yml    # 開発ツール更新
│       ├── update-libraries.yml    # ライブラリ自動更新
│       └── templates/              # 再利用可能ワークフローテンプレート
│           ├── README.md
│           ├── monorepo-release.yml
│           ├── tls-evidence.yml
│           ├── unified-ci.yml
│           ├── update-db-types.yml
│           └── zap-baseline.yml
├── .husky/                         # Git フック
│   ├── commit-msg
│   └── pre-commit
├── .vscode/                        # VS Code 設定
│   ├── extensions.json
│   └── settings.json
├── .zsh/                           # Zsh 設定モジュール
│   ├── configs/
│   │   ├── aliases.zsh
│   │   ├── color.zsh
│   │   ├── completion.zsh
│   │   ├── history.zsh
│   │   ├── keybindings.zsh
│   │   ├── prompt.zsh
│   │   ├── pre/                    # 初期化前設定
│   │   │   ├── .env
│   │   │   ├── .env.secret.template
│   │   │   ├── .gitignore
│   │   │   ├── completion.zsh
│   │   │   ├── envup.zsh
│   │   │   └── path.zsh
│   │   └── virtual/               # 言語バージョン管理
│   │       ├── dart.zsh
│   │       ├── java.zsh
│   │       ├── node.zsh
│   │       ├── php.zsh
│   │       └── ruby.zsh
│   └── functions/                  # カスタムシェル関数
│       ├── docker
│       ├── gcp
│       ├── git
│       ├── mkcd
│       ├── op
│       ├── peco
│       ├── process
│       ├── terraform
│       └── utilities
├── brew/                           # Homebrew 設定（Linux 用）
│   ├── LinuxBrewfile
│   └── LinuxBrewfile.lock.json
├── nix/                            # Nix 環境管理（macOS）
│   ├── flake.nix                   # nix-darwin + home-manager flake
│   ├── flake.lock
│   ├── home/                       # home-manager モジュール
│   │   ├── default.nix
│   │   ├── packages.nix
│   │   ├── git.nix
│   │   └── zsh.nix
│   ├── hosts/darwin/default.nix    # macOS システム設定
│   └── modules/homebrew.nix        # Homebrew cask/tap 管理
├── credentials/                    # 認証情報管理
│   ├── README.md
│   ├── setup.md
│   ├── .gitignore
│   └── templates/
│       ├── devcontainer.env.template
│       └── mcp.env.template
├── docs/                           # ドキュメント
│   ├── README.md
│   ├── doppler-setup-guide.md    # Doppler シークレット管理ガイド
│   ├── mcp-servers-guide.md
│   ├── sentry-setup-guide.md
│   ├── tool-catalog.md
│   ├── using-config-base-image.md
│   ├── adr/                        # Architecture Decision Records
│   │   ├── README.md
│   │   ├── 0001-devcontainer-base-image.md
│   │   ├── 0002-auto-version-updates.md
│   │   └── 0003-remove-rust-from-base-image.md
│   └── setup/                      # プロジェクト種別セットアップガイド
│       ├── README.md
│       ├── desktop-extension-ts.md
│       ├── mobile-android.md
│       ├── mobile-flutter.md
│       ├── npm-library-cli.md
│       ├── spa-react-vite.md
│       └── web-app-nextjs.md
├── dot/                            # ホームディレクトリ用 dotfiles
│   ├── .peco/config.json
│   └── .zshrc.devcontainer
├── eslint/                         # ESLint 設定テンプレート
│   ├── README.md
│   └── complexity-rules.mjs
├── git/                            # Git 設定
│   ├── README.md
│   ├── commitlint.config.js
│   ├── gitconfig
│   └── gitignore
├── npm/                            # npm グローバルパッケージ設定
│   └── global.json
├── script/                         # ユーティリティスクリプト
│   ├── README.md
│   ├── .shellcheck-exclude
│   ├── aerospace-fix-layout
│   ├── branch-cleanup.sh
│   ├── brew-deps.sh
│   ├── changelog-generator.sh
│   ├── check-file-length.sh
│   ├── check-image-version.sh
│   ├── code-complexity-check.sh
│   ├── codespaces-secrets.sh
│   ├── container-health.sh
│   ├── create-codespace.sh
│   ├── credentials.sh
│   ├── dependency-health-check.sh
│   ├── export.sh
│   ├── fix-container-plugins.sh
│   ├── import.sh
│   ├── install-claude-plugins.sh
│   ├── install-npm-globals.sh
│   ├── install-skills.sh
│   ├── pre-pr-checklist.sh
│   ├── restore-cli-auth.sh
│   ├── security-credential-scan.sh
│   ├── setup-claude-build.sh
│   ├── setup-claude.sh
│   ├── setup-env.sh
│   ├── setup-file-length-check.sh
│   ├── setup-lsp.sh
│   ├── setup-mcp.sh
│   ├── setup-scheduled-agents.sh  # Scheduled remote agents セットアップ
│   ├── setup-team-protection.sh
│   ├── update-agents-md.sh         # AGENTS.md 自動生成セクション更新
│   ├── test-coverage-trend.sh
│   ├── update-actions.sh
│   ├── update-all.sh
│   ├── update-claude-code.sh
│   ├── update-libraries.sh
│   ├── verify-container-setup.sh
│   ├── version.sh
│   ├── credentials/
│   │   └── providers/op.sh
│   └── lib/                        # 共通ライブラリ
│       ├── brew_categories.py
│       ├── claude_plugins.sh
│       ├── config.sh
│       ├── devcontainer.sh
│       ├── output.sh
│       └── platform.sh
├── templates/                      # プロジェクトテンプレート
│   ├── README.md
│   ├── doppler.yaml                # Doppler プロジェクト設定テンプレート
│   ├── editorconfig
│   ├── github/                     # GitHub テンプレート
│   │   ├── CODEOWNERS
│   │   ├── CONTRIBUTING.md
│   │   ├── SECURITY.md
│   │   ├── dependabot.yml
│   │   ├── labels.yml
│   │   ├── pull_request_template.md
│   │   ├── renovate.json
│   │   └── ISSUE_TEMPLATE/
│   │       ├── bug_report.yml
│   │       ├── config.yml
│   │       └── feature_request.yml
│   ├── husky/                      # Git フックテンプレート
│   │   ├── commit-msg              # commitlint（Conventional Commits）
│   │   ├── pre-commit              # lint-staged + ファイル長チェック
│   │   └── pre-push               # typecheck + lint + test
│   ├── lintstagedrc-biome.json     # lint-staged: Biome
│   ├── lintstagedrc-eslint.json    # lint-staged: ESLint + Prettier
│   ├── lintstagedrc-prettier-only.json # lint-staged: Prettier のみ
│   ├── pre-commit-config-base.yaml
│   ├── pre-commit-config-full.yaml
│   ├── pre-commit-config-terraform.yaml
│   ├── prettierignore              # Prettier 除外パターン
│   ├── prettierrc-base.json        # Prettier 標準設定（printWidth: 80）
│   ├── prettierrc-wide.json        # Prettier ワイド設定（printWidth: 120）
│   ├── testing/                    # テスト設定テンプレート
│   │   ├── README.md
│   │   ├── ci-test-jobs.yml
│   │   ├── jest.config.js
│   │   ├── jest.polyfills.js
│   │   ├── jest.regression.config.js
│   │   ├── jest.scenario.config.js
│   │   ├── jest.setup.js
│   │   ├── playwright.config.ts
│   │   ├── playwright.regression.config.ts
│   │   └── examples/              # テスト実装例（21種）
│   │       ├── a11y.spec.ts
│   │       ├── api-route.test.ts
│   │       ├── api.test.ts
│   │       ├── component.test.tsx
│   │       ├── contract.test.ts
│   │       ├── database.test.ts
│   │       ├── e2e-auth.spec.ts
│   │       ├── edge-functions.test.ts
│   │       ├── hook.test.ts
│   │       ├── i18n.test.tsx
│   │       ├── integration.test.ts
│   │       ├── load.test.ts
│   │       ├── mutation.config.js
│   │       ├── performance.spec.ts
│   │       ├── property-based.test.ts
│   │       ├── regression-auth.spec.ts
│   │       ├── security.test.ts
│   │       ├── smoke.test.ts
│   │       ├── snapshot.test.tsx
│   │       ├── ssr-hydration.spec.ts
│   │       └── visual.spec.ts
│   └── workflows/                  # ワークフローテンプレート
│       ├── claude-health-check.yml # Claude Code トークン有効性チェック
│       ├── claude.yml              # Claude Code 連携
│       ├── dependabot-auto-merge.yml
│       ├── e2e-playwright.yml      # Playwright E2E CI
│       ├── label-sync.yml
│       ├── scheduled-maintenance.yml # 定期メンテナンス
│       ├── stale.yml
│       └── terraform-drift.yml
├── test/                           # テスト
│   ├── commitlint-config.test.js
│   ├── config-validation.test.js
│   ├── credential-filtering.test.js
│   ├── eslint-config.test.js
│   ├── jest-config.test.js
│   ├── python/
│   │   └── test_hooks.py
│   ├── integration/                # 統合テスト（BATS）
│   │   ├── core-scripts.bats
│   │   ├── coverage-report-workflow.bats
│   │   ├── development-tools.bats
│   │   ├── e2e-scenarios.bats
│   │   ├── install_claude_plugins.bats
│   │   ├── lib_functions.bats
│   │   ├── platform_basic.bats
│   │   ├── security-scripts.bats
│   │   ├── setup_claude.bats
│   │   ├── update_actions.bats
│   │   ├── update_all.bats
│   │   ├── update_libraries.bats
│   │   ├── verify_container_setup.bats
│   │   └── workflows.bats
│   └── test_helper/
│       └── test_helper.bash
├── vscode/                         # VS Code 設定
│   ├── README.md
│   └── extensions.txt
├── AGENTS.md                       # AI エージェント設定
├── CLAUDE.md                       # 開発標準（ルート）
├── LICENSE
├── Makefile
├── README.md
├── SECURITY.md
├── commitlint.config.js
├── cspell.json
├── eslint.config.mjs
├── jest.config.js
├── package.json
├── package-lock.json
├── pnpm-workspace.yaml
├── .dockerignore
├── .editorconfig
├── .env.example
├── .filelengthignore.template
├── .gitattributes
├── .gitignore
├── .gitleaks.toml
├── .lsp.json
├── .mcp.json
├── .node-version
├── .npmrc
├── .prettierignore
├── .prettierrc
├── .releaserc.json
└── .trivyignore
```

**ファイル総数**: 360 ファイル（Git 管理対象）

各ディレクトリの概要：

- **`.claude/`**: Claude Code 設定（settings, commands, agents, hooks, skills, plugins）
- **`.codex/`**: Codex CLI の MCP サーバー設定
- **`.context/`**: エージェント間共有の中間成果物（コード複雑度レポート等）
- **`.devcontainer/`**: DevContainer / Codespaces 設定。`templates/` にオプション言語サポート
- **`.github/`**: GitHub Actions ワークフロー、Issue/PR テンプレート、カスタムアクション
- **`.zsh/`**: Zsh モジュール構成（aliases, functions, 言語バージョン管理）
- **`brew/`**: Linux 用 Brewfile
- **`credentials/`**: 1Password CLI 連携の認証情報テンプレート
- **`docs/`**: セットアップガイド、ADR、ツールカタログ
- **`dot/`**: ホームディレクトリ用 dotfiles（DevContainer 用 .zshrc 等）
- **`nix/`**: nix-darwin + home-manager による macOS 環境の宣言的管理
- **`eslint/`**: ESLint 複雑度ルールテンプレート
- **`git/`**: gitconfig, gitignore, commitlint 設定
- **`npm/`**: npm グローバルパッケージ定義
- **`script/`**: インポート/エクスポート、セットアップ、更新等のユーティリティスクリプト
- **`templates/`**: GitHub, テスト, ワークフローの再利用可能テンプレート
- **`test/`**: Jest 単体テスト、BATS 統合テスト、Python フックテスト
- **`vscode/`**: VS Code 拡張機能リストと設定

## Security

This repository follows security best practices to protect sensitive information:

### Credential Management

- **No hardcoded credentials**: Personal information like email addresses and SSH keys are not stored in configuration files
- **Environment variables**: Sensitive data is managed through environment variables and templates
- **1Password integration**: Use `script/credentials.sh` for secure credential management via 1Password CLI
- **Secure file permissions**: Generated credential files are automatically set to 600 permissions

### Git Configuration Security

The `git/gitconfig` file uses commented placeholders instead of hardcoded values. Configure your Git settings securely with:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

### Setup Instructions

#### Quick Start (Recommended)

1. **Install 1Password CLI**

   ```bash
   brew install --cask 1password-cli
   ```

2. **Sign in to 1Password**

   ```bash
   op signin
   ```

3. **Set up environment variables** ⚠️ **Run on host machine BEFORE DevContainer**

   For multiple 1Password accounts:

   ```bash
   OP_ACCOUNT=my.1password.com bash script/setup-env.sh
   bash script/setup-mcp.sh
   ```

   For single account:

   ```bash
   bash script/setup-env.sh
   bash script/setup-mcp.sh
   ```

   This creates `~/.devcontainer.env` which is **required** for DevContainer startup.

4. **Configure Git settings**

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   git config --global user.signingkey ~/.ssh/id_ed25519.pub
   ```

5. **Apply Nix configuration (macOS)**
   ```bash
   make nix-switch
   ```

#### What Gets Set Up

The automated setup creates:

- `~/.devcontainer.env` - DevContainer environment variables (600 permissions)
- `credentials/mcp.env` - MCP environment variables (600 permissions)
- `.mcp.json` - MCP configuration file (600 permissions)

All generated files are automatically excluded from Git via `.gitignore`.

#### 1Password Vault Structure

For the automated setup to work, create items in your 1Password Vault "Dev":

```
Vault: Dev
├── AWS (Login)
│   ├── AWS_ACCESS_KEY_ID: AKIA...
│   ├── AWS_SECRET_ACCESS_KEY: ...
│   └── AWS_REGION: ap-northeast-1
└── Other credentials
```

For detailed security guidelines and troubleshooting, see [SECURITY.md](SECURITY.md) and [credentials/README.md](credentials/README.md).

## Claude Code Configuration Management

The `.claude/` directory contains Claude Code configuration that is partially version-controlled:

> Note: This section is an overview. For authoritative development standards and AI workflow details, see `CLAUDE.md` and `AGENTS.md`.

### Version-Controlled Files

- `settings.json` - Shared permissions, environment variables, and hooks
- `commands/` - Custom slash commands available to all users
- `agents/` - Specialized agent configurations
- `hooks/` - Event-driven automation scripts
- `skills/` - Claude Code skills list (`skills.txt`) and skill-specific configurations
- `plugins/config.json` - Custom plugin repository configuration
- `plugins/known_marketplaces.json.template` - Template for plugin marketplace configuration (generates `known_marketplaces.json` locally)
- `plugins/plugins.txt` - Plugin list installed during DevContainer build
- `CLAUDE.md` - Global development standards and guidelines

### Local-Only Files (Git-Ignored)

- `settings.local.json` - User-specific overrides (plugin preferences, local permissions)
- `.credentials.json` - Sensitive authentication data
- `plugins/installed_plugins.json` - Installed plugin metadata (environment-specific)
- `plugins/marketplaces/` - Downloaded plugin files from marketplaces
- `plugins/repos/` - Custom repository plugins
- `debug/`, `file-history/`, `history.jsonl`, `plans/`, `projects/`, `session-env/`, `shell-snapshots/`, `statsig/`, `todos/` - Runtime and session data

### Synchronizing Configuration

Claude Code設定は`export.sh`と`import.sh`スクリプトで自動的に同期されます：

**自動同期される設定**

- `settings.json` - 共有パーミッション、環境変数、フック
- `commands/` - カスタムスラッシュコマンド
- `agents/` - 専用エージェント設定
- `hooks/` - イベント駆動の自動化スクリプト
- `skills/` - Claude Code スキル一覧（`skills.txt`）とスキル設定
- `plugins/config.json`, `plugins/known_marketplaces.json.template`, `plugins/plugins.txt` - プラグイン設定（テンプレート・一覧）
- `CLAUDE.md` - 開発標準とガイドライン

**同期されない設定（ローカル専用）**

- `settings.local.json` - ユーザー固有のオーバーライド
- `.credentials.json` - 認証情報
- `plugins/installed_plugins.json` - インストール済みプラグイン
- ランタイムデータ（`debug/`, `projects/`, `todos/`など）

`export.sh`を実行すると、これらの共有設定が自動的にリポジトリにコピーされます。`import.sh`を実行すると、リポジトリから`~/.claude/`に復元されます。

### Plugin Management

Plugin configuration is managed through three layers:

1. **Plugin List** (`plugins/plugins.txt` - version-controlled)
   - Declarative list of plugins installed during DevContainer build
   - Format: `plugin-name@marketplace-name`
   - Shared across all team members
   - Processed by `script/install-claude-plugins.sh`

2. **Marketplace Configuration** (template in `plugins/known_marketplaces.json.template`, generated as `known_marketplaces.json` locally)
   - Defines which plugin marketplaces to use
   - Template is shared across all team members
   - Generated file is local-only (not version-controlled)
   - Examples: official Anthropic plugins, community repositories

3. **Plugin Activation** (local-only in `settings.local.json`)
   - Individual choice of which plugins to enable
   - Environment-specific preferences
   - Not committed to version control

### Skills Management

Claude Code skills are managed separately from plugins:

- **Skills List** (`skills/skills.txt` - version-controlled): Declarative list of skills installed during DevContainer startup via `script/install-skills.sh`
- Skills are cloned into `~/.agents/skills/` and activated automatically
- Format: `owner/repo` or `owner/repo@branch`

For detailed plugin management instructions, see [.claude/plugins/README.md](.claude/plugins/README.md).

### Language Server Protocol (LSP) Configuration

The repository includes LSP configuration (`.claude-plugin/plugin.json`) to enable advanced code analysis and IntelliSense features in Claude Code v2.0.74+.

**Supported Language Servers:**

- **TypeScript/JavaScript**: `typescript-language-server` - Provides type checking, auto-completion, and navigation
- **Bash**: `bash-language-server` - Shell script analysis and validation
- **JSON**: `vscode-json-language-server` - JSON schema validation and formatting
- **YAML**: `yaml-language-server` - YAML syntax checking and schema validation

**Installation:**

Language servers are automatically installed as global npm packages during DevContainer setup. To manually install:

```bash
npm install -g typescript-language-server typescript bash-language-server vscode-langservers-extracted yaml-language-server
```

**Configuration:**

The `.claude-plugin/plugin.json` file defines LSP server configurations. Language servers are automatically activated based on file extensions:

- TypeScript/JavaScript: `.js`, `.jsx`, `.ts`, `.tsx`
- Bash: `.sh`, `.bash`
- JSON: `.json`, `.jsonc`
- YAML: `.yaml`, `.yml`

**Benefits:**

- Real-time code analysis and error detection
- Intelligent auto-completion and suggestions
- Go-to-definition and find-references navigation
- Inline documentation and type information
- Refactoring support

For more information about LSP support in Claude Code, see [Claude Code LSP Guide](https://blog.lai.so/claude-code-lsp/).

### Claude Code Hooks

Hooksは、Claude Codeの特定のイベントに自動実行されるスクリプトです。`.claude/hooks/` ディレクトリに格納されており、config-base イメージにも組み込まれるため DevContainer/Codespaces 環境でデフォルト有効です。

| Hook                          | トリガー                   | 目的                                                      |
| ----------------------------- | -------------------------- | --------------------------------------------------------- |
| `block_git_no_verify.py`      | `PreToolUse(Bash)`         | `--no-verify` や `HUSKY=0` の使用をブロック               |
| `block_config_edit.py`        | `PreToolUse(Write\|Edit)`  | リンター/フォーマッター設定ファイルの編集をブロック       |
| `block_dangerous_commands.py` | `PreToolUse(Bash)`         | 危険な Bash コマンドの実行をブロック                      |
| `pre_git_quality_gates.py`    | `PreToolUse(Bash)`         | git commit/push 前に品質チェックを自動実行                |
| `post_edit_auto_lint.py`      | `PostToolUse(Write\|Edit)` | ファイル編集後に自動フォーマット＋リント → 自己修正ループ |
| `post_git_push_ci.py`         | `PostToolUse(Bash)`        | git push 後に CI 状態を監視・報告                         |
| `post_pr_ai_review.py`        | `PostToolUse(Bash)`        | PR 作成後に AI レビューを実行                             |
| `post_pr_ci_watch.py`         | `PostToolUse(Bash)`        | PR 作成後に CI 状態を監視                                 |
| `post_commit_adr_reminder.py` | `PostToolUse(Bash)`        | git commit 後に ADR 作成をリマインド                      |
| `pre_exit_plan_ai_review.py`  | `PreToolUse(ExitPlanMode)` | プラン承認前に AI レビューを実行                          |
| `stop_test_verification.py`   | `Stop`                     | エージェント完了前にテスト実行 → 失敗時は修正を促す       |

**Quality Gates（自動検出方式）:**

`package.json` の `scripts` を解析し、利用可能なチェックを自動検出して実行します。パッケージマネージャー（npm / pnpm / yarn / bun）もロックファイルから自動判定されます。

| チェック            | 検出するスクリプト名                           |
| ------------------- | ---------------------------------------------- |
| Format Check        | `format:check`                                 |
| Lint                | `lint`, `lint:check`                           |
| Test                | `test`, `test:unit`                            |
| Type Check          | `typecheck`, `type-check`, `tsc`               |
| ShellCheck          | `shellcheck`                                   |
| Security Credential | `script/security-credential-scan.sh`（存在時） |
| Code Complexity     | `script/code-complexity-check.sh`（存在時）    |

詳細は [.claude/hooks/README.md](.claude/hooks/README.md) を参照してください。

## Usage

Before using these configuration settings, you should review them and adjust as necessary for your specific environment and preferences. For credentials, we use environment variables managed by 1Password.

### Importing Configuration Settings

Set the `REPO_PATH` environment variable to this repository's root and run the `import.sh` script to import configuration settings:

```bash
export REPO_PATH=/path/to/config
cd "$REPO_PATH"
./script/import.sh
```

The script performs the following actions:

- Linux: Installs Homebrew packages from LinuxBrewfile
- macOS: Guides to use `make nix-switch` for Nix-managed packages
- Installs Oh My Zsh and zsh-autosuggestions plugin
- Installs VS Code/Cursor extensions
- Copies Git configuration files (`.gitconfig`, `.gitignore`, `.gitattributes`)
- Copies DevContainer Zsh configuration (`.zshrc.devcontainer`, `.zsh/`)
- Copies Peco configuration (`.peco/`)
- Installs npm global packages
- Copies Claude Code shared configuration (`settings.json`, `commands/`, `agents/`, `hooks/`, `skills/`, `plugins/`)
- Clones GitHub repositories using `ghq` (if available)

⚠️ **Note**: macOS の Zsh/Git 設定は nix home-manager (`nix/home/`) で管理されています。`settings.local.json` 等のローカル専用ファイルは上書きされません。

#### Native Windows (winget)

WSL2 を使う場合は、WSL 内で上記の `script/import.sh` をそのまま実行できます。Windows ホスト側 (Cursor / VS Code / Claude Code on Windows など) もセットアップしたい場合は、以下の PowerShell スクリプトを使います。

```powershell
# PowerShell 7+ (推奨)
pwsh -File script/import.ps1

# Windows PowerShell 5.1 でも動作
powershell -ExecutionPolicy Bypass -File script\import.ps1

# 各ステップを個別に無効化したい場合
pwsh -File script/import.ps1 -DryRun
pwsh -File script/import.ps1 -SkipWinget -SkipNpm -SkipExtensions -SkipRepos
```

The script performs the following actions:

- `brew/Winfile.json` を `winget import` で適用 (git, gh, ghq, Node.js, Go, kubectl, helm, terraform, 1Password CLI, VS Code, Cursor, PowerShell 7, jq, GnuPG など)
- Git 設定ファイル (`.gitconfig`, `.gitignore`, `.gitattributes`) を `%USERPROFILE%` にコピー
- Claude / Codex / Cursor / Gemini / MCP の設定を `%USERPROFILE%` 配下にコピー
- VS Code が導入済みなら `extensions.txt` の拡張機能を一括インストール
- npm が導入済みなら `npm/global.json` のグローバルパッケージを導入
- `gh` + `ghq` が揃っていればユーザーリポジトリを `ghq get` で取得

⚠️ **制約事項**:

- ネイティブ Windows では Homebrew / nix-darwin / oh-my-zsh は対象外です。Linux 互換のシェル環境が必要なら WSL2 をご利用ください。
- `script/import.sh` を Git Bash / MSYS / Cygwin から実行するとエラーで停止します (PowerShell 版に誘導)。
- 1Password CLI を使ったクレデンシャル展開 (`script/credentials.sh`) は今のところ Windows 非対応です。手動で `~/.devcontainer.env` などを配置してください。

### Exporting Configuration Settings

Ensure `REPO_PATH` points to the repository and run the `export.sh` script to capture the current machine's configuration:

```bash
export REPO_PATH=/path/to/config
cd "$REPO_PATH"
./script/export.sh
```

The script performs the following actions:

- Linux: Exports Homebrew package lists to LinuxBrewfile
- macOS: Skips Brewfile export (managed by nix-darwin)
- Exports VS Code/Cursor extensions list
- Exports Git configuration files (`.gitconfig`, `.gitignore`, `.gitattributes`)
- Exports DevContainer Zsh configuration (`.zshrc.devcontainer`, `.zsh/`)
- Exports Peco configuration (`.peco/`)
- Exports npm global packages list
- Exports Claude Code shared configuration (`settings.json`, `commands/`, `agents/`, `hooks/`, `skills/`, `plugins/`)

⚠️ **Note**: Local-only files like `settings.local.json` and credentials are excluded.

### Updating Codex & Claude Tooling

#### Update All Libraries

- Run `npm run update:libs` (wrapper for `script/update-libraries.sh`) to refresh npm devDependencies together with Codex/Claude Code CLI definitions captured in `npm/global.json`.
- The script performs `npm-check-updates`, `npm install`, and re-synchronizes global CLI versions via `npm view <package> version` before running lint/tests to verify the updated toolchain.
- Packages that currently require newer Node.js releases (`semantic-release`, `@semantic-release/github`) are excluded by default. Override the exclusion list with `UPDATE_LIBS_REJECT="pkg1,pkg2" npm run update:libs` when you are ready to bump them.
- `.github/workflows/update-libraries.yml` executes the same script weekly and opens a PR whenever it produces changes, ensuring Codex/Claude Code tooling stays current without manual effort.

#### Update Claude Code Only

- Run `npm run update:claude` (wrapper for `script/update-claude-code.sh`) to update Claude Code to the latest version.
- Claude Code uses the **native installer** (npm installation is deprecated).
- The script runs `claude update` command to update to the latest version.
- Use `/update-claude-code` Claude command for interactive update within Claude Code sessions.
- Claude Code supports automatic updates - manual updates may not be necessary if auto-update is enabled.

**Installation (if not already installed):**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

#### Commit Requirements

- Commits that touch release-critical files (`package*.json`, `npm/global.json`, `.devcontainer/codex*`, `.codex/**`) **must** use a release-triggering Conventional Commit type (`feat`, `fix`, `perf`, `revert`, or `docs`). Commitlint enforces this so semantic-release can publish automatically when tooling versions change.

#### Global CLI version source of truth

- `npm/global.json` is the single source of truth for `@openai/codex` and other npm-installed global packages.
- **Note:** Claude Code is no longer managed via npm. It uses the native installer (`curl -fsSL https://claude.ai/install.sh | bash`) and updates via `claude update`.
- The DevContainer Dockerfile copies `npm/global.json` into the build context and reads the versions at build time for npm-installed packages.
- Rebuild the DevContainer image after updating CLI versions to ensure consistency across environments.

### Configuration Setup

The repository provides standardized configuration files that can be imported to set up a consistent development environment. See the usage instructions below for importing and exporting configurations.

### Environment Variables and Credentials Management

This repository uses 1Password CLI for secure, automated environment variable management. Credentials are never committed to Git.

#### Automated Setup (Recommended)

Use the automated setup scripts to generate environment files from 1Password:

```bash
# For multiple 1Password accounts
OP_ACCOUNT=my.1password.com bash script/setup-env.sh
bash script/setup-mcp.sh

# For single account
bash script/setup-env.sh
bash script/setup-mcp.sh
```

This automatically creates:

- `~/.devcontainer.env` - DevContainer environment variables
- `credentials/mcp.env` - MCP environment variables
- `.mcp.json` - MCP configuration file

All files are set with 600 permissions and excluded from Git.

#### Manual Setup (Alternative)

If 1Password CLI is not available, you can manually create the environment file:

```bash
cat <<'EOF' > ~/.devcontainer.env
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-northeast-1
EOF
chmod 600 ~/.devcontainer.env
```

If you need to customize `.mcp.json`:

```bash
# Edit .mcp.json to add additional MCP servers
chmod 600 .mcp.json
```

#### When to Run Setup Scripts

The environment variable setup is required at specific times:

**1. Initial Setup (Required - Run on Host Machine)**

Before using DevContainer for the first time, run on your **host machine**:

```bash
OP_ACCOUNT=my.1password.com bash script/setup-env.sh
```

This creates `~/.devcontainer.env` which is required for DevContainer startup via `runArgs`.

**2. DevContainer Startup (Automatic)**

When DevContainer starts, `postCreateCommand` automatically runs:

- `setup-env.sh` - Regenerates environment files inside container
- `setup-mcp.sh` - Generates `.mcp.json` from template

**3. Credential Updates (Manual)**

Re-run setup scripts when:

- API keys are rotated in 1Password
- New credentials are added to templates
- Environment variables need to be refreshed

```bash
# On host machine
OP_ACCOUNT=my.1password.com bash script/setup-env.sh

# Inside DevContainer (or rebuild container)
bash script/setup-env.sh
bash script/setup-mcp.sh
```

**4. Template Updates (Manual)**

After modifying `credentials/templates/*.env.template`, regenerate:

```bash
bash script/setup-env.sh
bash script/setup-mcp.sh
```

#### How It Works

- Environment variables are injected into DevContainer via `runArgs: ["--env-file=${localEnv:HOME}/.devcontainer.env"]`
- Templates are version-controlled; generated files are git-ignored
- Update tokens by re-running setup scripts; no repository changes required

For detailed instructions, troubleshooting, and 1Password Vault structure, see [credentials/README.md](credentials/README.md).

### Available Commands

The repository includes a Makefile with various utility commands:

#### Version Management

```bash
# Create a patch version (1.0.0 -> 1.0.1)
make version-patch

# Create a minor version (1.0.0 -> 1.1.0)
make version-minor

# Create a major version (1.0.0 -> 2.0.0)
make version-major

# Preview next version without creating tag
make version-dry-run
```

#### Credential Management

```bash
# Automated setup (recommended)
bash script/setup-env.sh    # Generate environment variables from 1Password
bash script/setup-mcp.sh    # Generate MCP configuration

# For multiple 1Password accounts
OP_ACCOUNT=my.1password.com bash script/setup-env.sh

# Legacy method
make credentials            # Fetch credentials from 1Password
make clean-credentials      # Clean up credential files
make list-credentials       # List available credential templates
```

#### Nix Environment Management (macOS)

```bash
# Apply Nix configuration
make nix-switch

# Build without applying (dry run)
make nix-build

# Update flake inputs (nixpkgs, home-manager, nix-darwin)
make nix-update

# Check flake for errors
make nix-check
```

### CI/CD and Development Workflow

This repository includes comprehensive GitHub Actions workflows and development tooling:

#### Setup Guide for New Projects

For setting up a complete CI/CD pipeline in a new repository, use the `/setup-ci` Claude command. This provides:

- Step-by-step CI/CD pipeline setup instructions
- Quality checks (lint, format, type-check, complexity analysis)
- Unit & E2E testing with 70%+ coverage requirement
- Security scanning (dependency audit, SAST, license compliance)
- Claude Code Review integration
- GitHub Secrets configuration guide
- Husky Git hooks setup
- Troubleshooting guidance

#### Test Configuration Setup

For comprehensive test setup in Next.js projects, use the `/setup-tests` Claude command. It provides 21 test types across 5 levels:

- **Minimal**: Unit, Component, Snapshot tests
- **Standard**: + Integration, E2E, API tests
- **Comprehensive**: + Regression, Smoke, Contract tests
- **Full**: + Visual, A11y, Scenario, Property-based tests
- **Enterprise**: + Performance, Load, Security, Database, Edge Functions, i18n, SSR, Mutation tests

```bash
/setup-tests                          # Standard level (default)
/setup-tests --level comprehensive    # More test types
/setup-tests --coverage-threshold 80  # Custom coverage
```

See [templates/testing/README.md](templates/testing/README.md) for detailed documentation.

#### GitHub Actions Workflows

- **CI Pipeline** (`.github/workflows/ci.yml`): Automated testing, linting, and quality checks (uses Node.js 22)
- **Claude Code Integration** (`.github/workflows/claude.yml`): AI-assisted code review and issue management
- **Docker Image Build** (`.github/workflows/docker-image.yml`): Containerized build and deployment pipeline
- **Library Auto-Update** (`.github/workflows/update-libraries.yml`): Scheduled Codex/Claude tooling refresh that raises a PR when `npm run update:libs` produces changes

#### Local GitHub Actions Testing with act

The repository includes configuration for [act](https://nektosact.com), a tool that allows you to run GitHub Actions workflows locally on your machine for testing and debugging before pushing to GitHub.

**Quick Start:**

```bash
# List all available workflows
act -l

# Run all workflows
act

# Run specific event triggers
act push
act pull_request

# Run a specific job
act -j quality

# Dry run (shows what would be executed without running)
act -n
```

**Configuration:**

The `.actrc` file provides default settings for act:

- Uses full-featured Ubuntu Docker images (`catthehacker/ubuntu:full-*`) for better GitHub Actions compatibility
- Loads environment variables from `.env.local` (git-ignored)
- Loads secrets from `~/.secrets` if available
- Enables workspace binding and container reuse for better performance
- Uses `linux/amd64` architecture for consistency

**Common Use Cases:**

```bash
# Test CI workflow before pushing
act -j quality

# Test with specific environment variables
echo "MY_VAR=value" > .env.local
act

# Use verbose output for debugging
act -v

# Run workflow without pulling latest images
act --pull=false
```

**Environment Variables:**

For workflows requiring secrets or environment variables:

1. Create `.env.local` in the repository root (already in `.gitignore`)
2. Add your variables: `GITHUB_TOKEN=your_token_here`
3. Run act normally - it will automatically load from `.env.local`

**Important Notes:**

- First run downloads large Docker images (~2.6GB), subsequent runs are faster with `--reuse`
- Some GitHub-hosted runner features may not work identically in local containers
- For sensitive workflows, ensure `.env.local` is never committed

#### Development Quality Tools

- **ESLint**: JavaScript/TypeScript linting with customizable rules
- **Prettier**: Code formatting with consistent style enforcement
- **Husky**: Git hooks for pre-commit and commit-msg validation
- **Commitlint**: Enforces conventional commit message format
- **semantic-release**: Automated version management and releases

#### DevContainer Support

The repository includes a complete DevContainer setup (`.devcontainer/`) that provides:

- Consistent development environment across different machines
- Pre-configured tools and extensions
- Automatic import of configuration settings on container startup
- Integrated Claude Code configuration with specialized agents and commands
- Bell notification system for development workflow events

**推奨**: `ghcr.io/keito4/config-base:latest`（常に最新の安定版）

**Pre-installed Plugins** (defined in `.claude/plugins/plugins.txt`):

- Official plugins: `commit-commands`, `hookify`, `plugin-dev`, `typescript-lsp`, `code-review`
- Workflow plugins: `code-refactoring`, `kubernetes-operations`, `javascript-typescript`, `backend-development`, `full-stack-orchestration`, `database-design`, `database-migrations`
- Supabase plugins: `postgres-best-practices`
- Vercel plugins: `agent-browser`
- Community plugins: `context7`

**Pre-installed Skills** (defined in `.claude/skills/skills.txt`):

- React: `facebook/react@fix`, `millionco/react-doctor`
- Vercel: `vercel-labs/agent-skills` (including composition patterns)
- Supabase: `supabase/agent-skills` (including postgres best practices)
- Discovery: `vercel-labs/skills` (find-skills), `vercel-labs/agent-browser`
- Context: `intellectronica/agent-skills` (Context7 integration)

**Recommended Usage**: For new projects, use the pre-built image without mounting host's `~/.claude` directory. This ensures the image configuration works immediately. See [docs/using-config-base-image.md](docs/using-config-base-image.md) for detailed usage instructions.

**DevContainer推奨設定**: 組織内のリポジトリで統一されたDevContainer環境を構築するための推奨設定とベストプラクティスについては、[.claude/devcontainer-recommendations.md](.claude/devcontainer-recommendations.md)を参照してください。

### Automated Releases

This repository uses semantic-release for automated version management and releases based on commit messages. Follow conventional commit format:

- `feat:` - New features (minor version bump)
- `fix:` - Bug fixes (patch version bump)
- `BREAKING CHANGE:` - Breaking changes (major version bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` - No version bump

Releases are automatically created when changes are pushed to the main branch.

#### Compatibility Notes

**Node.js Version**: The repository uses Node.js v24.14.1 in development containers and CI, which is compatible with semantic-release (v25.0.2) requirements (^22.14.0 || >= 24.10.0).

### AI-Assisted Development Workflows

This repository supports AI-assisted development through Claude Code integration:

#### Development Quality Standards

The `CLAUDE.md` file defines organization-wide development standards in Japanese:

- **Test-Driven Development (TDD)**: Red → Green → Refactor methodology with 70%+ line coverage requirement
- **Static Quality Gates**: Automated linting, formatting, security analysis, and license checking
- **Git Workflow**: Conventional commits, branch naming conventions, and pull request requirements
- **AI Prompt Design Guidelines**: Structured approach for requirements definition and implementation

#### Slack Notifications Integration

The repository includes automated Slack notifications for development workflow events:

- **Task Completion Notifications**: Claude Code automatically sends notifications to Slack when tasks are completed
- **CI/CD Pipeline Status**: Integration with GitHub Actions for build and deployment status updates
- **Error Alerts**: Critical errors and CI failures trigger immediate Slack notifications to #ci-alerts channel
- **MCP Integration**: Uses Model Context Protocol (MCP) for seamless Slack workspace integration

**Configuration Requirements:**

- Slack workspace with MCP integration enabled
- Appropriate channel permissions for bot posting
- Environment variables configured for Slack API access

## Glossary

- **act**: A tool that allows you to run GitHub Actions workflows locally on your machine for testing and debugging before pushing to GitHub.
- **Homebrew (Brew)**: A package manager for macOS and Linux. macOS では GUI アプリ (cask) と tap 依存パッケージの管理に使用。CLI ツールは Nix で管理。
- **Nix / nix-darwin**: macOS 環境の宣言的パッケージ管理。`nix/flake.nix` で CLI ツール、シェル設定、システム設定を一元管理。
- **home-manager**: Nix ベースのユーザー環境管理ツール。dotfiles やユーザーパッケージを宣言的に管理。
- **1Password**: A password manager that securely stores credentials, with CLI integration for automated credential management.
- **1Password CLI**: Command-line tool for 1Password that enables automated credential retrieval using `op inject` command.
- **op inject**: 1Password CLI command that replaces `op://Vault/Item/Field` references in templates with actual credential values.
- **Environment Variable Template**: A template file (e.g., `*.env.template`) containing `op://` references that get expanded by 1Password CLI.
- **Claude Code**: AI-powered development assistant with specialized agents for code review, architecture validation, and quality analysis.
- **MCP (Model Context Protocol)**: Integration protocol enabling Claude Code to interact with external services like Slack, n8n, and Playwright automation.
- **DevContainer**: A containerized development environment that provides consistent tooling and configurations across different machines and platforms.
- **ESLint**: A static analysis tool for identifying problematic patterns in JavaScript/TypeScript code.
- **Git**: A distributed version control system for tracking changes in source code during software development.
- **GitHub Actions**: CI/CD platform integrated with GitHub for automating workflows.
- **Husky**: Git hooks tool that enables running scripts at various Git lifecycle events.
- **npm**: The default package manager for the JavaScript runtime environment Node.js.
- **Prettier**: An opinionated code formatter that enforces consistent code style.
- **Semantic Release**: Automated version management and release process based on commit messages.
- **Visual Studio Code**: A free source-code editor made by Microsoft for Windows, Linux, and macOS.
- **Zsh**: An extended Unix shell with advanced features for interactive use and scripting.
- **envsubst**: GNU gettext utility that substitutes environment variables in shell format strings (e.g., `${VARIABLE}`).
- **Gitleaks**: Secret scanning tool that detects hardcoded secrets, API keys, and passwords in Git repositories.
- **Jest**: JavaScript testing framework with a focus on simplicity, supporting unit tests, component tests, and snapshot testing.
- **ni (@antfu/ni)**: Universal package manager wrapper that automatically detects and uses the correct package manager (npm, pnpm, yarn, bun).
- **Playwright**: End-to-end testing framework for web applications, supporting cross-browser testing with Chromium, Firefox, and WebKit.
- **pnpm**: Fast, disk space efficient package manager for Node.js with strict dependency management and built-in security features.
- **Testing Library**: Family of packages for testing UI components in a user-centric way, encouraging best practices and accessibility.

## Disclaimer

This repository is intended for personal use. While it's made public for reference and learning purposes, it may not fit your development environment or use case directly. Always review and understand the settings and scripts before use.
