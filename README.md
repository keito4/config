# Config Repository

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

- `.claude/`: Comprehensive Claude Code configuration directory with:
  - **13 specialized AI agents**: Architecture validation (DDD, Clean Architecture), accessibility & design validation, concurrency safety analysis, documentation consistency checking, dependency auditing, performance analysis, testability & coverage analysis, and issue resolution workflows
  - **14 automated commands**: Code coverage checking, CI/CD troubleshooting, project initialization, pull request creation, quality checks, security reviews, test execution, dependency updates, and n8n MCP integration setup
  - **Development quality standards**: Japanese-language guidelines for TDD methodology, static quality gates, Git workflow conventions, and AI-assisted development practices
- `.devcontainer/`: Development container configuration providing containerized development environment with consistent tooling across different machines.
- `brew/`: Contains Brewfiles for different operating systems (Linux, macOS) and dependency configurations, including lock files for reproducible package installations. Supports categorized package management and dependency analysis.
- `credentials/`: Contains templates and scripts for secure credential management using 1Password CLI integration.
- `dot/`: Directory for dotfiles and configuration files that are typically placed in the home directory, including Zsh configuration with comprehensive aliases, functions, and environment setup.
- `git/`: Contains Git configuration files including gitconfig, gitignore, and modular configuration files in the `gitconfig.d/` subdirectory.
- `npm/`: Contains npm global package configuration.
- `script/`: Contains utility scripts for exporting configuration settings (`export.sh`), importing configuration settings (`import.sh`), checking for changes and making commits (`commit_changes.sh`), credential management (`credentials.sh`), Homebrew dependency management (`brew-deps.sh`), and version management (`version.sh`).
- `supabase/`: Contains Supabase-related configuration and documentation.
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

## Usage

Before using these configuration settings, you should review them and adjust as necessary for your specific environment and preferences. For credentials, we use environment variables managed by 1Password.

### Importing Configuration Settings

Set the `REPO_PATH` environment variable to this repository's root and run the `import.sh` script to import configuration settings. Depending on the operating system, it performs the following actions:

- Installs packages listed in a Brewfile.
- Installs VS Code extensions listed in a specific file.
- Injects environment variables from a specific file managed by 1Password.
- Copies configuration files to the home directory.

### Exporting Configuration Settings

Ensure `REPO_PATH` points to the repository and run the `export.sh` script to capture the current machine's configuration. Depending on the operating system, it performs the following actions:

- Writes the list of installed VS Code extensions to a file.
- Dumps the list of installed Brew packages to a Brewfile.
- Copies various configuration files from the home directory to the repository.

### Checking for Changes

Run the `commit_changes.sh` script with `REPO_PATH` set to this repository to check for local modifications. If there are changes, it stages all of them and makes a commit.

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

- **CI Pipeline** (`.github/workflows/ci.yml`): Automated testing, linting, and quality checks
- **Claude Code Integration** (`.github/workflows/claude.yml`): AI-assisted code review and issue management
- **Docker Image Build** (`.github/workflows/docker-image.yml`): Containerized build and deployment pipeline

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

### AI-Assisted Development Workflows

This repository includes comprehensive Claude Code configuration for AI-assisted development:

#### Specialized AI Agents

The `.claude/agents/` directory provides 13 specialized agents:

- **Architecture & Code Quality**
  - `ddd-architecture-validator.md`: Validates Domain-Driven Design, Clean Architecture, and Hexagonal Architecture principles
  - `performance-analyzer.md`: Analyzes performance implications of code changes, particularly C#/.NET applications
  - `concurrency-safety-analyzer.md`: Reviews async/await patterns and thread safety in C# code
  - `testability-coverage-analyzer.md`: Evaluates testability and test coverage of new or modified code

- **Documentation & Consistency**
  - `docs-consistency-checker.md`: Ensures documentation consistency across README, ADR, XML comments, and OpenAPI specs
  - `accessibility-design-validator.md`: Validates accessibility compliance and design consistency in frontend code

- **Dependencies & Security**
  - `nuget-dependency-auditor.md`: Audits NuGet dependencies for licensing, maintenance, and architectural alignment
  - `issue-resolver-security.md`: Automated security analysis and vulnerability resolution
  - `issue-resolver-dependencies.md`: Comprehensive dependency management and conflict resolution

- **Issue Resolution Workflow**
  - `issue-resolver-orchestrator.md`: Coordinated multi-agent issue resolution workflow
  - `issue-resolver-code-quality.md`: Automated code quality analysis and improvement
  - `issue-resolver-documentation.md`: Documentation generation and maintenance
  - `issue-resolver-test-coverage.md`: Test coverage analysis and improvement suggestions

#### Automated Commands

The `.claude/commands/` directory provides 14 pre-configured commands:

- **Quality & Testing**: `check-coverage.md`, `quality-check.md`, `test-all.md`
- **Project Management**: `init-project.md`, `issue-auto-resolve.md`, `issue-create.md`, `issue-review.md`
- **Pull Request Workflow**: `pr-create.md`, `pr.md`, `review-feedback-processor.md`
- **CI/CD & Maintenance**: `fix-ci.md`, `security-review.md`, `update-deps.md`
- **Integration Setup**: `n8n-mcp-setup.md`

#### Development Quality Standards

The `.claude/CLAUDE.md` file defines organization-wide development standards in Japanese:

- **Test-Driven Development (TDD)**: Red → Green → Refactor methodology with 70%+ line coverage requirement
- **Static Quality Gates**: Automated linting, formatting, security analysis, and license checking
- **Git Workflow**: Conventional commits, branch naming conventions, and pull request requirements
- **AI Prompt Design Guidelines**: Structured approach for requirements definition and implementation

### Gemini CLI Integration

This repository includes support for Google's Gemini AI through the Gemini CLI tool, providing an alternative AI assistant for development tasks.

#### Setup

1. **Install Gemini CLI**:

   ```bash
   # Run the setup script
   ./script/gemini-setup.sh

   # Or install manually
   npm install -g @google/generative-ai-cli
   # or
   pip install google-generativeai-cli
   ```

2. **Configure API Key**:
   - Obtain your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Set the environment variable: `export GEMINI_API_KEY="your-api-key"`
   - Or use 1Password integration with the provided template

3. **Configuration**:
   - Copy `.geminirc.example` to `.geminirc` and customize settings
   - Configure model preferences, temperature, and safety settings

#### Features

- **Code Generation**: Generate code snippets and implementations
- **Code Review**: AI-powered code review and suggestions
- **Documentation**: Automatic documentation generation
- **Debugging**: Error analysis and debugging assistance
- **Multi-Model Support**: Access to Gemini Pro, Gemini Ultra, and other models

#### Usage Examples

```bash
# Generate code
gemini generate "Create a REST API endpoint"

# Review code
gemini review src/main.js

# Explain code
gemini explain complex-function.py

# Debug errors
gemini debug "Error message here"
```

For detailed configuration and usage instructions, see the [Gemini CLI section in CLAUDE.md](./CLAUDE.md#gemini-cli-integration).

## Glossary

- **Homebrew (Brew)**: A package manager for macOS and Linux that allows easy installation and management of software packages.
- **Brewfile**: A file format used by Homebrew to declare and install packages in a reproducible way.
- **1Password**: A password manager that securely stores credentials, with CLI integration for automated credential management.
- **Claude Code**: AI-powered development assistant with specialized agents for code review, architecture validation, and quality analysis.
- **DevContainer**: A containerized development environment that provides consistent tooling and configurations across different machines and platforms.
- **ESLint**: A static analysis tool for identifying problematic patterns in JavaScript/TypeScript code.
- **Git**: A distributed version control system for tracking changes in source code during software development.
- **GitHub Actions**: CI/CD platform integrated with GitHub for automating workflows.
- **Husky**: Git hooks tool that enables running scripts at various Git lifecycle events.
- **npm**: The default package manager for the JavaScript runtime environment Node.js.
- **Prettier**: An opinionated code formatter that enforces consistent code style.
- **Semantic Release**: Automated version management and release process based on commit messages.
- **Supabase**: An open-source Firebase alternative providing backend-as-a-service features.
- **Visual Studio Code**: A free source-code editor made by Microsoft for Windows, Linux, and macOS.
- **Zsh**: An extended Unix shell with advanced features for interactive use and scripting.

## Disclaimer

This repository is intended for personal use. While it's made public for reference and learning purposes, it may not fit your development environment or use case directly. Always review and understand the settings and scripts before use.
