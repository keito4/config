# Claude Specialized Agents

This directory contains 13 specialized AI agents designed to provide comprehensive code analysis, quality assurance, and development assistance. Each agent is optimized for specific aspects of software development and can be invoked proactively or on-demand.

## Agent Categories

### Architecture & Code Quality

#### `ddd-architecture-validator.md`
**Purpose**: Validates adherence to Domain-Driven Design, Clean Architecture, and Hexagonal Architecture principles
**Use Cases**:
- Review pull requests affecting domain models or architecture layers
- Adding new entities, services, or use cases
- Assessing boundary contexts and aggregate consistency
- Quantifying technical debt

#### `performance-analyzer.md`
**Purpose**: Analyzes performance implications of code changes, particularly for C#/.NET applications
**Use Cases**:
- PRs with 50+ lines of algorithm changes
- Database query additions or modifications
- Loop processing improvements
- LINQ, EF Core, or async I/O pattern optimization

#### `concurrency-safety-analyzer.md`
**Purpose**: Reviews async/await patterns, thread safety, and concurrency issues in C# code
**Use Cases**:
- Code using async/await, locks, or threading primitives
- Pull requests with asynchronous processing changes
- Thread safety validation and deadlock prevention
- Cancellation token propagation analysis

#### `testability-coverage-analyzer.md`
**Purpose**: Evaluates testability and test coverage of new or modified code
**Use Cases**:
- Changes involving 100+ lines or public API modifications
- Dependency injection analysis
- Missing test scenario identification
- Coverage reports below 80% threshold

### Documentation & Consistency

#### `docs-consistency-checker.md`
**Purpose**: Ensures documentation consistency across README, ADR, XML comments, and OpenAPI specs
**Use Cases**:
- Pull requests modifying documentation files
- Public API changes with Swagger/OpenAPI specs
- PR descriptions shorter than 200 characters
- Verifying Why/What/How/Risk structure compliance

#### `accessibility-design-validator.md`
**Purpose**: Validates accessibility compliance and design consistency in frontend code
**Use Cases**:
- HTML/Razor/Blazor/React component changes
- WCAG compliance verification
- ARIA attributes and semantic HTML validation
- Color contrast and keyboard navigation checks
- Figma specification adherence

### Dependencies & Security

#### `nuget-dependency-auditor.md`
**Purpose**: Audits NuGet dependencies for licensing, maintenance, and architectural alignment
**Use Cases**:
- Pull requests modifying `*.csproj` files
- NuGet package additions, updates, or removals
- Licensing compliance verification
- Package maintenance status assessment

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
- **Architecture validators** trigger on domain model changes
- **Performance analyzers** activate for algorithmic changes
- **Security agents** engage for authentication/authorization code
- **Documentation agents** respond to API or documentation changes

### Manual Invocation
You can explicitly request specific agents in Claude interactions:
```
@claude please use the performance-analyzer agent to review this optimization
@claude invoke the ddd-architecture-validator for this domain model change
@claude run the accessibility-design-validator on these UI components
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