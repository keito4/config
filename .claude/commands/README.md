# Claude Automated Commands

This directory contains pre-configured commands that provide automated workflows for common development tasks. These commands can be invoked directly by Claude or triggered automatically based on repository events and context.

## Available Commands

### Maintenance

#### `repo-maintenance.md`

**Purpose**: Comprehensive repository maintenance - run all health checks and updates
**Features**:

- Environment health checks (container, DevContainer version, Claude Code)
- CI/CD setup checks (team protection, Husky, pre-PR checklist)
- Repository cleanup (branches, git gc)
- New feature discovery from config repository

**Usage**:

```
/repo-maintenance                    # Full maintenance
/repo-maintenance --mode quick       # Quick check (no updates)
/repo-maintenance --mode check-only  # Read-only checks
/repo-maintenance --skip security    # Skip specific category
/repo-maintenance --create-pr        # Create PR for changes
```

**Modes**:

| Mode       | Description                        |
| ---------- | ---------------------------------- |
| full       | Run all updates and checks         |
| quick      | Important checks only (no updates) |
| check-only | Read-only status checks            |

### Git Workflow

#### `git-sync.md`

**Purpose**: Provides comprehensive Git synchronization and branch management workflows
**Features**:

- Branch synchronization with upstream
- Conflict resolution guidance
- Git workflow automation
- Repository state validation

### Code Analysis

#### `similarity-analysis.md`

**Purpose**: Analyze code similarity in the repository to detect duplicate functions and patterns
**Features**:

- AST-based code similarity detection (not just text matching)
- Configurable similarity threshold
- Detailed refactoring recommendations
- Support for TypeScript/JavaScript codebases

**Usage**:

```
/similarity-analysis
/similarity-analysis path=src threshold=0.9
```

#### `code-complexity-check.md`

**Purpose**: Analyze code complexity and identify refactoring candidates
**Features**:

- Cyclomatic complexity analysis
- Function length and nesting depth detection
- Complexity thresholds (low/medium/high/critical)
- Refactoring recommendations
- CI integration with strict mode

**Usage**:

```
/code-complexity-check
/code-complexity-check --threshold 15
/code-complexity-check --strict
```

### Quality & Testing

#### `pre-pr-checklist.md`

**Purpose**: Automate comprehensive checks before creating a pull request
**Features**:

- Sequential quality checks (lint, format, test, etc.)
- PR size estimation and labeling
- Linked issues verification
- Branch status validation
- Merge conflict detection

**Usage**:

```
/pre-pr-checklist
/pre-pr-checklist --skip-tests
/pre-pr-checklist --verbose
```

#### `test-coverage-trend.md`

**Purpose**: Track and visualize test coverage trends over time
**Features**:

- Historical coverage tracking
- Trend analysis with ASCII graphs
- Threshold alerts (70% coverage)
- Per-file coverage breakdown
- CSV export for external analysis

**Usage**:

```
/test-coverage-trend
/test-coverage-trend --days 30
/test-coverage-trend --graph
```

### Security

#### `dependency-health-check.md`

**Purpose**: Comprehensive dependency health analysis
**Features**:

- npm package updates detection
- Security vulnerability scanning (`npm audit`)
- Deprecated package identification
- License compliance checking
- Health score calculation

**Usage**:

```
/dependency-health-check
/dependency-health-check --strict
/dependency-health-check --json
```

#### `security-credential-scan.md`

**Purpose**: Scan repository for hardcoded credentials and secrets
**Features**:

- API key, token, and password detection
- Private key and certificate scanning
- .env file validation
- False positive reduction
- Auto-fix capabilities

**Usage**:

```
/security-credential-scan
/security-credential-scan --fix
/security-credential-scan --strict
```

### Development Environment

#### `setup-husky.md`

**Purpose**: Configures Husky Git hooks for automated code quality enforcement
**Features**:

- Pre-commit hook setup
- Commit message validation
- Code quality gate enforcement
- Development workflow integration

#### `setup-ci.md`

**Purpose**: Setup comprehensive CI/CD workflows for your repository
**Features**:

- Project type auto-detection (Next.js, Node.js, Terraform, Monorepo)
- Gap analysis comparing current vs recommended CI configuration
- Multi-level setup (minimal, standard, comprehensive)
- Security scanning, E2E tests, and Claude Code Review integration

**Usage**:

```
/setup-ci                           # Auto-detect and recommend
/setup-ci --type nextjs             # Specify project type
/setup-ci --level comprehensive     # Full CI/CD setup
/setup-ci --dry-run                 # Preview changes only
```

**Levels**:

| Level         | Features                                            |
| ------------- | --------------------------------------------------- |
| minimal       | Lint + Build                                        |
| standard      | Lint + Test + Build + Security Audit                |
| comprehensive | All + E2E + CodeQL + Claude Review + Scheduled Scan |

#### `container-health.md`

**Purpose**: Verify DevContainer environment health and configuration
**Features**:

- Tool availability verification
- Version checking (Node.js, npm, Claude Code)
- Configuration validation
- System resource monitoring
- Auto-fix capabilities

**Usage**:

```
/container-health
/container-health --fix
/container-health --verbose
```

#### `setup-new-repo.md`

**Purpose**: Bootstrap a new repository with this configuration
**Features**:

- DevContainer setup
- Git configuration (commitlint, Husky)
- GitHub Actions workflows
- Development tools (ESLint, Prettier, Jest)
- Documentation templates

**Usage**:

```
/setup-new-repo /path/to/new/repo
/setup-new-repo --minimal
/setup-new-repo --no-devcontainer
```

### Repository Management

#### `branch-cleanup.md`

**Purpose**: Clean up merged and stale branches
**Features**:

- Merged branch detection and deletion
- Stale branch identification (30+ days)
- Protected branch exclusion
- Interactive confirmation
- Remote branch cleanup support

**Usage**:

```
/branch-cleanup
/branch-cleanup --dry-run
/branch-cleanup --remote
```

#### `changelog-generator.md`

**Purpose**: Generate CHANGELOG from Conventional Commits history
**Features**:

- Automatic commit grouping by type
- GitHub commit and PR links
- Breaking changes highlighting
- Version detection
- Keep a Changelog format

**Usage**:

```
/changelog-generator
/changelog-generator --since v1.0.0
/changelog-generator --contributors
```

#### `setup-team-protection.md`

**Purpose**: Setup GitHub repository protection rules for team development
**Features**:

- Branch protection (no direct push, required reviews)
- Required status checks (CI passing)
- Repository settings (squash merge, auto-delete branches)
- Security features (Dependabot, vulnerability alerts)
- Configurable reviewer count and enforcement

**Usage**:

```
/setup-team-protection
/setup-team-protection --reviewers 2
/setup-team-protection owner/repo --dry-run
```

## Additional Commands

For a comprehensive set of automated development commands, see the `.codex/prompts/` directory which contains 11 specialized prompts for:

- **Security Analysis**: Next.js security checks, dependency scanning, configuration auditing
- **Code Refactoring**: Decoupling, deduplication, reorganization, simplification
- **Git Operations**: Advanced Git workflows and synchronization

## Command Usage

### Direct Invocation

Commands can be invoked directly in Claude interactions:

```
@claude run git-sync to synchronize the current branch
@claude execute setup-husky to configure Git hooks
```

For additional commands available in `.codex/prompts/`:

```
@claude use next-security-check for comprehensive security analysis
@claude run refactor:decouple to improve code organization
@claude execute next-security:deps-scan for dependency vulnerability scanning
```

### Automatic Triggers

Commands are automatically triggered by:

- **Repository Events**: Push, PR creation, issue updates
- **Quality Thresholds**: Coverage drops, lint failures, security issues
- **Time-based Triggers**: Scheduled maintenance, dependency updates
- **Context Patterns**: Specific file changes, error patterns, user actions

### Workflow Integration

Commands integrate with development workflows through:

- **GitHub Actions**: Automated execution in CI/CD pipelines
- **Git Hooks**: Pre-commit, pre-push, and post-merge execution
- **IDE Integration**: Direct invocation from development environments
- **Slack/Teams**: Notification-driven execution

## Command Configuration

### Global Settings

Command behavior is configured in:

- `.claude/settings.json`: Global command preferences and thresholds
- `.claude/CLAUDE.md`: Quality standards and workflow requirements
- Repository-specific overrides in individual command files

### Environment Variables

Commands support customization through environment variables:

- `CLAUDE_COVERAGE_THRESHOLD`: Test coverage requirements
- `CLAUDE_SECURITY_LEVEL`: Security analysis strictness
- `CLAUDE_CI_TIMEOUT`: CI operation timeout limits
- `CLAUDE_REVIEWER_COUNT`: Required reviewer count for PRs

### Quality Gates

Commands enforce quality standards through:

- **Coverage Requirements**: 70%+ line coverage for all repositories
- **Security Standards**: Critical vulnerability blocking
- **Performance Thresholds**: Response time and resource usage limits
- **Documentation Standards**: Completeness and consistency requirements

## Best Practices

### For Development Teams

#### Command Usage

- **Use specific commands** for targeted analysis and fixes
- **Combine commands** for comprehensive workflows
- **Monitor command results** and act on recommendations
- **Customize thresholds** based on project requirements

#### Integration Strategies

- **Incorporate in CI/CD** for automated quality assurance
- **Use in code reviews** for consistent feedback
- **Schedule regular maintenance** commands for proactive management
- **Train team members** on command capabilities and usage

### For Project Maintainers

#### Configuration Management

- **Set appropriate thresholds** for quality gates
- **Customize command behavior** for technology stack
- **Monitor command performance** and effectiveness
- **Update configurations** based on team feedback

#### Workflow Optimization

- **Identify bottlenecks** in development processes
- **Automate repetitive tasks** with command workflows
- **Measure improvement** in code quality and velocity
- **Refine triggers** based on usage patterns

## Advanced Usage

### Command Chaining

Commands can be chained for complex workflows:

```
@claude run quality-check followed by test-all, then create a PR if all pass
@claude execute issue-auto-resolve, update dependencies, and run security-review
```

### Conditional Execution

Commands support conditional execution based on context:

```
@claude run fix-ci only if tests are failing
@claude execute security-review if changes affect authentication code
@claude run check-coverage if new code was added
```

### Custom Workflows

Create custom workflows by combining commands:

```yaml
# Example: Release Preparation Workflow
- quality-check
- test-all
- check-coverage
- security-review
- update-deps
- pr (with release template)
```

## Monitoring and Analytics

### Command Performance

Monitor command effectiveness through:

- **Execution time** and resource usage
- **Success rates** and failure patterns
- **Code quality improvements** over time
- **Developer productivity** metrics

### Quality Trends

Track quality improvements through:

- **Coverage trend** analysis
- **Security vulnerability** reduction
- **CI/CD reliability** improvements
- **Issue resolution time** reduction

## Troubleshooting

### Command Failures

If commands fail or produce unexpected results:

1. **Check prerequisites** (dependencies, permissions, environment)
2. **Review configuration** (settings, thresholds, environment variables)
3. **Examine logs** for error messages and stack traces
4. **Test manually** with reduced scope or simplified inputs
5. **Update command definitions** if necessary

### Performance Issues

If commands are slow or timing out:

1. **Review scope** and reduce if necessary
2. **Check resource availability** (memory, CPU, network)
3. **Optimize thresholds** and filters
4. **Consider parallel execution** for independent operations
5. **Monitor API rate limits** and usage

### Integration Problems

If commands don't integrate properly with workflows:

1. **Verify trigger configurations** and event handling
2. **Check permissions** and access controls
3. **Review environment variables** and context passing
4. **Test isolated execution** before workflow integration
5. **Update integration configurations** as needed

For detailed configuration and customization options, see the main [CLAUDE.md](../CLAUDE.md) documentation.
