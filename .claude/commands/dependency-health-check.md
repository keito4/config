# Dependency Health Check Command

Comprehensive dependency health analysis including updates, security, and licensing.

## Usage

```bash
/dependency-health-check
```

## What It Does

This command performs a comprehensive health check of all project dependencies:

### npm Dependencies

- **Outdated Packages**: Detects packages with available updates
- **Security Vulnerabilities**: Scans for known vulnerabilities (`npm audit`)
- **Deprecated Packages**: Identifies deprecated dependencies
- **License Compliance**: Checks for incompatible licenses
- **Peer Dependencies**: Validates peer dependency requirements

### DevContainer Features

- **Feature Updates**: Checks for newer versions of DevContainer features
- **Base Image**: Verifies if base image has updates
- **Deprecated Features**: Identifies deprecated features

### Analysis Report

- **Risk Level**: Critical, High, Medium, Low
- **Action Required**: Immediate, Soon, Optional
- **Recommendations**: Specific actions to improve dependency health

## Example Output

```
🔍 Dependency Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 npm Packages (425 total)
  ✓ No critical vulnerabilities
  ⚠ 3 high severity vulnerabilities
  • 12 packages can be updated
  • 2 deprecated packages found

🔒 Security Status: Medium Risk
  High: 3 vulnerabilities
  - axios: Prototype pollution (CVE-2023-XXXX)
  - semver: ReDoS vulnerability (CVE-2023-YYYY)
  - json5: Prototype pollution (CVE-2022-ZZZZ)

📊 Update Summary
  Major: 2 packages
  Minor: 7 packages
  Patch: 3 packages

⚠ Deprecated Packages
  • request (use axios or node-fetch instead)
  • babel-eslint (use @babel/eslint-parser)

✅ License Compliance
  • All licenses compatible
  • MIT: 387 packages
  • Apache-2.0: 28 packages
  • BSD-3-Clause: 10 packages

🏥 Overall Health: 75/100
  Recommendations:
  1. Update axios to v1.6.0 (security fix)
  2. Replace deprecated packages
  3. Update 12 minor/patch versions

Next steps:
  npm update          # Update minor/patch versions
  npm audit fix       # Auto-fix security issues
  npm outdated        # See all outdated packages
```

## Options

```bash
# Production dependencies only
/dependency-health-check --prod

# Include DevContainer features
/dependency-health-check --include-container

# JSON output for CI integration
/dependency-health-check --json

# Fail on high severity issues
/dependency-health-check --strict
```

## CI Integration

```yaml
# .github/workflows/dependency-health.yml
- name: Dependency Health Check
  run: bash script/dependency-health-check.sh --strict
```

## Risk Levels

| Level    | Criteria                           | Action    |
| -------- | ---------------------------------- | --------- |
| Critical | Critical vulnerabilities           | Immediate |
| High     | High severity or many outdated     | Soon      |
| Medium   | Some vulnerabilities or deprecated | Optional  |
| Low      | Minor updates only                 | Optional  |

## Benefits

- 🛡️ **Security**: Early detection of vulnerabilities
- 📊 **Visibility**: Clear dependency status
- ⚡ **Proactive**: Catch issues before they're problems
- 📋 **Compliance**: License and policy enforcement
- 🔄 **Maintenance**: Easier dependency management

## Implementation

This command is implemented in `script/dependency-health-check.sh`.

## Requirements

- Node.js and npm
- Access to npm registry
- DevContainer configuration (optional)
