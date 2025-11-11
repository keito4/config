# Claude Automated Commands

This directory contains 14 pre-configured commands that provide automated workflows for common development tasks. These commands can be invoked directly by Claude or triggered automatically based on repository events and context.

## Command Categories

### Quality & Testing

#### `check-coverage.md`

**Purpose**: Analyzes test coverage reports and identifies areas needing attention
**Triggers**:

- Coverage drops below configured thresholds
- New code additions without corresponding tests
- Manual coverage analysis requests

#### `quality-check.md`

**Purpose**: Runs comprehensive code quality analysis including linting, formatting, and static analysis
**Triggers**:

- Pre-commit hooks
- Pull request creation
- Manual quality validation requests

#### `test-all.md`

**Purpose**: Executes complete test suite with proper reporting and failure analysis
**Triggers**:

- Major code changes
- Release preparation
- CI/CD pipeline integration

### Project Management

#### `init-project.md`

**Purpose**: Sets up new projects with standardized structure, tools, and configurations
**Features**:

- Dependency management setup
- CI/CD pipeline configuration
- Quality gate establishment
- Documentation templates

#### `issue-auto-resolve.md`

**Purpose**: Automated issue analysis and resolution using specialized agents
**Capabilities**:

- Issue classification and priority assessment
- Automated fix generation for common problems
- Multi-agent coordination for complex issues
- Solution validation and testing

#### `issue-create.md`

**Purpose**: Creates well-structured GitHub issues with proper templates and metadata
**Features**:

- Issue template selection
- Automatic labeling and assignment
- Related issue linking
- Priority and milestone setting

#### `issue-review.md`

**Purpose**: Reviews existing issues for completeness, priority, and actionability
**Functions**:

- Issue triage and categorization
- Duplicate detection and consolidation
- Priority reassessment
- Resolution pathway recommendations

### Pull Request Workflow

#### `pr.md`

**Purpose**: Comprehensive pull request analysis and preparation
**Features**:

- Automated PR description generation
- Change impact analysis
- Reviewer suggestion based on code ownership
- Merge readiness assessment

#### `review-feedback-processor.md`

**Purpose**: Processes and responds to code review feedback systematically
**Capabilities**:

- Feedback categorization and prioritization
- Automated response generation
- Code change suggestions
- Discussion thread management

### CI/CD & Maintenance

#### `fix-ci.md`

**Purpose**: Diagnoses and resolves continuous integration pipeline failures
**Diagnostic Areas**:

- Build failures and dependency issues
- Test failures and environment problems
- Deployment issues and configuration errors
- Performance bottlenecks and resource constraints

#### `security-review.md`

**Purpose**: Conducts comprehensive security analysis of code changes
**Security Checks**:

- Vulnerability scanning and assessment
- Authentication and authorization validation
- Data protection compliance
- Security best practices enforcement

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

#### `update-deps.md`

**Purpose**: Manages dependency updates with safety checks and compatibility validation
**Features**:

- Automated dependency analysis
- Breaking change detection
- Security vulnerability assessment
- Update strategy recommendations

### Integration & Automation

#### `n8n-mcp-setup.md`

**Purpose**: Configures n8n workflows with Model Context Protocol (MCP) integration
**Setup Areas**:

- Workflow automation configuration
- API endpoint integration
- Event trigger setup
- Data flow optimization

#### `commit.md`

**Purpose**: Ensures commit message quality and conventional commit compliance
**Validation**:

- Conventional commit format enforcement
- Commit message clarity and completeness
- Change scope validation
- Breaking change identification

## Command Usage

### Direct Invocation

Commands can be invoked directly in Claude interactions:

```
@claude run the quality-check command on the current branch
@claude execute check-coverage for the test suite
@claude use fix-ci to diagnose the build failure
@claude run issue-auto-resolve for issue #123
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
