'use strict';

describe('git/commitlint.config.js', () => {
  let config;

  beforeAll(() => {
    config = require('../git/commitlint.config.js');
  });

  describe('Configuration structure', () => {
    test('should export an object', () => {
      expect(typeof config).toBe('object');
      expect(config).not.toBeNull();
    });

    test('should extend @commitlint/config-conventional', () => {
      expect(Array.isArray(config.extends)).toBe(true);
      expect(config.extends).toContain('@commitlint/config-conventional');
    });

    test('should have rules object', () => {
      expect(typeof config.rules).toBe('object');
      expect(config.rules).not.toBeNull();
    });

    test('should not have plugins (unlike root commitlint.config.js)', () => {
      expect(config.plugins).toBeUndefined();
    });
  });

  describe('Japanese / multilingual support', () => {
    test('should disable subject-case rule for Japanese/CJK commit messages', () => {
      expect(config.rules['subject-case']).toEqual([0]);
    });

    test('subject-case severity should be 0 (off)', () => {
      const [severity] = config.rules['subject-case'];
      expect(severity).toBe(0);
    });
  });

  describe('Required rules', () => {
    test('should require non-empty subject', () => {
      expect(config.rules['subject-empty']).toEqual([2, 'never']);
    });

    test('should require non-empty type', () => {
      expect(config.rules['type-empty']).toEqual([2, 'never']);
    });

    test('should allow optional scope', () => {
      expect(config.rules['scope-empty']).toEqual([0]);
    });
  });

  describe('type-enum rule', () => {
    let typeEnumRule;

    beforeAll(() => {
      typeEnumRule = config.rules['type-enum'];
    });

    test('should be defined', () => {
      expect(typeEnumRule).toBeDefined();
    });

    test('should have severity 2 (error)', () => {
      const [severity] = typeEnumRule;
      expect(severity).toBe(2);
    });

    test('should use "always" condition', () => {
      const [, condition] = typeEnumRule;
      expect(condition).toBe('always');
    });

    test('should be an array with exactly 3 elements', () => {
      expect(typeEnumRule).toHaveLength(3);
    });

    test('should define an array of allowed types', () => {
      const [, , types] = typeEnumRule;
      expect(Array.isArray(types)).toBe(true);
      expect(types.length).toBeGreaterThan(0);
    });

    test('should include standard Conventional Commit feature/fix types', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('feat');
      expect(types).toContain('fix');
    });

    test('should include documentation type', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('docs');
    });

    test('should include code quality types', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('style');
      expect(types).toContain('refactor');
    });

    test('should include test type', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('test');
    });

    test('should include chore type for maintenance tasks', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('chore');
    });

    test('should include performance type', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('perf');
    });

    test('should include CI type', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('ci');
    });

    test('should include build type', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('build');
    });

    test('should include revert type', () => {
      const [, , types] = typeEnumRule;
      expect(types).toContain('revert');
    });

    test('should have exactly 11 allowed types', () => {
      const [, , types] = typeEnumRule;
      expect(types).toHaveLength(11);
    });
  });

  describe('Configuration completeness', () => {
    test('should have all required rule keys', () => {
      const expectedRules = ['subject-case', 'subject-empty', 'type-empty', 'scope-empty', 'type-enum'];
      expectedRules.forEach((rule) => {
        expect(config.rules).toHaveProperty(rule);
      });
    });
  });
});
