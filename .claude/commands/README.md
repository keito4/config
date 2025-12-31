# Claude Automated Commands

This directory contains pre-configured commands that provide automated workflows for common development tasks. These commands can be invoked directly by Claude or triggered automatically based on repository events and context. Additional automated commands are available in the `.codex/prompts/` directory.

## Available Commands

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

### Development Environment

#### `setup-husky.md`

**Purpose**: Configures Husky Git hooks for automated code quality enforcement
**Features**:

- Pre-commit hook setup
- Commit message validation
- Code quality gate enforcement
- Development workflow integration

#### `setup-team-protection.md`

**Purpose**: Configures GitHub repository protection for team development
**Features**:

- Branch protection rules (no direct push, required reviews)
- Required status checks (CI passing)
- Repository settings (squash merge, auto-delete branches)
- Security features (Dependabot, vulnerability alerts)

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
