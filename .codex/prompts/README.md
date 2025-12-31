# Codex Automated Prompts

This directory contains 12 pre-configured prompts that provide automated workflows for common development tasks. These prompts can be invoked directly by Codex CLI or triggered automatically based on repository events and context.

## Command Categories

### Quality & Testing

### Security Analysis

#### `next-security-check.md`

**Purpose**: Comprehensive security review for Next.js applications
**Features**:

- Full security audit workflow
- Dependency vulnerability scanning
- Configuration security assessment
- Authorization flow validation

#### `next-security:deps-scan.md`

**Purpose**: Focused dependency vulnerability scanning for Next.js applications
**Features**:

- `npm audit --omit dev` execution for critical/high vulnerabilities
- Major package delay detection via `npm outdated`
- Security-related ESLint plugin version health checks
- Severity-based summary and response plan templates

#### `next-security:config-audit.md`

**Purpose**: Static audit of Next.js configuration files and build output
**Checks**:

- HSTS, CSP, Permissions-Policy, images.domains, environment variable exposure settings
- `next-safe-middleware` / `helmet` application status and matcher coverage
- `npm run lint / type-check / build` execution to collect warnings and configuration issues

#### `next-security:authz-review.md`

**Purpose**: Reviews authentication and authorization flows (RBAC/ABAC) in Next.js applications
**Highlights**:

- Verification that middleware/API routes/Server Actions enforce roles and permissions
- NextAuth/Lucia session configuration, Cookie, and CSRF countermeasures inventory
- Role × resource matrix and gap correction action reporting

### Code Refactoring

#### `refactor:decouple.md`

**Purpose**: Guides decoupling of tightly coupled code components
**Focus**:

- Component dependency reduction
- Interface-based design patterns
- Separation of concerns improvement

#### `refactor:dedupe.md`

**Purpose**: Eliminates code duplication and consolidates redundant implementations
**Focus**:

- Duplicate code identification
- Common utility extraction
- Single source of truth establishment

#### `refactor:reorganize.md`

**Purpose**: Improves code organization and project structure
**Focus**:

- File and directory restructuring
- Logical grouping of related functionality
- Import path optimization

#### `refactor:simplify.md`

**Purpose**: Simplifies complex code structures and reduces cognitive load
**Focus**:

- Complex logic breakdown
- Unnecessary abstraction removal
- Code readability improvement

#### `refactor:split.md`

**Purpose**: Splits large files or functions into smaller, manageable pieces
**Focus**:

- Large file decomposition
- Function size reduction
- Modular design promotion

### Development Environment

#### `git-sync.md`

**Purpose**: Provides comprehensive Git synchronization and branch management workflows
**Features**:

- Branch synchronization with upstream
- Conflict resolution guidance
- Git workflow automation
- Repository state validation

#### `setup-husky.md`

**Purpose**: Configures Husky Git hooks for automated code quality enforcement
**Features**:

- Pre-commit hook setup
- Commit message validation
- Code quality gate enforcement
- Development workflow integration

#### `setup-recommended-ci.md`

**Purpose**: Comprehensive guide for setting up recommended CI/CD pipeline based on Elu-co-jp organization standards
**Features**:

- Step-by-step CI/CD setup instructions
- Quality checks (lint, format, type-check, complexity)
- Unit & E2E testing with 70%+ coverage requirement
- Security scanning (dependency audit, SAST, license compliance)
- Claude Code Review integration
- GitHub Secrets configuration guide
- Husky Git hooks setup
- Troubleshooting guide

#### `next-security:deps-scan.md`

**Purpose**: Runs a least-privilege dependency vulnerability sweep for Next.js apps  
**Features**:

- `npm audit --omit dev`, `npm outdated` などでクリティカル/ハイの脆弱性と主要パッケージの遅延を検出
- セキュリティ関連 ESLint / lint プラグインのバージョン健全性を確認
- 重大度別のサマリーと対応計画テンプレを出力

#### `next-security:config-audit.md`

**Purpose**: Static audit of `next.config.*`, middleware, and build output  
**Checks**:

- HSTS, CSP, Permissions-Policy, images.domains、環境変数公開設定
- `next-safe-middleware` / `helmet` 適用状況と matcher の網羅性
- `npm run lint / type-check / build` を実行し、警告や設定不備を収集

#### `next-security:authz-review.md`

**Purpose**: Reviews authentication & authorization flows (RBAC/ABAC) in Next.js  
**Highlights**:

- Middleware / API Routes / Server Actions がロールや権限を強制しているか検証
- NextAuth/Lucia のセッション設定、Cookie、CSRF 対策の棚卸し
- ロール×リソース表とギャップ修正アクションをレポート化

## Command Usage

### Direct Invocation

Commands can be invoked directly in Claude interactions:

```
codex run next-security-check
codex execute refactor:decouple
codex run next-security:deps-scan
codex execute git-sync
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
