# GitHub Actions Workflows

This document provides comprehensive documentation for the automated workflows in the `.github/workflows/` directory. These workflows provide continuous integration, AI-assisted development, and automated deployment capabilities.

## Workflow Overview

### CI/CD Pipelines

#### `ci.yml` - CI Pipeline
**Purpose**: Automated code quality validation with linting, formatting, testing, and building  
**Triggers**: 
- Pull requests to any branch
- Push to `main` or `master` branches

**Quality Gates**:
- **Linting**: ESLint validation with error blocking
- **Formatting**: Prettier formatting checks  
- **Testing**: Complete test suite execution
- **Building**: Build validation and artifact generation
- **Configuration**: Custom validation scripts

**Technology Stack**:
- Node.js 20 with npm caching
- Ubuntu latest runner environment
- Automated dependency installation

#### `docker-image.yml` - DevContainer Build
**Purpose**: Automated container image building with semantic versioning and multi-platform support  
**Triggers**:
- Push to `main` branch
- Manual workflow dispatch

**Features**:
- **Semantic Versioning**: Automated version detection based on commit messages
- **Multi-platform Support**: Linux AMD64 and ARM64 architectures
- **Container Registry**: Published to `ghcr.io/keito4/config-base`
- **Build Caching**: Registry-based caching for faster builds
- **Artifact Generation**: Tool version documentation export

**Container Features**:
- Consistent development environment across platforms
- Pre-configured development tools and dependencies
- Integrated Claude Code configuration

#### `manual-release.yml` - Manual Release
**Purpose**: On-demand release creation with flexible versioning options  
**Triggers**: Manual workflow dispatch with parameters

**Version Options**:
- **Semantic Types**: patch, minor, major
- **Custom Versions**: Specific version numbers (e.g., 1.2.3)
- **Fallback Logic**: Automatic version calculation if semantic-release fails

**Release Process**:
- Multi-platform container image building
- GitHub release creation with automated release notes
- Git tag creation and publishing
- Container registry updates

### AI-Assisted Development

#### `claude.yml` - Claude Code Integration
**Purpose**: Automatic AI assistance triggered by `@claude` mentions in issues, PRs, and comments  
**Triggers**:
- Issue comments containing `@claude`
- PR review comments containing `@claude`
- PR reviews containing `@claude`
- New issues with `@claude` in title or body

**Permissions**:
- **Contents**: Repository content access for code analysis
- **Issues**: Issue creation, modification, and commenting
- **Pull Requests**: PR creation, modification, and commenting

**Security**:
- Uses official Anthropic Claude Code action (`anthropics/claude-code-action@beta`)
- Secure API key management through GitHub Secrets
- Limited tool access (`Bash` tools only)

## Development Quality Standards

### Automated Quality Gates

The CI pipeline enforces organization-wide quality standards:

#### Code Quality
- **Linting**: ESLint with error-level blocking
- **Formatting**: Prettier with auto-fix validation
- **Testing**: Jest test suite with coverage reporting
- **Building**: Successful compilation and asset generation

#### Validation Steps
1. **Dependency Installation**: npm ci for reproducible installs
2. **Lint Check**: ESLint validation with configurable rules
3. **Format Check**: Prettier formatting consistency
4. **Test Execution**: Complete test suite with coverage
5. **Build Process**: Production build validation
6. **Configuration Validation**: Custom script validation

### Container Image Standards

#### Multi-Platform Support
- **AMD64**: Standard x86_64 architecture
- **ARM64**: Apple Silicon and ARM server support
- **Base Configuration**: Ubuntu with development tools

#### Version Management
- **Semantic Versioning**: Automated version detection
- **Tag Strategy**: `latest` and version-specific tags
- **Cache Strategy**: Registry-based for build optimization
- **Release Notes**: Automated generation from commit history

## Integration with Development Workflow

### Pull Request Process

1. **Automated Validation**: CI pipeline runs on PR creation
2. **Quality Gates**: All checks must pass for merge eligibility
3. **AI Assistance**: Mention `@claude` for automated code review and assistance
4. **Manual Review**: Human review required alongside automated checks

### Release Process

#### Automatic Releases
- Triggered by pushes to `main` branch
- Semantic versioning based on conventional commits
- Container image building and publishing
- GitHub release creation with notes

#### Manual Releases
- Workflow dispatch for immediate releases
- Flexible versioning options (patch/minor/major/custom)
- Emergency release capabilities
- Container image updates

### AI-Assisted Development

#### Claude Code Capabilities
- **Issue Analysis**: Automated issue triage and resolution suggestions
- **Code Review**: Comprehensive pull request analysis
- **Documentation**: Automated documentation updates and consistency checks
- **Quality Assurance**: Architecture validation and best practices enforcement

#### Usage Patterns
```
@claude review this PR for performance issues
@claude help implement this feature request
@claude update documentation based on recent changes
@claude analyze this issue and suggest solutions
```

## Configuration Management

### Workflow Configuration Files

#### Environment Variables
- `ANTHROPIC_API_KEY`: Claude Code API authentication
- `GITHUB_TOKEN`: GitHub API access for workflow operations

#### Repository Secrets
- Secure storage of API keys and tokens
- Automatic injection into workflow contexts
- Access control through GitHub permissions

### Quality Thresholds

#### CI Pipeline
- **Test Coverage**: Configurable thresholds in jest.config.js
- **Lint Rules**: Defined in .eslintrc.js
- **Format Rules**: Configured in .prettierrc
- **Build Targets**: Specified in package.json scripts

#### Container Build
- **Platform Targets**: linux/amd64, linux/arm64
- **Cache Strategy**: Registry-based with maximum cache duration
- **Tool Versions**: Documented and exported in artifacts

## Troubleshooting

### CI Pipeline Issues

#### Common Problems
1. **Lint Failures**: Review ESLint configuration and fix code issues
2. **Format Issues**: Run `npm run format` to auto-fix Prettier issues
3. **Test Failures**: Check test files and fix broken tests
4. **Build Errors**: Review build scripts and dependency issues

#### Debugging Steps
1. Check workflow run logs in GitHub Actions tab
2. Review specific step failures and error messages
3. Run commands locally to reproduce issues
4. Update dependencies if version conflicts exist

### Container Build Issues

#### Common Problems
1. **Build Timeouts**: Review Dockerfile complexity and dependency installation
2. **Platform Issues**: Check multi-platform compatibility
3. **Registry Access**: Verify permissions and authentication
4. **Cache Problems**: Clear registry cache or disable caching temporarily

#### Resolution Steps
1. Review Docker build logs for specific errors
2. Test Dockerfile changes locally before pushing
3. Verify registry permissions and token access
4. Check semantic-release configuration for version detection

### Claude Code Issues

#### Common Problems
1. **No Response**: Check trigger conditions and `@claude` mention formatting
2. **Permission Errors**: Verify workflow permissions and API key configuration
3. **Timeout Issues**: Large repositories may require longer processing times
4. **Tool Restrictions**: Limited to allowed tools (currently Bash only)

#### Support Resources
1. Check Claude Code action logs in workflow runs
2. Review trigger conditions in claude.yml workflow
3. Verify API key configuration in repository secrets
4. Consult Claude Code documentation for usage patterns

## Best Practices

### For Development Teams

#### CI/CD Usage
- **Commit Frequently**: Small, focused commits for easier CI debugging
- **Test Locally**: Run lint, format, and test commands before pushing
- **Monitor Builds**: Address CI failures promptly to avoid blocking teammates
- **Use Conventional Commits**: Enable semantic versioning and automated releases

#### Claude Code Usage
- **Be Specific**: Provide context and specific requests for better AI assistance
- **Use Appropriately**: Leverage AI for code review, documentation, and complex analysis
- **Provide Feedback**: Report issues and suggest improvements for AI responses
- **Understand Limitations**: AI assistance complements but doesn't replace human judgment

### For Project Maintainers

#### Workflow Management
- **Monitor Performance**: Track workflow execution times and success rates
- **Update Dependencies**: Keep action versions and tool dependencies current
- **Review Configurations**: Regularly audit quality thresholds and rules
- **Document Changes**: Update this documentation when modifying workflows

#### Security Considerations
- **Protect Secrets**: Use GitHub Secrets for sensitive information
- **Review Permissions**: Limit workflow permissions to minimum required
- **Monitor Access**: Track who can trigger workflows and access secrets
- **Update Regularly**: Keep actions and dependencies updated for security patches

## Future Enhancements

### Planned Improvements
- **Enhanced Testing**: Add E2E and integration testing workflows
- **Security Scanning**: Implement SAST and dependency vulnerability scanning
- **Performance Monitoring**: Add build time and resource usage tracking
- **Documentation Automation**: Expand automated documentation generation
- **Multi-Environment**: Add staging and production deployment workflows

### Integration Opportunities
- **Slack/Teams**: Notification integration for workflow events
- **Jira/Linear**: Issue tracking integration
- **SonarCloud**: Code quality and security analysis
- **Dependabot**: Automated dependency updates with CI validation

For additional configuration options and advanced usage patterns, see the main [CLAUDE.md](../CLAUDE.md) documentation and the [.claude/](../.claude/) configuration directory.