# Config Repository

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

- `.devcontainer/`: Provides a reusable devcontainer configuration and feature for applying these settings automatically in VS Code Dev Containers.
- `brew/`: Contains Brewfiles for different operating systems (Linux, macOS) and dependency configurations, including lock files for reproducible package installations.
- `docker/`: Contains a Dockerfile and docker-compose file for setting up a Docker-based development environment.
- `dot/`: Contains dotfiles and configuration files that are typically placed in the home directory.
- `git/`: Contains Git configuration files including gitconfig, gitignore, and modular configuration files in the `gitconfig.d/` subdirectory.
- `kubernetes/`: Contains files for setting up a Kubernetes cluster using Vagrant, including a Vagrantfile, scripts for the master and worker nodes, and a script for fetching GKE credentials.
- `linux/`: Contains Linux-specific setup scripts for 1Password, Brew, Kubernetes, NordVPN, and Ubuntu-specific configurations.
- `macOS/`: Contains macOS-specific configuration files including Brewfile and system preferences scripts.
- `npm/`: Contains npm global package configuration.
- `script/`: Contains utility scripts for exporting configuration settings (`export.sh`), importing configuration settings (`import.sh`), checking for changes and making commits (`commit_changes.sh`), and version management (`version.sh`).
- `supabase/`: Contains Supabase-related configuration and documentation.
- `vscode/`: Contains Visual Studio Code configuration including extensions list, color themes, and documentation.
- GitHub Actions builds the `docker/Dockerfile` and publishes the image to GitHub Container Registry.

## 🔒 Security

**IMPORTANT**: This repository has been updated to improve security by removing hardcoded credentials.

Before using these configuration settings:
1. Review the `SECURITY.md` file for detailed security guidelines
2. Copy `.env.example` to `.env` and set your actual values
3. Never commit real credentials to version control
4. Use environment variables or secret management tools (like 1Password)

For detailed security instructions, see [SECURITY.md](SECURITY.md).

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

### Devcontainer

The `.devcontainer` directory provides a base configuration for VS Code Dev Containers. Include it in a project or reference the feature directly to automatically apply the settings in this repository when the container is built.

#### Versioning

The devcontainer images are released with semantic versioning. Use the following commands to create version tags:

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

After creating a tag, push it to trigger the Docker image build:
```bash
git push origin v1.0.1
```

For detailed information about the versioning system, see [.devcontainer/VERSIONING.md](.devcontainer/VERSIONING.md).

## Glossary

- Docker: An open-source platform used for automating the deployment, scaling, and management of applications.
- Kubernetes: An open-source platform designed to automate deploying, scaling, and operating application containers.
- Vagrant: A tool for building and managing virtual machine environments in a single workflow.
- Zsh: A shell designed for interactive use, although it is also a powerful scripting language.
- Git: A distributed version control system for tracking changes in source code during software development.
- npm: The default package manager for the JavaScript runtime environment Node.js.
- Visual Studio Code: A free source-code editor made by Microsoft for Windows, Linux, and macOS.
- 1Password: A password manager, which provides a place for users to store various passwords, software licenses, and other sensitive information in a virtual vault locked with a PBKDF2-guarded master password.

## Disclaimer

This repository is intended for personal use. While it's made public for reference and learning purposes, it may not fit your development environment or use case directly. Always review and understand the settings and scripts before use.
