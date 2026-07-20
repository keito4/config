'use strict';

const fs = require('fs');
const path = require('path');

describe('eslint/complexity-rules.mjs', () => {
  const filePath = path.join(__dirname, '../eslint/complexity-rules.mjs');
  let content;

  beforeAll(() => {
    content = fs.readFileSync(filePath, 'utf8');
  });

  describe('File structure', () => {
    test('should exist', () => {
      expect(fs.existsSync(filePath)).toBe(true);
    });

    test('should be an ES module (.mjs)', () => {
      expect(filePath).toMatch(/\.mjs$/);
    });

    test('should export complexityRules as a named export', () => {
      expect(content).toContain('export const complexityRules');
    });

    test('should use named export (not default export) for the rules object', () => {
      // The file uses `export const complexityRules` (named export).
      // `export default` only appears inside the JSDoc usage-example comment.
      expect(content).toContain('export const complexityRules');
      expect(content).not.toMatch(/^export default/m);
    });
  });

  describe('Rule definitions', () => {
    test('should define cyclomatic complexity rule', () => {
      // The key is written as `complexity:` (object shorthand, no quotes)
      expect(content).toContain('complexity:');
    });

    test('should set cyclomatic complexity max to 15', () => {
      expect(content).toContain('max: 15');
    });

    test('should define max-lines-per-function rule', () => {
      expect(content).toContain("'max-lines-per-function'");
    });

    test('should set max-lines-per-function to 100', () => {
      expect(content).toContain('max: 100');
    });

    test('should skip blank lines in max-lines-per-function', () => {
      expect(content).toContain('skipBlankLines: true');
    });

    test('should skip comments in max-lines-per-function', () => {
      expect(content).toContain('skipComments: true');
    });

    test('should define max-lines rule', () => {
      expect(content).toContain("'max-lines'");
    });

    test('should set max-lines to 500', () => {
      expect(content).toContain('max: 500');
    });

    test('should define max-depth rule', () => {
      expect(content).toContain("'max-depth'");
    });

    test('should set max-depth to 4', () => {
      expect(content).toContain("'warn', 4");
    });

    test('should define max-params rule', () => {
      expect(content).toContain("'max-params'");
    });

    test('should set max-params to 5', () => {
      expect(content).toContain("'warn', 5");
    });

    test('should use warn severity for all rules (Phase 1 strategy)', () => {
      const warnMatches = content.match(/'warn'/g);
      expect(warnMatches).not.toBeNull();
      expect(warnMatches?.length ?? 0).toBeGreaterThanOrEqual(5);
    });

    test('should not use error severity for any rule (Phase 1)', () => {
      // Rules should use 'warn' during phase 1 to avoid breaking builds
      const errorMatches = content.match(/:\s*\['error'/g);
      expect(errorMatches).toBeNull();
    });
  });

  describe('Documentation', () => {
    test('should include a usage example', () => {
      expect(content).toContain('Usage Example');
    });

    test('should describe the phase-based implementation strategy', () => {
      expect(content).toContain('Phase');
    });

    test('should document cyclomatic complexity concept', () => {
      expect(content).toContain('Cyclomatic Complexity');
    });

    test('should document function length concept', () => {
      expect(content).toContain('Function Length');
    });

    test('should document file length concept', () => {
      expect(content).toContain('File Length');
    });

    test('should document nesting depth concept', () => {
      expect(content).toContain('Nesting Depth');
    });

    test('should document function parameters concept', () => {
      expect(content).toContain('Function Parameters');
    });

    test('should show how to spread rules into ESLint config', () => {
      expect(content).toContain('...complexityRules');
    });
  });

  describe('Consistency with eslint.config.mjs', () => {
    const mainConfigPath = path.join(__dirname, '../eslint.config.mjs');
    let mainConfig;

    beforeAll(() => {
      mainConfig = fs.readFileSync(mainConfigPath, 'utf8');
    });

    test('main ESLint config should use the same complexity max (15)', () => {
      expect(mainConfig).toContain('max: 15');
    });

    test('main ESLint config should use the same max-lines-per-function max (100)', () => {
      expect(mainConfig).toContain('max: 100');
    });

    test('main ESLint config should use the same max-lines max (500)', () => {
      expect(mainConfig).toContain('max: 500');
    });
  });
});
