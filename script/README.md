# Scripts

This directory contains utility scripts for managing configuration, credentials, and development workflows.

## Quick Reference

| Script                   | Purpose                          | Used By                |
| ------------------------ | -------------------------------- | ---------------------- |
| `setup-claude.sh`        | Claude Code CLI setup            | Makefile, DevContainer |
| `credentials.sh`         | 1Password credential management  | Makefile               |
| `update-libraries.sh`    | Library updates for Codex/Claude | package.json           |
| `version.sh`             | Semantic versioning              | Makefile               |
| `check-image-version.sh` | Show DevContainer image version  | Manual                 |

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

### check-docs-sync.sh

Verifies that generated documentation is synchronized with code changes.

**Usage**: `./script/check-docs-sync.sh`

**Configuration**:

```bash
export DOC_GENERATE_CMD="npm run docs:generate"  # Documentation generation command
export DOCS_DIR="docs"                            # Documentation directory
```

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

Automated library updates for Codex/Claude Code tooling.

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

## Git & GitHub

### branch-cleanup.sh

Cleans up merged and stale git branches.

**Usage**: `./script/branch-cleanup.sh [--merged-only] [--yes]`

**Claude command**: `/branch-cleanup`

### setup-team-protection.sh

Configures GitHub branch protection rules for team development.

**Usage**:

```bash
./script/setup-team-protection.sh                    # Current repo
./script/setup-team-protection.sh owner/repo         # Specific repo
./script/setup-team-protection.sh --interactive      # Interactive mode
./script/setup-team-protection.sh --dry-run          # Preview changes
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
| `docs-common.js`     | Documentation generation utilities                         |

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
