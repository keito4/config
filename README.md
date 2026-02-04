# Config Repository

[![CI](https://github.com/keito4/config/actions/workflows/ci.yml/badge.svg)](https://github.com/keito4/config/actions/workflows/ci.yml)
[![Security](https://github.com/keito4/config/actions/workflows/security.yml/badge.svg)](https://github.com/keito4/config/actions/workflows/security.yml)
[![codecov](https://codecov.io/gh/keito4/config/branch/main/graph/badge.svg)](https://codecov.io/gh/keito4/config)

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

- `.claude/`: Claude Code configuration directory containing settings, commands, agents, and hooks. User-specific settings like `settings.local.json` are git-ignored while shared configurations are version-controlled.
- `.codex/`: Contains MCP (Model Context Protocol) server configuration (`config.toml`) for Claude Code integration with external services like AWS, GitHub, Playwright, o3, Linear, n8n, Supabase, and Vercel.
- `.devcontainer/`: Development container configuration providing containerized development environment with consistent tooling across different machines. The `templates/` subdirectory contains optional DevContainer features templates for additional language support (Python, Ruby, Go, Java, .NET).
- `.github/`: GitHub configuration including workflows for CI/CD, security scanning, and release automation. The `templates/` subdirectory contains reusable workflow templates for unified CI with coverage reporting and monorepo releases with change detection.
- `brew/`: Contains Brewfiles for different operating systems (Linux, macOS) and dependency configurations, including lock files for reproducible package installations. Supports categorized package management and dependency analysis.
- `credentials/`: Contains templates and scripts for secure credential management using 1Password CLI integration.
- `eslint/`: Contains recommended ESLint complexity rules template and documentation to prevent technical debt accumulation. See [eslint/README.md](eslint/README.md) for usage guidelines.
- `dot/`: Directory for dotfiles and configuration files that are typically placed in the home directory, including Zsh configuration with comprehensive aliases, functions, and environment setup.
- `git/`: Contains Git configuration files including gitconfig, gitignore, commitlint configuration with i18n support, and modular configuration files in the `gitconfig.d/` subdirectory. See [git/README.md](git/README.md) for details.
- `npm/`: Contains npm global package configuration.
- `script/`: Contains utility scripts for exporting configuration settings (`export.sh`), importing configuration settings (`import.sh`), credential management (`credentials.sh`), Homebrew dependency management (`brew-deps.sh`), semantic versioning (`version.sh`), documentation sync checking (`check-docs-sync.sh`), and automated library updates for Codex/Claude Code tooling (`update-libraries.sh`). See [script/README.md](script/README.md) for details.
- `vscode/`: Contains Visual Studio Code configuration including extensions list and installation documentation. The `templates/` subdirectory contains project-specific settings templates such as Tailwind CSS + CVA IntelliSense configuration. See [vscode/README.md](vscode/README.md) for details.

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
git config --global user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"
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
   git config --global user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"
   ```

5. **Install packages using Homebrew**
   ```bash
   brew bundle --file=brew/StandaloneBrewfile
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
├── OPENAI_API_KEY (Login)
│   └── value: sk-proj-...
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
- `plugins/config.json` - Custom plugin repository configuration
- `plugins/known_marketplaces.json.template` - Template for plugin marketplace configuration (generates `known_marketplaces.json` locally)
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
- `plugins/config.json`, `plugins/known_marketplaces.json.template` - プラグイン設定（テンプレート）
- `CLAUDE.md` - 開発標準とガイドライン

**同期されない設定（ローカル専用）**

- `settings.local.json` - ユーザー固有のオーバーライド
- `.credentials.json` - 認証情報
- `plugins/installed_plugins.json` - インストール済みプラグイン
- ランタイムデータ（`debug/`, `projects/`, `todos/`など）

`export.sh`を実行すると、これらの共有設定が自動的にリポジトリにコピーされます。`import.sh`を実行すると、リポジトリから`~/.claude/`に復元されます。

### Plugin Management

Plugin configuration is managed through two layers:

1. **Marketplace Configuration** (template in `plugins/known_marketplaces.json.template`, generated as `known_marketplaces.json` locally)
   - Defines which plugin marketplaces to use
   - Template is shared across all team members
   - Generated file is local-only (not version-controlled)
   - Examples: official Anthropic plugins, community repositories

2. **Plugin Activation** (local-only in `settings.local.json`)
   - Individual choice of which plugins to enable
   - Environment-specific preferences
   - Not committed to version control

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

- Installs Homebrew packages listed in OS-specific Brewfiles
- Installs Oh My Zsh and zsh-autosuggestions plugin
- Installs VS Code/Cursor extensions
- Copies Git configuration files (`.gitconfig`, `.gitignore`, `.gitattributes`)
- Copies Zsh configuration files (`.zprofile`, `.zshrc`, `.zshrc.devcontainer`, `.zsh/`)
- Copies Peco configuration (`.peco/`)
- Installs npm global packages
- Copies Claude Code shared configuration (`settings.json`, `commands/`, `agents/`, `hooks/`, `plugins/`)
- Clones GitHub repositories using `ghq` (if available)

⚠️ **Note**: Local-only files like `settings.local.json` are not overwritten.

### Exporting Configuration Settings

Ensure `REPO_PATH` points to the repository and run the `export.sh` script to capture the current machine's configuration:

```bash
export REPO_PATH=/path/to/config
cd "$REPO_PATH"
./script/export.sh
```

The script performs the following actions:

- Exports Homebrew package lists to OS-specific Brewfiles
- Exports VS Code/Cursor extensions list
- Exports Git configuration files (`.gitconfig`, `.gitignore`, `.gitattributes`)
- Exports Zsh configuration files (`.zprofile`, `.zshrc`, `.zshrc.devcontainer`, `.zsh/`)
- Exports Peco configuration (`.peco/`)
- Exports npm global packages list
- Exports Claude Code shared configuration (`settings.json`, `commands/`, `agents/`, `hooks/`, `plugins/`)

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
OPENAI_API_KEY=your_openai_api_key
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-northeast-1
EOF
chmod 600 ~/.devcontainer.env
```

The `.mcp.json` file is already configured with Linear MCP server. If you need to customize it:

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
- MCP configuration references environment variables (e.g., `"OPENAI_API_KEY": "${OPENAI_API_KEY}"`)
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

#### Homebrew Package Management

```bash
# List packages without dependencies (standalone packages)
make brew-leaves

# List packages organized by category
make brew-categorized

# Generate Brewfiles for standalone packages
make brew-generate

# Show dependencies of a specific package
make brew-deps pkg=<package>

# Show packages that depend on a specific package
make brew-uses pkg=<package>
```

### CI/CD and Development Workflow

This repository includes comprehensive GitHub Actions workflows and development tooling:

#### Setup Guide for New Projects

For setting up a complete CI/CD pipeline in a new repository following Elu-co-jp organization standards, use the `setup-recommended-ci` command available in `.codex/prompts/setup-recommended-ci.md`. This comprehensive guide provides:

- Step-by-step CI/CD pipeline setup instructions
- Quality checks (lint, format, type-check, complexity analysis)
- Unit & E2E testing with 70%+ coverage requirement
- Security scanning (dependency audit, SAST, license compliance)
- Claude Code Review integration
- GitHub Secrets configuration guide
- Husky Git hooks setup
- Troubleshooting guidance

**Quick Start:**

```
@claude use setup-recommended-ci to set up CI/CD pipeline
```

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

**Latest Version**: `ghcr.io/keito4/config-base:1.62.1`

**Pre-installed Plugins** (v1.62.1):

- Official plugins: `commit-commands`, `hookify`, `plugin-dev`, `typescript-lsp`, `code-review`
- Workflow plugins: `code-refactoring`, `kubernetes-operations`, `javascript-typescript`, `backend-development`, `full-stack-orchestration`, `database-design`, `database-migrations`

**Recommended Usage**: For new projects, use the pre-built image without mounting host's `~/.claude` directory. This ensures the image configuration works immediately. See [docs/using-config-base-image.md](docs/using-config-base-image.md) for detailed usage instructions.

**DevContainer推奨設定**: Elu-co-jp配下のリポジトリで統一されたDevContainer環境を構築するための推奨設定とベストプラクティスについては、[.codex/devcontainer-recommendations.md](.codex/devcontainer-recommendations.md)を参照してください。

### Automated Releases

This repository uses semantic-release for automated version management and releases based on commit messages. Follow conventional commit format:

- `feat:` - New features (minor version bump)
- `fix:` - Bug fixes (patch version bump)
- `BREAKING CHANGE:` - Breaking changes (major version bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` - No version bump

Releases are automatically created when changes are pushed to the main branch.

#### Compatibility Notes

**Node.js Version**: The repository uses Node.js v22.14.0 in development containers and CI, which is compatible with semantic-release (v25.0.2) requirements (^22.14.0 || >= 24.10.0).

### AI-Assisted Development Workflows

This repository supports AI-assisted development through Claude Code integration:

#### Development Quality Standards

The `CLAUDE.md` file defines organization-wide development standards in Japanese:

- **Test-Driven Development (TDD)**: Red → Green → Refactor methodology with 70%+ line coverage requirement
- **Static Quality Gates**: Automated linting, formatting, security analysis, and license checking
- **Git Workflow**: Conventional commits, branch naming conventions, and pull request requirements
- **AI Prompt Design Guidelines**: Structured approach for requirements definition and implementation

#### Technical Assistance with o3 MCP

When encountering technical challenges, unresolved errors, or implementation roadblocks during development, consult o3 MCP (integrated via Model Context Protocol) for advanced problem-solving assistance. o3 MCP specializes in:

- Complex debugging scenarios and error resolution
- Architecture design decisions and pattern recommendations
- Performance optimization strategies
- Advanced algorithm implementation
- Real-time web search for latest documentation and solutions
- Root cause analysis for persistent issues

**Usage Guidelines:**

1. **When to consult o3 MCP**:
   - Stuck on complex implementation details
   - Encountering persistent errors or bugs
   - Need architectural guidance or design review
   - Performance bottlenecks requiring optimization
   - Complex algorithm design and implementation

2. **Integration with Claude Code**:
   - o3 MCP is accessible through Claude Code's MCP integration
   - Formulate questions in English for optimal results
   - Include relevant context, error messages, and code snippets
   - Specify what solutions you've already attempted

3. **Example consultation**:
   ```
   @claude Use o3 MCP to help debug this async/await deadlock issue
   @claude Consult o3 MCP for optimizing this database query performance
   @claude Ask o3 MCP about best practices for implementing this design pattern
   ```

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
- **Homebrew (Brew)**: A package manager for macOS and Linux that allows easy installation and management of software packages.
- **Brewfile**: A file format used by Homebrew to declare and install packages in a reproducible way.
- **1Password**: A password manager that securely stores credentials, with CLI integration for automated credential management.
- **1Password CLI**: Command-line tool for 1Password that enables automated credential retrieval using `op inject` command.
- **op inject**: 1Password CLI command that replaces `op://Vault/Item/Field` references in templates with actual credential values.
- **Environment Variable Template**: A template file (e.g., `*.env.template`) containing `op://` references that get expanded by 1Password CLI.
- **Claude Code**: AI-powered development assistant with specialized agents for code review, architecture validation, and quality analysis.
- **MCP (Model Context Protocol)**: Integration protocol enabling Claude Code to interact with external services like Slack, o3 search, and Playwright automation.
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

## Disclaimer

This repository is intended for personal use. While it's made public for reference and learning purposes, it may not fit your development environment or use case directly. Always review and understand the settings and scripts before use.
