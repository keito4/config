#!/usr/bin/env node

/**
 * Example Integration Test
 * Demonstrates how to write integration tests for Claude configurations
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

// ANSI colors for output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m'
};

describe('Agent-Command Integration', () => {
  const agentsDir = path.join(__dirname, '../../agents');
  const commandsDir = path.join(__dirname, '../../commands');

  it('should have all agents referenced by pr command', () => {
    const prCommandPath = path.join(commandsDir, 'pr.md');
    const prContent = fs.readFileSync(prCommandPath, 'utf8');

    // Expected agents in pr command
    const expectedAgents = [
      'accessibility-design-validator',
      'concurrency-safety-analyzer',
      'ddd-architecture-validator',
      'docs-consistency-checker',
      'nuget-dependency-auditor',
      'performance-analyzer',
      'testability-coverage-analyzer'
    ];

    // Check each agent exists and is referenced
    for (const agent of expectedAgents) {
      const agentFile = path.join(agentsDir, `${agent}.md`);
      assert(fs.existsSync(agentFile), `Agent file ${agent}.md should exist`);
      assert(prContent.includes(agent), `PR command should reference ${agent}`);
    }
  });

  it('should have consistent agent naming', () => {
    const agents = fs.readdirSync(agentsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');

    for (const agentFile of agents) {
      const agentName = agentFile.replace('.md', '');
      const agentPath = path.join(agentsDir, agentFile);
      const content = fs.readFileSync(agentPath, 'utf8');

      // Check if agent has proper suffix
      const validSuffixes = ['validator', 'analyzer', 'checker', 'auditor', 'resolver'];
      const hasSuffix = validSuffixes.some(suffix => agentName.endsWith(suffix));
      
      if (!agentName.startsWith('issue-resolver')) {
        assert(hasSuffix, `Agent ${agentName} should end with a valid suffix (validator, analyzer, checker, auditor)`);
      }
    }
  });

  it('should have commands that reference existing agents', () => {
    const commands = fs.readdirSync(commandsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');
    
    const agents = fs.readdirSync(agentsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md')
      .map(file => file.replace('.md', ''));

    for (const commandFile of commands) {
      const commandPath = path.join(commandsDir, commandFile);
      const content = fs.readFileSync(commandPath, 'utf8');

      // Find all potential agent references
      const agentPattern = /[a-z-]+(?:-[a-z]+)*-(?:validator|analyzer|checker|auditor|resolver)/g;
      const matches = content.match(agentPattern) || [];

      for (const match of matches) {
        if (match !== commandFile.replace('.md', '')) {
          // Skip self-references and check if it's supposed to be an agent
          if (agents.some(agent => match.includes(agent.split('-').pop()))) {
            assert(
              agents.includes(match),
              `Command ${commandFile} references non-existent agent: ${match}`
            );
          }
        }
      }
    }
  });

  it('should have documentation for all configurations', () => {
    // Check main README exists
    assert(fs.existsSync(path.join(__dirname, '../../README.md')), 'Main Claude README should exist');
    
    // Check agent documentation
    assert(fs.existsSync(path.join(agentsDir, 'README.md')), 'Agent documentation should exist');
    
    // Check command documentation
    assert(fs.existsSync(path.join(commandsDir, 'README.md')), 'Command documentation should exist');
    
    // Check test documentation
    assert(fs.existsSync(path.join(__dirname, '../README.md')), 'Test documentation should exist');
  });

  it('should have valid cross-references in documentation', () => {
    const mainReadme = fs.readFileSync(path.join(__dirname, '../../README.md'), 'utf8');
    
    // Check that main README references subdocumentation
    assert(mainReadme.includes('agents/README.md'), 'Main README should reference agent docs');
    assert(mainReadme.includes('commands/README.md'), 'Main README should reference command docs');
    assert(mainReadme.includes('tests/README.md'), 'Main README should reference test docs');
  });
});

// Simple test runner for standalone execution
function describe(name, fn) {
  console.log(`\nTesting: ${name}`);
  const tests = [];
  global.it = (testName, testFn) => {
    tests.push({ name: testName, fn: testFn });
  };
  
  fn();
  
  let passed = 0;
  let failed = 0;
  
  for (const test of tests) {
    try {
      test.fn();
      console.log(`${colors.green}  ✓ ${test.name}${colors.reset}`);
      passed++;
    } catch (error) {
      console.log(`${colors.red}  ✗ ${test.name}: ${error.message}${colors.reset}`);
      failed++;
    }
  }
  
  console.log(`\nResults: ${passed} passed, ${failed} failed`);
  return failed === 0;
}

// Run if executed directly
if (require.main === module) {
  process.exit(describe('Agent-Command Integration', () => {
    const agentsDir = path.join(__dirname, '../../agents');
    const commandsDir = path.join(__dirname, '../../commands');

    it('should have all agents referenced by pr command', () => {
      const prCommandPath = path.join(commandsDir, 'pr.md');
      const prContent = fs.readFileSync(prCommandPath, 'utf8');

      // Expected agents in pr command
      const expectedAgents = [
        'accessibility-design-validator',
        'concurrency-safety-analyzer',
        'ddd-architecture-validator',
        'docs-consistency-checker',
        'nuget-dependency-auditor',
        'performance-analyzer',
        'testability-coverage-analyzer'
      ];

      // Check each agent exists and is referenced
      for (const agent of expectedAgents) {
        const agentFile = path.join(agentsDir, `${agent}.md`);
        assert(fs.existsSync(agentFile), `Agent file ${agent}.md should exist`);
        assert(prContent.includes(agent), `PR command should reference ${agent}`);
      }
    });

    it('should have consistent agent naming', () => {
      const agents = fs.readdirSync(agentsDir)
        .filter(file => file.endsWith('.md') && file !== 'README.md');

      for (const agentFile of agents) {
        const agentName = agentFile.replace('.md', '');
        
        // Check if agent has proper suffix
        const validSuffixes = ['validator', 'analyzer', 'checker', 'auditor', 'resolver'];
        const hasSuffix = validSuffixes.some(suffix => agentName.endsWith(suffix));
        
        if (!agentName.startsWith('issue-resolver')) {
          assert(hasSuffix, `Agent ${agentName} should end with a valid suffix (validator, analyzer, checker, auditor)`);
        }
      }
    });

    it('should have commands that reference existing agents', () => {
      const commands = fs.readdirSync(commandsDir)
        .filter(file => file.endsWith('.md') && file !== 'README.md');
      
      const agents = fs.readdirSync(agentsDir)
        .filter(file => file.endsWith('.md') && file !== 'README.md')
        .map(file => file.replace('.md', ''));

      for (const commandFile of commands) {
        const commandPath = path.join(commandsDir, commandFile);
        const content = fs.readFileSync(commandPath, 'utf8');

        // Find all potential agent references
        const agentPattern = /[a-z-]+(?:-[a-z]+)*-(?:validator|analyzer|checker|auditor|resolver)/g;
        const matches = content.match(agentPattern) || [];

        for (const match of matches) {
          if (match !== commandFile.replace('.md', '')) {
            // Skip self-references and check if it's supposed to be an agent
            if (agents.some(agent => match.includes(agent.split('-').pop()))) {
              assert(
                agents.includes(match),
                `Command ${commandFile} references non-existent agent: ${match}`
              );
            }
          }
        }
      }
    });

    it('should have documentation for all configurations', () => {
      // Check main README exists
      assert(fs.existsSync(path.join(__dirname, '../../README.md')), 'Main Claude README should exist');
      
      // Check agent documentation
      assert(fs.existsSync(path.join(agentsDir, 'README.md')), 'Agent documentation should exist');
      
      // Check command documentation
      assert(fs.existsSync(path.join(commandsDir, 'README.md')), 'Command documentation should exist');
      
      // Check test documentation
      assert(fs.existsSync(path.join(__dirname, '../README.md')), 'Test documentation should exist');
    });

    it('should have valid cross-references in documentation', () => {
      const mainReadme = fs.readFileSync(path.join(__dirname, '../../README.md'), 'utf8');
      
      // Check that main README references subdocumentation
      assert(mainReadme.includes('agents/README.md'), 'Main README should reference agent docs');
      assert(mainReadme.includes('commands/README.md'), 'Main README should reference command docs');
      assert(mainReadme.includes('tests/README.md'), 'Main README should reference test docs');
    });
  }) ? 0 : 1);
}