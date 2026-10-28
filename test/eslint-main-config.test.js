'use strict';

const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

// The root eslint.config.mjs is verified by executing it in
// eslint-modules-runtime.test.js and eslint-runtime.test.js; only the
// (non-executed) TypeScript template is checked here as text.
describe('templates/eslint/eslint.config.mjs — TypeScript/Next.js ESLint template', () => {
  const filePath = path.join(repoPath, 'templates', 'eslint', 'eslint.config.mjs');
  let content;

  beforeAll(() => {
    content = fs.readFileSync(filePath, 'utf8');
  });

  describe('File structure', () => {
    test('should use default export', () => {
      expect(content).toContain('export default');
    });

    test('should import typescript-eslint', () => {
      expect(content).toContain("from 'typescript-eslint'");
    });
  });

  describe('Ignores configuration', () => {
    test('should ignore node_modules', () => {
      expect(content).toContain('node_modules/**');
    });

    test('should ignore .next directory', () => {
      expect(content).toContain('.next/**');
    });

    test('should ignore dist directory', () => {
      expect(content).toContain('dist/**');
    });

    test('should ignore build directory', () => {
      expect(content).toContain('build/**');
    });

    test('should ignore coverage directory', () => {
      expect(content).toContain('coverage/**');
    });
  });

  describe('TypeScript configuration', () => {
    test('should use tseslint.configs.recommended spread', () => {
      expect(content).toContain('...tseslint.configs.recommended');
    });

    test('should target TypeScript files', () => {
      expect(content).toContain("'**/*.{ts,tsx}'");
    });

    test('should configure @typescript-eslint/no-unused-vars', () => {
      expect(content).toContain('@typescript-eslint/no-unused-vars');
    });

    test('should allow underscore-prefixed unused variables', () => {
      expect(content).toContain("argsIgnorePattern: '^_'");
      expect(content).toContain("varsIgnorePattern: '^_'");
    });
  });

  describe('Documentation and usage hints', () => {
    test('should include usage instructions in comments', () => {
      expect(content).toContain('使い方');
    });

    test('should reference complexity-rules.mjs for complexity guards', () => {
      expect(content).toContain('complexity-rules.mjs');
    });

    test('should have commented-out complexityRules import (opt-in)', () => {
      // The complexity rules import should be commented out (opt-in pattern)
      expect(content).toContain('// import { complexityRules }');
    });

    test('should have commented-out Next.js config (opt-in)', () => {
      expect(content).toContain('// import nextCoreWebVitals');
    });
  });
});
