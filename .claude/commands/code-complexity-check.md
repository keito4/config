# Code Complexity Check Command

Analyze code complexity and identify refactoring candidates.

## Usage

```bash
/code-complexity-check
/code-complexity-check --threshold 10
/code-complexity-check --report
```

## What It Does

This command analyzes code complexity metrics to identify complex code that may need refactoring:

### Complexity Metrics

- **Cyclomatic Complexity**: Number of independent paths
- **Function Length**: Lines of code per function
- **Nesting Depth**: Maximum nesting level
- **Parameter Count**: Number of function parameters

### Thresholds

| Metric          | Low  | Medium | High   | Critical |
| --------------- | ---- | ------ | ------ | -------- |
| Cyclomatic      | < 5  | 5-10   | 10-20  | > 20     |
| Function Length | < 20 | 20-50  | 50-100 | > 100    |
| Nesting Depth   | < 3  | 3-4    | 4-6    | > 6      |
| Parameters      | < 3  | 3-5    | 5-7    | > 7      |

### Analysis Output

- **Complexity Score**: Overall codebase complexity
- **Hotspots**: Most complex files/functions
- **Refactoring Candidates**: Functions above threshold
- **Trend**: Complexity over time

## Example Output

```
🔍 Code Complexity Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Overall Complexity Score: 6.8/20 (Good)

📈 Distribution
  Low (< 5):      85% (120 functions)
  Medium (5-10):  12% (17 functions)
  High (10-20):   2% (3 functions)
  Critical (> 20): 1% (1 function)

🚨 High Complexity Functions

1. script/pre-pr-checklist.sh:check_quality()
   Complexity: 15
   Length: 85 lines
   Nesting: 4 levels
   ⚠️ Recommendation: Break into smaller functions

2. script/dependency-health-check.sh:analyze_dependencies()
   Complexity: 12
   Length: 120 lines
   Nesting: 5 levels
   ⚠️ Recommendation: Extract validation logic

3. script/setup-new-repo.sh:copy_configuration()
   Complexity: 11
   Length: 95 lines
   Nesting: 3 levels
   ℹ️ Note: Consider extracting file operations

⚠️ Critical Complexity (> 20)

1. script/changelog-generator.sh:generate_changelog()
   Complexity: 22
   Length: 180 lines
   Nesting: 6 levels
   🚨 URGENT: Refactor required
   Suggestions:
     - Extract commit grouping logic
     - Separate formatting functions
     - Reduce nesting with early returns

📉 Top 5 Most Complex Files

1. script/changelog-generator.sh: 15.3 avg complexity
2. script/dependency-health-check.sh: 10.8 avg complexity
3. script/pre-pr-checklist.sh: 9.5 avg complexity
4. script/branch-cleanup.sh: 8.2 avg complexity
5. script/setup-new-repo.sh: 7.1 avg complexity

💡 Recommendations

1. Refactor 1 critical function (> 20 complexity)
2. Review 3 high complexity functions (10-20)
3. Consider extracting common patterns
4. Apply early return pattern to reduce nesting
5. Break large functions into smaller units

✅ Maintainability Index: 78/100 (Good)
```

## Options

```bash
# Custom complexity threshold
/code-complexity-check --threshold 15

# Generate detailed report
/code-complexity-check --report complexity-report.md

# Check specific files
/code-complexity-check --files "script/*.sh"

# Fail CI if critical complexity found
/code-complexity-check --strict

# JSON output for CI
/code-complexity-check --json
```

## Complexity Calculation

Cyclomatic complexity is calculated as:

```
CC = E - N + 2P

Where:
  E = number of edges in control flow graph
  N = number of nodes
  P = number of connected components
```

## CI Integration

```yaml
# .github/workflows/complexity.yml
- name: Check Code Complexity
  run: |
    bash script/code-complexity-check.sh --threshold 15 --strict
```

## Refactoring Suggestions

For high complexity code:

1. **Extract Method**: Break large functions into smaller ones
2. **Early Returns**: Reduce nesting with guard clauses
3. **Strategy Pattern**: Replace complex conditionals
4. **State Machine**: For complex state transitions
5. **Configuration**: Move complexity to data

## Benefits

- 🔍 **Early Detection**: Catch complexity before it's a problem
- 📊 **Metrics**: Quantify code quality
- 🎯 **Targeted**: Focus refactoring efforts
- ⚡ **Prevention**: Enforce complexity limits in CI
- 📈 **Tracking**: Monitor complexity trends

## Implementation

This command is implemented in `script/code-complexity-check.sh`.

## Requirements

- Bash 4.0+
- Optional: `complexity-report` npm package for detailed analysis
- Shell scripts for analysis
