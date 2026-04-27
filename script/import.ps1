# ============================================================================
# Windows ネイティブ環境セットアップ
# ----------------------------------------------------------------------------
# - Bash / nix / Homebrew が無い Windows ホスト向けのブートストラップ。
# - winget で基本パッケージを一括導入し、各種 dotfile / ツール設定を
#   %USERPROFILE% 配下にコピーする。
# - WSL2 上のセットアップは引き続き script/import.sh を使う。
#
# Usage:
#   pwsh -File script/import.ps1            # 通常実行
#   pwsh -File script/import.ps1 -DryRun    # 実行せず内容のみ表示
#   pwsh -File script/import.ps1 -SkipWinget -SkipNpm
#
# 互換: Windows PowerShell 5.1 / PowerShell 7+ の両方で動作する。
# ============================================================================

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipWinget,
    [switch]$SkipExtensions,
    [switch]$SkipNpm,
    [switch]$SkipRepos
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$UserHome = $env:USERPROFILE

function Write-Step($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  + $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Skip($msg)  { Write-Host "  - $msg" -ForegroundColor DarkGray }

function Test-Cmd($name) {
    $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Copy-Tracked {
    param([string]$Source, [string]$Target, [switch]$Recurse)

    if (-not (Test-Path $Source)) {
        Write-Skip "missing: $Source"
        return
    }
    if ($DryRun) {
        Write-Step "[dry-run] copy $Source -> $Target"
        return
    }
    $targetDir = Split-Path -Parent $Target
    if ($targetDir -and -not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    if ($Recurse) {
        if (-not (Test-Path $Target)) {
            New-Item -ItemType Directory -Path $Target -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $Source '*') -Destination $Target -Recurse -Force
    } else {
        Copy-Item -Path $Source -Destination $Target -Force
    }
    Write-Ok "imported $(Split-Path -Leaf $Target)"
}

# ---------------------------------------------------------------------------
# 1. winget packages
# ---------------------------------------------------------------------------
if ($SkipWinget) {
    Write-Step 'skip winget (--SkipWinget)'
} elseif (-not (Test-Cmd 'winget')) {
    Write-Warn2 'winget not found. Install "App Installer" from Microsoft Store, then re-run.'
} else {
    $manifest = Join-Path $RepoRoot 'brew\Winfile.json'
    if (-not (Test-Path $manifest)) {
        Write-Warn2 "manifest not found: $manifest"
    } else {
        Write-Step "winget import: $manifest"
        if (-not $DryRun) {
            $wingetArgs = @(
                'import',
                '--import-file', $manifest,
                '--accept-package-agreements',
                '--accept-source-agreements',
                '--ignore-versions',
                '--no-upgrade'
            )
            & winget @wingetArgs
            if ($LASTEXITCODE -ne 0) {
                Write-Warn2 "winget import exited with code $LASTEXITCODE (continuing)"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 2. Git config (~/.gitconfig, ~/.gitignore, ~/.gitattributes)
# ---------------------------------------------------------------------------
Write-Step 'git config'
Copy-Tracked (Join-Path $RepoRoot 'git\gitconfig')     (Join-Path $UserHome '.gitconfig')
Copy-Tracked (Join-Path $RepoRoot 'git\gitignore')     (Join-Path $UserHome '.gitignore')
Copy-Tracked (Join-Path $RepoRoot 'git\gitattributes') (Join-Path $UserHome '.gitattributes')

if ((Test-Path (Join-Path $UserHome '.gitconfig')) -and -not $DryRun) {
    Write-Warn2 '~/.gitconfig has commented-out user info. Configure manually:'
    Write-Host '    git config --global user.name  "Your Name"'
    Write-Host '    git config --global user.email "your.email@example.com"'
}

# ---------------------------------------------------------------------------
# 3. Tool configs (Claude / Codex / Cursor / Gemini / MCP / VS Code)
# ---------------------------------------------------------------------------
Write-Step 'tool configs'

$toolDirs = @(
    @{ Name = 'Claude'; Source = '.claude'; Target = '.claude' },
    @{ Name = 'Codex' ; Source = '.codex' ; Target = '.codex'  },
    @{ Name = 'Cursor'; Source = '.cursor'; Target = '.cursor' },
    @{ Name = 'Gemini'; Source = '.gemini'; Target = '.gemini' }
)
foreach ($t in $toolDirs) {
    Copy-Tracked (Join-Path $RepoRoot $t.Source) (Join-Path $UserHome $t.Target) -Recurse
}

Copy-Tracked (Join-Path $RepoRoot '.mcp.json') (Join-Path $UserHome '.mcp.json')

# VS Code user settings (only when VS Code is installed)
$vscodeUserDir = Join-Path $env:APPDATA 'Code\User'
if (Test-Path $vscodeUserDir) {
    Copy-Tracked (Join-Path $RepoRoot '.vscode\settings.json') (Join-Path $vscodeUserDir 'settings.json')
} else {
    Write-Skip 'VS Code user dir not found; skipping settings.json'
}

# ---------------------------------------------------------------------------
# 4. VS Code extensions
# ---------------------------------------------------------------------------
$extFile = Join-Path $RepoRoot 'vscode\extensions.txt'
if ($SkipExtensions) {
    Write-Step 'skip VS Code extensions (--SkipExtensions)'
} elseif (-not (Test-Cmd 'code')) {
    Write-Skip 'code CLI not on PATH; skipping extension install'
} elseif (-not (Test-Path $extFile)) {
    Write-Skip "extensions.txt missing: $extFile"
} else {
    Write-Step 'VS Code extensions'
    Get-Content $extFile | ForEach-Object {
        $ext = $_.Trim()
        if ([string]::IsNullOrEmpty($ext) -or $ext.StartsWith('#')) { return }
        if ($DryRun) {
            Write-Step "[dry-run] code --install-extension $ext"
        } else {
            & code --install-extension $ext --force | Out-Null
            Write-Ok $ext
        }
    }
}

# ---------------------------------------------------------------------------
# 5. npm global packages
# ---------------------------------------------------------------------------
if ($SkipNpm) {
    Write-Step 'skip npm globals (--SkipNpm)'
} elseif (-not (Test-Cmd 'npm')) {
    Write-Skip 'npm not found; install Node.js via winget then re-run with -SkipWinget'
} else {
    $globalJson = Join-Path $RepoRoot 'npm\global.json'
    if (-not (Test-Path $globalJson)) {
        Write-Skip "npm/global.json missing"
    } else {
        Write-Step 'npm global packages'
        $deps = (Get-Content $globalJson -Raw | ConvertFrom-Json).dependencies
        foreach ($prop in $deps.PSObject.Properties) {
            $pkg = "$($prop.Name)@$($prop.Value.version)"
            if ($DryRun) {
                Write-Step "[dry-run] npm install -g $pkg"
            } else {
                & npm install -g $pkg
                if ($LASTEXITCODE -eq 0) { Write-Ok $pkg } else { Write-Warn2 "npm install failed: $pkg" }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 6. Clone GitHub repos via ghq (mirrors Linux/macOS flow)
# ---------------------------------------------------------------------------
if ($SkipRepos) {
    Write-Step 'skip ghq clone (--SkipRepos)'
} elseif (-not ((Test-Cmd 'gh') -and (Test-Cmd 'ghq'))) {
    Write-Skip 'gh or ghq not on PATH; skipping repo clone'
} elseif ($DryRun) {
    Write-Step '[dry-run] gh api user/repos | ghq get'
} else {
    Write-Step 'ghq get (user repos)'
    $sshUrls = & gh api user/repos --paginate --jq '.[].ssh_url'
    if ($LASTEXITCODE -eq 0) {
        ($sshUrls -split "`n") | Where-Object { $_ } | ForEach-Object { & ghq get $_ }
    } else {
        Write-Warn2 'gh api failed; skipping ghq get'
    }
}

Write-Step 'Windows bootstrap complete.'
