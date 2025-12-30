const fs = require('fs');
const path = require('path');

describe('ESLint Configuration', () => {
  const eslintConfigPath = path.join(__dirname, '../eslint.config.mjs');
  let configContent;

  beforeAll(() => {
    // Read the ESM config file content for static analysis
    configContent = fs.readFileSync(eslintConfigPath, 'utf8');
  });

  describe('File structure', () => {
    test('should exist', () => {
      expect(fs.existsSync(eslintConfigPath)).toBe(true);
    });

    test('should be a .mjs file (ES Module)', () => {
      expect(eslintConfigPath).toMatch(/\.mjs$/);
    });

    test('should import required dependencies', () => {
      expect(configContent).toContain("from '@eslint/js'");
      expect(configContent).toContain("from 'globals'");
      expect(configContent).toContain("from 'eslint-config-prettier'");
    });

    test('should use ES6 export default', () => {
      expect(configContent).toContain('export default');
    });
  });

  describe('Configuration structure', () => {
    test('should export an array', () => {
      expect(configContent).toContain('export default [');
    });

    test('should have multiple configuration objects', () => {
      // Count opening braces in the default export array
      const exportMatch = configContent.match(/export default \[([\s\S]*)\];/);
      expect(exportMatch).toBeTruthy();
    });
  });

  describe('Ignore patterns', () => {
    test('should have ignores configuration', () => {
      expect(configContent).toContain('ignores:');
    });

    test('should ignore node_modules directory', () => {
      expect(configContent).toContain("'node_modules/'");
    });

    test('should ignore dist directory', () => {
      expect(configContent).toContain("'dist/'");
    });

    test('should ignore coverage directory', () => {
      expect(configContent).toContain("'coverage/'");
    });

    test('should ignore minified files', () => {
      expect(configContent).toContain("'*.min.js'");
    });
  });

  describe('File patterns', () => {
    test('should have configuration for JavaScript files', () => {
      expect(configContent).toContain('files:');
      expect(configContent).toContain("'**/*.{js,jsx}'");
    });
  });

  describe('Language options', () => {
    test('should configure ECMAScript version', () => {
      expect(configContent).toContain('ecmaVersion: 2022');
    });

    test('should use module sourceType', () => {
      expect(configContent).toContain("sourceType: 'module'");
    });

    test('should include Node.js globals', () => {
      expect(configContent).toContain('globals.node');
    });

    test('should include Jest globals', () => {
      expect(configContent).toContain('globals.jest');
    });
  });

  describe('Rules', () => {
    test('should have custom rules configured', () => {
      expect(configContent).toContain('rules:');
    });

    test('should disable no-console rule', () => {
      expect(configContent).toContain("'no-console': 'off'");
    });

    test('should configure no-unused-vars with argsIgnorePattern', () => {
      expect(configContent).toContain("'no-unused-vars'");
      expect(configContent).toContain("argsIgnorePattern: '^_'");
    });
  });

  describe('Prettier integration', () => {
    test('should include eslint-config-prettier', () => {
      expect(configContent).toContain('eslint-config-prettier');
    });

    test('should import Prettier config', () => {
      expect(configContent).toContain('import');
      expect(configContent).toContain('eslintConfigPrettier');
    });

    test('should include Prettier config in export', () => {
      expect(configContent).toContain('eslintConfigPrettier');
      // Verify it's in the exported array
      const exportMatch = configContent.match(/export default \[([\s\S]*)\];/);
      expect(exportMatch).toBeTruthy();
      expect(exportMatch[1]).toContain('eslintConfigPrettier');
    });
  });

  describe('Configuration completeness', () => {
    test('should include ESLint recommended rules', () => {
      expect(configContent).toContain('js.configs.recommended');
    });

    test('should have all required sections', () => {
      expect(configContent).toContain('ignores:');
      expect(configContent).toContain('files:');
      expect(configContent).toContain('rules:');
      expect(configContent).toContain('languageOptions:');
    });

    test('should be properly formatted ES module', () => {
      expect(configContent).toContain('import');
      expect(configContent).toContain('export default');
      expect(configContent).toContain('from');
    });
  });
});
