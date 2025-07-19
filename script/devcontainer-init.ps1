# PowerShell script for devcontainer initialization on Windows
# Creates necessary directories on the host system before container startup

Write-Host "Initializing devcontainer environment on Windows..."

# Determine home directory
$HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
Write-Host "Home directory: $HomeDir"

# Function to safely create directory
function New-DirectorySafe {
    param([string]$Path)
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Host "✓ Created directory: $Path"
            return $true
        } else {
            Write-Host "✓ Directory already exists: $Path"
            return $true
        }
    }
    catch {
        Write-Host "⚠ Warning: Failed to create directory $Path - $($_.Exception.Message)"
        return $false
    }
}

# Create necessary directories
Write-Host "Creating Claude configuration directory..."
$claudeDir = Join-Path $HomeDir ".claude"
$claudeSuccess = New-DirectorySafe -Path $claudeDir

Write-Host "Creating Cursor configuration directory..."
$cursorDir = Join-Path $HomeDir ".cursor"
$cursorSuccess = New-DirectorySafe -Path $cursorDir

# Create .claude.json if it doesn't exist
$claudeConfigPath = Join-Path $HomeDir ".claude.json"
if (-not (Test-Path $claudeConfigPath)) {
    Write-Host "Creating default .claude.json configuration..."
    try {
        $defaultConfig = @{
            version = "1.0"
            created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            platform = "Windows"
            powershell_version = $PSVersionTable.PSVersion.ToString()
        }
        
        $defaultConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath $claudeConfigPath -Encoding utf8
        Write-Host "✓ Default .claude.json created"
    }
    catch {
        Write-Host "⚠ Warning: Failed to create .claude.json - $($_.Exception.Message)"
    }
} else {
    Write-Host "✓ .claude.json already exists"
}

# Summary
Write-Host ""
Write-Host "Devcontainer initialization summary:"
Write-Host "- Claude directory: $(if ($claudeSuccess) { '✓ Success' } else { '✗ Failed' })"
Write-Host "- Cursor directory: $(if ($cursorSuccess) { '✓ Success' } else { '✗ Failed' })"
Write-Host "- Configuration file: $(if (Test-Path $claudeConfigPath) { '✓ Present' } else { '✗ Missing' })"
Write-Host ""
Write-Host "Devcontainer initialization completed!"

# Exit with appropriate code
if ($claudeSuccess -and $cursorSuccess) {
    exit 0
} else {
    exit 1
}