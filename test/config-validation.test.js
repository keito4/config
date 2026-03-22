const fs = require('fs');
const path = require('path');

describe('Configuration Validation', () => {
  const repoPath = path.resolve(__dirname, '..');

  describe('Package.json validation', () => {
    test('should have valid package.json structure', () => {
      const packageJson = JSON.parse(fs.readFileSync(path.join(repoPath, 'package.json'), 'utf8'));

      expect(packageJson).toHaveProperty('name');
      expect(packageJson).toHaveProperty('version');
      expect(packageJson).toHaveProperty('scripts');
      expect(packageJson).toHaveProperty('devDependencies');

      // Validate required scripts
      expect(packageJson.scripts).toHaveProperty('test');
      expect(packageJson.scripts).toHaveProperty('lint');
      expect(packageJson.scripts).toHaveProperty('format');
    });

    test('should have required dev dependencies', () => {
      const packageJson = JSON.parse(fs.readFileSync(path.join(repoPath, 'package.json'), 'utf8'));

      expect(packageJson.devDependencies).toHaveProperty('jest');
      expect(packageJson.devDependencies).toHaveProperty('eslint');
      expect(packageJson.devDependencies).toHaveProperty('prettier');
      expect(packageJson.devDependencies).toHaveProperty('husky');
    });
  });

  describe('Git configuration validation', () => {
    test('should have gitconfig file', () => {
      const gitconfigPath = path.join(repoPath, 'git', 'gitconfig');
      expect(fs.existsSync(gitconfigPath)).toBe(true);
    });

    test('should have gitignore file', () => {
      const gitignorePath = path.join(repoPath, 'git', 'gitignore');
      expect(fs.existsSync(gitignorePath)).toBe(true);
    });

    test('gitconfig should not contain hardcoded personal information', () => {
      const gitconfigPath = path.join(repoPath, 'git', 'gitconfig');
      const gitconfig = fs.readFileSync(gitconfigPath, 'utf8');

      // Check for placeholder patterns instead of hardcoded values
      expect(gitconfig).toMatch(/Your Name/);
      expect(gitconfig).toMatch(/your\.email@example\.com/);

      // Should not contain actual personal email addresses (excluding placeholders and git URLs)
      const emailMatches = gitconfig.match(/@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g);
      if (emailMatches) {
        emailMatches.forEach((email) => {
          // Allow placeholder emails, generic domains, and git URLs
          const isPlaceholder =
            email === 'your.email@example.com' ||
            email === '@example.com' ||
            email.includes('example.com') ||
            email.includes('github.com');
          expect(isPlaceholder).toBe(true);
        });
      }
    });
  });

  describe('Brewfile validation', () => {
    test('should have Linux Brewfile', () => {
      const linuxBrewfilePath = path.join(repoPath, 'brew', 'LinuxBrewfile');
      expect(fs.existsSync(linuxBrewfilePath)).toBe(true);
    });

    test('LinuxBrewfile should have valid syntax', () => {
      const brewfilePath = path.join(repoPath, 'brew', 'LinuxBrewfile');
      const content = fs.readFileSync(brewfilePath, 'utf8');
      expect(content).not.toMatch(/^\s*$/);
      expect(content).toMatch(/^#|^brew|^cask|^tap|^mas/);
    });

    test('should have Nix flake for macOS package management', () => {
      const flakePath = path.join(repoPath, 'nix', 'flake.nix');
      expect(fs.existsSync(flakePath)).toBe(true);
    });
  });

  describe('VS Code configuration validation', () => {
    test('should have extensions.txt file', () => {
      const extensionsPath = path.join(repoPath, 'vscode', 'extensions.txt');
      expect(fs.existsSync(extensionsPath)).toBe(true);
    });

    test('extensions.txt should contain valid extension IDs', () => {
      const extensionsPath = path.join(repoPath, 'vscode', 'extensions.txt');
      const extensions = fs
        .readFileSync(extensionsPath, 'utf8')
        .split('\n')
        .filter((line) => line.trim());

      extensions.forEach((extension) => {
        // VS Code extensions should be in format: publisher.extension-name
        expect(extension).toMatch(/^[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z0-9][a-zA-Z0-9-]*$/);
      });
    });
  });

  describe('Script validation', () => {
    test('should have required scripts', () => {
      const requiredScripts = [
        'script/export.sh',
        'script/import.sh',
        'script/credentials.sh',
        'script/version.sh',
        'script/brew-deps.sh',
      ];

      requiredScripts.forEach((script) => {
        const scriptPath = path.join(repoPath, script);
        expect(fs.existsSync(scriptPath)).toBe(true);
      });
    });

    test('scripts should be executable', () => {
      const scriptDir = path.join(repoPath, 'script');
      const scripts = fs.readdirSync(scriptDir).filter((file) => file.endsWith('.sh'));

      scripts.forEach((script) => {
        const scriptPath = path.join(scriptDir, script);
        const stats = fs.statSync(scriptPath);
        expect(stats.mode & parseInt('111', 8)).toBeTruthy(); // Check if executable
      });
    });
  });

  describe('Security validation', () => {
    test('should not contain hardcoded secrets', () => {
      const sensitivePatterns = [
        /password\s*=\s*['"][^'"]+['"]/i,
        /token\s*=\s*['"][^'"]+['"]/i,
        /key\s*=\s*['"][^'"]+['"]/i,
        /secret\s*=\s*['"][^'"]+['"]/i,
      ];

      const filesToCheck = ['git/gitconfig', 'script/credentials.sh', 'script/export.sh', 'script/import.sh'];

      filesToCheck.forEach((file) => {
        const filePath = path.join(repoPath, file);
        if (fs.existsSync(filePath)) {
          const content = fs.readFileSync(filePath, 'utf8');
          sensitivePatterns.forEach((pattern) => {
            expect(content).not.toMatch(pattern);
          });
        }
      });
    });

    test('should have proper file permissions for sensitive files', () => {
      const sensitiveFiles = ['credentials/templates'];

      sensitiveFiles.forEach((file) => {
        const filePath = path.join(repoPath, file);
        if (fs.existsSync(filePath)) {
          const stats = fs.statSync(filePath);
          // Check that sensitive files are not world-readable (skip if directory)
          if (stats.isFile()) {
            expect(stats.mode & parseInt('004', 8)).toBe(0);
          }
        }
      });
    });
  });

  describe('Documentation validation', () => {
    test('should have required documentation files', () => {
      const requiredDocs = ['README.md', 'SECURITY.md', 'LICENSE'];

      requiredDocs.forEach((doc) => {
        const docPath = path.join(repoPath, doc);
        expect(fs.existsSync(docPath)).toBe(true);
      });
    });

    test('README should contain essential sections', () => {
      const readmePath = path.join(repoPath, 'README.md');
      const readme = fs.readFileSync(readmePath, 'utf8');

      expect(readme).toMatch(/## Usage/);
      expect(readme).toMatch(/## Security/);
      expect(readme).toMatch(/## Directory Structure/);
    });
  });
});
