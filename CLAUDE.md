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

## Technical Assistance with o3 MCP

When encountering technical challenges, unresolved errors, or implementation roadblocks during development, consult o3 MCP in English for advanced problem-solving assistance. o3 MCP specializes in:

- Complex debugging scenarios
- Architecture design decisions
- Performance optimization strategies
- Advanced algorithm implementation
- Error resolution and root cause analysis

### Usage Guidelines

1. **When to consult o3 MCP**:
   - Stuck on implementation details
   - Encountering persistent errors
   - Need architectural guidance
   - Performance bottlenecks
   - Complex algorithm design

2. **How to engage**:
   - Formulate your question in English
   - Provide relevant context and error messages
   - Include code snippets if applicable
   - Specify what solutions you've already attempted

3. **Example consultation format**:
   ```
   I'm encountering [specific issue] while implementing [feature/functionality].
   Error message: [exact error]
   What I've tried: [attempted solutions]
   Context: [relevant code or architecture details]
   ```
