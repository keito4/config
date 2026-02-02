# Development Container Configuration

This directory contains a comprehensive development container setup that provides a consistent development environment across different machines and platforms.

## Overview

The DevContainer configuration includes:

- **Pre-configured development tools**: Git, Node.js, npm, and essential development utilities
- **Automatic configuration import**: Shell settings, VS Code extensions, and dotfiles
- **Claude Code integration**: AI-assisted development with specialized agents and commands
- **Security tools**: 1Password CLI integration for secure credential management
- **Build and deployment tools**: Docker, semantic-release, and CI/CD utilities

## Files

- `devcontainer.json`: Main DevContainer configuration
- `Dockerfile`: Custom container image with development tools
- `claude-settings.json`: Claude Code configuration for AI-assisted development
- `VERSIONING.md`: Semantic versioning guidelines for container releases
- `templates/`: Optional DevContainer features templates for additional language support (Python, Ruby, Go, Java, .NET). See [templates/README.md](templates/README.md) for usage instructions.

## Quick Start

### Using with VS Code

1. Install the "Dev Containers" extension in VS Code
2. Open the repository in VS Code
3. When prompted, click "Reopen in Container" or use Command Palette: "Dev Containers: Reopen in Container"
4. The container will build and configure automatically

### Using with GitHub Codespaces

1. Click "Code" → "Codespaces" → "Create codespace on main" in the GitHub repository
2. The environment will be automatically configured with all tools and settings

## Features

### Automatic Configuration Import

On container startup, the following configurations are automatically applied:

- **Shell configuration** (`.zshrc`, aliases, functions)
- **Git configuration** (user settings, signing keys, aliases)
- **Commitlint configuration** (`git/commitlint.config.js` with Japanese language support)
- **Husky Git hooks** (pre-commit, commit-msg, pre-push)
- **VS Code extensions** (from `vscode/extensions.txt`)
- **Homebrew packages** (development dependencies)
- **Credential templates** (1Password integration)

### Development Tools Included

- **Languages**: Node.js 22.14.0, npm, various language runtimes
- **Version Control**: Git with advanced configuration and hooks
- **Container Tools**: Docker, docker-compose
- **Cloud Tools**: AWS CLI, Terraform, kubectl
- **Security**: 1Password CLI, credential management tools
- **Quality Tools**: ESLint, Prettier, Husky, commitlint

### Known Issues

No known issues at this time. The container uses Node.js v22.14.0, which is compatible with all dependencies including `semantic-release` (v25.0.2).

### Claude Code Integration

The container includes comprehensive AI-assisted development capabilities:

- **17 Specialized Agents**: Architecture validation, performance analysis, security review, accessibility validation, concurrency safety analysis, Playwright test automation, and more
- **22 Automated Commands**: Repository maintenance, Git workflows, code analysis, quality checks, DevContainer management, dependency health, security scanning, and CI/CD setup
- **Quality Standards**: Japanese-language development guidelines with TDD methodology and static quality gates

## Container Versioning

This DevContainer image is automatically built and versioned using semantic-release:

- **Patch versions**: Bug fixes and minor improvements (1.0.0 → 1.0.1)
- **Minor versions**: New features and enhancements (1.0.0 → 1.1.0)
- **Major versions**: Breaking changes (1.0.0 → 2.0.0)

**Latest Version**: `v1.54.0`

Images are published to GitHub Container Registry: `ghcr.io/keito4/config-base`

### Embedded Setup Script

The image includes `/usr/local/bin/setup-claude.sh` which automatically:

- Copies Claude Code configuration from the image to `~/.claude/`
- Installs project-specific plugins from `.claude/plugins/plugins.txt`
- Applies hookify patches for Git hooks integration

**Note**: This script is only necessary when mounting host's `~/.claude` directory. For DevContainer-only usage, the image works standalone without any setup.

## Customization

### For Other Projects

#### Option 1: DevContainer-Only (Recommended)

Use the pre-built image without mounting host's `~/.claude` directory:

```json
{
  "name": "My Project",
  "image": "ghcr.io/keito4/config-base:1.54.0",
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  }
}
```

**Benefits**:

- Image configuration works immediately without setup
- No conflicts with host configuration
- Consistent environment across all team members

See [docs/devcontainer.json.example](../docs/devcontainer.json.example) for complete example.

#### Option 2: With Host Persistence

Mount host's `~/.claude` to persist custom plugin installations:

```json
{
  "name": "My Project",
  "image": "ghcr.io/keito4/config-base:1.54.0",
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  },
  "initializeCommand": "mkdir -p ~/.claude",
  "mounts": ["source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind"],
  "postCreateCommand": "/usr/local/bin/setup-claude.sh"
}
```

**Note**: This overwrites image configuration with host settings. Use only when you need to persist custom plugins.

#### Option 3: Custom Setup

To fully customize:

1. **Copy the entire `.devcontainer` directory** to your project root
2. **Modify `devcontainer.json`** to add project-specific requirements
3. **Update `claude-settings.json`** for project-specific AI assistance settings

### Environment Variables

The container supports various environment variables for customization:

- `REPO_PATH`: Path to the configuration repository (default: `/workspaces/config`)
- Credential-related variables (managed via 1Password templates)

## Troubleshooting

### Container Build Issues

If the container fails to build:

1. Check Docker daemon status
2. Ensure sufficient disk space
3. Try rebuilding without cache: Command Palette → "Dev Containers: Rebuild Container"

### Extension Installation Issues

If VS Code extensions fail to install:

1. Check internet connectivity
2. Verify extension IDs in `vscode/extensions.txt`
3. Manually install problematic extensions

### 1Password Integration Issues

If credential management fails:

1. Ensure 1Password CLI is properly authenticated: `op signin`
2. Check that required secret references exist in 1Password
3. Verify template files in `credentials/templates/`

## Security Considerations

- **No hardcoded credentials**: All sensitive data is managed via environment variables and 1Password
- **Secure file permissions**: Generated credential files are set to 600 permissions
- **Container isolation**: Development environment is isolated from host system
- **Signed commits**: Git signing is configured with 1Password SSH keys

For detailed security guidelines, see the main [SECURITY.md](../SECURITY.md) file.
