# Container Health Command

Verify DevContainer environment health and configuration.

## Usage

```bash
/container-health
/container-health --verbose
/container-health --fix
```

## What It Does

This command performs comprehensive health checks on your DevContainer environment:

### Tool Availability

- **Required Tools**: git, node, npm, docker (if applicable)
- **Claude Code Tools**: claude, codex
- **Development Tools**: eslint, prettier, jest
- **Optional Tools**: gh (GitHub CLI), shellcheck

### Version Verification

- **Node.js**: Checks for v22.14.0 (or configured version)
- **npm**: Verifies compatible version
- **Claude Code**: Checks for latest version
- **Global Packages**: Verifies required global packages

### Configuration Validation

- **package.json**: Validates structure and scripts
- **DevContainer Config**: Checks devcontainer.json
- **Git Config**: Verifies git user and email
- **Environment Variables**: Checks required variables

### System Resources

- **Disk Space**: Warns if < 1GB free
- **Memory**: Checks available memory
- **File Permissions**: Verifies executable permissions

## Example Output

```
🏥 DevContainer Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Required Tools
  ✓ git 2.43.0
  ✓ node v22.14.0
  ✓ npm 10.2.4
  ✓ docker 24.0.7

✅ Claude Code Tools
  ✓ claude 0.9.0
  ✓ codex 1.2.0

✅ Development Tools
  ✓ eslint 8.57.0
  ✓ prettier 3.1.1
  ✓ jest 29.7.0

⚠️ Optional Tools
  ✓ gh 2.40.1
  ✗ shellcheck (not installed)

✅ Version Verification
  ✓ Node.js version matches (v22.14.0)
  ✓ npm version compatible (10.2.4)

✅ Configuration
  ✓ package.json valid
  ✓ devcontainer.json exists
  ✓ git user configured
  ✓ git email configured

✅ System Resources
  ✓ Disk space: 15.2 GB free
  ✓ Memory: 8.0 GB available
  ✓ Shell scripts executable

🏥 Health Score: 95/100

⚠️ Recommendations:
  1. Install shellcheck for shell script validation
     Run: apt-get install shellcheck

✨ DevContainer is healthy!
```

## Options

```bash
# Verbose output with detailed diagnostics
/container-health --verbose

# Attempt automatic fixes for common issues
/container-health --fix

# Check specific component
/container-health --check tools
/container-health --check config
/container-health --check resources

# JSON output for CI
/container-health --json
```

## Health Checks

| Category      | Checks                   | Weight |
| ------------- | ------------------------ | ------ |
| Tools         | Required tools installed | 30     |
| Versions      | Correct versions         | 25     |
| Configuration | Valid configs            | 25     |
| Resources     | Adequate disk/memory     | 15     |
| Permissions   | Executable permissions   | 5      |

## Auto-Fix Capabilities

With `--fix` flag, the command can automatically:

- Install missing npm packages
- Set git user/email from environment
- Fix file permissions
- Create missing configuration files
- Update outdated global packages

## CI Integration

```yaml
# .github/workflows/container-health.yml
- name: Container Health Check
  run: |
    bash script/container-health.sh --json
```

## Exit Codes

| Code | Meaning               |
| ---- | --------------------- |
| 0    | All checks passed     |
| 1    | Critical issues found |
| 2    | Configuration errors  |
| 3    | Tool not found        |

## Benefits

- 🔍 **Early Detection**: Catch environment issues early
- ⚡ **Fast Diagnosis**: Quick health assessment
- 🔧 **Auto-Fix**: Resolve common issues automatically
- 📊 **Visibility**: Clear health score and metrics
- ✅ **CI Ready**: JSON output for automation

## Implementation

This command is implemented in `script/container-health.sh`.

## Requirements

- DevContainer environment
- Bash 4.0+
- Basic POSIX utilities (df, free, which)
