# Claude Commands Documentation

## Overview

Claude commands are pre-configured workflows that automate common development tasks. They combine multiple operations, agents, and validations into single, easy-to-use commands.

## Command Categories

### Development Workflow Commands

#### pr

**Purpose**: Create a pull request with comprehensive multi-agent review.

**Features**:
- Automatic branch creation if on main
- File-by-file git add for security
- Multi-agent review (7 agents)
- Comprehensive quality validation

**Usage**:
```
Claude, use the pr command to create a pull request
```

**Process**:
1. Check current branch (create new if on main)
2. Stage changes file by file
3. Create commit with descriptive message
4. Run 7 validation agents:
   - accessibility-design-validator
   - concurrency-safety-analyzer
   - ddd-architecture-validator
   - docs-consistency-checker
   - nuget-dependency-auditor
   - performance-analyzer
   - testability-coverage-analyzer
5. Create pull request
6. Post review comments

**Configuration**:
```yaml
agents:
  - accessibility-design-validator
  - concurrency-safety-analyzer
  - ddd-architecture-validator
  - docs-consistency-checker
  - nuget-dependency-auditor
  - performance-analyzer
  - testability-coverage-analyzer
options:
  auto_branch: true
  security_check: true
  file_by_file_add: true
```

**Output**:
- PR URL
- Review summary from all agents
- Action items prioritized by severity

---

#### pr-create

**Purpose**: Simplified pull request creation without extensive reviews.

**Features**:
- Quick PR creation
- Basic validation only
- Suitable for small changes
- Fast execution

**Usage**:
```
Claude, execute pr-create for this hotfix
```

**Process**:
1. Stage all changes
2. Create commit
3. Push to remote
4. Create PR with template
5. Basic validation check

**When to Use**:
- Hotfixes
- Documentation updates
- Small bug fixes
- Non-critical changes

---

#### init-project

**Purpose**: Initialize new projects with best practices and standard structure.

**Features**:
- Project scaffolding
- Git initialization
- CI/CD setup
- Testing framework
- Documentation templates

**Usage**:
```
Claude, run init-project for a new TypeScript API
```

**Parameters**:
- `type`: Project type (api, web, library, cli)
- `language`: Programming language
- `framework`: Optional framework choice
- `features`: Additional features (docker, k8s, etc.)

**Process**:
1. Create project structure
2. Initialize git repository
3. Setup package manager
4. Configure linting and formatting
5. Create CI/CD pipelines
6. Add testing framework
7. Generate initial documentation
8. Create .claude configuration

**Output Structure**:
```
project/
├── src/
├── tests/
├── docs/
├── .github/workflows/
├── .claude/
├── .gitignore
├── README.md
├── package.json
└── tsconfig.json
```

---

### Quality Assurance Commands

#### quality-check

**Purpose**: Run comprehensive quality checks across the entire codebase.

**Features**:
- Multiple quality dimensions
- Parallel agent execution
- Consolidated reporting
- Action item generation

**Usage**:
```
Claude, perform a quality-check on the codebase
```

**Checks Performed**:
1. **Code Quality**
   - Linting violations
   - Code complexity
   - Duplication
   - SOLID principles
2. **Architecture**
   - Layer violations
   - Dependency issues
   - Pattern compliance
3. **Testing**
   - Coverage metrics
   - Test quality
   - Missing tests
4. **Documentation**
   - Completeness
   - Accuracy
   - Examples
5. **Security**
   - Vulnerabilities
   - Best practices
   - Input validation

**Output Format**:
```
Quality Check Report
====================
Overall Score: 85/100

✅ Passing (7)
⚠️ Warnings (3)
❌ Failures (1)

Detailed Findings:
[Category-wise breakdown]

Action Items:
1. [Critical] Fix security vulnerability in auth.js
2. [High] Improve test coverage (currently 65%)
3. [Medium] Update API documentation
```

---

#### check-coverage

**Purpose**: Analyze and report test coverage metrics.

**Features**:
- Line coverage analysis
- Branch coverage analysis
- Function coverage analysis
- Uncovered code identification
- Trend analysis

**Usage**:
```
Claude, check-coverage for the entire project
```

**Parameters**:
- `threshold`: Minimum coverage percentage (default: 70)
- `scope`: Files/directories to analyze
- `exclude`: Patterns to exclude
- `format`: Output format (text, html, json)

**Output**:
```
Test Coverage Report
===================
Overall Coverage: 78.5%

File Coverage:
✅ src/utils/index.js        95.2%
✅ src/services/auth.js      82.1%
⚠️ src/controllers/user.js   68.9%
❌ src/models/order.js       45.3%

Uncovered Lines:
- src/models/order.js: 23-45, 67-89
- src/controllers/user.js: 102-115

Recommendations:
1. Add tests for Order model validation
2. Cover error handling in UserController
3. Test edge cases in authentication flow
```

---

#### test-all

**Purpose**: Execute all test suites with comprehensive reporting.

**Features**:
- Unit test execution
- Integration test execution
- E2E test execution
- Performance test execution
- Parallel test running

**Usage**:
```
Claude, run test-all with verbose output
```

**Options**:
- `--parallel`: Run tests in parallel
- `--bail`: Stop on first failure
- `--watch`: Watch mode for development
- `--coverage`: Include coverage report
- `--filter`: Run specific test suites

**Process**:
1. Discover all test files
2. Group by test type
3. Execute in optimal order
4. Collect results
5. Generate report
6. Check against thresholds

**Output**:
```
Test Execution Summary
=====================
Total: 342 tests
Passed: 338
Failed: 3
Skipped: 1
Time: 45.2s

Failed Tests:
❌ OrderService > should handle payment failure
❌ UserAPI > should return 404 for unknown user
❌ E2E > checkout flow > should show error on timeout

Coverage: 81.2%
```

---

### Issue Management Commands

#### issue-create

**Purpose**: Create detailed, well-structured GitHub issues.

**Features**:
- Template selection
- Label assignment
- Milestone linking
- Automatic categorization
- Dependency tracking

**Usage**:
```
Claude, issue-create for the payment bug we discussed
```

**Templates**:
- Bug Report
- Feature Request
- Documentation
- Performance Issue
- Security Vulnerability
- Technical Debt

**Process**:
1. Gather issue details
2. Select appropriate template
3. Generate issue body
4. Assign labels
5. Link related issues
6. Create on GitHub
7. Return issue URL

**Example Output**:
```markdown
## Bug Report: Payment Processing Timeout

### Description
Payment processing fails with timeout after 30 seconds for orders over $1000

### Steps to Reproduce
1. Add items worth >$1000 to cart
2. Proceed to checkout
3. Enter payment details
4. Submit order

### Expected Behavior
Payment should process within 10 seconds

### Actual Behavior
Request times out after 30 seconds

### Environment
- Production
- Node.js 18.x
- Payment Service v2.3.1

### Priority: High
### Labels: bug, payment, performance
```

---

#### issue-review

**Purpose**: Review and triage GitHub issues with recommendations.

**Features**:
- Priority assessment
- Effort estimation
- Solution suggestions
- Duplicate detection
- Dependency analysis

**Usage**:
```
Claude, issue-review for all open issues
```

**Review Criteria**:
- Completeness of information
- Reproducibility
- Business impact
- Technical complexity
- Dependencies

**Output**:
```
Issue Review Summary
===================
Total Issues: 23
Reviewed: 23

Priority Breakdown:
🔴 Critical: 2
🟠 High: 5
🟡 Medium: 10
🟢 Low: 6

Recommendations:
1. #45 - Duplicate of #32, recommend closing
2. #51 - Needs more info, tagged 'needs-clarification'
3. #48 - Ready for development, assigned to sprint
4. #39 - Blocked by #38, updated dependencies

Suggested Sprint Planning:
- Sprint 1: #48, #42, #37
- Sprint 2: #51 (after clarification), #46
- Backlog: Remaining items
```

---

### Maintenance Commands

#### fix-ci

**Purpose**: Diagnose and fix CI/CD pipeline failures.

**Features**:
- Log analysis
- Common issue detection
- Automated fixes
- Configuration validation
- Retry logic

**Usage**:
```
Claude, fix-ci for the failing build
```

**Common Fixes**:
1. **Dependency Issues**
   - Clear cache
   - Update lock files
   - Fix version conflicts
2. **Test Failures**
   - Identify flaky tests
   - Fix timing issues
   - Update assertions
3. **Build Errors**
   - Fix compilation errors
   - Update build configs
   - Resolve path issues
4. **Environment Issues**
   - Update secrets
   - Fix permissions
   - Correct variables

**Process**:
1. Fetch recent CI logs
2. Identify failure patterns
3. Determine root cause
4. Apply appropriate fix
5. Trigger rebuild
6. Verify success

---

#### update-deps

**Purpose**: Update project dependencies safely with compatibility checks.

**Features**:
- Semantic versioning respect
- Breaking change detection
- Compatibility validation
- Security updates priority
- Rollback capability

**Usage**:
```
Claude, update-deps with security patches only
```

**Update Strategies**:
- `patch`: Bug fixes only (1.0.x)
- `minor`: New features (1.x.0)
- `major`: Breaking changes (x.0.0)
- `security`: Security updates only
- `latest`: All to latest versions

**Process**:
1. Analyze current dependencies
2. Check for updates
3. Identify breaking changes
4. Run compatibility tests
5. Update incrementally
6. Run test suite
7. Generate changelog

**Output**:
```
Dependency Update Report
=======================
Updates Applied: 12
Security Fixes: 3

Updated Packages:
✅ express: 4.17.1 → 4.18.2 (minor)
✅ lodash: 4.17.19 → 4.17.21 (security)
✅ jest: 27.0.0 → 29.0.0 (major - breaking)

Breaking Changes:
- jest: Config format changed, updated jest.config.js

All tests passing ✓
No compatibility issues detected ✓
```

---

#### security-review

**Purpose**: Perform comprehensive security audit of the codebase.

**Features**:
- Vulnerability scanning
- Dependency auditing
- Code pattern analysis
- OWASP compliance check
- Security best practices

**Usage**:
```
Claude, run security-review with OWASP Top 10 check
```

**Security Checks**:
1. **Dependencies**
   - Known CVEs
   - Outdated packages
   - License compliance
2. **Code Patterns**
   - SQL injection risks
   - XSS vulnerabilities
   - Insecure randomness
   - Hardcoded secrets
3. **Configuration**
   - HTTPS enforcement
   - CORS settings
   - CSP headers
   - Authentication config
4. **Infrastructure**
   - Container scanning
   - Secret management
   - Access controls

**Output Format**:
```
Security Review Report
=====================
Risk Level: MEDIUM

Vulnerabilities Found: 4
🔴 Critical: 0
🟠 High: 1
🟡 Medium: 2
🟢 Low: 1

Critical Findings:
1. [HIGH] SQL injection risk in user.js:45
   - Use parameterized queries
   - Severity: 8.5/10

2. [MEDIUM] Outdated dependency: axios@0.19.0
   - Has known vulnerability CVE-2021-3749
   - Update to 0.21.2 or higher

Recommendations:
1. Implement input validation middleware
2. Enable security headers
3. Update dependencies monthly
4. Add secret scanning to CI
```

## Command Configuration

### Configuration Structure

```yaml
# .claude/commands/command-name.md
name: command-name
description: Command purpose
requires:
  - git
  - npm
  - docker
agents:
  - agent1
  - agent2
parameters:
  param1:
    type: string
    required: true
    default: value
options:
  parallel: true
  timeout: 300
  retries: 3
```

### Parameter Types

- `string`: Text input
- `boolean`: True/false flag
- `number`: Numeric value
- `array`: List of values
- `enum`: Predefined options

### Execution Modes

- **Sequential**: Execute steps in order
- **Parallel**: Run independent steps simultaneously
- **Conditional**: Execute based on conditions
- **Interactive**: Request user input when needed

## Best Practices

### Command Selection

1. **Use Commands for Workflows**: Prefer commands for multi-step processes
2. **Use Agents for Analysis**: Use agents directly for specific analysis
3. **Combine Wisely**: Don't over-orchestrate simple tasks
4. **Cache Results**: Enable caching for expensive operations

### Performance Optimization

#### Parallel Execution
```yaml
# Run independent checks in parallel
quality-check:
  parallel:
    - lint
    - test
    - security-scan
```

#### Conditional Execution
```yaml
# Skip expensive checks on small changes
pr:
  conditions:
    - if: changes < 100 lines
      skip: [performance-analyzer]
```

#### Incremental Processing
```yaml
# Process only changed files
update-deps:
  incremental: true
  scope: changed
```

## Custom Commands

### Creating Custom Commands

1. Create command file in `.claude/commands/`
2. Define workflow steps
3. Specify required agents
4. Add parameter validation
5. Include error handling
6. Write documentation
7. Add tests

### Example Custom Command

```yaml
# .claude/commands/deploy-prod.md
---
name: deploy-prod
description: Deploy to production with validations
---

Steps:
1. Run quality-check
2. Execute test-all
3. Perform security-review
4. Build production bundle
5. Deploy to staging
6. Run smoke tests
7. Deploy to production
8. Verify deployment
9. Send notifications

Rollback on any failure
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Command not found | Check command name spelling |
| Parameter missing | Review required parameters |
| Agent failure | Check agent configuration |
| Timeout | Increase timeout setting |
| Permission denied | Verify access rights |

### Debug Mode

```bash
# Enable debug output
export CLAUDE_DEBUG=true
export CLAUDE_VERBOSE=true

# Run with debug flags
claude command --debug --verbose
```

### Logging

```bash
# View command logs
cat ~/.claude/logs/commands.log

# Stream logs in real-time
tail -f ~/.claude/logs/commands.log
```

## Integration Examples

### Git Hooks

```bash
#!/bin/bash
# .git/hooks/pre-push
claude run quality-check --fail-fast
claude run test-all --bail
```

### CI/CD Pipeline

```yaml
# .github/workflows/main.yml
jobs:
  validate:
    steps:
      - uses: actions/checkout@v3
      - name: Quality Check
        run: claude run quality-check
      - name: Security Review
        run: claude run security-review
      - name: Test Coverage
        run: claude run check-coverage --threshold 80
```

### VS Code Tasks

```json
// .vscode/tasks.json
{
  "tasks": [
    {
      "label": "Claude: Quality Check",
      "type": "shell",
      "command": "claude run quality-check",
      "problemMatcher": []
    },
    {
      "label": "Claude: Create PR",
      "type": "shell",
      "command": "claude run pr",
      "problemMatcher": []
    }
  ]
}
```

## Performance Metrics

### Command Execution Times

| Command | Avg. Time | Max Time | Complexity |
|---------|-----------|----------|------------|
| pr | 2-3 min | 5 min | High |
| pr-create | 30s | 1 min | Low |
| init-project | 1-2 min | 3 min | Medium |
| quality-check | 1-2 min | 4 min | High |
| check-coverage | 30-60s | 2 min | Medium |
| test-all | 1-5 min | 10 min | High |
| issue-create | 10-20s | 30s | Low |
| issue-review | 30-60s | 2 min | Medium |
| fix-ci | 1-3 min | 5 min | High |
| update-deps | 2-5 min | 10 min | High |
| security-review | 1-2 min | 3 min | Medium |

### Optimization Tips

1. **Use Caching**: Enable result caching for repeated runs
2. **Scope Commands**: Target specific files/directories
3. **Skip Unnecessary**: Use conditions to skip irrelevant checks
4. **Parallel When Possible**: Enable parallel execution
5. **Fail Fast**: Use --bail for quick feedback

## Related Documentation

- [Agents Documentation](../agents/README.md)
- [Testing Guide](../tests/README.md)
- [Main Claude README](../README.md)