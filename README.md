# Config Repository

This repository holds a collection of configuration settings and scripts for managing a consistent development environment across different systems. The primary purpose of this repository is to reduce the time and effort required to set up a new development environment. By running a single command, you can replicate the same development environment on a new computer.

It includes settings for various tools, such as the shell (Zsh), Git, npm, and Visual Studio Code, and provides specific configurations for different operating systems.

## Directory Structure

- `docker`: Contains a Dockerfile and docker-compose file for setting up a Docker-based development environment using the `codercom/code-server` image. Set the `CODE_SERVER_PASSWORD` environment variable to control the login password.
- `kubernetes`: Contains files for setting up a Kubernetes cluster using Vagrant, including a Vagrantfile, scripts for the master and worker nodes, and a script for fetching GKE credentials.
- `script`: Contains scripts for exporting configuration settings from a system to this repository (`export.sh`), importing configuration settings from this repository to a system (`import.sh`), and checking for changes and making a commit (`commit_changes.sh`).
- `.zsh`, `git`, `macOS`, `.vscode`, `linux`, `vscode`, `npm`, `brew`, `dot`: These directories contain various configuration files and settings for different tools and systems.
- `.devcontainer`: Provides a reusable devcontainer configuration and feature for applying these settings automatically.

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

The `.devcontainer` directory offers a reusable setup for VS Code Dev Containers. Refer to the included feature to copy shell functions and Git settings into the container without installing heavy packages like Homebrew.

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
