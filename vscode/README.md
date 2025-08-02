# Visual Studio Code Configuration

This directory contains Visual Studio Code configuration files and scripts for maintaining a consistent development environment.

## Files

- `extensions.txt`: List of VS Code extensions to be installed

## Installation

### Prerequisites

Ensure Visual Studio Code is installed and the `code` command is available in your PATH.

### Install Extensions

Choose the appropriate method for your operating system:

#### Unix/Linux/macOS

```bash
cat ./extensions.txt | xargs -L 1 code --install-extension
```

#### Windows (PowerShell)

```powershell
Get-Content ./extensions.txt | ForEach-Object { code --install-extension $_ }
```

#### Alternative Windows Command

```powershell
cat ./extensions.txt | % { code --install-extension $_ }
```

## Exporting Current Extensions

To update the `extensions.txt` file with your currently installed extensions:

```bash
code --list-extensions > extensions.txt
```

## Usage in Automation

This extensions list can be used as part of the repository's import script (`../script/import.sh`) to automatically set up a development environment on new machines.

## Troubleshooting

### Extension Installation Fails

- Ensure you're logged into VS Code with your Microsoft/GitHub account
- Check your internet connection
- Verify the extension ID is correct in `extensions.txt`
- Try installing the problematic extension manually first

### `code` Command Not Found

Add VS Code to your PATH:

- **macOS**: `Command + Shift + P` → "Shell Command: Install 'code' command in PATH"
- **Windows**: Ensure VS Code installation directory is in your system PATH
- **Linux**: The `code` command should be available after installation via package manager
