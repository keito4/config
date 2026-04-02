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

### Code Review (5観点)

差分に対して以下の5観点でクイックレビューを実施する:

1. **Security**: 機密情報露出、インジェクション、認証漏れ
2. **Performance**: N+1クエリ、メモリリーク、不要な再レンダリング
3. **Quality**: 命名、単一責任、テストカバレッジ、エラーハンドリング
4. **Accessibility**: ARIA属性、キーボードナビ、セマンティックHTML
5. **AI Residuals**: `it.skip`、`localhost`ハードコード、`TODO`/`FIXME`残骸、仮実装

critical / major の指摘があれば警告を表示し、PR作成前の修正を推奨する。
minor / recommendation のみなら APPROVE 相当として通過。

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

🔍 Code Review (5観点)
  ✓ Security: No issues
  ✓ Performance: No issues
  ⚠ Quality: 1 minor (naming in src/utils.ts:42)
  ✓ Accessibility: No issues
  ⚠ AI Residuals: 1 minor (TODO in src/handler.ts:15)
  → Verdict: APPROVE (minor only)

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
