'use strict';

const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

describe('eslint.config.mjs — root ESLint configuration', () => {
  const filePath = path.join(repoPath, 'eslint.config.mjs');
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

    test('should use default export', () => {
      expect(content).toContain('export default');
    });

    test('should import @eslint/js', () => {
      expect(content).toContain("from '@eslint/js'");
    });

    test('should import globals', () => {
      expect(content).toContain("from 'globals'");
    });

    test('should import eslint-config-prettier', () => {
      expect(content).toContain("from 'eslint-config-prettier'");
    });
  });

  describe('Ignores configuration', () => {
    test('should define an ignores entry', () => {
      expect(content).toContain('ignores:');
    });

    test('should ignore node_modules', () => {
      expect(content).toContain('node_modules/');
    });

    test('should ignore dist directory', () => {
      expect(content).toContain('dist/');
    });

    test('should ignore coverage directory', () => {
      expect(content).toContain('coverage/');
    });

    test('should ignore templates directory', () => {
      expect(content).toContain("'templates/'");
    });

    test('should ignore minified files', () => {
      expect(content).toContain('*.min.js');
    });
  });

  describe('Language options', () => {
    test('should target files with js and jsx extensions', () => {
      expect(content).toContain("'**/*.{js,jsx}'");
    });

    test('should set ecmaVersion to 2022 or later', () => {
      expect(content).toMatch(/ecmaVersion:\s*202[2-9]/);
    });

    test('should set sourceType to module', () => {
      expect(content).toContain("sourceType: 'module'");
    });

    test('should include Node.js globals', () => {
      expect(content).toContain('globals.node');
    });

    test('should include Jest globals', () => {
      expect(content).toContain('globals.jest');
    });
  });

  describe('Rule configuration', () => {
    test('should allow console usage (no-console: off)', () => {
      expect(content).toContain("'no-console': 'off'");
    });

    test('should error on unused vars (with underscore exception)', () => {
      expect(content).toContain("'no-unused-vars'");
      expect(content).toContain("argsIgnorePattern: '^_'");
    });

    test('should include complexity rule with max 15', () => {
      expect(content).toContain('complexity:');
      expect(content).toContain('max: 15');
    });

    test('should include max-lines-per-function rule with max 100', () => {
      expect(content).toContain("'max-lines-per-function'");
      expect(content).toContain('max: 100');
    });

    test('should include max-lines rule with max 500', () => {
      expect(content).toContain("'max-lines'");
      expect(content).toContain('max: 500');
    });

    test('should include max-depth rule', () => {
      expect(content).toContain("'max-depth'");
    });

    test('should include max-params rule with max 5', () => {
      expect(content).toContain("'max-params'");
      expect(content).toContain("'warn', 5");
    });

    test('should include max-nested-callbacks rule', () => {
      expect(content).toContain("'max-nested-callbacks'");
    });

    test('should use warn severity for complexity rules (Phase 1 strategy)', () => {
      // All complexity rules should use 'warn' not 'error'
      const warnMatches = content.match(/'warn'/g);
      expect(warnMatches).not.toBeNull();
      expect(warnMatches.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('Test file overrides', () => {
    test('should have a config block targeting test files', () => {
      expect(content).toContain("'**/*.test.js'");
    });

    test('should also target spec files', () => {
      expect(content).toContain("'**/*.spec.js'");
    });

    test('should also target files under test/ directory', () => {
      expect(content).toContain("'**/test/**/*.js'");
    });

    test('should disable max-lines-per-function for test files', () => {
      expect(content).toContain("'max-lines-per-function': 'off'");
    });

    test('should relax max-nested-callbacks limit for test files', () => {
      // Test files need more nesting for describe/test/beforeAll etc.
      expect(content).toContain("'max-nested-callbacks': ['warn', 5]");
    });
  });

  describe('Consistency with complexity-rules.mjs template', () => {
    const templatePath = path.join(repoPath, 'eslint', 'complexity-rules.mjs');
    let template;

    beforeAll(() => {
      template = fs.readFileSync(templatePath, 'utf8');
    });

    test('both files should use the same cyclomatic complexity limit (15)', () => {
      const rootMatch = content.match(/complexity:\s*\[.*?max:\s*(\d+)/s);
      const templateMatch = template.match(/complexity:\s*\[.*?max:\s*(\d+)/s);
      expect(rootMatch).not.toBeNull();
      expect(templateMatch).not.toBeNull();
      expect(rootMatch[1]).toBe(templateMatch[1]);
    });

    test('both files should use the same max-lines-per-function limit (100)', () => {
      // Both files should reference max: 100 for max-lines-per-function
      expect(content).toContain('max: 100');
      expect(template).toContain('max: 100');
    });

    test('both files should use the same max-lines limit (500)', () => {
      expect(content).toContain('max: 500');
      expect(template).toContain('max: 500');
    });
  });
});

describe('templates/eslint/eslint.config.mjs — TypeScript/Next.js ESLint template', () => {
  const filePath = path.join(repoPath, 'templates', 'eslint', 'eslint.config.mjs');
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
