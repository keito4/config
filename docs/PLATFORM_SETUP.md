# Platform-Specific Setup Guide

This document provides detailed setup instructions for different operating systems to ensure optimal cross-platform compatibility with the configuration repository.

## Overview

The configuration system supports three main platforms:
- **macOS (Darwin)** - Full native support
- **Linux** - Full native support  
- **Windows** - PowerShell-based support with Unix tool compatibility

## Platform Detection

The system automatically detects your platform using:
- `uname` output for Unix-like systems
- Environment variables (`WINDIR`, `SYSTEMROOT`) for Windows
- Special cases for MINGW, MSYS, and Cygwin environments

## macOS Setup

### Prerequisites
- macOS 10.15+ (Catalina or later)
- Homebrew package manager
- Zsh shell (default in macOS 10.15+)

### Setup Steps
1. Install Homebrew if not already installed:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Export your configuration:
   ```bash
   ./script/export.sh
   ```

3. Import configuration to a new system:
   ```bash
   ./script/import.sh
   ```

### macOS-Specific Features
- Cursor/VSCode extension export
- Homebrew package management with dependency analysis
- Parallel processing for dependency detection
- Native `.zshrc` and `.zprofile` handling

## Linux Setup

### Prerequisites
- Any modern Linux distribution
- Bash or Zsh shell
- Package manager (apt, yum, pacman, etc.)

### Setup Steps
1. Install Homebrew (optional but recommended):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Export your configuration:
   ```bash
   ./script/export.sh
   ```

3. Import configuration to a new system:
   ```bash
   ./script/import.sh
   ```

### Linux-Specific Features
- Homebrew on Linux support
- Native shell configuration handling
- Git configuration export/import
- npm global package management

## Windows Setup

### Prerequisites
- Windows 10/11 with PowerShell 5.1+ or PowerShell Core 7+
- Git for Windows (recommended)
- Windows Subsystem for Linux (WSL) - optional but recommended

### Setup Methods

#### Option 1: PowerShell (Recommended)
1. Open PowerShell as Administrator
2. Set execution policy (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. Export your configuration:
   ```powershell
   .\script\export.ps1
   ```

4. Import configuration:
   ```powershell
   .\script\import.ps1  # (to be created)
   ```

#### Option 2: Unix Tools (Git Bash/WSL)
1. Open Git Bash or WSL terminal
2. Export using the Unix script:
   ```bash
   ./script/export.sh
   ```
   
   Note: The script will detect Windows and recommend using PowerShell for optimal support.

### Windows-Specific Features
- PowerShell profile export/import
- VSCode/Cursor settings from AppData
- Chocolatey package management
- Winget package export
- WSL configuration support
- Cross-platform path handling

### Package Managers on Windows
The system supports multiple Windows package managers:

1. **Chocolatey**
   - Exports installed packages to `chocolatey/packages.txt`
   - Install: Visit [chocolatey.org](https://chocolatey.org/install)

2. **Winget**
   - Exports packages to `winget/packages.json`
   - Built into Windows 10/11 (Windows Package Manager)

3. **Homebrew**
   - Can be used via WSL or native Windows installation
   - Exports to `brew/WindowsBrewfile`

## Development Container Support

### Cross-Platform Devcontainer Configuration

The devcontainer setup automatically handles platform differences:

#### Path Mounting
- **Unix-like systems**: Uses `${localEnv:HOME}` directly
- **Windows**: Automatically translates to Windows paths

#### Commands
- **Initialize**: Creates necessary directories cross-platform
- **Post-create**: Handles file permissions and ownership appropriately

#### Environment Variables
- `HOMEBREW_NO_AUTO_UPDATE=1` - Consistent across platforms
- `SHELL=/bin/bash` - Standardized shell in container

## Troubleshooting

### Common Issues

#### Windows Path Issues
- **Problem**: Scripts can't find files due to path differences
- **Solution**: Use the PowerShell scripts instead of Unix scripts

#### Permission Errors
- **Problem**: PowerShell execution policy blocks scripts
- **Solution**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

#### Missing Commands
- **Problem**: `brew`, `code`, or other commands not found
- **Solution**: Install the required tools or check your PATH

#### WSL Integration
- **Problem**: Mixed Windows/Linux environments cause conflicts
- **Solution**: Choose one environment consistently or use platform-specific scripts

### Platform-Specific Debugging

#### macOS
```bash
# Check system info
uname -a
sw_vers

# Verify Homebrew
brew --version

# Check shell
echo $SHELL
```

#### Linux
```bash
# Check system info
uname -a
cat /etc/os-release

# Verify package managers
which apt yum pacman

# Check shell
echo $SHELL
```

#### Windows
```powershell
# Check system info
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion

# Check PowerShell version
$PSVersionTable.PSVersion

# Check package managers
Get-Command choco, winget -ErrorAction SilentlyContinue
```

## Best Practices

1. **Use platform-specific scripts** when available for optimal compatibility
2. **Test configurations** in isolated environments before applying system-wide
3. **Keep backups** of important configuration files before importing
4. **Verify tool availability** before running export/import scripts
5. **Use absolute paths** when possible to avoid platform path differences

## Contributing

When adding new platform support or features:

1. **Test on all supported platforms** before submitting changes
2. **Use platform detection** to handle OS-specific logic
3. **Document platform-specific behavior** in this guide
4. **Follow existing patterns** for consistency across scripts
5. **Add error handling** for missing dependencies or tools

## Related Files

- `script/export.sh` - Unix/Linux/macOS export script
- `script/export.ps1` - Windows PowerShell export script
- `script/import.sh` - Unix/Linux/macOS import script
- `.devcontainer/devcontainer.json` - Development container configuration
- `brew/` - Platform-specific Homebrew files
- `docs/` - Additional documentation