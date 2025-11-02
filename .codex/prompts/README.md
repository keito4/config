# Codex CLI Prompts

This directory contains 2 pre-configured prompts that mirror selected Claude commands for use with Codex CLI. These prompts provide automated workflows for Git synchronization and Husky setup tasks, integrating with the broader configuration management system.

## Overview

The Codex CLI integration provides a desktop-native interface for configuration management tasks that complement the web-based Claude Code functionality. These prompts are specifically designed for local development workflows and can be invoked through the Codex CLI with desktop notification support.

## Available Prompts

### `git-sync.md`

**Purpose**: Automated Git repository synchronization and maintenance

**Features**:

- Branch synchronization with remote repositories
- Conflict detection and resolution guidance
- Commit history analysis and cleanup
- Remote repository health checks
- Automated merge and rebase operations

**Usage**:

```bash
codex run git-sync
```

### `setup-husky.md`

**Purpose**: Git hooks setup and configuration using Husky

**Features**:

- Automatic Husky installation and initialization
- Pre-commit and commit-msg hook configuration
- Integration with ESLint, Prettier, and commitlint
- Hook validation and testing
- Troubleshooting for common setup issues

**Usage**:

```bash
codex run setup-husky
```

## Codex CLI Configuration

The prompts are configured through the `.codex/config.toml` file which defines:

### MCP Server Integration

- **Playwright MCP**: Browser automation for testing and validation
- **o3 MCP**: Advanced AI reasoning for complex problem-solving
- **Desktop Notifications**: Audio notifications using system sounds

### Environment Configuration

```toml
[mcp_servers.o3]
command = "npx"
args = ["o3-search-mcp"]
env = {
  OPENAI_API_KEY = "",
  SEARCH_CONTEXT_SIZE = "medium",
  REASONING_EFFORT = "medium"
}
```

## Desktop Integration

### Notification System

Codex CLI provides desktop notifications for workflow completion:

```toml
notify = ["bash", "-lc", "afplay /System/Library/Sounds/Glass.aiff"]
```

### Workflow Integration

Prompts integrate with local development workflows through:

- **Terminal Integration**: Direct command line access
- **IDE Integration**: Can be triggered from development environments
- **File System Monitoring**: Automatic triggers based on file changes
- **Git Hook Integration**: Execution during Git lifecycle events

## Differences from Claude Code

While Claude Code provides comprehensive web-based AI assistance, Codex CLI offers:

### Local Execution

- **Offline Capability**: Works without internet for basic operations
- **File System Access**: Direct interaction with local files and repositories
- **System Integration**: Native OS notifications and tools

### Specialized Focus

- **Configuration Management**: Specialized for this repository's configuration tasks
- **Developer Tools**: Optimized for command-line and terminal workflows
- **Quick Operations**: Faster execution for routine maintenance tasks

### Complementary Usage

- **Use Claude Code for**: Complex analysis, code reviews, issue resolution, comprehensive documentation
- **Use Codex CLI for**: Quick Git operations, setup tasks, local configuration management

## Installation and Setup

### Prerequisites

1. **Install Codex CLI**: Follow installation instructions from Codex documentation
2. **Configure MCP Servers**: Ensure required MCP servers are available
3. **Set Environment Variables**: Configure API keys and settings as needed

### Configuration Steps

1. **Copy Configuration**:

   ```bash
   cp .codex/config.toml ~/.config/codex/config.toml
   ```

2. **Install MCP Dependencies**:

   ```bash
   npm install -g @playwright/mcp o3-search-mcp
   ```

3. **Set API Keys** (if using o3 MCP):
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   ```

## Best Practices

### For Daily Development

- **Use `git-sync`** for routine repository maintenance
- **Use `setup-husky`** when onboarding new team members
- **Combine with Claude Code** for complex problem-solving

### For Team Workflows

- **Standardize Configuration**: Ensure all team members use the same config.toml
- **Document Local Setup**: Include Codex CLI setup in onboarding documentation
- **Monitor Notifications**: Use desktop notifications to stay informed of workflow status

### For Maintenance

- **Keep Prompts Updated**: Regularly sync with Claude command updates
- **Test MCP Integration**: Verify MCP servers are working correctly
- **Update Dependencies**: Keep MCP packages and Codex CLI current

## Troubleshooting

### Codex CLI Issues

If Codex CLI fails to execute prompts:

1. **Check Installation**: Verify Codex CLI is properly installed and in PATH
2. **Validate Configuration**: Ensure config.toml is syntactically correct
3. **Test MCP Servers**: Verify MCP servers start and respond correctly
4. **Check Permissions**: Ensure file system access permissions are correct

### MCP Server Issues

If MCP servers fail to start or respond:

1. **Verify Installation**: Ensure MCP packages are installed globally
2. **Check API Keys**: Verify environment variables are set correctly
3. **Test Connectivity**: Check network access for cloud-based MCP servers
4. **Review Logs**: Check Codex CLI logs for detailed error messages

### Integration Issues

If prompts don't integrate properly with workflows:

1. **Verify File Paths**: Check that prompt files are in correct locations
2. **Test Execution**: Run prompts manually to verify functionality
3. **Check Dependencies**: Ensure required tools (Git, npm, etc.) are available
4. **Update Configuration**: Sync with latest configuration changes

## Relationship to Main Configuration

These Codex CLI prompts are part of the broader configuration management ecosystem:

- **Mirror Claude Commands**: Selected commands ported for local execution
- **Complement Web Interface**: Provide desktop alternative for common tasks
- **Maintain Consistency**: Use same quality standards and conventions
- **Support Workflows**: Integrate with existing Git workflows and CI/CD pipelines

For comprehensive development workflows, use both Claude Code (for complex analysis and issue resolution) and Codex CLI (for quick local operations and maintenance tasks).
