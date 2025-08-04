#!/usr/bin/env node

/**
 * Example Command Test
 * Demonstrates how to write tests for Claude commands
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

describe('pr command', () => {
  const commandPath = path.join(__dirname, '../../commands/pr.md');
  let content;

  beforeEach(() => {
    content = fs.readFileSync(commandPath, 'utf8');
  });

  it('should exist and have content', () => {
    assert(content.length > 100, 'Command file should have substantial content');
  });

  it('should mention git operations', () => {
    assert(content.includes('git') || content.includes('Git'), 'Should mention git operations');
    assert(content.includes('branch') || content.includes('ブランチ'), 'Should mention branch operations');
    assert(content.includes('commit') || content.includes('コミット'), 'Should mention commit operations');
  });

  it('should use file-by-file git add for security', () => {
    if (content.includes('git add')) {
      assert(
        content.includes('ファイルごと') || content.includes('file-by-file'),
        'Should use file-by-file git add for security'
      );
    }
  });

  it('should reference multiple agents for review', () => {
    const agents = [
      'accessibility-design-validator',
      'concurrency-safety-analyzer',
      'ddd-architecture-validator',
      'docs-consistency-checker',
      'nuget-dependency-auditor',
      'performance-analyzer',
      'testability-coverage-analyzer'
    ];

    let referencedAgents = 0;
    for (const agent of agents) {
      if (content.includes(agent)) {
        referencedAgents++;
      }
    }

    assert(referencedAgents >= 5, `Should reference multiple agents for review (found ${referencedAgents})`);
  });

  it('should have instructions for main branch handling', () => {
    assert(
      content.includes('main') || content.includes('メインブランチ'),
      'Should mention main branch handling'
    );
  });

  it('should mention PR creation', () => {
    assert(
      content.includes('PR') || content.includes('pull request') || content.includes('プルリクエスト'),
      'Should mention pull request creation'
    );
  });
});

// Simple test runner for standalone execution
function describe(name, fn) {
  console.log(`\nTesting: ${name}`);
  const tests = [];
  global.it = (testName, testFn) => {
    tests.push({ name: testName, fn: testFn });
  };
  global.beforeEach = () => {}; // Simplified for example
  
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
  process.exit(describe('pr command', () => {
    const commandPath = path.join(__dirname, '../../commands/pr.md');
    let content;

    beforeEach(() => {
      content = fs.readFileSync(commandPath, 'utf8');
    });

    it('should exist and have content', () => {
      assert(content.length > 100, 'Command file should have substantial content');
    });

    it('should mention git operations', () => {
      assert(content.includes('git') || content.includes('Git'), 'Should mention git operations');
      assert(content.includes('branch') || content.includes('ブランチ'), 'Should mention branch operations');
      assert(content.includes('commit') || content.includes('コミット'), 'Should mention commit operations');
    });

    it('should use file-by-file git add for security', () => {
      if (content.includes('git add')) {
        assert(
          content.includes('ファイルごと') || content.includes('file-by-file'),
          'Should use file-by-file git add for security'
        );
      }
    });

    it('should reference multiple agents for review', () => {
      const agents = [
        'accessibility-design-validator',
        'concurrency-safety-analyzer',
        'ddd-architecture-validator',
        'docs-consistency-checker',
        'nuget-dependency-auditor',
        'performance-analyzer',
        'testability-coverage-analyzer'
      ];

      let referencedAgents = 0;
      for (const agent of agents) {
        if (content.includes(agent)) {
          referencedAgents++;
        }
      }

      assert(referencedAgents >= 5, `Should reference multiple agents for review (found ${referencedAgents})`);
    });

    it('should have instructions for main branch handling', () => {
      assert(
        content.includes('main') || content.includes('メインブランチ'),
        'Should mention main branch handling'
      );
    });

    it('should mention PR creation', () => {
      assert(
        content.includes('PR') || content.includes('pull request') || content.includes('プルリクエスト'),
        'Should mention pull request creation'
      );
    });
  }) ? 0 : 1);
}