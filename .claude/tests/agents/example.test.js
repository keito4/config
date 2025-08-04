#!/usr/bin/env node

/**
 * Example Agent Test
 * Demonstrates how to write tests for Claude agents
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

describe('ddd-architecture-validator', () => {
  const agentPath = path.join(__dirname, '../../agents/ddd-architecture-validator.md');
  let content;

  beforeEach(() => {
    content = fs.readFileSync(agentPath, 'utf8');
  });

  it('should have valid YAML frontmatter', () => {
    assert(content.startsWith('---'), 'Missing YAML frontmatter');
    const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
    assert(yamlMatch, 'Invalid YAML frontmatter format');
  });

  it('should have required fields', () => {
    const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
    assert(yamlMatch[1].includes('name:'), 'Missing name field');
    assert(yamlMatch[1].includes('description:'), 'Missing description field');
    assert(yamlMatch[1].includes('model:'), 'Missing model field');
  });

  it('should have core responsibility sections', () => {
    assert(content.includes('Core Responsibilities'), 'Missing Core Responsibilities section');
    assert(content.includes('Analysis Process'), 'Missing Analysis Process section');
    assert(content.includes('Output Format'), 'Missing Output Format section');
  });

  it('should define validation criteria', () => {
    assert(content.includes('Validation Criteria'), 'Missing Validation Criteria section');
    assert(content.includes('Domain layer'), 'Should mention Domain layer');
    assert(content.includes('Application layer'), 'Should mention Application layer');
    assert(content.includes('Infrastructure layer'), 'Should mention Infrastructure layer');
  });

  it('should include PlantUML diagram template', () => {
    assert(content.includes('@startuml'), 'Missing PlantUML diagram start');
    assert(content.includes('@enduml'), 'Missing PlantUML diagram end');
  });

  it('should define red flags', () => {
    assert(content.includes('Red Flags'), 'Missing Red Flags section');
    assert(content.includes('Direct database access'), 'Should mention database access issues');
    assert(content.includes('Circular dependencies'), 'Should mention circular dependencies');
  });
});

// Simple test runner for standalone execution
function describe(name, fn) {
  console.log(`\nTesting: ${name}`);
  const tests = [];
  let setupFn = null;
  
  global.it = (testName, testFn) => {
    tests.push({ name: testName, fn: testFn });
  };
  global.beforeEach = (fn) => {
    setupFn = fn;
  };
  
  fn();
  
  let passed = 0;
  let failed = 0;
  
  for (const test of tests) {
    try {
      if (setupFn) setupFn();
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
  process.exit(describe('ddd-architecture-validator', () => {
    const agentPath = path.join(__dirname, '../../agents/ddd-architecture-validator.md');
    let content;

    beforeEach(() => {
      content = fs.readFileSync(agentPath, 'utf8');
    });

    it('should have valid YAML frontmatter', () => {
      assert(content.startsWith('---'), 'Missing YAML frontmatter');
      const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
      assert(yamlMatch, 'Invalid YAML frontmatter format');
    });

    it('should have required fields', () => {
      const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
      assert(yamlMatch[1].includes('name:'), 'Missing name field');
      assert(yamlMatch[1].includes('description:'), 'Missing description field');
      assert(yamlMatch[1].includes('model:'), 'Missing model field');
    });

    it('should have core responsibility sections', () => {
      assert(content.includes('Core Responsibilities'), 'Missing Core Responsibilities section');
      assert(content.includes('Analysis Process'), 'Missing Analysis Process section');
      assert(content.includes('Output Format'), 'Missing Output Format section');
    });

    it('should define validation criteria', () => {
      assert(content.includes('Validation Criteria'), 'Missing Validation Criteria section');
      assert(content.includes('Domain layer'), 'Should mention Domain layer');
      assert(content.includes('Application layer'), 'Should mention Application layer');
      assert(content.includes('Infrastructure layer'), 'Should mention Infrastructure layer');
    });

    it('should include PlantUML diagram template', () => {
      assert(content.includes('@startuml'), 'Missing PlantUML diagram start');
      assert(content.includes('@enduml'), 'Missing PlantUML diagram end');
    });

    it('should define red flags', () => {
      assert(content.includes('Red Flags'), 'Missing Red Flags section');
      assert(content.includes('Direct database access'), 'Should mention database access issues');
      assert(content.includes('Circular dependencies'), 'Should mention circular dependencies');
    });
  }) ? 0 : 1);
}