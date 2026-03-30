const fs = require('fs');
const path = require('path');

describe('Credential Filtering', () => {
  describe('gitconfig credential filtering', () => {
    const gitconfigPath = path.join(__dirname, '..', 'git', 'gitconfig');

    test('should have gitconfig file', () => {
      expect(fs.existsSync(gitconfigPath)).toBe(true);
    });

    test('should not contain real email addresses', () => {
      const gitconfig = fs.readFileSync(gitconfigPath, 'utf8');

      // Check that there are no uncommented email lines with real values
      const emailPattern = /^\s*email\s*=\s*[^#]/m;
      expect(gitconfig).not.toMatch(emailPattern);
    });

    test('should not contain real user names', () => {
      const gitconfig = fs.readFileSync(gitconfigPath, 'utf8');

      // Check that there are no uncommented name lines with real values
      const namePattern = /^\s*name\s*=\s*[^#]/m;
      expect(gitconfig).not.toMatch(namePattern);
    });

    test('should not contain real signing keys', () => {
      const gitconfig = fs.readFileSync(gitconfigPath, 'utf8');

      // Check that there are no uncommented signingkey lines with real values
      const signingkeyPattern = /^\s*signingkey\s*=\s*[^#]/m;
      expect(gitconfig).not.toMatch(signingkeyPattern);
    });

    test('should contain commented placeholders for user info', () => {
      const gitconfig = fs.readFileSync(gitconfigPath, 'utf8');

      // Verify that commented placeholders exist
      expect(gitconfig).toMatch(/# name = # Configure with:/);
      expect(gitconfig).toMatch(/# email = # Configure with:/);
      expect(gitconfig).toMatch(/# signingkey = # Configure with:/);
    });
  });

  // .zshrc credential filtering is no longer needed
  // macOS: .zshrc is managed by nix home-manager (nix/home/zsh.nix)

  describe('.claude/settings.json credential filtering', () => {
    const settingsPath = path.join(__dirname, '..', '.claude', 'settings.json');

    test('should have settings.json file', () => {
      expect(fs.existsSync(settingsPath)).toBe(true);
    });

    test('should not contain API keys or tokens', () => {
      const settings = fs.readFileSync(settingsPath, 'utf8');

      // Check for common API key patterns
      expect(settings).not.toMatch(/api[_-]?key["']?\s*:\s*["'][^"']+["']/i);
      expect(settings).not.toMatch(/token["']?\s*:\s*["'][^"']+["']/i);
      expect(settings).not.toMatch(/secret["']?\s*:\s*["'][^"']+["']/i);
      expect(settings).not.toMatch(/password["']?\s*:\s*["'][^"']+["']/i);
    });

    test('should be valid JSON', () => {
      const settings = fs.readFileSync(settingsPath, 'utf8');
      expect(() => JSON.parse(settings)).not.toThrow();
    });
  });

  describe('Template files existence', () => {
    test('should have settings.local.json.template', () => {
      const templatePath = path.join(__dirname, '..', '.claude', 'settings.local.json.template');
      expect(fs.existsSync(templatePath)).toBe(true);
    });

    test('should have .env.secret.template', () => {
      const templatePath = path.join(__dirname, '..', '.zsh', 'configs', 'pre', '.env.secret.template');
      expect(fs.existsSync(templatePath)).toBe(true);
    });

    test('settings.local.json.template should be valid JSON', () => {
      const templatePath = path.join(__dirname, '..', '.claude', 'settings.local.json.template');
      const template = fs.readFileSync(templatePath, 'utf8');
      expect(() => JSON.parse(template)).not.toThrow();
    });
  });

  describe('Credential documentation', () => {
    test('should have credentials/README.md', () => {
      const readmePath = path.join(__dirname, '..', 'credentials', 'README.md');
      expect(fs.existsSync(readmePath)).toBe(true);
    });

    test('credentials/README.md should mention filtering', () => {
      const readmePath = path.join(__dirname, '..', 'credentials', 'README.md');
      const readme = fs.readFileSync(readmePath, 'utf8');

      expect(readme).toMatch(/フィルタリング/);
      expect(readme).toMatch(/export\.sh/);
      expect(readme).toMatch(/\.env\.secret/);
    });
  });
});
