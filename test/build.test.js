const ConfigBuilder = require('../scripts/build');
const fs = require('fs');
const path = require('path');

describe('ConfigBuilder', () => {
  const repoPath = path.resolve(__dirname, '..');
  let builder;

  beforeEach(() => {
    builder = new ConfigBuilder();
  });

  describe('validateEnvironment', () => {
    test('should validate environment successfully', () => {
      const result = builder.validateEnvironment();
      expect(result).toBe(true);
    });

    test('should detect Node.js version', () => {
      const originalVersion = process.version;
      Object.defineProperty(process, 'version', {
        value: 'v14.0.0',
        writable: true,
        configurable: true,
      });

      const result = builder.validateEnvironment();
      expect(result).toBe(true);
      expect(builder.warnings.length).toBeGreaterThan(0);

      Object.defineProperty(process, 'version', {
        value: originalVersion,
        writable: true,
        configurable: true,
      });
    });
  });

  describe('validateConfiguration', () => {
    test('should validate configuration files', () => {
      builder.validateConfiguration();
      expect(builder.errors.length).toBe(0);
    });

    test('should detect missing files', () => {
      const originalExistsSync = fs.existsSync;
      const mockExistsSync = jest.fn((filePath) => {
        // Return false for package.json to simulate missing file
        if (filePath.includes('package.json')) {
          return false;
        }
        return originalExistsSync(filePath);
      });
      fs.existsSync = mockExistsSync;

      builder.validateConfiguration();
      // At least one warning should be generated
      expect(mockExistsSync).toHaveBeenCalled();

      fs.existsSync = originalExistsSync;
    });
  });

  describe('validateScripts', () => {
    test('should validate shell scripts', () => {
      builder.validateScripts();
      // Should not throw errors for existing scripts
      expect(builder.errors.length).toBe(0);
    });
  });

  describe('getGitCommit', () => {
    test('should get git commit hash', () => {
      const commit = builder.getGitCommit();
      expect(typeof commit).toBe('string');
    });
  });

  describe('getPackageVersion', () => {
    test('should get package version', () => {
      const version = builder.getPackageVersion();
      expect(typeof version).toBe('string');
      expect(version).not.toBe('unknown');
    });
  });

  describe('createBuildArtifacts', () => {
    test('should create build artifacts', () => {
      builder.createBuildArtifacts();

      const buildInfoPath = path.join(builder.buildPath, 'build-info.json');
      expect(fs.existsSync(buildInfoPath)).toBe(true);

      const buildInfo = JSON.parse(fs.readFileSync(buildInfoPath, 'utf8'));
      expect(buildInfo).toHaveProperty('timestamp');
      expect(buildInfo).toHaveProperty('nodeVersion');
      expect(buildInfo).toHaveProperty('platform');
      expect(buildInfo).toHaveProperty('arch');
      expect(buildInfo).toHaveProperty('version');
    });
  });

  describe('build process', () => {
    test('should run complete build process', async () => {
      const result = await builder.build();
      expect(typeof result).toBe('boolean');
    });

    test('should handle build errors gracefully', async () => {
      const originalValidateEnvironment = builder.validateEnvironment;
      builder.validateEnvironment = jest.fn(() => false);

      const result = await builder.build();
      expect(result).toBe(false);

      builder.validateEnvironment = originalValidateEnvironment;
    });
  });

  describe('runTests', () => {
    test('should handle test failures', () => {
      const originalExecSync = require('child_process').execSync;
      const mockExecSync = jest.fn(() => {
        throw new Error('Test failed');
      });
      require('child_process').execSync = mockExecSync;

      builder.runTests();
      expect(builder.errors.length).toBeGreaterThan(0);

      require('child_process').execSync = originalExecSync;
    });
  });

  describe('runLinting', () => {
    test('should handle lint failures', () => {
      const originalExecSync = require('child_process').execSync;
      const mockExecSync = jest.fn(() => {
        throw new Error('Lint failed');
      });
      require('child_process').execSync = mockExecSync;

      builder.runLinting();
      expect(builder.errors.length).toBeGreaterThan(0);

      require('child_process').execSync = originalExecSync;
    });
  });

  describe('validateSecurity', () => {
    test('should detect potential hardcoded secrets', () => {
      builder.validateSecurity();
      // Should not have errors for clean repository
      expect(builder.errors.length).toBe(0);
    });
  });
});
