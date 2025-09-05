#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * Build process for configuration repository
 * Validates and prepares configuration files for deployment
 */

class ConfigBuilder {
  constructor() {
    this.repoPath = path.resolve(__dirname, '..');
    this.buildPath = path.join(this.repoPath, 'dist');
    this.errors = [];
    this.warnings = [];
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = type === 'error' ? '❌' : type === 'warning' ? '⚠️' : '✅';
    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  validateEnvironment() {
    this.log('Validating build environment...');

    // Check if we're in the right directory
    if (!fs.existsSync(path.join(this.repoPath, 'package.json'))) {
      this.errors.push('Not in a valid Node.js project directory');
      return false;
    }

    // Check Node.js version
    const nodeVersion = process.version;
    const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
    if (majorVersion < 16) {
      this.warnings.push(`Node.js version ${nodeVersion} is older than recommended (16+)`);
    }

    this.log(`Using Node.js ${nodeVersion}`);
    return true;
  }

  validateConfiguration() {
    this.log('Validating configuration files...');

    const configFiles = [
      'package.json',
      'git/gitconfig',
      'git/gitignore',
      'git/gitattributes',
      'brew/LinuxBrewfile',
      'brew/MacOSBrewfile',
      'brew/StandaloneBrewfile',
      'vscode/extensions.txt',
      'commitlint.config.js',
      '.releaserc.json',
    ];

    configFiles.forEach((file) => {
      const filePath = path.join(this.repoPath, file);
      if (fs.existsSync(filePath)) {
        this.log(`✓ Found ${file}`);

        // Validate JSON files
        if (file.endsWith('.json')) {
          try {
            JSON.parse(fs.readFileSync(filePath, 'utf8'));
            this.log(`✓ Valid JSON: ${file}`);
          } catch (error) {
            this.errors.push(`Invalid JSON in ${file}: ${error.message}`);
          }
        }
      } else {
        this.warnings.push(`Missing configuration file: ${file}`);
      }
    });
  }

  validateScripts() {
    this.log('Validating shell scripts...');

    const scriptDir = path.join(this.repoPath, 'script');
    if (!fs.existsSync(scriptDir)) {
      this.errors.push('Script directory not found');
      return;
    }

    const scripts = fs.readdirSync(scriptDir).filter((file) => file.endsWith('.sh'));
    scripts.forEach((script) => {
      const scriptPath = path.join(scriptDir, script);
      const stats = fs.statSync(scriptPath);

      if (!(stats.mode & parseInt('111', 8))) {
        this.warnings.push(`Script ${script} is not executable`);
      }

      // Check for shebang
      const content = fs.readFileSync(scriptPath, 'utf8');
      if (!content.startsWith('#!/')) {
        this.warnings.push(`Script ${script} missing shebang`);
      }

      this.log(`✓ Validated script: ${script}`);
    });
  }

  validateSecurity() {
    this.log('Performing security validation...');

    const sensitivePatterns = [
      /password\s*=\s*['"][^'"]+['"]/i,
      /token\s*=\s*['"][^'"]+['"]/i,
      /key\s*=\s*['"][^'"]+['"]/i,
      /secret\s*=\s*['"][^'"]+['"]/i,
    ];

    const filesToCheck = ['git/gitconfig', 'script/credentials.sh', 'script/export.sh', 'script/import.sh'];

    filesToCheck.forEach((file) => {
      const filePath = path.join(this.repoPath, file);
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        sensitivePatterns.forEach((pattern) => {
          if (pattern.test(content)) {
            this.errors.push(`Potential hardcoded secret found in ${file}`);
          }
        });
      }
    });

    this.log('✓ Security validation completed');
  }

  createBuildArtifacts() {
    this.log('Creating build artifacts...');

    // Create dist directory
    if (!fs.existsSync(this.buildPath)) {
      fs.mkdirSync(this.buildPath, { recursive: true });
    }

    // Copy essential configuration files
    const essentialFiles = ['package.json', 'commitlint.config.js', '.releaserc.json', 'jest.config.js'];

    essentialFiles.forEach((file) => {
      const srcPath = path.join(this.repoPath, file);
      const destPath = path.join(this.buildPath, file);

      if (fs.existsSync(srcPath)) {
        fs.copyFileSync(srcPath, destPath);
        this.log(`✓ Copied ${file}`);
      }
    });

    // Create build info
    const buildInfo = {
      timestamp: new Date().toISOString(),
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch,
      gitCommit: this.getGitCommit(),
      version: this.getPackageVersion(),
    };

    fs.writeFileSync(path.join(this.buildPath, 'build-info.json'), JSON.stringify(buildInfo, null, 2));

    this.log('✓ Build artifacts created');
  }

  getGitCommit() {
    try {
      return execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim();
    } catch {
      return 'unknown';
    }
  }

  getPackageVersion() {
    try {
      const packageJson = JSON.parse(fs.readFileSync(path.join(this.repoPath, 'package.json'), 'utf8'));
      return packageJson.version;
    } catch {
      return 'unknown';
    }
  }

  runTests() {
    this.log('Running tests...');

    try {
      execSync('npm test', {
        cwd: this.repoPath,
        stdio: 'inherit',
        timeout: 30000,
      });
      this.log('✓ All tests passed');
    } catch (error) {
      this.errors.push(`Tests failed: ${error.message}`);
    }
  }

  runLinting() {
    this.log('Running linter...');

    try {
      execSync('npm run lint', {
        cwd: this.repoPath,
        stdio: 'inherit',
        timeout: 30000,
      });
      this.log('✓ Linting passed');
    } catch (error) {
      this.errors.push(`Linting failed: ${error.message}`);
    }
  }

  async build() {
    this.log('Starting build process...');

    // Validate environment
    if (!this.validateEnvironment()) {
      this.log('Environment validation failed', 'error');
      return false;
    }

    // Run validation steps
    this.validateConfiguration();
    this.validateScripts();
    this.validateSecurity();

    // Run quality checks
    this.runLinting();
    this.runTests();

    // Create build artifacts
    this.createBuildArtifacts();

    // Report results
    this.log('Build process completed');

    if (this.warnings.length > 0) {
      this.log(`Warnings (${this.warnings.length}):`, 'warning');
      this.warnings.forEach((warning) => this.log(`  - ${warning}`, 'warning'));
    }

    if (this.errors.length > 0) {
      this.log(`Errors (${this.errors.length}):`, 'error');
      this.errors.forEach((error) => this.log(`  - ${error}`, 'error'));
      return false;
    }

    this.log('Build successful! 🎉');
    return true;
  }
}

// Run build if called directly
if (require.main === module) {
  const builder = new ConfigBuilder();
  builder
    .build()
    .then((success) => {
      process.exit(success ? 0 : 1);
    })
    .catch((error) => {
      console.error('Build failed:', error);
      process.exit(1);
    });
}

module.exports = ConfigBuilder;
