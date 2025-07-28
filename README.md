# Config Repository

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

- `brew/`: Contains Brewfiles for different operating systems (Linux, macOS) and dependency configurations, including lock files for reproducible package installations. Supports categorized package management and dependency analysis.
- `credentials/`: Contains templates and scripts for secure credential management using 1Password CLI integration.
- `dot/`: Directory for dotfiles and configuration files that are typically placed in the home directory.
- `.devcontainer/`: Contains shared DevContainer configuration files, including Docker setup, versioning documentation, and task completion notification scripts for development environment containerization.
- `git/`: Contains Git configuration files including gitconfig, gitignore, and modular configuration files in the `gitconfig.d/` subdirectory.
- `npm/`: Contains npm global package configuration.
- `script/`: Contains utility scripts for exporting configuration settings (`export.sh`), importing configuration settings (`import.sh`), checking for changes and making commits (`commit_changes.sh`), credential management (`credentials.sh`), Homebrew dependency management (`brew-deps.sh`), and version management (`version.sh`).
- `supabase/`: Contains Supabase-related configuration and documentation.
- `vscode/`: Contains Visual Studio Code configuration including extensions list and installation documentation.
- `.claude/`: Contains Claude AI development guidelines and quality standards, including conversation guidelines and development philosophy documentation.

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

### DevContainer Support

This repository includes shared DevContainer configuration for consistent development environments across projects.

#### Features
- **Shared configuration**: Reusable DevContainer setup that can be referenced from other repositories
- **Automated setup**: Automatically applies repository configurations via `script/import.sh` when container starts
- **Semantic versioning**: Support for versioned DevContainer images using git tags
- **Task notifications**: Bell notification system for task completion feedback

#### Usage
Reference the shared DevContainer configuration in your project's `devcontainer.json`:

```jsonc
{
  "features": {
    "../features/common": {}
  }
}
```

#### Versioning
Create versioned releases of the DevContainer image:

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

For detailed DevContainer versioning information, see [.devcontainer/VERSIONING.md](.devcontainer/VERSIONING.md).

### Automated Releases

This repository uses semantic-release for automated version management and releases based on commit messages. Follow conventional commit format:

- `feat:` - New features (minor version bump)
- `fix:` - Bug fixes (patch version bump)
- `BREAKING CHANGE:` - Breaking changes (major version bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` - No version bump

Releases are automatically created when changes are pushed to the main branch.

## Glossary

- **Homebrew (Brew)**: A package manager for macOS and Linux that allows easy installation and management of software packages.
- **Brewfile**: A file format used by Homebrew to declare and install packages in a reproducible way.
- **1Password**: A password manager that securely stores credentials, with CLI integration for automated credential management.
- **DevContainer**: A containerized development environment that provides consistent tooling and configurations across different machines and platforms.
- **Git**: A distributed version control system for tracking changes in source code during software development.
- **npm**: The default package manager for the JavaScript runtime environment Node.js.
- **Visual Studio Code**: A free source-code editor made by Microsoft for Windows, Linux, and macOS.
- **Supabase**: An open-source Firebase alternative providing backend-as-a-service features.
- **Semantic Release**: Automated version management and release process based on commit messages.
- **GitHub Actions**: CI/CD platform integrated with GitHub for automating workflows.
- **Claude**: AI assistant with development guidelines and quality standards defined in the `.claude/` directory.

## Disclaimer

This repository is intended for personal use. While it's made public for reference and learning purposes, it may not fit your development environment or use case directly. Always review and understand the settings and scripts before use.
