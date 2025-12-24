# Config Repository

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

- `.claude/`: Claude Code configuration directory containing settings, commands, agents, and hooks. User-specific settings like `settings.local.json` are git-ignored while shared configurations are version-controlled.
- `.codex/`: Codex CLI configuration directory containing automated prompts and configuration for security analysis, refactoring, and development workflow automation
- `.devcontainer/`: Development container configuration providing containerized development environment with consistent tooling across different machines.
- `brew/`: Contains Brewfiles for different operating systems (Linux, macOS) and dependency configurations, including lock files for reproducible package installations. Supports categorized package management and dependency analysis.
- `credentials/`: Contains templates and scripts for secure credential management using 1Password CLI integration.
- `issues/`: Templates and helper notes for managing known issues and troubleshooting steps.
- `dot/`: Directory for dotfiles and configuration files that are typically placed in the home directory, including Zsh configuration with comprehensive aliases, functions, and environment setup.
- `git/`: Contains Git configuration files including gitconfig, gitignore, and modular configuration files in the `gitconfig.d/` subdirectory.
- `npm/`: Contains npm global package configuration.
- `script/`: Contains utility scripts for exporting configuration settings (`export.sh`), importing configuration settings (`import.sh`), checking for changes and making commits (`commit_changes.sh`), credential management (`credentials.sh`), Homebrew dependency management (`brew-deps.sh`), semantic versioning (`version.sh`), and automated library updates for Codex/Claude Code tooling (`update-libraries.sh`).
- `vscode/`: Contains Visual Studio Code configuration including extensions list and installation documentation.

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

1. Configure Git settings using the commands above
2. Install 1Password CLI: `brew install --cask 1password-cli`
3. Sign in to 1Password: `op signin`
4. Use the credentials script for 1Password integration: `make credentials`
5. Install packages using Homebrew: `brew bundle --file=brew/StandaloneBrewfile`

For detailed security guidelines, see [SECURITY.md](SECURITY.md).

## Claude Code Configuration Management

The `.claude/` directory contains Claude Code configuration that is partially version-controlled:

### Version-Controlled Files

- `settings.json` - Shared permissions, environment variables, and hooks
- `commands/` - Custom slash commands available to all users
- `agents/` - Specialized agent configurations
- `hooks/` - Event-driven automation scripts
- `plugins/config.json` - Custom plugin repository configuration
- `plugins/known_marketplaces.json` - List of plugin marketplaces
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
- `plugins/config.json`, `plugins/known_marketplaces.json` - プラグイン設定
- `CLAUDE.md` - 開発標準とガイドライン

**同期されない設定（ローカル専用）**

- `settings.local.json` - ユーザー固有のオーバーライド
- `.credentials.json` - 認証情報
- `plugins/installed_plugins.json` - インストール済みプラグイン
- ランタイムデータ（`debug/`, `projects/`, `todos/`など）

`export.sh`を実行すると、これらの共有設定が自動的にリポジトリにコピーされます。`import.sh`を実行すると、リポジトリから`~/.claude/`に復元されます。

### Plugin Management

Plugin configuration is managed through two layers:

1. **Marketplace Configuration** (version-controlled in `plugins/known_marketplaces.json`)
   - Defines which plugin marketplaces to use
   - Shared across all team members
   - Examples: official Anthropic plugins, community repositories

2. **Plugin Activation** (local-only in `settings.local.json`)
   - Individual choice of which plugins to enable
   - Environment-specific preferences
   - Not committed to version control

For detailed plugin management instructions, see [.claude/plugins/README.md](.claude/plugins/README.md).

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

### Checking for Changes

Run the `commit_changes.sh` script with `REPO_PATH` set to this repository to check for local modifications. If there are changes, it stages all of them and makes a commit.

### Updating Codex & Claude Tooling

- Run `npm run update:libs` (wrapper for `script/update-libraries.sh`) to refresh npm devDependencies together with Codex/Claude Code CLI definitions captured in `npm/global.json`.
- The script performs `npm-check-updates`, `npm install`, and re-synchronizes global CLI versions via `npm view <package> version` before running lint/tests to verify the updated toolchain.
- Packages that currently require newer Node.js releases (`semantic-release`, `@semantic-release/github`) are excluded by default. Override the exclusion list with `UPDATE_LIBS_REJECT="pkg1,pkg2" npm run update:libs` when you are ready to bump them.
- `.github/workflows/update-libraries.yml` executes the same script weekly and opens a PR whenever it produces changes, ensuring Codex/Claude Code tooling stays current without manual effort.
- Commits that touch release-critical files (`package*.json`, `npm/global.json`, `.devcontainer/codex*`, `.codex/**`) **must** use a release-triggering Conventional Commit type (`feat`, `fix`, `perf`, `revert`, or `docs`). Commitlint enforces this so semantic-release can publish automatically when tooling versions change.

#### Global CLI version source of truth

- `npm/global.json` is the single source of truth for both `@openai/codex` and `@anthropic-ai/claude-code` versions.
- The DevContainer Dockerfile copies this file into the build context and reads the versions at build time, guaranteeing that `npm install -g ...` pins to the same versions used by local setups.
- When bumping either CLI, update the version in `npm/global.json` (or run `npm run update:libs`) and rebuild the DevContainer image. No manual edits in `.devcontainer/Dockerfile` are required anymore.
- Rebuild the DevContainer image after updating CLI versions to ensure consistency across environments.

### Configuration Setup

The repository provides standardized configuration files that can be imported to set up a consistent development environment. See the usage instructions below for importing and exporting configurations.

### Secure MCP Credential Configuration

The Dev Container loads an environment file from your host machine to avoid committing API tokens. Create `${HOME}/.devcontainer.env` (ignored by Git) with the required secrets:

```bash
cat <<'EOF' > ~/.devcontainer.env
SUPABASE_MCP_TOKEN=your_supabase_token
VERCEL_MCP_TOKEN=your_vercel_token
GITHUB_COPILOT_MCP_TOKEN=your_github_copilot_token
OPENAI_API_KEY=your_openai_api_key
EOF
```

These variables are injected into the container via `runArgs` and referenced in `.codex/config.toml` for MCP server headers (e.g., `Authorization = "Bearer ${SUPABASE_MCP_TOKEN}"`). Update the file locally whenever tokens rotate; no repository changes are required.

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
# Fetch credentials from 1Password
make credentials

# Clean up credential files
make clean-credentials

# List available credential templates
make list-credentials
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

#### GitHub Actions Workflows

- **CI Pipeline** (`.github/workflows/ci.yml`): Automated testing, linting, and quality checks (uses Node.js 20)
- **Claude Code Integration** (`.github/workflows/claude.yml`): AI-assisted code review and issue management
- **Docker Image Build** (`.github/workflows/docker-image.yml`): Containerized build and deployment pipeline
- **Library Auto-Update** (`.github/workflows/update-libraries.yml`): Scheduled Codex/Claude tooling refresh that raises a PR when `npm run update:libs` produces changes

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

### Automated Releases

This repository uses semantic-release for automated version management and releases based on commit messages. Follow conventional commit format:

- `feat:` - New features (minor version bump)
- `fix:` - Bug fixes (patch version bump)
- `BREAKING CHANGE:` - Breaking changes (major version bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` - No version bump

Releases are automatically created when changes are pushed to the main branch.

#### Compatibility Notes

**Node.js Version Requirements**: The current semantic-release (v25.0.2) requires Node.js ^22.14.0 || >= 24.10.0, but the repository currently uses Node.js v20.x in development containers and CI. This produces warnings but continues to function. Consider upgrading Node.js versions for full compatibility.

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

- **Homebrew (Brew)**: A package manager for macOS and Linux that allows easy installation and management of software packages.
- **Brewfile**: A file format used by Homebrew to declare and install packages in a reproducible way.
- **1Password**: A password manager that securely stores credentials, with CLI integration for automated credential management.
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

## Disclaimer

This repository is intended for personal use. While it's made public for reference and learning purposes, it may not fit your development environment or use case directly. Always review and understand the settings and scripts before use.
