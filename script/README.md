# Scripts

This directory contains utility scripts for managing configuration, credentials, and development workflows.

## Quick Reference

| Script                      | Purpose                                                  | Used By                |
| --------------------------- | -------------------------------------------------------- | ---------------------- |
| `setup-claude.sh`           | Claude Code CLI setup                                    | Makefile, DevContainer |
| `credentials.sh`            | 1Password credential management                          | Makefile               |
| `update-libraries.sh`       | Refresh `npm/global.json` (Dependabot owns package.json) | package.json           |
| `version.sh`                | Semantic versioning                                      | Makefile               |
| `check-image-version.sh`    | Show DevContainer image version                          | Manual                 |
| `.shellcheck-exclude`       | ShellCheck 除外パターン定義                              | npm run shellcheck     |
| `setup-scheduled-agents.sh` | Claude Code スケジュール済みエージェント セットアップ    | Manual                 |
| `update-agents-md.sh`       | AGENTS.md 自動生成セクション更新                         | repo-maintenance       |

## Configuration Management

### export.sh

Exports configuration settings (Zsh dotfiles, etc.) to the home directory.

**Usage**: `./script/export.sh`

### import.sh

Imports configuration settings from the home directory back to the repository.

**Usage**: `./script/import.sh`

## Credential Management

### credentials.sh

Secure credential management using 1Password CLI integration.

**Usage**:

```bash
# Fetch all credentials from 1Password
./script/credentials.sh fetch

# Clean up generated credential files
./script/credentials.sh clean

# List available credential templates
./script/credentials.sh list
```

**Makefile targets**: `make credentials`, `make clean-credentials`, `make list-credentials`

### codespaces-secrets.sh

Manage GitHub Codespaces secrets across multiple repositories.

**Usage**:

```bash
./script/codespaces-secrets.sh list          # List all secrets
./script/codespaces-secrets.sh repos         # List configured repos
./script/codespaces-secrets.sh repos add owner/repo  # Add repo
./script/codespaces-secrets.sh diff          # Show sync status
./script/codespaces-secrets.sh sync          # Sync all secrets
./script/codespaces-secrets.sh init          # Initialize config
```

**Claude command**: `/codespaces-secrets`

### setup-env.sh

Sets up environment variables for DevContainer from credential files.

**Usage**: `./script/setup-env.sh`

### setup-mcp.sh

Sets up MCP (Model Context Protocol) configuration for Claude Code.

**Usage**: `./script/setup-mcp.sh`

## Claude Code Development

### setup-claude.sh

Initializes Claude Code CLI configuration, syncs settings, and installs plugins.

**Usage**: `./script/setup-claude.sh`

**Makefile target**: `make claude-setup`

### setup-claude-build.sh

Build-time setup for Claude Code in DevContainer images.

**Used by**: DevContainer Dockerfile

### install-claude-plugins.sh

Installs Claude Code plugins from the configured plugin list.

**Used by**: DevContainer build process

### install-skills.sh

Installs Claude Code skills from the configured skills list.

**Used by**: DevContainer postStartCommand

### restore-cli-auth.sh

Restores CLI authentication state (Claude, GitHub, etc.) from environment variables.

**Used by**: DevContainer postStartCommand

### update-claude-code.sh

Updates Claude Code CLI to the latest version.

**Usage**: `npm run update:claude` or `./script/update-claude-code.sh`

**Claude command**: `/update-claude-code`

## Quality & CI Scripts

### check-file-length.sh

Checks staged TS/JS files for excessive line counts.

**Usage**: `./script/check-file-length.sh`

**Behavior**:

| Line Count | Behavior                         |
| ---------- | -------------------------------- |
| ~349       | Pass (no output)                 |
| 350-499    | Warning displayed, commit passes |
| 500+       | Error, commit blocked            |

**Configuration**: Create `.filelengthignore` (same syntax as `.gitignore`) to exclude files.

**Template**: `.filelengthignore.template`

### .shellcheck-exclude

ShellCheck の除外対象ファイル一覧を管理する設定ファイル。

**場所**: `script/.shellcheck-exclude`

**用途**: `npm run shellcheck` 実行時に `grep -vFf` で参照され、ShellCheck の対象外とするスクリプトパターンを定義する。

**フォーマット**: 1行1パターン（ファイル名またはパス）

**除外対象の追加**: `.shellcheck-exclude` に1行追加するだけで完結。`package.json` の変更不要。

### pre-pr-checklist.sh

Runs pre-PR quality checklist before creating pull requests.

**Claude command**: `/pre-pr-checklist`

### security-credential-scan.sh

Scans codebase for accidentally committed credentials and secrets.

**Usage**: `./script/security-credential-scan.sh [--strict]`

**Claude command**: `/security-credential-scan`

### code-complexity-check.sh

Analyzes code complexity metrics (cyclomatic complexity, nesting depth, etc.).

**Usage**: `./script/code-complexity-check.sh [--threshold N] [--strict]`

**Claude command**: `/code-complexity-check`

### test-coverage-trend.sh

Tracks and reports test coverage trends over time.

**Usage**: `./script/test-coverage-trend.sh [--record]`

**Claude command**: `/test-coverage-trend`

### changelog-generator.sh

Generates changelog from conventional commits.

**Usage**: `./script/changelog-generator.sh --since <tag>`

**Claude command**: `/changelog-generator`

## Infrastructure & DevContainer

### version.sh

Semantic versioning helper for DevContainer releases.

**Usage**:

```bash
./script/version.sh --type patch  # Create patch version
./script/version.sh --type minor  # Create minor version
./script/version.sh --type major  # Create major version
./script/version.sh --dry-run     # Preview next version
```

**Makefile targets**: `make version-patch`, `make version-minor`, `make version-major`

### update-libraries.sh

Refreshes `npm/global.json` to the latest published versions via `npm view`. npm devDependencies (`package.json`) are managed by Dependabot — see [ADR 0006](../docs/adr/0006-consolidate-version-updates.md). Entries with `overridden: true` are pinned and skipped.

**Usage**: `npm run update:libs`

### brew-deps.sh

Homebrew dependency management and analysis.

**Usage**:

```bash
./script/brew-deps.sh leaves       # List packages without dependencies
./script/brew-deps.sh categorized  # List packages by category
./script/brew-deps.sh generate     # Generate standalone Brewfiles
./script/brew-deps.sh deps <pkg>   # Show dependencies of a package
./script/brew-deps.sh uses <pkg>   # Show packages depending on a package
```

**Makefile targets**: `make brew-leaves`, `make brew-categorized`, `make brew-generate`, etc.

### verify-container-setup.sh

Verifies that DevContainer setup completed successfully.

**Used by**: DevContainer validation

### fix-container-plugins.sh

Fixes container plugin permission and path issues.

**Used by**: DevContainer troubleshooting

### container-health.sh

Comprehensive DevContainer health check.

**Usage**: `./script/container-health.sh [--json]`

**Claude command**: `/container-health`

### check-image-version.sh

Displays the config-base DevContainer image version.

**Usage**:

```bash
./script/check-image-version.sh        # Show version
./script/check-image-version.sh -v     # Show version with additional info
```

**Note**: Version tracking was added in v1.64.0. Older images will show "unknown".

### install-npm-globals.sh

Installs global npm packages defined in `npm/global.json`.
Uses npm's legacy peer dependency resolver for global CLI packages to match DevContainer builds.

**Used by**: DevContainer postCreateCommand

### create-codespace.sh

Creates a GitHub Codespace with configurable options.

**Usage**:

```bash
./script/create-codespace.sh                      # Default settings
./script/create-codespace.sh -b feature/branch    # Specific branch
./script/create-codespace.sh -m premiumLinux      # Larger machine
./script/create-codespace.sh -n "My Environment"  # Custom display name
./script/create-codespace.sh --dry-run            # Preview command
./script/create-codespace.sh -l                   # List machine sizes
```

**Options**:

| Option               | Description                 | Default                                    |
| -------------------- | --------------------------- | ------------------------------------------ |
| `-b, --branch`       | Branch name                 | Current branch                             |
| `-m, --machine`      | Machine size                | standardLinux32gb                          |
| `-r, --repo`         | Repository (owner/repo)     | Current repo                               |
| `-t, --idle-timeout` | Idle timeout                | 30m                                        |
| `-n, --name`         | Display name (max 48 chars) | -                                          |
| `-c, --devcontainer` | devcontainer.json path      | .devcontainer/codespaces/devcontainer.json |

**Machine sizes**: `basicLinux32gb`, `standardLinux32gb`, `premiumLinux`, `largePremiumLinux`

### setup-lsp.sh

Sets up Language Server Protocol servers for various languages.

**Usage**: `./script/setup-lsp.sh`

### setup-scheduled-agents.sh

Sets up Claude Code scheduled remote agents (9 agents) for automated repository maintenance.

**Usage**: `./script/setup-scheduled-agents.sh`

Registers the following scheduled agents:

| #   | Agent Name               | Schedule           | Purpose                                |
| --- | ------------------------ | ------------------ | -------------------------------------- |
| 1   | 依存関係健全性レビュー   | 毎週月曜 10:00 JST | npm audit / outdated チェック          |
| 2   | config-base同期チェック  | 毎週水曜 10:00 JST | ベースイメージのダイジスト比較・更新PR |
| 3   | コード複雑度監視         | 毎週金曜 10:00 JST | 循環的複雑度の悪化検出                 |
| 4   | テンプレート乖離チェック | 毎月1日 10:00 JST  | templates/ と実ファイルの差分確認      |
| 5   | ドキュメント鮮度チェック | 毎月15日 10:00 JST | README / CLAUDE.md の陳腐化検出        |
| 6   | CI失敗分析               | 毎日 10:00 JST     | 過去24時間のCI失敗を根本原因ごとに分類 |
| 7   | 未テストパス検出         | 毎週木曜 10:00 JST | 変更ファイルのカバレッジ不足を検出     |
| 8   | 新規Issueトリアージ      | 毎日 11:00 JST     | ラベルなしIssueに自動でラベル付与      |
| 9   | 週次リリースノート       | 毎週月曜 11:00 JST | 先週マージPRからリリースノートを生成   |

**Note**: 冪等性あり（登録済みのスケジュールはスキップ）。管理画面: https://claude.ai/code/scheduled

### update-agents-md.sh

Regenerates the auto-generated section of `AGENTS.md` from the current repository state.

**Usage**:

```bash
./script/update-agents-md.sh          # Update AGENTS.md
./script/update-agents-md.sh --check  # Check for diff only (exit 1 if diff exists)
```

**Used by**: `/repo-maintenance` command

## Git & GitHub

### branch-cleanup.sh

Cleans up merged and stale git branches.

**Usage**: `./script/branch-cleanup.sh [--merged-only] [--yes]`

**Claude command**: `/branch-cleanup`

### setup-team-protection.sh

Configures GitHub branch protection rules for team development.

**Auto-detection**: When run without `--branches`, the script automatically includes existing `pre-production` and `production` branches alongside `main`. Passing `--branches` explicitly disables this auto-detection.

**Branch-type defaults** (when `--uniform` is NOT set):

| Branch                      | enforce_admins | required_reviews | code_owner_reviews |
| --------------------------- | -------------- | ---------------- | ------------------ |
| main                        | false          | 0                | false              |
| pre-production / production | false          | 1                | true               |

**Usage**:

```bash
./script/setup-team-protection.sh                         # Current repo (auto-detects env branches)
./script/setup-team-protection.sh owner/repo              # Specific repo
./script/setup-team-protection.sh --interactive           # Interactive mode with confirmations
./script/setup-team-protection.sh --dry-run               # Preview changes without applying
./script/setup-team-protection.sh --reviewers 2           # Require 2 approving reviewers
./script/setup-team-protection.sh --enforce-admins        # Apply rules to administrators too
./script/setup-team-protection.sh --branches main,pre-production,production --create-branches
./script/setup-team-protection.sh --protection-level strict  # 2 reviewers, linear history, signed commits
./script/setup-team-protection.sh --merge-method squash   # squash | merge | rebase | all | none
./script/setup-team-protection.sh --uniform               # Identical settings for all branches
./script/setup-team-protection.sh --skip-status-checks    # Skip Quality Gate required check
```

**Claude command**: `/setup-team-protection`

### dependency-health-check.sh

Analyzes project dependencies for security vulnerabilities and updates.

**Usage**: `./script/dependency-health-check.sh [--strict]`

**Claude command**: `/dependency-health-check`

## macOS Specific

### aerospace-fix-layout

Fixes AeroSpace window manager layout issues on macOS.

**Usage**: Add as alias in `.zshrc`:

```bash
alias aerospace-fix='~/path/to/config/script/aerospace-fix-layout'
```

## Library Functions (lib/)

Shared library functions used by multiple scripts:

| File                 | Purpose                                                    |
| -------------------- | ---------------------------------------------------------- |
| `output.sh`          | Colored output utilities (print_info, print_success, etc.) |
| `config.sh`          | Configuration loading utilities                            |
| `platform.sh`        | Platform detection (macOS, Linux, etc.)                    |
| `devcontainer.sh`    | DevContainer-specific utilities                            |
| `claude_plugins.sh`  | Claude plugin management utilities                         |
| `brew_categories.py` | Homebrew package categorization                            |

## Credential Providers (credentials/providers/)

| Provider  | File    | Description                            |
| --------- | ------- | -------------------------------------- |
| 1Password | `op.sh` | Uses `op` CLI for credential injection |

## ShellCheck Coverage

The following scripts are excluded from ShellCheck due to Zsh-specific features:

- `import.sh`, `export.sh` (Zsh-only syntax)
- `credentials.sh` (dynamic credential providers)
- `brew-deps.sh` (dynamic Homebrew metadata)
- `codespaces-secrets.sh` (complex GitHub API interactions)

## See Also

- [Main README](../README.md)
- [Credentials Documentation](../credentials/README.md)
- [DevContainer Documentation](../.devcontainer/README.md)
- [Claude Commands](./.claude/commands/README.md)
