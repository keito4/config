# Pre-PR Checklist Command

Automate comprehensive checks before creating a pull request.

## Usage

```bash
/pre-pr-checklist
```

## What It Does

This command runs a comprehensive checklist to ensure your changes are ready for pull request:

### Quality Checks (Sequential)

1. **Lint Check**: Runs ESLint to detect code issues
2. **Format Check**: Verifies Prettier formatting
3. **Type Check**: Validates TypeScript types (if applicable)
4. **Unit Tests**: Runs all tests with coverage
5. **Integration Tests**: Runs Bats integration tests
6. **Shellcheck**: Validates shell scripts

### PR Analysis

- **Size Estimation**: Calculates diff lines and file count
- **Size Label**: Suggests appropriate size label (S/M/L/XL)
- **Linked Issues**: Checks for related GitHub issues
- **Commit Messages**: Validates conventional commit format

### PR Preparation

- **Branch Status**: Checks if branch is up-to-date with main
- **Merge Conflicts**: Detects potential merge conflicts
- **Template Suggestion**: Recommends PR template content

## Size Thresholds

| Label   | Line Changes | File Count |
| ------- | ------------ | ---------- |
| size/S  | < 100        | < 10       |
| size/M  | < 300        | < 20       |
| size/L  | < 1000       | < 30       |
| size/XL | ≥ 1000       | ≥ 30       |

## Example Output

```
📋 Pre-PR Checklist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Quality Checks
  ✓ Lint check passed
  ✓ Format check passed
  ✓ Tests passed (101/101)
  ✓ Coverage: 82.5% (threshold: 70%)

📊 PR Analysis
  • Size: Medium (247 lines, 8 files)
  • Suggested label: size/M
  • Linked issues: #227
  • Commits: 3 (all follow conventional commits)

🔄 Branch Status
  ✓ Up-to-date with main
  ✓ No merge conflicts

✨ Ready to create PR!
```

## Options

```bash
# Skip tests (faster, but not recommended)
/pre-pr-checklist --skip-tests

# Skip integration tests only
/pre-pr-checklist --skip-integration

# Verbose output
/pre-pr-checklist --verbose
```

## Implementation

This command is implemented in `script/pre-pr-checklist.sh`.

## Integration

Works seamlessly with:

- GitHub Actions CI workflows
- Git hooks (pre-push)
- IDE integrations
- Manual PR preparation

## Benefits

- 🚀 **Faster Reviews**: Catch issues before PR creation
- ✅ **Quality Assurance**: All checks pass before submission
- 📊 **Better PRs**: Proper sizing and documentation
- ⚡ **Time Saving**: One command instead of multiple

## Requirements

- Git repository
- Node.js and npm
- GitHub CLI (`gh`) for issue detection
- All project dependencies installed
