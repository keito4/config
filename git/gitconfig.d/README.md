# Git Configuration Structure

This directory contains modular Git configuration files that are included by the main `gitconfig` file.

## File Structure

- `common.conf` - Platform-agnostic settings (URL rewriting, pull/push behavior)
- `macos.conf` - macOS-specific settings (1Password SSH signing path)
- `linux.conf` - Linux-specific settings (1Password SSH signing via PATH)
- `no-1password.conf` - Configuration for environments without 1Password
- `platform.conf` - Symlink to the appropriate platform configuration

## Setup Instructions

### For macOS:
```bash
cd ~/.gitconfig.d
ln -sf macos.conf platform.conf
```

### For Linux with 1Password:
```bash
cd ~/.gitconfig.d
ln -sf linux.conf platform.conf
```

### For environments without 1Password:
```bash
cd ~/.gitconfig.d
ln -sf no-1password.conf platform.conf
```

## Features

### URL Rewriting
- Automatically converts HTTPS GitHub URLs to SSH
- Consistent access method across platforms

### 1Password Integration
- macOS: Uses full application path
- Linux: Uses `op-ssh-sign` from PATH
- Fallback: Disables signing if 1Password unavailable

### Platform-Specific Settings
- macOS: `trustctime = false` (HFS+ compatibility)
- Linux: `trustctime = true` (ext4/other filesystems)

## Troubleshooting

If Git signing fails, check:
1. 1Password is installed and SSH agent is enabled
2. The `op-ssh-sign` binary is accessible
3. The correct platform configuration is linked