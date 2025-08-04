#!/usr/bin/env node

/**
 * Claude Configuration Test Runner
 * Orchestrates all validation tests for agents and commands
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m'
};

class TestRunner {
  constructor() {
    this.results = {
      passed: [],
      failed: [],
      warnings: [],
      errors: []
    };
    this.startTime = Date.now();
  }

  log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
  }

  logBold(message, color = 'reset') {
    console.log(`${colors.bold}${colors[color]}${message}${colors.reset}`);
  }

  banner() {
    console.clear();
    this.logBold('\n╔══════════════════════════════════════════════════════╗', 'cyan');
    this.logBold('║     Claude Configuration Test Suite v1.0.0          ║', 'cyan');
    this.logBold('╚══════════════════════════════════════════════════════╝\n', 'cyan');
    this.log(`Started at: ${new Date().toLocaleString()}`, 'blue');
    this.log('─'.repeat(58), 'blue');
  }

  async runTest(name, scriptPath, description) {
    return new Promise((resolve) => {
      this.log(`\n▶ Running: ${description}`, 'yellow');
      
      const startTime = Date.now();
      const child = spawn('node', [scriptPath], {
        stdio: 'pipe',
        env: { ...process.env, NO_COLOR: '0' }
      });

      let output = '';
      let errorOutput = '';

      child.stdout.on('data', (data) => {
        output += data.toString();
        if (process.env.CLAUDE_TEST_VERBOSE) {
          process.stdout.write(data);
        }
      });

      child.stderr.on('data', (data) => {
        errorOutput += data.toString();
        if (process.env.CLAUDE_TEST_VERBOSE) {
          process.stderr.write(data);
        }
      });

      child.on('close', (code) => {
        const duration = ((Date.now() - startTime) / 1000).toFixed(2);
        
        if (code === 0) {
          this.log(`  ✅ PASSED (${duration}s)`, 'green');
          this.results.passed.push({ name, duration });
          
          // Extract warnings from output
          const warningMatches = output.match(/⚠️.*$/gm) || [];
          warningMatches.forEach(warning => {
            this.results.warnings.push({ test: name, message: warning });
          });
        } else {
          this.log(`  ❌ FAILED (${duration}s)`, 'red');
          this.results.failed.push({ name, duration, error: errorOutput || output });
          
          // Extract errors from output
          const errorMatches = output.match(/❌.*$/gm) || [];
          errorMatches.forEach(error => {
            this.results.errors.push({ test: name, message: error });
          });
        }
        
        resolve(code === 0);
      });
    });
  }

  async runValidationTests() {
    this.logBold('\n📋 Configuration Validation Tests', 'magenta');
    this.log('─'.repeat(58), 'magenta');

    const tests = [
      {
        name: 'agent-validation',
        script: path.join(__dirname, 'validate-agents.js'),
        description: 'Agent Configuration Validation'
      },
      {
        name: 'command-validation',
        script: path.join(__dirname, 'validate-commands.js'),
        description: 'Command Configuration Validation'
      }
    ];

    for (const test of tests) {
      if (!fs.existsSync(test.script)) {
        this.log(`  ⚠️ Test script not found: ${test.script}`, 'yellow');
        continue;
      }
      await this.runTest(test.name, test.script, test.description);
    }
  }

  async runUnitTests() {
    this.logBold('\n🧪 Unit Tests', 'magenta');
    this.log('─'.repeat(58), 'magenta');

    // Check for agent tests
    const agentTestDir = path.join(__dirname, 'agents');
    if (fs.existsSync(agentTestDir)) {
      const agentTests = fs.readdirSync(agentTestDir)
        .filter(file => file.endsWith('.test.js'));
      
      if (agentTests.length > 0) {
        this.log(`  Found ${agentTests.length} agent test files`, 'cyan');
        for (const testFile of agentTests) {
          await this.runTest(
            testFile.replace('.test.js', ''),
            path.join(agentTestDir, testFile),
            `Agent Test: ${testFile}`
          );
        }
      } else {
        this.log('  ℹ️  No agent unit tests found', 'yellow');
      }
    } else {
      this.log('  ℹ️  Agent test directory not found', 'yellow');
    }

    // Check for command tests
    const commandTestDir = path.join(__dirname, 'commands');
    if (fs.existsSync(commandTestDir)) {
      const commandTests = fs.readdirSync(commandTestDir)
        .filter(file => file.endsWith('.test.js'));
      
      if (commandTests.length > 0) {
        this.log(`  Found ${commandTests.length} command test files`, 'cyan');
        for (const testFile of commandTests) {
          await this.runTest(
            testFile.replace('.test.js', ''),
            path.join(commandTestDir, testFile),
            `Command Test: ${testFile}`
          );
        }
      } else {
        this.log('  ℹ️  No command unit tests found', 'yellow');
      }
    } else {
      this.log('  ℹ️  Command test directory not found', 'yellow');
    }
  }

  async runIntegrationTests() {
    this.logBold('\n🔗 Integration Tests', 'magenta');
    this.log('─'.repeat(58), 'magenta');

    const integrationTestDir = path.join(__dirname, 'integration');
    if (fs.existsSync(integrationTestDir)) {
      const integrationTests = fs.readdirSync(integrationTestDir)
        .filter(file => file.endsWith('.test.js'));
      
      if (integrationTests.length > 0) {
        this.log(`  Found ${integrationTests.length} integration test files`, 'cyan');
        for (const testFile of integrationTests) {
          await this.runTest(
            testFile.replace('.test.js', ''),
            path.join(integrationTestDir, testFile),
            `Integration Test: ${testFile}`
          );
        }
      } else {
        this.log('  ℹ️  No integration tests found', 'yellow');
      }
    } else {
      this.log('  ℹ️  Integration test directory not found', 'yellow');
    }
  }

  async checkTestCoverage() {
    this.logBold('\n📊 Test Coverage Analysis', 'magenta');
    this.log('─'.repeat(58), 'magenta');

    const agentsDir = path.join(__dirname, '..', 'agents');
    const commandsDir = path.join(__dirname, '..', 'commands');
    const agentTestDir = path.join(__dirname, 'agents');
    const commandTestDir = path.join(__dirname, 'commands');

    // Check agent test coverage
    if (fs.existsSync(agentsDir)) {
      const agents = fs.readdirSync(agentsDir)
        .filter(file => file.endsWith('.md'))
        .map(file => file.replace('.md', ''));
      
      const agentTests = fs.existsSync(agentTestDir) 
        ? fs.readdirSync(agentTestDir)
            .filter(file => file.endsWith('.test.js'))
            .map(file => file.replace('.test.js', ''))
        : [];
      
      const agentCoverage = (agentTests.length / agents.length * 100).toFixed(1);
      this.log(`  Agent Test Coverage: ${agentCoverage}% (${agentTests.length}/${agents.length})`, 
        agentCoverage >= 80 ? 'green' : agentCoverage >= 50 ? 'yellow' : 'red');
      
      const missingAgentTests = agents.filter(agent => !agentTests.includes(agent));
      if (missingAgentTests.length > 0 && process.env.CLAUDE_TEST_VERBOSE) {
        this.log('  Missing agent tests:', 'yellow');
        missingAgentTests.forEach(agent => {
          this.log(`    • ${agent}`, 'yellow');
        });
      }
    }

    // Check command test coverage
    if (fs.existsSync(commandsDir)) {
      const commands = fs.readdirSync(commandsDir)
        .filter(file => file.endsWith('.md'))
        .map(file => file.replace('.md', ''));
      
      const commandTests = fs.existsSync(commandTestDir)
        ? fs.readdirSync(commandTestDir)
            .filter(file => file.endsWith('.test.js'))
            .map(file => file.replace('.test.js', ''))
        : [];
      
      const commandCoverage = (commandTests.length / commands.length * 100).toFixed(1);
      this.log(`  Command Test Coverage: ${commandCoverage}% (${commandTests.length}/${commands.length})`,
        commandCoverage >= 80 ? 'green' : commandCoverage >= 50 ? 'yellow' : 'red');
      
      const missingCommandTests = commands.filter(cmd => !commandTests.includes(cmd));
      if (missingCommandTests.length > 0 && process.env.CLAUDE_TEST_VERBOSE) {
        this.log('  Missing command tests:', 'yellow');
        missingCommandTests.forEach(cmd => {
          this.log(`    • ${cmd}`, 'yellow');
        });
      }
    }
  }

  generateReport() {
    const duration = ((Date.now() - this.startTime) / 1000).toFixed(2);
    
    this.log('\n' + '═'.repeat(58), 'blue');
    this.logBold('\n📈 Test Results Summary', 'cyan');
    this.log('─'.repeat(58), 'cyan');
    
    const total = this.results.passed.length + this.results.failed.length;
    const passRate = total > 0 ? (this.results.passed.length / total * 100).toFixed(1) : 0;
    
    this.log(`\n  Total Tests: ${total}`, 'blue');
    this.log(`  ✅ Passed: ${this.results.passed.length}`, 'green');
    this.log(`  ❌ Failed: ${this.results.failed.length}`, 'red');
    this.log(`  ⚠️  Warnings: ${this.results.warnings.length}`, 'yellow');
    this.log(`  Pass Rate: ${passRate}%`, passRate >= 90 ? 'green' : passRate >= 70 ? 'yellow' : 'red');
    this.log(`  Duration: ${duration}s`, 'blue');

    if (this.results.failed.length > 0) {
      this.logBold('\n❌ Failed Tests:', 'red');
      this.results.failed.forEach(test => {
        this.log(`  • ${test.name} (${test.duration}s)`, 'red');
        if (process.env.CLAUDE_TEST_VERBOSE && test.error) {
          console.log(test.error.split('\n').map(line => '    ' + line).join('\n'));
        }
      });
    }

    if (this.results.warnings.length > 0 && process.env.CLAUDE_TEST_VERBOSE) {
      this.logBold('\n⚠️  Warnings:', 'yellow');
      this.results.warnings.forEach(warning => {
        this.log(`  • [${warning.test}] ${warning.message}`, 'yellow');
      });
    }

    if (this.results.errors.length > 0) {
      this.logBold('\n❌ Errors:', 'red');
      this.results.errors.forEach(error => {
        this.log(`  • [${error.test}] ${error.message}`, 'red');
      });
    }

    // Generate status badge
    let status = 'PASSING';
    let statusColor = 'green';
    
    if (this.results.failed.length > 0) {
      status = 'FAILING';
      statusColor = 'red';
    } else if (this.results.warnings.length > 10) {
      status = 'UNSTABLE';
      statusColor = 'yellow';
    }

    this.log('\n' + '═'.repeat(58), 'blue');
    this.logBold(`\n🏁 Test Suite Status: ${status}`, statusColor);
    this.log('═'.repeat(58) + '\n', 'blue');

    // Write results to file if requested
    if (process.env.CLAUDE_TEST_OUTPUT) {
      const outputPath = path.join(__dirname, 'test-results.json');
      fs.writeFileSync(outputPath, JSON.stringify({
        timestamp: new Date().toISOString(),
        duration,
        total,
        passed: this.results.passed.length,
        failed: this.results.failed.length,
        warnings: this.results.warnings.length,
        passRate,
        status,
        results: this.results
      }, null, 2));
      this.log(`Results written to: ${outputPath}`, 'cyan');
    }

    return this.results.failed.length === 0;
  }

  async run() {
    this.banner();
    
    try {
      // Run tests in sequence
      await this.runValidationTests();
      await this.runUnitTests();
      await this.runIntegrationTests();
      await this.checkTestCoverage();
      
      // Generate and display report
      const success = this.generateReport();
      
      // Exit with appropriate code
      process.exit(success ? 0 : 1);
      
    } catch (error) {
      this.log(`\n❌ Test runner error: ${error.message}`, 'red');
      if (process.env.CLAUDE_TEST_DEBUG) {
        console.error(error.stack);
      }
      process.exit(1);
    }
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
if (args.includes('--verbose') || args.includes('-v')) {
  process.env.CLAUDE_TEST_VERBOSE = 'true';
}
if (args.includes('--debug') || args.includes('-d')) {
  process.env.CLAUDE_TEST_DEBUG = 'true';
  process.env.CLAUDE_TEST_VERBOSE = 'true';
}
if (args.includes('--output') || args.includes('-o')) {
  process.env.CLAUDE_TEST_OUTPUT = 'true';
}
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
Claude Configuration Test Runner

Usage: node run-all-tests.js [options]

Options:
  -v, --verbose    Show detailed test output
  -d, --debug      Enable debug mode (implies verbose)
  -o, --output     Write results to test-results.json
  -h, --help       Show this help message

Environment Variables:
  CLAUDE_TEST_VERBOSE   Enable verbose output
  CLAUDE_TEST_DEBUG     Enable debug output
  CLAUDE_TEST_OUTPUT    Write results to file
  `);
  process.exit(0);
}

// Run the test suite
const runner = new TestRunner();
runner.run();