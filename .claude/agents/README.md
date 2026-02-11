# Claude Specialized Agents

This directory contains 11 specialized AI agents designed to provide comprehensive code analysis, quality assurance, and development assistance. Each agent is optimized for specific aspects of software development and can be invoked proactively or on-demand.

## Agent Categories

### DevOps & CI/CD

#### `act-local-ci-manager.md`

**Purpose**: Manages local CI pipeline execution using act (GitHub Actions local runner)
**Use Cases**:

- Setting up act configuration for testing GitHub Actions workflows locally
- Configuring Docker environment for act execution
- Managing secrets and environment variables for local testing
- Running full CI pipeline validation before pushing code
- Debugging workflow failures locally
- Integrating act with development workflows (pre-commit hooks, VS Code tasks)

### E2E Testing (Playwright)

#### `playwright-test-generator.md`

**Purpose**: Automatically generates Playwright E2E tests by observing browser interactions
**Use Cases**:

- Creating new E2E tests by navigating and interacting with web applications
- Converting manual test cases to automated Playwright tests
- Generating regression tests for existing features
- Recording user flows and generating corresponding test code

#### `playwright-test-healer.md`

**Purpose**: Debugs and fixes failing Playwright E2E tests
**Use Cases**:

- Diagnosing test failures due to selector changes
- Fixing timing issues and race conditions
- Updating tests after application UI changes
- Resolving assertion failures and state mismatches

#### `playwright-test-planner.md`

**Purpose**: Creates comprehensive E2E test plans for web applications
**Use Cases**:

- Planning E2E testing for new features
- Auditing existing test coverage gaps
- Creating structured regression test suites
- Mapping user journeys and edge cases

### Documentation & Consistency

#### `docs-consistency-checker.md`

**Purpose**: Ensures documentation consistency across README, ADR, XML comments, and OpenAPI specs
**Use Cases**:

- Pull requests modifying documentation files
- Public API changes with Swagger/OpenAPI specs
- PR descriptions shorter than 200 characters
- Verifying Why/What/How/Risk structure compliance

### Issue Resolution Workflow

#### `issue-resolver-orchestrator.md`

**Purpose**: Coordinates multi-agent issue resolution workflow with specialized sub-agents
**Use Cases**:

- Complex issues requiring multiple types of analysis
- Coordinated responses across different domains
- Workflow management for large-scale changes
- Priority assessment and task delegation

#### `issue-resolver-code-quality.md`

**Purpose**: Automated code quality analysis and improvement suggestions
**Use Cases**:

- Code quality violations and technical debt
- Static analysis results interpretation
- Best practices enforcement
- Refactoring recommendations

#### `issue-resolver-dependencies.md`

**Purpose**: Comprehensive dependency management and conflict resolution
**Use Cases**:

- Dependency conflicts and version mismatches
- Security vulnerability assessments
- Package upgrade strategies
- License compliance issues

#### `issue-resolver-documentation.md`

**Purpose**: Documentation generation, maintenance, and consistency enforcement
**Use Cases**:

- Missing or outdated documentation
- API documentation generation
- README and wiki maintenance
- Documentation structure improvements

#### `issue-resolver-security.md`

**Purpose**: Automated security analysis and vulnerability resolution
**Use Cases**:

- Security vulnerability identification
- Code security best practices
- Authentication and authorization issues
- Data protection compliance

#### `issue-resolver-test-coverage.md`

**Purpose**: Test coverage analysis and improvement suggestions
**Use Cases**:

- Low test coverage identification
- Test scenario gap analysis
- Test quality improvements
- Coverage report interpretation

## Agent Invocation

### Proactive Invocation

Agents are automatically invoked by Claude Code based on context and code changes:

- **CI/CD managers** trigger on workflow configuration changes
- **Security agents** engage for authentication/authorization code
- **Documentation agents** respond to API or documentation changes
- **Issue resolvers** activate based on issue type and complexity

### Manual Invocation

You can explicitly request specific agents in Claude interactions:

```
@claude please use the issue-resolver-security agent to analyze this vulnerability
@claude invoke the docs-consistency-checker for this documentation update
@claude run the act-local-ci-manager to test these workflow changes
```

## Configuration

### Agent Settings

Agent behavior is configured through:

- `.claude/settings.json`: Global agent preferences
- Repository-specific configurations in `CLAUDE.md`
- Project-specific overrides in individual files

### Quality Thresholds

Agents enforce quality standards defined in `.claude/CLAUDE.md`:

- **Test Coverage**: 70%+ line coverage requirement
- **Performance**: Response time and resource usage thresholds
- **Security**: Critical vulnerability blocking
- **Documentation**: Completeness and consistency requirements

## Integration with Development Workflow

### Pull Request Reviews

Agents automatically participate in PR reviews when:

- Changes match agent specialization triggers
- Explicit agent mentions in PR descriptions
- Quality thresholds are at risk of being violated

### Issue Resolution

Agents contribute to issue resolution through:

- **Automated analysis** of reported problems
- **Solution recommendations** based on best practices
- **Implementation guidance** for fixes
- **Testing strategies** for validation

### Continuous Improvement

Agents contribute to long-term code quality through:

- **Technical debt identification** and prioritization
- **Architecture evolution** recommendations
- **Performance optimization** opportunities
- **Security posture** improvements

## Best Practices

### For Developers

- **Understand agent triggers** to anticipate automated feedback
- **Use specific agent names** when requesting particular types of analysis
- **Provide context** in PR descriptions to help agents understand intent
- **Address agent feedback** as part of the development process

### For Teams

- **Configure quality thresholds** appropriate for your project
- **Customize agent behavior** based on technology stack
- **Monitor agent effectiveness** and adjust configurations
- **Train team members** on agent capabilities and usage

### For Maintainers

- **Keep agent definitions updated** with evolving best practices
- **Monitor agent performance** and effectiveness
- **Gather feedback** from development teams
- **Refine triggers and thresholds** based on experience

## Troubleshooting

### Agent Not Triggering

If an agent doesn't activate when expected:

1. **Check trigger conditions** in the agent definition file
2. **Verify file patterns** match your changes
3. **Review repository configuration** in `CLAUDE.md`
4. **Manually invoke** the agent to test functionality

### Inconsistent Results

If agent analysis seems inconsistent:

1. **Review context provided** in the request
2. **Check for configuration conflicts** between settings files
3. **Verify agent version** and update if necessary
4. **Provide more specific guidance** in the request

### Performance Issues

If agents are slow or timing out:

1. **Reduce scope** of analysis by being more specific
2. **Check repository size** and exclude unnecessary files
3. **Review agent complexity** and simplify if needed
4. **Monitor API usage** and rate limits

For additional support and customization options, see the main [CLAUDE.md](../CLAUDE.md) documentation.
