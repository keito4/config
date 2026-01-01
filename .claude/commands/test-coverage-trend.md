# Test Coverage Trend Command

Track and visualize test coverage trends over time.

## Usage

```bash
/test-coverage-trend
/test-coverage-trend --days 30
/test-coverage-trend --graph
```

## What It Does

This command tracks test coverage metrics over time:

### Coverage Tracking

- **Historical Data**: Stores coverage data per commit
- **Trend Analysis**: Shows coverage improvements/declines
- **Threshold Alerts**: Warns when coverage drops below 70%
- **Component Breakdown**: Per-file coverage tracking

### Metrics Tracked

- **Line Coverage**: Percentage of lines covered
- **Branch Coverage**: Percentage of branches covered
- **Function Coverage**: Percentage of functions covered
- **Statement Coverage**: Percentage of statements covered

### Visualization

- **ASCII Graph**: Simple trend graph in terminal
- **Statistics**: Min, max, average coverage
- **Recent Changes**: Coverage diff from last run
- **Hotspots**: Files with low coverage

## Example Output

```
📊 Test Coverage Trend
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 Coverage History (Last 30 days)

Line Coverage Trend:
100% ┤
 95% ┤     ╭─╮
 90% ┤   ╭─╯ ╰─╮
 85% ┤ ╭─╯     ╰──╮
 80% ┤─╯           ╰─╮
 75% ┤               ╰─
 70% ┼─────────────────────────────────
     └─────────────────────────────────
     30d                           now

📊 Current Coverage
  • Lines: 82.5% (↑ 1.2% from last week)
  • Branches: 78.3% (↓ 0.5% from last week)
  • Functions: 85.0% (↑ 2.0% from last week)
  • Statements: 82.1% (↑ 1.0% from last week)

✅ Above threshold (70%)

📈 Statistics (30 days)
  • Average: 81.2%
  • Min: 75.0% (2025-12-01)
  • Max: 85.5% (2025-12-28)
  • Trend: ↗ Improving (+5.5% over period)

⚠️ Low Coverage Files
  1. script/lib/output.sh: 45.2%
  2. script/credentials.sh: 58.7%
  3. test/config-validation.test.js: 65.3%

💡 Recommendations
  • Add tests for low-coverage files
  • Coverage trend is positive - keep it up!
```

## Options

```bash
# Show last N days
/test-coverage-trend --days 30

# Show ASCII graph
/test-coverage-trend --graph

# Show per-file details
/test-coverage-trend --detailed

# Export to CSV
/test-coverage-trend --export coverage-trend.csv

# CI-friendly JSON output
/test-coverage-trend --json
```

## Data Storage

Coverage data is stored in `.coverage-history/`:

```
.coverage-history/
├── 2025-12-31.json
├── 2025-12-30.json
└── 2025-12-29.json
```

Each file contains:

```json
{
  "date": "2025-12-31",
  "commit": "a1b2c3d",
  "coverage": {
    "lines": 82.5,
    "branches": 78.3,
    "functions": 85.0,
    "statements": 82.1
  },
  "files": {
    "script/pre-pr-checklist.sh": 95.0,
    "script/dependency-health-check.sh": 88.5
  }
}
```

## CI Integration

```yaml
# .github/workflows/coverage-trend.yml
- name: Track Coverage Trend
  run: |
    npm run test:coverage
    bash script/test-coverage-trend.sh --record
    git add .coverage-history/
    git commit -m "chore: update coverage history"
```

## Alerts

| Condition      | Alert                        |
| -------------- | ---------------------------- |
| Coverage < 70% | 🚨 Critical: Below threshold |
| Drop > 5%      | ⚠️ Warning: Significant drop |
| Drop > 2%      | ℹ️ Info: Minor decline       |
| Increase > 2%  | ✅ Success: Improvement      |

## Benefits

- 📊 **Visibility**: Clear coverage trends
- ⚠️ **Early Warning**: Detect coverage regressions
- 📈 **Motivation**: Visualize improvements
- 🎯 **Targeted**: Identify low-coverage files
- 🤖 **Automated**: CI integration

## Implementation

This command is implemented in `script/test-coverage-trend.sh`.

## Requirements

- Jest with coverage enabled
- Git repository
- `coverage/coverage-summary.json` output from Jest
