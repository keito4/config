# PowerShell script for exporting configuration on Windows
# Equivalent to export.sh for Windows systems

param(
    [string]$RepoPath = $PWD
)

# Ensure REPO_PATH exists and create necessary directories
if (-not $RepoPath) {
    $RepoPath = Get-Location
}

$directories = @("brew", "vscode", "git", "dot", "npm", ".zsh")
foreach ($dir in $directories) {
    $path = Join-Path $RepoPath $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Determine the OS (should be Windows, but check for WSL)
$OS = "windows"
if ($env:WSL_DISTRO_NAME) {
    $OS = "wsl"
}

# Check if running in devcontainer/Docker environment
$IS_DEVCONTAINER = $false
if ((Test-Path "/.dockerenv") -or $env:REMOTE_CONTAINERS -or $env:CODESPACES) {
    $IS_DEVCONTAINER = $true
}

Write-Host "Detected OS: $OS"
Write-Host "Devcontainer: $IS_DEVCONTAINER"

# Export settings for Windows
if ($OS -eq "windows" -or $OS -eq "wsl") {
    # Export VSCode/Cursor extensions if available
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        $extensionsPath = Join-Path $RepoPath "vscode\extensions.txt"
        & code --list-extensions | Out-File -FilePath $extensionsPath -Encoding utf8
        Write-Host "Exported VSCode extensions to $extensionsPath"
    }
    elseif (Get-Command "cursor" -ErrorAction SilentlyContinue) {
        $extensionsPath = Join-Path $RepoPath "vscode\extensions.txt"
        & cursor --list-extensions | Out-File -FilePath $extensionsPath -Encoding utf8
        Write-Host "Exported Cursor extensions to $extensionsPath"
    }
}

# Export brew bundle if available (Windows may have Homebrew via WSL or Linux subsystem)
if ((Get-Command "brew" -ErrorAction SilentlyContinue) -and (-not $IS_DEVCONTAINER)) {
    if ($OS -eq "windows" -or $OS -eq "wsl") {
        $brewfilePath = Join-Path $RepoPath "brew\WindowsBrewfile"
        & brew bundle dump --file $brewfilePath --force --all
        Write-Host "Exported Homebrew packages to $brewfilePath"
    }
}

# Export git configuration (cross-platform paths)
$gitConfigSources = @{
    "gitconfig" = @("$env:USERPROFILE\.gitconfig", "$env:HOME\.gitconfig")
    "gitignore" = @("$env:USERPROFILE\.gitignore", "$env:HOME\.gitignore")
    "gitattributes" = @("$env:USERPROFILE\.gitattributes", "$env:HOME\.gitattributes")
}

foreach ($configType in $gitConfigSources.Keys) {
    $targetPath = Join-Path $RepoPath "git\$configType"
    
    foreach ($sourcePath in $gitConfigSources[$configType]) {
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            Write-Host "Exported $configType from $sourcePath"
            break
        }
    }
}

# Export PowerShell profile (Windows equivalent to .zshrc)
$profilePaths = @(
    $PROFILE.CurrentUserAllHosts,
    $PROFILE.CurrentUserCurrentHost,
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)

foreach ($profilePath in $profilePaths) {
    if (Test-Path $profilePath) {
        $targetPath = if ($IS_DEVCONTAINER) {
            Join-Path $RepoPath "dot\.powershell_profile.devcontainer.ps1"
        } else {
            Join-Path $RepoPath "dot\.powershell_profile.ps1"
        }
        Copy-Item -Path $profilePath -Destination $targetPath -Force
        Write-Host "Exported PowerShell profile from $profilePath"
        break
    }
}

# Export additional dotfiles commonly found in Windows
$windowsDotfiles = @{
    "$env:USERPROFILE\.wslconfig" = "dot\.wslconfig"
    "$env:USERPROFILE\.gitconfig" = "dot\.gitconfig.windows"
    "$env:APPDATA\Code\User\settings.json" = "vscode\settings.json"
    "$env:APPDATA\Cursor\User\settings.json" = "vscode\cursor-settings.json"
}

foreach ($source in $windowsDotfiles.Keys) {
    if (Test-Path $source) {
        $target = Join-Path $RepoPath $windowsDotfiles[$source]
        $targetDir = Split-Path $target -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -Path $source -Destination $target -Force
        Write-Host "Exported $(Split-Path $source -Leaf) to $target"
    }
}

# Export npm packages (cross-platform)
if (Get-Command "npm" -ErrorAction SilentlyContinue) {
    $npmPath = Join-Path $RepoPath "npm\global.json"
    try {
        $npmOutput = & npm list -g --depth=0 --json 2>$null
        if ($npmOutput) {
            $npmOutput | Out-File -FilePath $npmPath -Encoding utf8
        } else {
            '{}' | Out-File -FilePath $npmPath -Encoding utf8
        }
        Write-Host "Exported npm global packages to $npmPath"
    }
    catch {
        '{}' | Out-File -FilePath $npmPath -Encoding utf8
        Write-Host "Created empty npm global packages file (npm command failed)"
    }
}

# Export package managers specific to Windows
if (Get-Command "choco" -ErrorAction SilentlyContinue) {
    $chocoPath = Join-Path $RepoPath "chocolatey\packages.txt"
    $chocoDir = Split-Path $chocoPath -Parent
    if (-not (Test-Path $chocoDir)) {
        New-Item -ItemType Directory -Path $chocoDir -Force | Out-Null
    }
    & choco list --local-only | Out-File -FilePath $chocoPath -Encoding utf8
    Write-Host "Exported Chocolatey packages to $chocoPath"
}

if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    $wingetPath = Join-Path $RepoPath "winget\packages.json"
    $wingetDir = Split-Path $wingetPath -Parent
    if (-not (Test-Path $wingetDir)) {
        New-Item -ItemType Directory -Path $wingetDir -Force | Out-Null
    }
    try {
        & winget export --output $wingetPath
        Write-Host "Exported Winget packages to $wingetPath"
    }
    catch {
        Write-Host "Failed to export Winget packages"
    }
}

Write-Host "Windows configuration export completed!"