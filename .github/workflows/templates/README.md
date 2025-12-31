# GitHub Actions Workflow Templates

This directory contains reusable GitHub Actions workflow templates for common CI/CD scenarios.

## Available Templates

### unified-ci.yml

A comprehensive CI workflow with coverage reporting and PR size detection.

**Features**:

- ✅ Unified quality checks (lint, type-check, build, test)
- 📊 Automatic coverage reporting in PR comments
- 🏷️ PR size detection and labeling
- ⚡ Fail-fast sequential execution
- 🚫 Concurrency control to cancel outdated runs

**Use Cases**:

- Projects requiring comprehensive quality gates
- Teams wanting automated coverage feedback
- Repositories with varying PR sizes

**Setup**:

1. Copy to `.github/workflows/ci.yml`
2. Customize quality check commands
3. Ensure test runner generates `coverage-summary.json`
4. Add size labels to repository: `size/S`, `size/M`, `size/L`, `size/XL`

**PR Size Thresholds**:

| Label   | Line Changes | File Count |
| ------- | ------------ | ---------- |
| size/S  | < 100        | < 10       |
| size/M  | < 300        | < 20       |
| size/L  | < 1000       | < 30       |
| size/XL | ≥ 1000       | ≥ 30       |

**Example Coverage Output**:

```markdown
## Test Coverage Report

### Overall Coverage

| Metric     | Coverage |
| ---------- | -------- |
| Statements | 85.2%    |
| Branches   | 78.6%    |
| Functions  | 90.1%    |
| Lines      | 84.9%    |
```

### monorepo-release.yml

A sophisticated release workflow for monorepo projects with intelligent change detection.

**Features**:

- 🔍 Per-package change detection
- 📦 Conditional semantic-release execution
- 🏷️ Separate versioning for each package
- 📤 GitHub Packages publishing support
- ✅ Pre-release testing for each package

**Use Cases**:

- Monorepo projects with multiple packages
- Teams wanting separate versioning per package
- Projects publishing to GitHub Packages

**Setup**:

1. Copy to `.github/workflows/release.yml`
2. Customize package names and paths
3. Create `.releaserc.json` for each package
4. Configure `publishConfig` in each `package.json`

**Package Configuration**:

Each package needs its own `.releaserc.json`:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/npm",
    "@semantic-release/github"
  ],
  "tagFormat": "package-name-v${version}"
}
```

For GitHub Packages, configure `package.json`:

```json
{
  "name": "@your-org/package-name",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

**Change Detection Logic**:

The workflow detects changes by comparing file paths:

- `packages/package1/` → triggers `release-package1` job
- `packages/package2/` → triggers `release-package2` job
- Root-level files → triggers `global-release` job

**First Commit Handling**:

On the first commit, all packages are considered changed to ensure initial releases.

## Customization Guide

### unified-ci.yml Customization

**Package Manager**:

Replace `npm` commands with your package manager:

```yaml
# For pnpm
- run: pnpm install --frozen-lockfile
- run: pnpm test -- --coverage

# For yarn
- run: yarn install --frozen-lockfile
- run: yarn test --coverage
```

**Quality Checks**:

Add or remove steps based on your project:

```yaml
# Add security scan
- name: Run security audit
  run: npm audit --audit-level=moderate

# Add dependency check
- name: Check dependencies
  run: npm run check:deps
```

**Coverage Format**:

If your coverage tool doesn't generate `coverage-summary.json`, modify the script:

```javascript
// For lcov format
const lcov = require('lcov-parse');
// Parse and format coverage data
```

### monorepo-release.yml Customization

**Package Paths**:

Update path patterns for your monorepo structure:

```bash
# For apps/ and packages/ structure
if git diff --name-only $PREV_COMMIT HEAD | grep -q "^apps/app1/"; then
  echo "app1_changed=true" >> $GITHUB_OUTPUT
fi
```

**Release Configuration**:

Customize release plugins per package:

```json
{
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/git",
    "@semantic-release/github"
  ]
}
```

**Registry Configuration**:

For npm registry instead of GitHub Packages:

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
    registry-url: 'https://registry.npmjs.org'

- name: Release
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
  run: npx semantic-release
```

## Best Practices

### CI Workflow

1. **Keep quality checks fast**: Use caching and parallel jobs where possible
2. **Fail early**: Put fastest checks first (lint before tests)
3. **Clear feedback**: Use descriptive job and step names
4. **Protect main**: Require CI to pass before merging

### Release Workflow

1. **Semantic commits**: Follow Conventional Commits specification
2. **Test before release**: Always run tests in release job
3. **Protect secrets**: Use GitHub secrets for tokens
4. **Tag format**: Use unique tag formats per package
5. **Branch protection**: Require releases only from main branch

## Troubleshooting

### Coverage Report Not Appearing

- Verify `coverage-summary.json` is generated in `coverage/` directory
- Check test script includes `--coverage` flag
- Ensure workflow has `pull-requests: write` permission

### PR Size Labels Not Working

- Create labels in repository: `size/S`, `size/M`, `size/L`, `size/XL`
- Verify workflow has `issues: write` permission
- Check PR is not from a fork (limitations on fork PRs)

### Release Not Triggering

- Verify commit follows Conventional Commits format
- Check `.releaserc.json` configuration
- Ensure `GITHUB_TOKEN` has correct permissions
- Review change detection logic matches your monorepo structure

### Multiple Releases Created

- Ensure each package has unique `tagFormat` in `.releaserc.json`
- Verify change detection correctly isolates package changes
- Check for overlapping path patterns in detection logic

## See Also

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Release](https://semantic-release.gitbook.io/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GitHub Packages](https://docs.github.com/en/packages)
