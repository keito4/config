# Security Credential Scan Command

Scan repository for hardcoded credentials and sensitive data.

## Usage

```bash
/security-credential-scan
/security-credential-scan --fix
/security-credential-scan --report
```

## What It Does

This command scans for potentially committed secrets and credentials:

### Detection Patterns

- **API Keys**: AWS, GitHub, Google Cloud, etc.
- **Tokens**: JWT, OAuth, Personal Access Tokens
- **Passwords**: Hardcoded passwords in code
- **Private Keys**: SSH keys, SSL certificates
- **Database Credentials**: Connection strings with passwords
- **Environment Variables**: Exposed secrets in .env files

### Validation

- **File Exclusions**: Skips .gitignore'd files
- **False Positive Reduction**: Smart pattern matching
- **Context Analysis**: Checks variable names and comments
- **.env Checking**: Verifies .env vs .env.example consistency

## Example Output

```
🔒 Security Credential Scan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Scanning 245 files...

🚨 CRITICAL: Potential Secrets Found

1. .env:12
   Type: AWS Access Key
   Pattern: AKIA[0-9A-Z]{16}
   Value: AKIA************ABCD
   🔥 Action: Move to .env.local (git-ignored)

2. src/config/database.js:23
   Type: Database Password
   Pattern: password: "..."
   Value: password: "***************"
   🔥 Action: Use environment variable

3. script/deploy.sh:45
   Type: GitHub Token
   Pattern: ghp_[a-zA-Z0-9]{36}
   Value: ghp_****************************1234
   🔥 Action: Use GitHub Secrets

⚠️ WARNING: Potential Issues

4. src/utils/api.ts:78
   Type: API Endpoint with Auth
   Pattern: https://user:pass@api.example.com
   Context: const API_URL = ...
   ℹ️ Note: Consider using tokens instead

5. test/fixtures/sample.json:5
   Type: JWT Token (Test Data)
   Pattern: eyJ[A-Za-z0-9-_=]+\\.eyJ[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_.+/=]*
   ✅ OK: In test fixtures (verify it's mock data)

📊 Summary

  Critical: 3 findings (MUST FIX)
  Warning: 2 findings (should review)
  Total Files Scanned: 245
  Files with Issues: 5

✅ .env Configuration

  ✓ .env.example exists
  ✓ .env in .gitignore
  ⚠️ .env has 3 keys not in .env.example:
    - AWS_SECRET_KEY
    - DATABASE_PASSWORD
    - GITHUB_TOKEN

  Add these to .env.example with placeholder values!

🔧 Recommended Actions

1. Move secrets from .env to .env.local
2. Update .env.example with all keys (use placeholder values)
3. Replace hardcoded credentials with environment variables
4. Add credential files to .gitignore:
   - *.key
   - *.pem
   - credentials.json
   - .env.local

5. Consider using:
   - 1Password CLI for local secrets
   - GitHub Secrets for CI/CD
   - AWS Secrets Manager for production

🚨 Security Score: 40/100 (Critical issues found)

Run with --fix to automatically remediate some issues.
```

## Options

```bash
# Attempt automatic fixes
/security-credential-scan --fix

# Generate detailed report
/security-credential-scan --report security-report.md

# Check specific paths
/security-credential-scan --path src/

# Ignore specific patterns
/security-credential-scan --ignore "test/**"

# Fail CI on critical findings
/security-credential-scan --strict

# JSON output
/security-credential-scan --json
```

## Detection Patterns

| Type           | Pattern                        | Example                                  |
| -------------- | ------------------------------ | ---------------------------------------- |
| AWS Access Key | `AKIA[0-9A-Z]{16}`             | AKIAIOSFODNN7EXAMPLE                     |
| AWS Secret     | `[A-Za-z0-9/+=]{40}`           | wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY |
| GitHub Token   | `ghp_[a-zA-Z0-9]{36}`          | ghp_1234567890abcdefghijklmnopqrstuvwx   |
| Google API     | `AIza[0-9A-Za-z-_]{35}`        | AIzaSyD-example-key                      |
| JWT Token      | `eyJ[A-Za-z0-9-_=]+\.eyJ...`   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  |
| Private Key    | `-----BEGIN.*PRIVATE KEY-----` | -----BEGIN RSA PRIVATE KEY-----          |
| Database URL   | `postgres://user:pass@host`    | postgres://admin:secret@localhost        |

## Auto-Fix Capabilities

With `--fix` flag:

- Creates .env.example from .env (with placeholders)
- Adds credential files to .gitignore
- Replaces hardcoded values with environment variable references
- Creates template files for secrets

## CI Integration

```yaml
# .github/workflows/security.yml
- name: Scan for Credentials
  run: |
    bash script/security-credential-scan.sh --strict
```

## False Positives

The scanner intelligently skips:

- Test fixtures (in `test/`, `__tests__/`, `*.test.*`)
- Example files (`*.example`, `*.sample`)
- Documentation (`*.md`, `docs/`)
- Comments and documentation strings
- Variable names and constants (not values)

## Benefits

- 🛡️ **Prevention**: Catch secrets before commit
- 🔍 **Detection**: Find existing credentials
- ⚡ **Fast**: Quick scans of entire codebase
- 🤖 **Automated**: CI integration
- 🔧 **Remediation**: Auto-fix capabilities

## Implementation

This command is implemented in `script/security-credential-scan.sh`.

## Requirements

- Bash 4.0+
- Git repository
- grep with regex support
