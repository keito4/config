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

### coverage-report.yml (Reusable Workflow)

A reusable workflow that posts coverage summary as PR comments. Supports multiple coverage formats.

**Features**:

- 📊 JaCoCo coverage report (Android/JVM) via `madrapps/jacoco-report`
- 📊 Jest/Vitest coverage report (JS/TS) via `actions/github-script`
- 📊 Cobertura coverage report (.NET/Python/Go) via `irongut/CodeCoverageSummary`
- 📊 LCOV coverage report (Istanbul/nyc/c8) via `romeovs/lcov-reporter-action`
- 🔄 Existing PR comment update (no duplicates)
- 📈 Configurable coverage thresholds
- 📦 Artifact-based report transfer (language-agnostic)

**Supported Formats**:

| format      | Tools                      | Parser                                |
| ----------- | -------------------------- | ------------------------------------- |
| `jacoco`    | JaCoCo (Android/JVM)       | `madrapps/jacoco-report@v1.7.2`       |
| `jest`      | Jest, Vitest, c8 (JS/TS)   | `actions/github-script@v8`            |
| `cobertura` | Cobertura (.NET/Python/Go) | `irongut/CodeCoverageSummary@v1.3.0`  |
| `lcov`      | Istanbul, nyc, c8 (LCOV)   | `romeovs/lcov-reporter-action@v0.4.0` |

**Usage (Jest)**:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - run: npm ci && npm test -- --coverage
      - uses: actions/upload-artifact@v6.0.0
        if: github.event_name == 'pull_request'
        with:
          name: coverage-report
          path: coverage/coverage-summary.json

  coverage:
    needs: test
    if: github.event_name == 'pull_request'
    uses: keito4/config/.github/workflows/coverage-report.yml@main
    with:
      format: jest
      report-path: coverage-summary.json
      artifact-name: coverage-report
    permissions:
      contents: read
      pull-requests: write
```

**Usage (JaCoCo)**:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: 17
      - run: ./gradlew testDebugUnitTest createDebugUnitTestCoverageReport
      - uses: actions/upload-artifact@v6.0.0
        if: github.event_name == 'pull_request'
        with:
          name: jacoco-report
          path: app/build/reports/coverage/test/debug/report.xml

  coverage:
    needs: test
    if: github.event_name == 'pull_request'
    uses: keito4/config/.github/workflows/coverage-report.yml@main
    with:
      format: jacoco
      report-path: report.xml
      artifact-name: jacoco-report
    permissions:
      contents: read
      pull-requests: write
```

**Usage (Cobertura / .NET)**:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0'
      - run: dotnet test --collect:"XPlat Code Coverage"
      - uses: actions/upload-artifact@v6.0.0
        if: github.event_name == 'pull_request'
        with:
          name: cobertura-report
          path: '**/coverage.cobertura.xml'

  coverage:
    needs: test
    if: github.event_name == 'pull_request'
    uses: keito4/config/.github/workflows/coverage-report.yml@main
    with:
      format: cobertura
      report-path: coverage.cobertura.xml
      artifact-name: cobertura-report
    permissions:
      contents: read
      pull-requests: write
```

**Usage (LCOV)**:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - run: npm ci && npm test -- --coverage --coverageReporters=lcov
      - uses: actions/upload-artifact@v6.0.0
        if: github.event_name == 'pull_request'
        with:
          name: lcov-report
          path: coverage/lcov.info

  coverage:
    needs: test
    if: github.event_name == 'pull_request'
    uses: keito4/config/.github/workflows/coverage-report.yml@main
    with:
      format: lcov
      report-path: lcov.info
      artifact-name: lcov-report
    permissions:
      contents: read
      pull-requests: write
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

For multi-format coverage support, use the reusable `coverage-report.yml` workflow instead of the hardcoded coverage-report job. See the [coverage-report.yml](#coverage-reportyml-reusable-workflow) section above.

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
  uses: actions/setup-node@v6.2.0
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

## Path Filters for CI Optimization

Path filtersを使用することで、変更されたファイルに応じて必要なワークフローやジョブのみを実行し、CI実行時間とコストを削減できます。

### ワークフローレベルのフィルタリング

ワークフロー全体をスキップするには、`on`セクションでpathsを指定します:

```yaml
on:
  pull_request:
    paths:
      - '**.js'
      - '**.ts'
      - 'src/**'
      - 'package.json'
      - '.github/workflows/**'
  push:
    branches: [main]
    # mainブランチでは全チェックを実行（pathsを指定しない）
```

### ジョブレベルのフィルタリング

より細かい制御には`dorny/paths-filter`アクションを使用します:

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      code: ${{ steps.filter.outputs.code }}
      docs: ${{ steps.filter.outputs.docs }}
    steps:
      - uses: actions/checkout@v6.0.2
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            code:
              - 'src/**'
              - 'test/**'
            docs:
              - '**.md'
              - 'docs/**'

  test:
    needs: changes
    if: needs.changes.outputs.code == 'true'
    # ... testジョブ

  deploy-docs:
    needs: changes
    if: needs.changes.outputs.docs == 'true'
    # ... ドキュメントデプロイジョブ
```

### 推奨フィルターパターン

| ワークフロー  | 推奨パス                                             | 理由                                               |
| ------------- | ---------------------------------------------------- | -------------------------------------------------- |
| CI Pipeline   | `**.{js,ts}`, `package.json`, `src/**`, `test/**`    | コード変更時のみテスト実行                         |
| Docker Build  | `.devcontainer/**`, `Dockerfile`, `package.json`     | コンテナ関連の変更時のみビルド                     |
| Documentation | `**.md`, `docs/**`                                   | ドキュメント変更時のみデプロイ                     |
| Security Scan | `**.{js,ts}`, `package-lock.json`, `npm/global.json` | セキュリティリスクのあるファイル変更時のみスキャン |

### 効果測定例

- **ドキュメントのみの変更**: CI実行時間 90%削減 (10分 → 1分)
- **Docker関連以外の変更**: イメージビルド スキップ (45分 → 0分)
- **コード変更なし**: テストスキップ (15分 → 0分)

### 注意事項

1. **mainブランチ**: 本番ブランチでは全チェックを実行することを推奨（path filtersを緩めに設定）
2. **skipped状態の処理**: Quality Gateで`skipped`を成功として扱う必要があります
3. **ワークフロー自体の変更**: `.github/workflows/**`は常に含める

## Best Practices

### CI Workflow

1. **Keep quality checks fast**: Use caching and parallel jobs where possible
2. **Fail early**: Put fastest checks first (lint before tests)
3. **Clear feedback**: Use descriptive job and step names
4. **Protect main**: Require CI to pass before merging
5. **Optimize with path filters**: Skip unnecessary jobs when files haven't changed

### Release Workflow

1. **Semantic commits**: Follow Conventional Commits specification
2. **Test before release**: Always run tests in release job
3. **Protect secrets**: Use GitHub secrets for tokens
4. **Tag format**: Use unique tag formats per package
5. **Branch protection**: Require releases only from main branch

## Troubleshooting

### Coverage Report Not Appearing

- Verify coverage report file is uploaded as an artifact in the calling job
- Ensure `artifact-name` matches the name used in `actions/upload-artifact`
- Ensure `report-path` matches the file path within the artifact
- Check that `pull-requests: write` permission is set in the calling workflow
- For jest: verify `coverage-summary.json` is generated (use `--coverage` flag)
- For jacoco: verify `report.xml` is generated by the Gradle coverage task
- For cobertura: verify `coverage.cobertura.xml` is generated by the test runner
- For lcov: verify `lcov.info` is generated (use `--coverageReporters=lcov` flag)

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
