# Claude Configuration

> **Last verified**: 2026-02-02 - All AI hooks (Codex/Gemini review) operational

## Development Quality Standards

This repository implements comprehensive development quality standards and AI-assisted workflows including:

### Code Quality Requirements

- **Test-Driven Development (TDD)**: Red → Green → Refactor methodology with 70%+ line coverage requirement
- **Static Quality Gates**: Automated linting, formatting, security analysis, and license checking
- **Git Workflow**: Conventional commits, branch naming conventions, and pull request requirements
- **Release Types Required for Tooling Changes**: Commits that touch `.codex/**`, `.devcontainer/codex*`, `package*.json`, or `npm/global.json` must use release-triggering types (`feat` / `fix` / `perf` / `revert` / `docs`). commitlint blocks `chore`など非リリース型のメッセージを防止し、semantic-release の自動リリースと整合させます。

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

## Development Tools & Automation

This repository provides comprehensive development tooling through GitHub Actions workflows and automated scripts:

## GitHub Actions Integration

The repository includes comprehensive automated workflows for continuous integration and AI-assisted development:

### CI/CD Pipelines

- **CI Pipeline** (`.github/workflows/ci.yml`): Code quality validation with linting, formatting, testing, and building
- **DevContainer Build** (`.github/workflows/docker-image.yml`): Automated container image building with semantic versioning and multi-platform support
- **Library Auto-Update** (`.github/workflows/update-libraries.yml`): Scheduled execution of `npm run update:libs` that opens a pull request when dependencies or Codex/Claude tooling change

### AI-Assisted Development

- **Claude Code Integration** (`.github/workflows/claude.yml`): Automatic AI assistance triggered by `@claude` mentions in issues, PRs, and comments

### Features

- **Conventional Commits**: Automated versioning based on commit message patterns
- **Quality Gates**: Enforced code standards and automated feedback
- **Container Registry**: Published DevContainer images at `ghcr.io/keito4/config-base`
- **Semantic Releases**: Automatic GitHub releases with generated release notes

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
