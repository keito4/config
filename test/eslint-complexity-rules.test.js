'use strict';

const fs = require('fs');
const path = require('path');

// Rule values and exports are verified by executing the module in
// eslint-modules-runtime.test.js; this file only checks the documentation text.
describe('eslint/complexity-rules.mjs', () => {
  const filePath = path.join(__dirname, '../eslint/complexity-rules.mjs');
  let content;

  beforeAll(() => {
    content = fs.readFileSync(filePath, 'utf8');
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
});
