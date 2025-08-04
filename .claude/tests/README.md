# Claude Configuration Tests

## Overview

This directory contains comprehensive validation tests for Claude agents and commands. The test suite ensures configuration integrity, validates cross-references, and maintains quality standards.

## Test Structure

```
tests/
├── validate-agents.js      # Agent configuration validator
├── validate-commands.js    # Command configuration validator
├── run-all-tests.js       # Main test runner
├── agents/                # Agent-specific tests
├── commands/              # Command-specific tests
├── integration/           # Integration tests
└── README.md             # This file
```

## Running Tests

### Quick Start

```bash
# Run all validation tests
npm run test:claude

# Run with verbose output
npm run test:claude -- --verbose

# Run specific test suite
npm run test:claude:agents
npm run test:claude:commands
```

### Individual Test Execution

```bash
# Validate all agents
node .claude/tests/validate-agents.js

# Validate all commands
node .claude/tests/validate-commands.js

# Run integration tests
node .claude/tests/run-all-tests.js
```

### Continuous Integration

```yaml
# GitHub Actions example
- name: Validate Claude Configuration
  run: |
    npm run test:claude
    if [ $? -ne 0 ]; then
      echo "Claude configuration validation failed"
      exit 1
    fi
```

## Test Categories

### Configuration Validation

#### Agent Validation

Tests for agent configurations include:

1. **Structure Validation**
   - YAML frontmatter presence and validity
   - Required fields (name, description, model)
   - Valid model selection
   - Color validation

2. **Content Validation**
   - Minimum prompt length
   - Required sections presence
   - Description quality
   - Usage examples

3. **Naming Convention**
   - File name matches agent name
   - Consistent naming patterns

4. **Cross-Reference Validation**
   - Referenced agents exist
   - No circular dependencies

Example test output:
```
🔍 Claude Agent Configuration Validator

Found 13 agent configuration files

Validating: ddd-architecture-validator.md
  ✓ Basic structure valid

Validating: accessibility-design-validator.md
  ✓ Basic structure valid

📊 Validation Summary
Total Agents: 13
Valid: 13
Invalid: 0

✅ All agent configurations are valid!
```

#### Command Validation

Tests for command configurations include:

1. **Content Validation**
   - Minimum content requirements
   - Command description presence
   - Error handling mentions

2. **Agent References**
   - Referenced agents exist
   - Agent availability check

3. **Security Checks**
   - File-by-file git operations
   - Credential protection

4. **Dependency Validation**
   - Command dependencies exist
   - No circular dependencies

5. **Usage Examples**
   - Example presence
   - Clear usage instructions

### Integration Tests

Integration tests validate the interaction between components:

1. **Agent-Command Integration**
   - Commands correctly invoke agents
   - Agent responses are handled properly
   - Error propagation works correctly

2. **Multi-Agent Orchestration**
   - Orchestrator coordinates agents properly
   - Results are aggregated correctly
   - Conflicts are resolved

3. **Workflow Tests**
   - Complete workflows execute successfully
   - State is maintained correctly
   - Rollback mechanisms work

### Performance Tests

Performance validation includes:

1. **Execution Time**
   - Agents complete within timeout
   - Commands meet performance SLAs
   - Parallel execution works

2. **Resource Usage**
   - Memory consumption stays within limits
   - CPU usage is reasonable
   - No memory leaks

## Test Coverage Requirements

### Minimum Coverage

- **Agents**: 100% configuration validation
- **Commands**: 100% configuration validation
- **Integration**: 80% critical path coverage
- **Performance**: Key scenarios covered

### Coverage Report

```bash
# Generate coverage report
npm run test:claude:coverage

# Example output
---------------------------|---------|----------|---------|---------|
File                       | % Stmts | % Branch | % Funcs | % Lines |
---------------------------|---------|----------|---------|---------|
All files                  |   95.5  |   92.3   |   98.0  |   95.5  |
 agents/                   |   98.0  |   95.0   |  100.0  |   98.0  |
 commands/                 |   96.5  |   93.0   |   98.5  |   96.5  |
 integration/              |   92.0  |   88.5   |   95.0  |   92.0  |
---------------------------|---------|----------|---------|---------|
```

## Writing Tests

### Adding Agent Tests

Create a test file in `tests/agents/`:

```javascript
// tests/agents/my-agent.test.js
const assert = require('assert');
const fs = require('fs');
const path = require('path');

describe('my-agent', () => {
  const agentPath = path.join(__dirname, '../../agents/my-agent.md');
  
  it('should have valid configuration', () => {
    const content = fs.readFileSync(agentPath, 'utf8');
    assert(content.includes('---'), 'Missing YAML frontmatter');
  });
  
  it('should have required sections', () => {
    const content = fs.readFileSync(agentPath, 'utf8');
    assert(content.includes('Responsibilities'), 'Missing Responsibilities section');
    assert(content.includes('Output'), 'Missing Output section');
  });
  
  it('should reference valid agents', () => {
    // Test agent references
  });
});
```

### Adding Command Tests

Create a test file in `tests/commands/`:

```javascript
// tests/commands/my-command.test.js
const assert = require('assert');
const fs = require('fs');
const path = require('path');

describe('my-command', () => {
  const commandPath = path.join(__dirname, '../../commands/my-command.md');
  
  it('should have valid structure', () => {
    const content = fs.readFileSync(commandPath, 'utf8');
    assert(content.length > 100, 'Command file too short');
  });
  
  it('should reference existing agents', () => {
    // Test agent references
  });
  
  it('should have usage examples', () => {
    const content = fs.readFileSync(commandPath, 'utf8');
    assert(content.includes('Usage') || content.includes('Example'), 
           'Missing usage examples');
  });
});
```

### Adding Integration Tests

Create integration tests in `tests/integration/`:

```javascript
// tests/integration/pr-workflow.test.js
describe('PR Workflow', () => {
  it('should execute complete PR workflow', async () => {
    // Test complete PR creation workflow
  });
  
  it('should handle errors gracefully', async () => {
    // Test error handling
  });
  
  it('should rollback on failure', async () => {
    // Test rollback mechanism
  });
});
```

## Validation Rules

### Agent Validation Rules

| Rule | Severity | Description |
|------|----------|-------------|
| Missing frontmatter | Error | YAML frontmatter is required |
| Invalid YAML | Error | YAML must be valid syntax |
| Missing name | Error | Agent name is required |
| Missing description | Error | Description is required |
| Invalid model | Warning | Model should be valid Claude model |
| Short description | Warning | Description should be >50 chars |
| Missing sections | Warning | Should have key sections |
| Name mismatch | Warning | Name should match filename |

### Command Validation Rules

| Rule | Severity | Description |
|------|----------|-------------|
| Empty file | Error | Command file cannot be empty |
| Too short | Warning | Should have substantial content |
| Unknown agent | Warning | Referenced agents should exist |
| No examples | Warning | Should include usage examples |
| No error handling | Warning | Should mention error handling |
| Circular dependency | Warning | Commands shouldn't have circular deps |

## Error Messages

### Common Error Messages

```
❌ Missing YAML frontmatter
   Fix: Add --- at the beginning of the file

❌ Invalid YAML syntax
   Fix: Check YAML formatting and indentation

❌ Agent prompt content is too short or missing
   Fix: Add detailed agent instructions after frontmatter

⚠️ Description seems too short
   Fix: Provide more detailed description (>50 chars)

⚠️ References unknown agent 'agent-name'
   Fix: Check agent name spelling or create missing agent

⚠️ Missing usage examples
   Fix: Add usage examples or documentation
```

## Continuous Improvement

### Test Metrics

Track these metrics over time:

1. **Configuration Validity**: % of valid configurations
2. **Test Coverage**: % of configurations with tests
3. **Cross-Reference Integrity**: % of valid references
4. **Documentation Quality**: Average quality score

### Quality Gates

Enforce these quality gates in CI/CD:

1. All configurations must be valid
2. No critical errors allowed
3. Warning count should decrease over time
4. Test coverage must be maintained

## Troubleshooting

### Debug Mode

Enable detailed output for debugging:

```bash
# Set debug environment variable
export CLAUDE_TEST_DEBUG=true

# Run tests with debug output
npm run test:claude -- --debug
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Tests not found | Check test file naming convention |
| False positives | Update validation rules |
| Slow execution | Run tests in parallel |
| Missing dependencies | Run `npm install` |

### Getting Help

1. Check test output for specific error messages
2. Review validation rules in test files
3. Enable debug mode for detailed information
4. Check GitHub issues for known problems

## Maintenance

### Regular Tasks

1. **Weekly**: Run full test suite
2. **Monthly**: Review and update validation rules
3. **Quarterly**: Analyze test metrics and trends
4. **Yearly**: Major test framework updates

### Adding New Validators

1. Identify validation need
2. Write validator function
3. Add to appropriate test file
4. Document validation rules
5. Test with sample configurations

## Related Documentation

- [Agents Documentation](../agents/README.md)
- [Commands Documentation](../commands/README.md)
- [Main Claude README](../README.md)