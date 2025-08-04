#!/usr/bin/env node

/**
 * Command Configuration Validator
 * Validates all Claude command configurations for correctness and completeness
 */

const fs = require('fs');
const path = require('path');

// ANSI color codes for output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

class CommandValidator {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.commandsDir = path.join(__dirname, '..', 'commands');
    this.agentsDir = path.join(__dirname, '..', 'agents');
  }

  log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
  }

  getAvailableAgents() {
    if (!fs.existsSync(this.agentsDir)) {
      return new Set();
    }
    
    return new Set(
      fs.readdirSync(this.agentsDir)
        .filter(file => file.endsWith('.md'))
        .map(file => file.replace('.md', ''))
    );
  }

  validateCommandFile(filePath) {
    const fileName = path.basename(filePath);
    this.log(`\nValidating: ${fileName}`, 'cyan');
    
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Check minimum content length
      if (content.trim().length < 50) {
        this.errors.push(`${fileName}: Command file is too short or empty`);
        return false;
      }

      // Check for command structure elements
      const hasDescription = content.length > 100;
      if (!hasDescription) {
        this.warnings.push(`${fileName}: Command lacks detailed description`);
      }

      // Extract referenced agents
      const agentMatches = content.match(/(?:^|\n)- ([a-z-]+(?:-[a-z]+)*)/gm) || [];
      const referencedAgents = agentMatches
        .map(match => match.replace(/^[^\w]*/, '').trim())
        .filter(agent => agent.includes('-'));

      const availableAgents = this.getAvailableAgents();
      
      // Validate referenced agents exist
      for (const agent of referencedAgents) {
        if (!availableAgents.has(agent)) {
          this.warnings.push(`${fileName}: References unknown agent '${agent}'`);
        }
      }

      // Check for specific command patterns
      const commandPatterns = {
        'pr.md': ['git', 'branch', 'commit', 'review'],
        'pr-create.md': ['pull request', 'PR', 'git'],
        'test-all.md': ['test', 'npm', 'coverage'],
        'quality-check.md': ['lint', 'quality', 'check'],
        'check-coverage.md': ['coverage', 'test', 'threshold'],
        'init-project.md': ['init', 'setup', 'scaffold'],
        'update-deps.md': ['dependencies', 'npm', 'update'],
        'security-review.md': ['security', 'vulnerability', 'CVE'],
        'fix-ci.md': ['CI', 'build', 'pipeline'],
        'issue-create.md': ['issue', 'GitHub', 'template'],
        'issue-review.md': ['issue', 'triage', 'priority']
      };

      if (commandPatterns[fileName]) {
        const expectedKeywords = commandPatterns[fileName];
        const contentLower = content.toLowerCase();
        const missingKeywords = expectedKeywords.filter(
          keyword => !contentLower.includes(keyword.toLowerCase())
        );
        
        if (missingKeywords.length > 0) {
          this.warnings.push(
            `${fileName}: Missing expected keywords: ${missingKeywords.join(', ')}`
          );
        }
      }

      // Check for git-related commands having proper safeguards
      if (content.includes('git add')) {
        if (!content.includes('ファイルごと') && !content.includes('file-by-file')) {
          this.warnings.push(`${fileName}: Git add should be done file-by-file for security`);
        }
      }

      // Check for proper error handling mentions
      const hasErrorHandling = 
        content.includes('error') || 
        content.includes('fail') || 
        content.includes('エラー') ||
        content.includes('失敗');
      
      if (!hasErrorHandling && fileName !== 'init-project.md') {
        this.warnings.push(`${fileName}: No error handling mentioned`);
      }

      this.log(`  ✓ Basic structure valid`, 'green');
      return true;

    } catch (error) {
      this.errors.push(`${fileName}: Failed to read file - ${error.message}`);
      return false;
    }
  }

  validateAllCommands() {
    this.log('\n🔍 Claude Command Configuration Validator\n', 'magenta');
    this.log('=' .repeat(50), 'blue');

    if (!fs.existsSync(this.commandsDir)) {
      this.log(`Error: Commands directory not found at ${this.commandsDir}`, 'red');
      return false;
    }

    const files = fs.readdirSync(this.commandsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');

    if (files.length === 0) {
      this.log('No command files found!', 'yellow');
      return false;
    }

    this.log(`Found ${files.length} command configuration files`, 'blue');

    let validCount = 0;
    for (const file of files) {
      const filePath = path.join(this.commandsDir, file);
      if (this.validateCommandFile(filePath)) {
        validCount++;
      }
    }

    // Print summary
    this.log('\n' + '=' .repeat(50), 'blue');
    this.log('\n📊 Validation Summary\n', 'magenta');
    
    this.log(`Total Commands: ${files.length}`, 'cyan');
    this.log(`Valid: ${validCount}`, 'green');
    this.log(`Invalid: ${files.length - validCount}`, 'red');

    if (this.errors.length > 0) {
      this.log(`\n❌ Errors (${this.errors.length}):`, 'red');
      this.errors.forEach(error => {
        this.log(`  • ${error}`, 'red');
      });
    }

    if (this.warnings.length > 0) {
      this.log(`\n⚠️  Warnings (${this.warnings.length}):`, 'yellow');
      this.warnings.forEach(warning => {
        this.log(`  • ${warning}`, 'yellow');
      });
    }

    if (this.errors.length === 0 && this.warnings.length === 0) {
      this.log('\n✅ All command configurations are valid!', 'green');
    }

    return this.errors.length === 0;
  }

  // Validate command dependencies
  validateCommandDependencies() {
    this.log('\n🔗 Validating Command Dependencies\n', 'cyan');
    
    const commands = new Map();
    const dependencies = new Map();

    const files = fs.readdirSync(this.commandsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');

    for (const file of files) {
      const commandName = file.replace('.md', '');
      const filePath = path.join(this.commandsDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      
      commands.set(commandName, content);
      
      // Find references to other commands
      const commandRefs = content.match(/(?:run|execute|call)\s+([a-z-]+)/g) || [];
      const refs = commandRefs
        .map(ref => ref.replace(/^(?:run|execute|call)\s+/, ''))
        .filter(ref => ref !== commandName);
      
      dependencies.set(commandName, new Set(refs));
    }

    // Check for circular dependencies
    for (const [cmd, deps] of dependencies.entries()) {
      for (const dep of deps) {
        const depDeps = dependencies.get(dep);
        if (depDeps && depDeps.has(cmd)) {
          this.warnings.push(`Circular dependency detected: ${cmd} <-> ${dep}`);
        }
      }
    }

    // Check if referenced commands exist
    for (const [cmd, deps] of dependencies.entries()) {
      for (const dep of deps) {
        if (!commands.has(dep)) {
          this.warnings.push(`Command '${cmd}' references unknown command '${dep}'`);
        }
      }
    }
  }

  // Validate test coverage for commands
  validateTestCoverage() {
    this.log('\n🧪 Checking Test Coverage\n', 'cyan');
    
    const testsDir = path.join(__dirname, 'commands');
    const commandFiles = fs.readdirSync(this.commandsDir)
      .filter(file => file.endsWith('.md'))
      .map(file => file.replace('.md', ''));

    const missingTests = [];
    
    for (const command of commandFiles) {
      const testFile = path.join(testsDir, `${command}.test.js`);
      if (!fs.existsSync(testFile)) {
        missingTests.push(command);
      }
    }

    if (missingTests.length > 0) {
      this.log(`⚠️  Missing tests for ${missingTests.length} commands:`, 'yellow');
      missingTests.forEach(command => {
        this.log(`  • ${command}`, 'yellow');
      });
    } else {
      this.log('✅ All commands have test coverage', 'green');
    }
  }

  // Validate command usage examples
  validateUsageExamples() {
    this.log('\n📚 Checking Usage Examples\n', 'cyan');
    
    const files = fs.readdirSync(this.commandsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');

    const missingExamples = [];
    
    for (const file of files) {
      const filePath = path.join(this.commandsDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Check for example usage patterns
      const hasExample = 
        content.includes('例') || 
        content.includes('Example') ||
        content.includes('Usage') ||
        content.includes('使用');
      
      if (!hasExample) {
        missingExamples.push(file.replace('.md', ''));
      }
    }

    if (missingExamples.length > 0) {
      this.log(`⚠️  Missing usage examples for ${missingExamples.length} commands:`, 'yellow');
      missingExamples.forEach(command => {
        this.log(`  • ${command}`, 'yellow');
      });
    } else {
      this.log('✅ All commands have usage examples', 'green');
    }
  }
}

// Run validation if executed directly
if (require.main === module) {
  const validator = new CommandValidator();
  const isValid = validator.validateAllCommands();
  validator.validateCommandDependencies();
  validator.validateTestCoverage();
  validator.validateUsageExamples();
  
  process.exit(isValid ? 0 : 1);
}

module.exports = CommandValidator;