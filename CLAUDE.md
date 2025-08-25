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

The `.claude/agents/` directory contains 13 specialized AI agents organized into categories:

### Architecture & Code Quality

- **DDD Architecture Validator**: Domain-Driven Design and Clean Architecture validation
- **Performance Analyzer**: C#/.NET performance analysis and optimization recommendations
- **Concurrency Safety Analyzer**: Async/await patterns and thread safety review
- **Testability Coverage Analyzer**: Test coverage analysis and improvement suggestions

### Documentation & Consistency

- **Documentation Consistency Checker**: README, ADR, XML comments, and OpenAPI spec validation
- **Accessibility Design Validator**: WCAG compliance and frontend design consistency

### Dependencies & Security

- **NuGet Dependency Auditor**: Package licensing, maintenance, and architectural alignment

### Issue Resolution Workflow

- **Issue Resolver Orchestrator**: Multi-agent coordination for complex issues
- **Issue Resolver Code Quality**: Automated code quality analysis and improvements
- **Issue Resolver Dependencies**: Dependency management and conflict resolution
- **Issue Resolver Documentation**: Documentation generation and maintenance
- **Issue Resolver Security**: Security analysis and vulnerability resolution
- **Issue Resolver Test Coverage**: Test coverage analysis and recommendations

For detailed information about each agent, see [.claude/agents/README.md](.claude/agents/README.md).

## Automated Commands

The `.claude/commands/` directory provides 14 pre-configured commands organized by category:

### Quality & Testing

- **Check Coverage**: Test coverage analysis and reporting
- **Quality Check**: Comprehensive code quality validation
- **Test All**: Complete test suite execution with reporting

### Project Management

- **Init Project**: Standardized project setup and configuration
- **Issue Auto Resolve**: Automated issue analysis and resolution
- **Issue Create**: Well-structured GitHub issue creation
- **Issue Review**: Issue triage and quality assessment

### Pull Request Workflow

- **PR**: Comprehensive pull request analysis and preparation
- **Review Feedback Processor**: Systematic code review feedback handling

### CI/CD & Maintenance

- **Fix CI**: CI/CD pipeline failure diagnosis and resolution
- **Security Review**: Comprehensive security analysis of changes
- **Update Dependencies**: Safe dependency updates with compatibility validation

### Integration & Automation

- **N8N MCP Setup**: n8n workflow automation with MCP integration
- **Commit**: Conventional commit compliance and message quality

For detailed information about each command, see [.claude/commands/README.md](.claude/commands/README.md).

## GitHub Actions Integration

The repository includes comprehensive automated workflows for continuous integration and AI-assisted development:

### CI/CD Pipelines

- **CI Pipeline** (`.github/workflows/ci.yml`): Code quality validation with linting, formatting, testing, and building
- **DevContainer Build** (`.github/workflows/docker-image.yml`): Automated container image building with semantic versioning and multi-platform support

### AI-Assisted Development

- **Claude Code Integration** (`.github/workflows/claude.yml`): Automatic AI assistance triggered by `@claude` mentions in issues, PRs, and comments

### Features

- **Conventional Commits**: Automated versioning based on commit message patterns
- **Quality Gates**: Enforced code standards and automated feedback
- **Container Registry**: Published DevContainer images at `ghcr.io/keito4/config-base`
- **Semantic Releases**: Automatic GitHub releases with generated release notes

For detailed workflow documentation, see [.github/workflows/README.md](.github/workflows/README.md).

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

## Gemini CLI Integration

This repository supports integration with Google's Gemini AI through the Gemini CLI tool, providing an alternative AI assistant for development tasks.

### Features

- **Code Generation**: Generate code snippets and complete implementations
- **Code Review**: AI-powered code review and suggestions
- **Documentation**: Automatic documentation generation
- **Debugging Assistance**: Help with error analysis and debugging
- **Multi-Model Support**: Access to Gemini Pro, Gemini Ultra, and other models

### Installation

1. **Install Gemini CLI**:

   ```bash
   npm install -g @google/generative-ai-cli
   # or
   pip install google-generativeai-cli
   ```

2. **Configure API Key**:
   ```bash
   export GEMINI_API_KEY="your-api-key-here"
   # or add to your shell profile
   echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
   ```

### Usage

1. **Basic Commands**:

   ```bash
   # Generate code
   gemini generate "Create a REST API endpoint for user authentication"

   # Review code
   gemini review path/to/file.js

   # Explain code
   gemini explain path/to/complex-function.py

   # Debug error
   gemini debug "TypeError: Cannot read property 'x' of undefined"
   ```

2. **Integration with Development Workflow**:

   ```bash
   # Use with git hooks
   gemini review --pre-commit

   # CI/CD integration
   gemini analyze --output=report.json

   # Documentation generation
   gemini docs --format=markdown src/
   ```

3. **Model Selection**:
   ```bash
   # Use specific model
   gemini --model=gemini-pro generate "Complex algorithm implementation"
   gemini --model=gemini-ultra review src/
   ```

### Configuration Options

Create a `.geminirc` file in the project root (copy from `.geminirc.example`):

```json
{
  "defaultModel": "gemini-1.5-pro",
  "models": {
    "gemini-1.5-pro": { "temperature": 0.7, "maxTokens": 8192 },
    "gemini-1.5-flash": { "temperature": 0.5, "maxTokens": 4096 }
  },
  "contexts": {
    "development": { "model": "gemini-1.5-pro", "temperature": 0.5 },
    "review": { "model": "gemini-1.5-flash", "temperature": 0.3 },
    "testing": { "model": "gemini-1.5-pro", "temperature": 0.3 },
    "documentation": { "model": "gemini-1.5-flash", "temperature": 0.4 }
  }
}
```

#### Available Models

- **gemini-1.5-pro**: Latest and most capable model with 8K token context
- **gemini-1.5-flash**: Fast and efficient model for quick tasks
- **gemini-pro**: Standard model for general use
- **gemini-pro-vision**: Multi-modal model for image analysis

#### Context-Based Usage

```bash
# Use specific context for different tasks
gemini generate --context=development "Create a REST API"
gemini review --context=review src/main.js
gemini test --context=testing src/functions.js
gemini docs --context=documentation src/
```

### Best Practices

1. **Complementary Usage**: Use Gemini CLI alongside Claude for diverse perspectives
2. **Model Selection**: Choose appropriate models based on task complexity
3. **Context Management**: Provide clear context and examples for better results
4. **Security**: Never expose API keys in code or version control
5. **Rate Limiting**: Be aware of API rate limits and quotas

### Comparison with Claude

| Feature          | Claude               | Gemini              |
| ---------------- | -------------------- | ------------------- |
| Code Generation  | ✅ Comprehensive     | ✅ Fast iteration   |
| Context Window   | Large                | Variable by model   |
| Language Support | All major languages  | All major languages |
| Integration      | MCP Protocol         | REST API            |
| Specialization   | Development workflow | Multi-purpose       |

### Troubleshooting

- **API Key Issues**: Ensure `GEMINI_API_KEY` is properly set
- **Rate Limits**: Implement exponential backoff for API calls
- **Model Availability**: Check regional availability of specific models
- **Network Issues**: Configure proxy settings if behind corporate firewall
