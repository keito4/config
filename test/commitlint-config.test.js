const { execSync } = require('child_process');

// Mock child_process before requiring the module
jest.mock('child_process');

describe('Commitlint Configuration', () => {
  let config;

  beforeEach(() => {
    // Clear module cache to get fresh config
    jest.clearAllMocks();
    delete require.cache[require.resolve('../commitlint.config.js')];
  });

  describe('Configuration structure', () => {
    beforeEach(() => {
      // Mock execSync to return empty string (no staged files)
      execSync.mockReturnValue('');
      config = require('../commitlint.config.js');
    });

    test('should extend @commitlint/config-conventional', () => {
      expect(config.extends).toContain('@commitlint/config-conventional');
    });

    test('should have plugins with codex-release-type rule', () => {
      expect(config.plugins).toBeDefined();
      expect(config.plugins).toHaveLength(1);
      expect(config.plugins[0].rules).toHaveProperty('codex-release-type');
    });

    test('should have required rules configured', () => {
      expect(config.rules).toHaveProperty('subject-empty', [2, 'never']);
      expect(config.rules).toHaveProperty('type-empty', [2, 'never']);
      expect(config.rules).toHaveProperty('codex-release-type', [2, 'always']);
    });

    test('should disable subject-case for Japanese support', () => {
      expect(config.rules).toHaveProperty('subject-case', [0]);
    });
  });

  describe('Release type rule', () => {
    let releaseTypeRule;

    beforeEach(() => {
      config = require('../commitlint.config.js');
      releaseTypeRule = config.plugins[0].rules['codex-release-type'];
    });

    test('should allow any commit type when no sensitive files are touched', () => {
      execSync.mockReturnValue('');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(true);
    });

    test('should require release type when package.json is modified', () => {
      execSync.mockReturnValue('package.json\nREADME.md\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(false);
      expect(result[1]).toContain('package.json');
      expect(result[1]).toContain('feat|fix|perf|revert|docs');
    });

    test('should allow feat type when package.json is modified', () => {
      execSync.mockReturnValue('package.json\n');
      const result = releaseTypeRule({ type: 'feat' });
      expect(result[0]).toBe(true);
    });

    test('should allow fix type when package-lock.json is modified', () => {
      execSync.mockReturnValue('package-lock.json\n');
      const result = releaseTypeRule({ type: 'fix' });
      expect(result[0]).toBe(true);
    });

    test('should require release type when .codex/ files are modified', () => {
      execSync.mockReturnValue('.codex/prompts/test.md\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(false);
      expect(result[1]).toContain('.codex/prompts/test.md');
    });

    test('should allow perf type when npm/global.json is modified', () => {
      execSync.mockReturnValue('npm/global.json\n');
      const result = releaseTypeRule({ type: 'perf' });
      expect(result[0]).toBe(true);
    });

    test('should allow revert type when .devcontainer/Dockerfile is modified', () => {
      execSync.mockReturnValue('.devcontainer/Dockerfile\n');
      const result = releaseTypeRule({ type: 'revert' });
      expect(result[0]).toBe(true);
    });

    test('should allow docs type when .devcontainer/codex-config.json is modified', () => {
      execSync.mockReturnValue('.devcontainer/codex-config.json\n');
      const result = releaseTypeRule({ type: 'docs' });
      expect(result[0]).toBe(true);
    });

    test('should handle multiple sensitive files', () => {
      execSync.mockReturnValue('package.json\nnpm/global.json\n.codex/prompts/test.md\n');
      const result = releaseTypeRule({ type: 'build' });
      expect(result[0]).toBe(false);
      expect(result[1]).toContain('package.json');
      expect(result[1]).toContain('npm/global.json');
      expect(result[1]).toContain('.codex/prompts/test.md');
    });

    test('should handle git command error gracefully', () => {
      execSync.mockImplementation(() => {
        throw new Error('git command failed');
      });
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(true);
    });

    test('should handle undefined commit type', () => {
      execSync.mockReturnValue('package.json\n');
      const result = releaseTypeRule({ type: undefined });
      expect(result[0]).toBe(false);
    });

    test('should handle null commit type', () => {
      execSync.mockReturnValue('package.json\n');
      const result = releaseTypeRule({ type: null });
      expect(result[0]).toBe(false);
    });
  });

  describe('Release-sensitive file patterns', () => {
    let releaseTypeRule;

    beforeEach(() => {
      config = require('../commitlint.config.js');
      releaseTypeRule = config.plugins[0].rules['codex-release-type'];
    });

    test('should match package.json exactly', () => {
      execSync.mockReturnValue('package.json\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(false);
    });

    test('should not match package.json in subdirectory', () => {
      execSync.mockReturnValue('subdir/package.json\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(true);
    });

    test('should match any file under .codex/', () => {
      execSync.mockReturnValue('.codex/prompts/deep/nested/file.md\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(false);
    });

    test('should match .devcontainer/Dockerfile exactly', () => {
      execSync.mockReturnValue('.devcontainer/Dockerfile\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(false);
    });

    test('should match .devcontainer/codex-config.json exactly', () => {
      execSync.mockReturnValue('.devcontainer/codex-config.json\n');
      const result = releaseTypeRule({ type: 'chore' });
      expect(result[0]).toBe(false);
    });
  });
});
