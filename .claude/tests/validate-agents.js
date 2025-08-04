#!/usr/bin/env node

/**
 * Agent Configuration Validator
 * Validates all Claude agent configurations for correctness and completeness
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

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

// Required fields for agent configuration
const REQUIRED_FIELDS = ['name', 'description', 'model'];
const VALID_MODELS = ['opus', 'sonnet', 'haiku', 'claude-3-opus-20240229', 'claude-3-sonnet-20240229', 'claude-3-haiku-20240307'];
const VALID_COLORS = ['red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'];

class AgentValidator {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.agentsDir = path.join(__dirname, '..', 'agents');
  }

  log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
  }

  validateAgentFile(filePath) {
    const fileName = path.basename(filePath);
    this.log(`\nValidating: ${fileName}`, 'cyan');
    
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Check if file has YAML frontmatter
      if (!content.startsWith('---')) {
        this.errors.push(`${fileName}: Missing YAML frontmatter`);
        return false;
      }

      // Extract YAML frontmatter
      const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
      if (!yamlMatch) {
        this.errors.push(`${fileName}: Invalid YAML frontmatter format`);
        return false;
      }

      let config;
      try {
        // Pre-process the YAML to handle escaped newlines in descriptions
        let yamlContent = yamlMatch[1];
        
        // Handle multiline descriptions by properly escaping them
        yamlContent = yamlContent.replace(/description:\s*(.+)$/gm, (match, desc) => {
          // If the description contains \n, wrap it in quotes
          if (desc.includes('\\n')) {
            return `description: "${desc.replace(/"/g, '\\"')}"`;
          }
          // If it's a long single line, wrap it in quotes
          if (desc.length > 80 && !desc.startsWith('"') && !desc.startsWith("'")) {
            return `description: "${desc.replace(/"/g, '\\"')}"`;
          }
          return match;
        });
        
        config = yaml.load(yamlContent);
      } catch (e) {
        this.errors.push(`${fileName}: Invalid YAML syntax - ${e.message}`);
        return false;
      }

      // Validate required fields
      for (const field of REQUIRED_FIELDS) {
        if (!config[field]) {
          this.errors.push(`${fileName}: Missing required field '${field}'`);
        }
      }

      // Validate model
      if (config.model && !VALID_MODELS.includes(config.model)) {
        this.warnings.push(`${fileName}: Unknown model '${config.model}'`);
      }

      // Validate color if specified
      if (config.color && !VALID_COLORS.includes(config.color)) {
        this.warnings.push(`${fileName}: Invalid color '${config.color}'`);
      }

      // Validate name matches filename (without .md)
      const expectedName = fileName.replace('.md', '');
      if (config.name && config.name !== expectedName) {
        this.warnings.push(`${fileName}: Agent name '${config.name}' doesn't match filename`);
      }

      // Check description quality
      if (config.description) {
        if (config.description.length < 50) {
          this.warnings.push(`${fileName}: Description seems too short (${config.description.length} chars)`);
        }
        if (!config.description.includes('\\n')) {
          this.warnings.push(`${fileName}: Description should include usage examples`);
        }
      }

      // Check for agent prompt content
      const promptContent = content.replace(/^---[\s\S]*?---\n/, '').trim();
      if (promptContent.length < 100) {
        this.errors.push(`${fileName}: Agent prompt content is too short or missing`);
      }

      // Check for specific sections in prompt
      const requiredSections = [
        'Responsibilities',
        'Analysis',
        'Output'
      ];

      for (const section of requiredSections) {
        if (!promptContent.toLowerCase().includes(section.toLowerCase())) {
          this.warnings.push(`${fileName}: Missing recommended section '${section}'`);
        }
      }

      this.log(`  ✓ Basic structure valid`, 'green');
      return true;

    } catch (error) {
      this.errors.push(`${fileName}: Failed to read file - ${error.message}`);
      return false;
    }
  }

  validateAllAgents() {
    this.log('\n🔍 Claude Agent Configuration Validator\n', 'magenta');
    this.log('=' .repeat(50), 'blue');

    if (!fs.existsSync(this.agentsDir)) {
      this.log(`Error: Agents directory not found at ${this.agentsDir}`, 'red');
      return false;
    }

    const files = fs.readdirSync(this.agentsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');

    if (files.length === 0) {
      this.log('No agent files found!', 'yellow');
      return false;
    }

    this.log(`Found ${files.length} agent configuration files`, 'blue');

    let validCount = 0;
    for (const file of files) {
      const filePath = path.join(this.agentsDir, file);
      if (this.validateAgentFile(filePath)) {
        validCount++;
      }
    }

    // Print summary
    this.log('\n' + '=' .repeat(50), 'blue');
    this.log('\n📊 Validation Summary\n', 'magenta');
    
    this.log(`Total Agents: ${files.length}`, 'cyan');
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
      this.log('\n✅ All agent configurations are valid!', 'green');
    }

    return this.errors.length === 0;
  }

  // Check for agent cross-references
  validateAgentReferences() {
    this.log('\n🔗 Validating Agent Cross-References\n', 'cyan');
    
    const agents = new Set();
    const references = new Map();

    // Collect all agent names
    const files = fs.readdirSync(this.agentsDir)
      .filter(file => file.endsWith('.md') && file !== 'README.md');

    for (const file of files) {
      const agentName = file.replace('.md', '');
      agents.add(agentName);
      
      const filePath = path.join(this.agentsDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Find references to other agents
      const agentRefs = content.match(/[a-z-]+(?:-[a-z]+)*-(?:validator|analyzer|checker|auditor|resolver)/g) || [];
      references.set(agentName, new Set(agentRefs));
    }

    // Check if referenced agents exist
    for (const [agent, refs] of references.entries()) {
      for (const ref of refs) {
        if (ref !== agent && !agents.has(ref)) {
          this.warnings.push(`Agent '${agent}' references unknown agent '${ref}'`);
        }
      }
    }
  }

  // Validate agent test coverage
  validateTestCoverage() {
    this.log('\n🧪 Checking Test Coverage\n', 'cyan');
    
    const testsDir = path.join(__dirname, 'agents');
    const agentFiles = fs.readdirSync(this.agentsDir)
      .filter(file => file.endsWith('.md'))
      .map(file => file.replace('.md', ''));

    const missingTests = [];
    
    for (const agent of agentFiles) {
      const testFile = path.join(testsDir, `${agent}.test.js`);
      if (!fs.existsSync(testFile)) {
        missingTests.push(agent);
      }
    }

    if (missingTests.length > 0) {
      this.log(`⚠️  Missing tests for ${missingTests.length} agents:`, 'yellow');
      missingTests.forEach(agent => {
        this.log(`  • ${agent}`, 'yellow');
      });
    } else {
      this.log('✅ All agents have test coverage', 'green');
    }
  }
}

// Run validation if executed directly
if (require.main === module) {
  const validator = new AgentValidator();
  const isValid = validator.validateAllAgents();
  validator.validateAgentReferences();
  validator.validateTestCoverage();
  
  process.exit(isValid ? 0 : 1);
}

module.exports = AgentValidator;