# Claude Configuration

## Development Quality Standards

This repository implements comprehensive development quality standards and AI-assisted workflows. See `.claude/CLAUDE.md` for detailed guidelines including:

### Code Quality Requirements

- **Test-Driven Development (TDD)**: Red → Green → Refactor methodology with 70%+ line coverage requirement
- **Static Quality Gates**: Automated linting, formatting, security analysis, and license checking
- **Git Workflow**: Conventional commits, branch naming conventions, and pull request requirements

### AI Prompt Design Guidelines

- Structured approach for requirements definition, implementation, and bug reporting
- Clear separation between requirements gathering and code generation phases
- Emphasis on test-first development practices

### Definition of Ready/Done Criteria

- **Ready**: Acceptance criteria defined, dependencies resolved
- **Done**: Quality gates passed, documentation updated, monitoring stable, release notes complete

## Slack Notifications

When completing tasks, Claude will automatically send a notification to Slack using the MCP Slack integration.

### Configuration

Claude is configured to send notifications to the Slack workspace when tasks are completed. This uses the MCP (Model Context Protocol) Slack integration.

## Specialized Agents

The `.claude/agents/` directory contains specialized AI agents for:

- Architecture validation (DDD, Clean Architecture, Hexagonal Architecture)
- Accessibility and design validation
- Concurrency safety analysis
- Documentation consistency checking
- NuGet dependency auditing
- Performance analysis
- Testability and coverage analysis

## Custom Commands

The `.claude/commands/` directory provides pre-configured commands for:

- Code coverage checking
- CI/CD troubleshooting
- Project initialization
- Pull request creation
- Quality checks
- Security reviews
- Test execution
- Dependency updates
