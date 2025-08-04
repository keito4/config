# Claude Configuration Documentation

## Overview

This directory contains Claude AI assistant configurations for automated development workflows, code quality assurance, and architectural validation. The system consists of specialized agents and pre-configured commands designed to enforce development best practices and maintain code quality standards.

## Directory Structure

```
.claude/
├── agents/           # Specialized AI agents for various validation tasks
├── commands/         # Pre-configured commands for common workflows
├── docs/            # Comprehensive documentation
├── tests/           # Validation tests for agents and commands
├── settings.json    # Global Claude settings
└── README.md        # This file
```

## Quick Start

### Using Commands

Commands provide pre-configured workflows for common development tasks:

```bash
# Create a pull request with automated reviews
Claude, use the pr command to create a pull request

# Run quality checks on the codebase
Claude, execute the quality-check command

# Check test coverage
Claude, run the check-coverage command
```

### Using Agents

Agents are specialized validators for specific aspects of code quality:

```bash
# Validate architecture compliance
Claude, use the ddd-architecture-validator agent to review my changes

# Check accessibility standards
Claude, run the accessibility-design-validator on the UI components

# Analyze performance implications
Claude, use the performance-analyzer to evaluate the new feature
```

## Components

### Agents (13 total)

Agents are specialized AI personalities focused on specific validation domains:

#### Architecture & Design
- **[ddd-architecture-validator](agents/README.md#ddd-architecture-validator)** - Validates Domain-Driven Design, Clean Architecture, and Hexagonal Architecture compliance
- **[accessibility-design-validator](agents/README.md#accessibility-design-validator)** - Ensures WCAG compliance and accessible design patterns
- **[concurrency-safety-analyzer](agents/README.md#concurrency-safety-analyzer)** - Detects race conditions and thread safety issues

#### Quality & Testing
- **[testability-coverage-analyzer](agents/README.md#testability-coverage-analyzer)** - Analyzes test coverage and testability metrics
- **[performance-analyzer](agents/README.md#performance-analyzer)** - Identifies performance bottlenecks and optimization opportunities
- **[docs-consistency-checker](agents/README.md#docs-consistency-checker)** - Validates documentation completeness and consistency

#### Dependencies & Security
- **[nuget-dependency-auditor](agents/README.md#nuget-dependency-auditor)** - Audits NuGet packages for vulnerabilities and updates

#### Issue Resolution Specialists
- **[issue-resolver-orchestrator](agents/README.md#issue-resolver-orchestrator)** - Coordinates multi-agent issue resolution
- **[issue-resolver-code-quality](agents/README.md#issue-resolver-code-quality)** - Focuses on code quality improvements
- **[issue-resolver-dependencies](agents/README.md#issue-resolver-dependencies)** - Resolves dependency-related issues
- **[issue-resolver-documentation](agents/README.md#issue-resolver-documentation)** - Handles documentation tasks
- **[issue-resolver-security](agents/README.md#issue-resolver-security)** - Addresses security vulnerabilities
- **[issue-resolver-test-coverage](agents/README.md#issue-resolver-test-coverage)** - Improves test coverage

### Commands (11 total)

Commands are pre-configured workflows that automate common development tasks:

#### Development Workflow
- **[pr](commands/README.md#pr)** - Create pull requests with multi-agent review
- **[pr-create](commands/README.md#pr-create)** - Simplified PR creation
- **[init-project](commands/README.md#init-project)** - Initialize new projects with best practices

#### Quality Assurance
- **[quality-check](commands/README.md#quality-check)** - Run comprehensive quality checks
- **[check-coverage](commands/README.md#check-coverage)** - Analyze test coverage metrics
- **[test-all](commands/README.md#test-all)** - Execute all test suites

#### Issue Management
- **[issue-create](commands/README.md#issue-create)** - Create detailed GitHub issues
- **[issue-review](commands/README.md#issue-review)** - Review and triage issues

#### Maintenance
- **[fix-ci](commands/README.md#fix-ci)** - Troubleshoot CI/CD failures
- **[update-deps](commands/README.md#update-deps)** - Update project dependencies
- **[security-review](commands/README.md#security-review)** - Perform security audits

## Configuration

### Global Settings

The `settings.json` file contains global Claude configuration:

```json
{
  "model": "claude-3-opus-20240229",
  "temperature": 0.7,
  "max_tokens": 4096,
  "validation": {
    "strict_mode": true,
    "auto_review": true
  }
}
```

### Local Settings

Create `settings.local.json` for project-specific overrides (gitignored by default).

## Testing

### Running Tests

```bash
# Run all validation tests
npm run test:claude

# Test specific agent
npm run test:claude:agent -- ddd-architecture-validator

# Test specific command
npm run test:claude:command -- pr

# Validate configurations
npm run validate:claude
```

### Test Coverage

All agents and commands have comprehensive test coverage including:
- Configuration validation
- Input/output testing
- Integration scenarios
- Error handling

## Best Practices

### When to Use Agents

Use specialized agents when you need:
- Deep analysis of specific code aspects
- Architectural compliance validation
- Security or performance audits
- Comprehensive documentation review

### When to Use Commands

Use pre-configured commands for:
- Standard workflows (PR creation, testing)
- Quick quality checks
- Automated issue management
- Dependency updates

### Combining Agents and Commands

Many commands internally use multiple agents. For example:
- `pr` command uses 7 different agents for comprehensive review
- `quality-check` combines architecture, testing, and documentation agents
- `security-review` uses security and dependency agents

## Integration with Development Workflow

### Git Hooks

Integrate Claude validations with git hooks:

```bash
# Pre-commit hook
.claude/hooks/pre-commit.sh

# Pre-push hook
.claude/hooks/pre-push.sh
```

### CI/CD Pipeline

Add Claude validations to your CI/CD:

```yaml
# GitHub Actions example
- name: Claude Quality Check
  run: |
    claude run quality-check
    claude run test-all
```

### VS Code Integration

Use the Claude VS Code extension for real-time validation:
1. Install the Claude extension
2. Configure with `.claude/settings.json`
3. Enable real-time validation in settings

## Troubleshooting

### Common Issues

1. **Agent not responding**: Check agent configuration syntax
2. **Command failing**: Verify all required parameters are provided
3. **Validation errors**: Review the specific agent's requirements

### Debug Mode

Enable debug mode for detailed logging:

```bash
export CLAUDE_DEBUG=true
claude run <command>
```

### Support

- [Report Issues](https://github.com/keito4/config/issues)
- [Documentation](https://github.com/keito4/config/wiki/Claude-Configuration)
- [Community Support](https://github.com/keito4/config/discussions)

## Contributing

### Adding New Agents

1. Create agent configuration in `.claude/agents/`
2. Add comprehensive documentation
3. Include test cases in `.claude/tests/agents/`
4. Update this README

### Adding New Commands

1. Create command configuration in `.claude/commands/`
2. Document usage and parameters
3. Add integration tests
4. Update command index

## License

This configuration is part of the main project and follows the same license terms.