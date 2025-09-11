#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Configuration validation script
 * Validates all configuration files and settings
 */

class ConfigValidator {
  constructor() {
    this.repoPath = path.resolve(__dirname, '..');
    this.errors = [];
    this.warnings = [];
  }

  log(message, type = 'info') {
    const prefix = type === 'error' ? '❌' : type === 'warning' ? '⚠️' : '✅';
    console.log(`${prefix} ${message}`);
  }

  validatePackageJson() {
    this.log('Validating package.json...');

    const packageJsonPath = path.join(this.repoPath, 'package.json');
    if (!fs.existsSync(packageJsonPath)) {
      this.errors.push('package.json not found');
      return;
    }

    try {
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

      // Check required fields
      const requiredFields = ['name', 'version', 'scripts', 'devDependencies'];
      requiredFields.forEach((field) => {
        if (!packageJson[field]) {
          this.errors.push(`Missing required field: ${field}`);
        }
      });

      // Check required scripts
      const requiredScripts = ['test', 'build', 'lint', 'format'];
      requiredScripts.forEach((script) => {
        if (!packageJson.scripts[script]) {
          this.errors.push(`Missing required script: ${script}`);
        }
      });

      // Check for Jest dependency
      if (!packageJson.devDependencies.jest) {
        this.warnings.push('Jest not found in devDependencies');
      }

      this.log('✓ package.json validation completed');
    } catch (error) {
      this.errors.push(`Invalid package.json: ${error.message}`);
    }
  }

  validateGitConfig() {
    this.log('Validating Git configuration...');

    const gitDir = path.join(this.repoPath, 'git');
    const requiredFiles = ['gitconfig', 'gitignore'];

    requiredFiles.forEach((file) => {
      const filePath = path.join(gitDir, file);
      if (!fs.existsSync(filePath)) {
        this.errors.push(`Missing Git configuration file: ${file}`);
      } else {
        this.log(`✓ Found ${file}`);
      }
    });

    // Validate gitconfig content
    const gitconfigPath = path.join(gitDir, 'gitconfig');
    if (fs.existsSync(gitconfigPath)) {
      const gitconfig = fs.readFileSync(gitconfigPath, 'utf8');

      // Check for placeholder values instead of hardcoded personal info
      if (!gitconfig.includes('Your Name') || !gitconfig.includes('your.email@example.com')) {
        this.warnings.push('gitconfig may contain hardcoded personal information');
      }
    }
  }

  validateBrewfiles() {
    this.log('Validating Brewfiles...');

    const brewDir = path.join(this.repoPath, 'brew');
    const brewfiles = ['LinuxBrewfile', 'MacOSBrewfile', 'StandaloneBrewfile'];

    brewfiles.forEach((brewfile) => {
      const filePath = path.join(brewDir, brewfile);
      if (!fs.existsSync(filePath)) {
        this.errors.push(`Missing Brewfile: ${brewfile}`);
      } else {
        const content = fs.readFileSync(filePath, 'utf8');
        if (content.trim().length === 0) {
          this.warnings.push(`Empty Brewfile: ${brewfile}`);
        } else {
          this.log(`✓ Validated ${brewfile}`);
        }
      }
    });
  }

  validateVSCodeConfig() {
    this.log('Validating VS Code configuration...');

    const vscodeDir = path.join(this.repoPath, 'vscode');
    const extensionsPath = path.join(vscodeDir, 'extensions.txt');

    if (!fs.existsSync(extensionsPath)) {
      this.errors.push('VS Code extensions.txt not found');
      return;
    }

    const extensions = fs
      .readFileSync(extensionsPath, 'utf8')
      .split('\n')
      .filter((line) => line.trim())
      .filter((line) => !line.startsWith('#'));

    if (extensions.length === 0) {
      this.warnings.push('No VS Code extensions configured');
    } else {
      // Validate extension ID format
      extensions.forEach((extension) => {
        if (!/^[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z0-9][a-zA-Z0-9-]*$/.test(extension)) {
          this.errors.push(`Invalid extension ID format: ${extension}`);
        }
      });
      this.log(`✓ Validated ${extensions.length} VS Code extensions`);
    }
  }

  validateScripts() {
    this.log('Validating shell scripts...');

    const scriptDir = path.join(this.repoPath, 'script');
    if (!fs.existsSync(scriptDir)) {
      this.errors.push('Script directory not found');
      return;
    }

    const scripts = fs.readdirSync(scriptDir).filter((file) => file.endsWith('.sh'));
    if (scripts.length === 0) {
      this.warnings.push('No shell scripts found');
      return;
    }

    scripts.forEach((script) => {
      const scriptPath = path.join(scriptDir, script);
      const stats = fs.statSync(scriptPath);

      // Check if executable
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
      { pattern: /password\s*=\s*['"][^'"]+['"]/i, name: 'password' },
      { pattern: /token\s*=\s*['"][^'"]+['"]/i, name: 'token' },
      { pattern: /key\s*=\s*['"][^'"]+['"]/i, name: 'key' },
      { pattern: /secret\s*=\s*['"][^'"]+['"]/i, name: 'secret' },
    ];

    const filesToCheck = ['git/gitconfig', 'script/credentials.sh', 'script/export.sh', 'script/import.sh'];

    filesToCheck.forEach((file) => {
      const filePath = path.join(this.repoPath, file);
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        sensitivePatterns.forEach(({ pattern, name }) => {
          if (pattern.test(content)) {
            this.errors.push(`Potential hardcoded ${name} found in ${file}`);
          }
        });
      }
    });

    this.log('✓ Security validation completed');
  }

  validateDocumentation() {
    this.log('Validating documentation...');

    const requiredDocs = [
      { file: 'README.md', description: 'Main documentation' },
      { file: 'SECURITY.md', description: 'Security guidelines' },
      { file: 'LICENSE', description: 'License file' },
    ];

    requiredDocs.forEach(({ file, description }) => {
      const filePath = path.join(this.repoPath, file);
      if (!fs.existsSync(filePath)) {
        this.errors.push(`Missing ${description}: ${file}`);
      } else {
        this.log(`✓ Found ${file}`);
      }
    });

    // Validate README content
    const readmePath = path.join(this.repoPath, 'README.md');
    if (fs.existsSync(readmePath)) {
      const readme = fs.readFileSync(readmePath, 'utf8');
      const requiredSections = ['Usage', 'Security', 'Directory Structure'];

      requiredSections.forEach((section) => {
        if (!readme.includes(section)) {
          this.warnings.push(`README missing section: ${section}`);
        }
      });
    }
  }

  validateCI() {
    this.log('Validating CI configuration...');

    const ciPath = path.join(this.repoPath, '.github', 'workflows', 'ci.yml');
    if (!fs.existsSync(ciPath)) {
      this.errors.push('CI workflow not found');
      return;
    }

    const ciContent = fs.readFileSync(ciPath, 'utf8');

    // Check for continue-on-error in test and build steps
    if (ciContent.includes('continue-on-error: true')) {
      this.warnings.push('CI pipeline has continue-on-error enabled for critical steps');
    }

    // Check for required steps
    const requiredSteps = ['lint', 'test', 'build'];
    requiredSteps.forEach((step) => {
      if (!ciContent.includes(`run: npm run ${step}`)) {
        this.warnings.push(`CI missing ${step} step`);
      }
    });

    this.log('✓ CI validation completed');
  }

  async validate() {
    this.log('Starting configuration validation...');

    this.validatePackageJson();
    this.validateGitConfig();
    this.validateBrewfiles();
    this.validateVSCodeConfig();
    this.validateScripts();
    this.validateSecurity();
    this.validateDocumentation();
    this.validateCI();

    // Report results
    this.log('Validation completed');

    if (this.warnings.length > 0) {
      this.log(`\nWarnings (${this.warnings.length}):`, 'warning');
      this.warnings.forEach((warning) => this.log(`  - ${warning}`, 'warning'));
    }

    if (this.errors.length > 0) {
      this.log(`\nErrors (${this.errors.length}):`, 'error');
      this.errors.forEach((error) => this.log(`  - ${error}`, 'error'));
      return false;
    }

    this.log('\nAll validations passed! 🎉');
    return true;
  }
}

// Run validation if called directly
if (require.main === module) {
  const validator = new ConfigValidator();
  validator
    .validate()
    .then((success) => {
      process.exit(success ? 0 : 1);
    })
    .catch((error) => {
      console.error('Validation failed:', error);
      process.exit(1);
    });
}

module.exports = ConfigValidator;
