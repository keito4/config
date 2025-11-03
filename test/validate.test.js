const ConfigValidator = require('../scripts/validate');
const fs = require('fs');
const path = require('path');

describe('ConfigValidator', () => {
  const repoPath = path.resolve(__dirname, '..');
  let validator;

  beforeEach(() => {
    validator = new ConfigValidator();
  });

  describe('validatePackageJson', () => {
    test('should validate package.json successfully', () => {
      validator.validatePackageJson();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validateGitConfig', () => {
    test('should validate Git configuration files', () => {
      validator.validateGitConfig();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validateBrewfiles', () => {
    test('should validate Brewfiles', () => {
      validator.validateBrewfiles();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validateVSCodeConfig', () => {
    test('should validate VS Code configuration', () => {
      validator.validateVSCodeConfig();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validateScripts', () => {
    test('should validate shell scripts', () => {
      validator.validateScripts();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validateSecurity', () => {
    test('should validate security settings', () => {
      validator.validateSecurity();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validateDocumentation', () => {
    test('should validate documentation files', () => {
      validator.validateDocumentation();
      expect(validator.errors.length).toBe(0);
    });

    test('should detect missing README sections', () => {
      const originalReadFileSync = fs.readFileSync;
      fs.readFileSync = jest.fn(() => '');

      validator.validateDocumentation();
      expect(validator.warnings.length).toBeGreaterThan(0);

      fs.readFileSync = originalReadFileSync;
    });
  });

  describe('validateCI', () => {
    test('should validate CI configuration', () => {
      validator.validateCI();
      expect(validator.errors.length).toBe(0);
    });
  });

  describe('validate', () => {
    test('should run complete validation', async () => {
      const result = await validator.validate();
      expect(typeof result).toBe('boolean');
    });
  });

  describe('validatePackageJson', () => {
    test('should handle missing package.json', () => {
      const originalExistsSync = fs.existsSync;
      fs.existsSync = jest.fn((filePath) => {
        if (filePath.includes('package.json')) {
          return false;
        }
        return originalExistsSync(filePath);
      });

      validator.validatePackageJson();
      expect(validator.errors.length).toBeGreaterThan(0);

      fs.existsSync = originalExistsSync;
    });

    test('should handle invalid JSON', () => {
      const originalReadFileSync = fs.readFileSync;
      fs.readFileSync = jest.fn(() => '{ invalid json }');

      validator.validatePackageJson();
      expect(validator.errors.length).toBeGreaterThan(0);

      fs.readFileSync = originalReadFileSync;
    });
  });

  describe('validateVSCodeConfig', () => {
    test('should handle missing extensions.txt', () => {
      const originalExistsSync = fs.existsSync;
      fs.existsSync = jest.fn((filePath) => {
        if (filePath.includes('extensions.txt')) {
          return false;
        }
        return originalExistsSync(filePath);
      });

      validator.validateVSCodeConfig();
      expect(validator.errors.length).toBeGreaterThan(0);

      fs.existsSync = originalExistsSync;
    });
  });

  describe('validateCI', () => {
    test('should handle missing CI file', () => {
      const originalExistsSync = fs.existsSync;
      fs.existsSync = jest.fn((filePath) => {
        if (filePath.includes('ci.yml')) {
          return false;
        }
        return originalExistsSync(filePath);
      });

      validator.validateCI();
      expect(validator.errors.length).toBeGreaterThan(0);

      fs.existsSync = originalExistsSync;
    });
  });
});
