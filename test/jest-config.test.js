describe('Jest Configuration', () => {
  let config;

  beforeAll(() => {
    config = require('../jest.config.js');
  });

  describe('Test environment', () => {
    test('should use node environment', () => {
      expect(config.testEnvironment).toBe('node');
    });
  });

  describe('Test matching', () => {
    test('should match test files with .test.js extension', () => {
      expect(config.testMatch).toContain('**/test/**/*.test.js');
    });

    test('should match test files with .spec.js extension', () => {
      expect(config.testMatch).toContain('**/test/**/*.spec.js');
    });

    test('should have exactly 2 test patterns', () => {
      expect(config.testMatch).toHaveLength(2);
    });
  });

  describe('Coverage configuration', () => {
    test('should collect coverage from JavaScript files', () => {
      expect(config.collectCoverageFrom).toContain('**/*.js');
    });

    test('should exclude script directory from coverage', () => {
      expect(config.collectCoverageFrom).toContain('!script/**/*');
    });

    test('should exclude node_modules from coverage', () => {
      expect(config.collectCoverageFrom).toContain('!node_modules/**/*');
    });

    test('should exclude coverage directory from coverage', () => {
      expect(config.collectCoverageFrom).toContain('!coverage/**/*');
    });

    test('should exclude test files from coverage', () => {
      expect(config.collectCoverageFrom).toContain('!**/*.test.js');
      expect(config.collectCoverageFrom).toContain('!**/*.spec.js');
    });

    test('should use coverage directory', () => {
      expect(config.coverageDirectory).toBe('coverage');
    });

    test('should include text, lcov, and html reporters', () => {
      expect(config.coverageReporters).toContain('text');
      expect(config.coverageReporters).toContain('lcov');
      expect(config.coverageReporters).toContain('html');
    });
  });

  describe('Coverage thresholds', () => {
    test('should have global coverage thresholds', () => {
      expect(config.coverageThreshold).toHaveProperty('global');
    });

    test('should require 70% branch coverage', () => {
      expect(config.coverageThreshold.global.branches).toBe(70);
    });

    test('should require 70% function coverage', () => {
      expect(config.coverageThreshold.global.functions).toBe(70);
    });

    test('should require 70% line coverage', () => {
      expect(config.coverageThreshold.global.lines).toBe(70);
    });

    test('should require 70% statement coverage', () => {
      expect(config.coverageThreshold.global.statements).toBe(70);
    });
  });

  describe('Test execution settings', () => {
    test('should enable verbose mode', () => {
      expect(config.verbose).toBe(true);
    });

    test('should have 10 second test timeout', () => {
      expect(config.testTimeout).toBe(10000);
    });
  });

  describe('Configuration completeness', () => {
    test('should have all required top-level properties', () => {
      expect(config).toHaveProperty('testEnvironment');
      expect(config).toHaveProperty('testMatch');
      expect(config).toHaveProperty('collectCoverageFrom');
      expect(config).toHaveProperty('coverageDirectory');
      expect(config).toHaveProperty('coverageReporters');
      expect(config).toHaveProperty('coverageThreshold');
      expect(config).toHaveProperty('verbose');
      expect(config).toHaveProperty('testTimeout');
    });

    test('should export valid Jest configuration object', () => {
      expect(typeof config).toBe('object');
      expect(config).not.toBeNull();
    });
  });
});
