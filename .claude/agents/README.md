# Claude Agents Documentation

## Overview

Claude agents are specialized AI personalities designed to perform specific validation, analysis, and review tasks. Each agent has deep expertise in its domain and follows strict validation criteria.

## Agent Categories

### Architecture & Design Agents

#### ddd-architecture-validator

**Purpose**: Validates adherence to Domain-Driven Design, Clean Architecture, and Hexagonal Architecture principles.

**When to Use**:
- Adding new entities, services, or use cases
- Refactoring application layers
- Reviewing architectural changes
- Assessing technical debt

**Key Features**:
- Validates DDD tactical patterns (Entities, Value Objects, Aggregates)
- Ensures Clean Architecture layer boundaries
- Detects dependency rule violations
- Quantifies technical debt with scoring

**Usage Example**:
```
Claude, use the ddd-architecture-validator agent to review the new Order entity and OrderService
```

**Output Includes**:
- PlantUML component diagrams
- Violation severity ratings
- Improvement roadmap with phases
- Technical debt score

**Configuration**:
```yaml
name: ddd-architecture-validator
model: sonnet
validation_criteria:
  - domain_layer_purity
  - dependency_inversion
  - aggregate_boundaries
  - transactional_consistency
```

---

#### accessibility-design-validator

**Purpose**: Ensures WCAG 2.1 compliance and validates accessible design patterns.

**When to Use**:
- Reviewing UI components
- Validating form implementations
- Checking keyboard navigation
- Ensuring screen reader compatibility

**Key Features**:
- WCAG 2.1 Level AA/AAA validation
- Color contrast analysis
- Keyboard navigation verification
- ARIA attribute validation
- Screen reader compatibility checks

**Usage Example**:
```
Claude, run the accessibility-design-validator on the new checkout form
```

**Output Includes**:
- WCAG compliance report
- Specific violation locations
- Remediation recommendations
- Priority-ordered fixes

---

#### concurrency-safety-analyzer

**Purpose**: Detects race conditions, deadlocks, and thread safety issues.

**When to Use**:
- Implementing multi-threaded code
- Using async/await patterns
- Managing shared resources
- Reviewing concurrent data structures

**Key Features**:
- Race condition detection
- Deadlock analysis
- Thread-safe pattern validation
- Lock contention identification
- Async/await best practices

**Usage Example**:
```
Claude, analyze the payment processing service with the concurrency-safety-analyzer
```

**Output Includes**:
- Potential race conditions
- Deadlock scenarios
- Thread safety violations
- Suggested synchronization improvements

---

### Quality & Testing Agents

#### testability-coverage-analyzer

**Purpose**: Analyzes code testability and test coverage metrics.

**When to Use**:
- Evaluating test coverage
- Identifying untestable code
- Improving test quality
- Planning test strategies

**Key Features**:
- Line, branch, and path coverage analysis
- Testability score calculation
- Identifies hard-to-test patterns
- Suggests refactoring for testability
- Mock/stub requirement analysis

**Usage Example**:
```
Claude, use the testability-coverage-analyzer to evaluate the OrderService class
```

**Output Includes**:
- Coverage metrics breakdown
- Testability score (0-100)
- Untested critical paths
- Refactoring suggestions
- Test strategy recommendations

---

#### performance-analyzer

**Purpose**: Identifies performance bottlenecks and optimization opportunities.

**When to Use**:
- Optimizing slow operations
- Reviewing database queries
- Analyzing memory usage
- Evaluating algorithm efficiency

**Key Features**:
- O(n) complexity analysis
- Database query optimization
- Memory leak detection
- Caching opportunity identification
- Async operation optimization

**Usage Example**:
```
Claude, run the performance-analyzer on the product search functionality
```

**Output Includes**:
- Performance hotspots
- Complexity analysis
- Optimization recommendations
- Estimated performance gains
- Implementation priorities

---

#### docs-consistency-checker

**Purpose**: Validates documentation completeness, accuracy, and consistency.

**When to Use**:
- Reviewing API documentation
- Validating README files
- Checking inline comments
- Ensuring documentation standards

**Key Features**:
- API documentation completeness
- README section validation
- Code-documentation sync check
- Example code validation
- Terminology consistency

**Usage Example**:
```
Claude, check documentation consistency with the docs-consistency-checker
```

**Output Includes**:
- Missing documentation sections
- Outdated examples
- Inconsistent terminology
- Coverage percentage
- Priority fixes

---

### Dependencies & Security Agents

#### nuget-dependency-auditor

**Purpose**: Audits NuGet packages for vulnerabilities, updates, and licensing issues.

**When to Use**:
- Regular security audits
- Before major releases
- Dependency updates
- License compliance checks

**Key Features**:
- CVE vulnerability scanning
- Version update recommendations
- License compatibility checks
- Transitive dependency analysis
- Package deprecation warnings

**Usage Example**:
```
Claude, audit dependencies with the nuget-dependency-auditor
```

**Output Includes**:
- Security vulnerabilities (CVE list)
- Available updates
- License conflicts
- Deprecated packages
- Update priority matrix

---

### Issue Resolution Specialists

#### issue-resolver-orchestrator

**Purpose**: Coordinates multiple agents to comprehensively resolve complex issues.

**When to Use**:
- Complex multi-faceted issues
- Cross-cutting concerns
- Major feature implementations
- System-wide refactoring

**Key Features**:
- Multi-agent coordination
- Task decomposition
- Priority sequencing
- Conflict resolution
- Progress tracking

**Usage Example**:
```
Claude, use the issue-resolver-orchestrator for issue #123
```

**Output Includes**:
- Task breakdown
- Agent assignment matrix
- Execution timeline
- Consolidated recommendations
- Success metrics

---

#### issue-resolver-code-quality

**Purpose**: Focuses on improving code quality metrics and standards.

**When to Use**:
- Code smell remediation
- Refactoring initiatives
- Quality metric improvements
- Standards enforcement

**Key Features**:
- Code smell detection
- Cyclomatic complexity analysis
- Duplication identification
- SOLID principle validation
- Clean code recommendations

**Usage Example**:
```
Claude, improve code quality for the payment module using issue-resolver-code-quality
```

**Output Includes**:
- Quality metrics before/after
- Specific improvements
- Refactoring steps
- Risk assessment
- Time estimates

---

#### issue-resolver-dependencies

**Purpose**: Resolves dependency conflicts, updates, and compatibility issues.

**When to Use**:
- Dependency conflicts
- Version incompatibilities
- Package updates
- Breaking change migrations

**Key Features**:
- Conflict resolution strategies
- Version compatibility matrix
- Migration path planning
- Breaking change analysis
- Alternative package suggestions

**Usage Example**:
```
Claude, resolve dependency issues with issue-resolver-dependencies
```

**Output Includes**:
- Resolution strategies
- Migration steps
- Risk analysis
- Testing requirements
- Rollback plans

---

#### issue-resolver-documentation

**Purpose**: Creates, updates, and improves project documentation.

**When to Use**:
- Missing documentation
- Outdated guides
- API documentation needs
- User manual creation

**Key Features**:
- Documentation generation
- Structure recommendations
- Example code creation
- Diagram generation
- Style guide enforcement

**Usage Example**:
```
Claude, create documentation for the new API using issue-resolver-documentation
```

**Output Includes**:
- Documentation structure
- Generated content
- Code examples
- Diagrams
- Review checklist

---

#### issue-resolver-security

**Purpose**: Identifies and resolves security vulnerabilities.

**When to Use**:
- Security audits
- Vulnerability patches
- Compliance requirements
- Penetration test findings

**Key Features**:
- OWASP Top 10 scanning
- Security pattern validation
- Encryption verification
- Authentication/authorization review
- Input validation checks

**Usage Example**:
```
Claude, address security vulnerabilities with issue-resolver-security
```

**Output Includes**:
- Vulnerability assessment
- Severity ratings
- Remediation steps
- Security test cases
- Compliance checklist

---

#### issue-resolver-test-coverage

**Purpose**: Improves test coverage and test quality.

**When to Use**:
- Low coverage areas
- Critical path testing
- Test suite improvements
- TDD implementation

**Key Features**:
- Coverage gap analysis
- Test case generation
- Edge case identification
- Test quality metrics
- TDD workflow guidance

**Usage Example**:
```
Claude, improve test coverage for the order module using issue-resolver-test-coverage
```

**Output Includes**:
- Coverage improvement plan
- Generated test cases
- Priority test areas
- Quality metrics
- Execution timeline

## Agent Configuration

### Configuration Structure

Each agent configuration follows this structure:

```yaml
---
name: agent-name
description: Agent purpose and usage scenarios
model: claude-model-version
color: terminal-color
validation_level: strict|standard|lenient
timeout: 300 # seconds
---

[Agent prompt and instructions]
```

### Model Selection

- **opus**: Complex analysis, architecture validation
- **sonnet**: Standard validation, code review
- **haiku**: Quick checks, simple validations

### Validation Levels

- **strict**: Zero tolerance for violations
- **standard**: Balanced approach with warnings
- **lenient**: Informational, non-blocking

## Best Practices

### Agent Selection

1. **Single Responsibility**: Use one agent per specific concern
2. **Combine for Complexity**: Use orchestrator for multi-faceted issues
3. **Regular Audits**: Schedule periodic agent reviews
4. **Progressive Enhancement**: Start with critical agents, add more over time

### Integration Patterns

#### Pre-Commit Validation
```bash
# .git/hooks/pre-commit
claude run ddd-architecture-validator --staged
claude run testability-coverage-analyzer --staged
```

#### Pull Request Reviews
```yaml
# .github/workflows/pr-review.yml
- name: Architecture Review
  run: claude agent ddd-architecture-validator
- name: Security Check
  run: claude agent issue-resolver-security
```

#### Scheduled Audits
```yaml
# .github/workflows/weekly-audit.yml
schedule:
  - cron: '0 0 * * 0'
jobs:
  audit:
    steps:
      - run: claude agent nuget-dependency-auditor
      - run: claude agent performance-analyzer
```

## Customizing Agents

### Creating Custom Agents

1. Create configuration file in `.claude/agents/`
2. Define validation criteria
3. Add test cases
4. Document usage

### Extending Existing Agents

```yaml
# .claude/agents/custom-validator.md
---
name: custom-validator
extends: ddd-architecture-validator
additional_checks:
  - custom_business_rules
  - industry_compliance
---
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Agent timeout | Increase timeout in configuration |
| False positives | Adjust validation_level |
| Missing context | Provide more specific file paths |
| Conflicting recommendations | Use orchestrator agent |

### Debug Output

```bash
# Enable verbose logging
export CLAUDE_AGENT_DEBUG=true
claude agent <agent-name> --verbose
```

## Performance Considerations

### Agent Performance Metrics

| Agent | Avg. Runtime | Memory Usage | Complexity |
|-------|-------------|--------------|------------|
| ddd-architecture-validator | 30-60s | Medium | High |
| accessibility-design-validator | 15-30s | Low | Medium |
| concurrency-safety-analyzer | 45-90s | High | High |
| testability-coverage-analyzer | 20-40s | Medium | Medium |
| performance-analyzer | 60-120s | High | High |
| docs-consistency-checker | 10-20s | Low | Low |
| nuget-dependency-auditor | 20-40s | Medium | Medium |

### Optimization Tips

1. **Scope Limiting**: Target specific directories/files
2. **Parallel Execution**: Run independent agents concurrently
3. **Caching**: Enable result caching for repeated runs
4. **Incremental Analysis**: Analyze only changed files

## Related Documentation

- [Commands Documentation](../commands/README.md)
- [Testing Guide](../tests/README.md)
- [Main Claude README](../README.md)