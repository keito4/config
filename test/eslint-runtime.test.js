'use strict';

const { spawnSync } = require('child_process');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

/**
 * Run ESLint via npx and return the result.
 * @param {string[]} args - Arguments to pass to eslint
 * @returns {{ status: number, stdout: string, stderr: string }}
 */
function runEslint(args) {
  const result = spawnSync('npx', ['--no-install', 'eslint', ...args], {
    cwd: repoPath,
    encoding: 'utf8',
    timeout: 30000,
  });
  return {
    status: result.status,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
  };
}

describe('ESLint runtime behavior', () => {
  describe('ESLint availability', () => {
    test('ESLint should be available via npx', () => {
      const result = spawnSync('npx', ['--no-install', 'eslint', '--version'], {
        cwd: repoPath,
        encoding: 'utf8',
        timeout: 15000,
      });
      expect(result.status).toBe(0);
      expect(result.stdout).toMatch(/^v?\d+\.\d+\.\d+/);
    });
  });

  describe('Configuration loading', () => {
    test('ESLint should load eslint.config.mjs without errors', () => {
      // Run ESLint on a known clean file to verify the config loads correctly
      const result = runEslint(['commitlint.config.js']);
      expect(result.status).toBe(0);
      expect(result.stderr).toBe('');
    });

    test('ESLint --print-config should output valid JSON for a JS file', () => {
      const result = runEslint(['--print-config', 'commitlint.config.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      expect(config).toHaveProperty('rules');
    });

    test('ESLint config should include no-unused-vars rule', () => {
      const result = runEslint(['--print-config', 'commitlint.config.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      // no-unused-vars should be configured (set to error or warn level)
      expect(config.rules).toHaveProperty('no-unused-vars');
      const ruleConfig = config.rules['no-unused-vars'];
      // Rule is configured as ['error', {...}] so first element is severity
      const severity = Array.isArray(ruleConfig) ? ruleConfig[0] : ruleConfig;
      expect(severity).not.toBe(0); // Should not be 'off'
    });

    test('ESLint config should have no-console set to off', () => {
      const result = runEslint(['--print-config', 'commitlint.config.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      expect(config.rules).toHaveProperty('no-console');
      // no-console is 'off' (0)
      const ruleConfig = config.rules['no-console'];
      const severity = Array.isArray(ruleConfig) ? ruleConfig[0] : ruleConfig;
      expect(severity).toBe(0);
    });

    test('ESLint config should include complexity rules (max 15)', () => {
      const result = runEslint(['--print-config', 'commitlint.config.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      expect(config.rules).toHaveProperty('complexity');
      const complexityConfig = config.rules['complexity'];
      // complexity: ['warn', { max: 15 }]
      expect(Array.isArray(complexityConfig)).toBe(true);
      const options = complexityConfig[1];
      expect(options.max).toBe(15);
    });

    test('ESLint config should include max-lines-per-function rule', () => {
      const result = runEslint(['--print-config', 'commitlint.config.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      expect(config.rules).toHaveProperty('max-lines-per-function');
    });

    test('ESLint config should include max-lines rule (max 500)', () => {
      const result = runEslint(['--print-config', 'commitlint.config.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      expect(config.rules).toHaveProperty('max-lines');
      const maxLinesConfig = config.rules['max-lines'];
      const options = Array.isArray(maxLinesConfig) ? maxLinesConfig[1] : {};
      expect(options.max).toBe(500);
    });
  });

  describe('Test file overrides', () => {
    test('ESLint test file config should disable max-lines-per-function', () => {
      // Print config for a test file to verify overrides are applied
      const result = runEslint(['--print-config', 'test/commitlint-config.test.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      // In test files, max-lines-per-function should be 'off' (0)
      expect(config.rules).toHaveProperty('max-lines-per-function');
      const ruleConfig = config.rules['max-lines-per-function'];
      const severity = Array.isArray(ruleConfig) ? ruleConfig[0] : ruleConfig;
      expect(severity).toBe(0);
    });

    test('ESLint test file config should relax max-nested-callbacks to 5', () => {
      const result = runEslint(['--print-config', 'test/commitlint-config.test.js']);
      expect(result.status).toBe(0);
      const config = JSON.parse(result.stdout);
      expect(config.rules).toHaveProperty('max-nested-callbacks');
      const callbackConfig = config.rules['max-nested-callbacks'];
      // In test files: ['warn', 5]
      expect(Array.isArray(callbackConfig)).toBe(true);
      expect(callbackConfig[1]).toBe(5);
    });
  });

  describe('Project files lint cleanly', () => {
    test('jest.config.js should pass ESLint without errors', () => {
      const result = runEslint(['jest.config.js']);
      expect(result.status).toBe(0);
    });

    test('commitlint.config.js should pass ESLint without errors', () => {
      const result = runEslint(['commitlint.config.js']);
      expect(result.status).toBe(0);
    });

    test('git/commitlint.config.js should pass ESLint without errors', () => {
      const result = runEslint(['git/commitlint.config.js']);
      expect(result.status).toBe(0);
    });
  });
});
