# Shell Script Test Suite

This directory contains comprehensive test coverage for all shell scripts in the `/script` directory using the Bats (Bash Automated Testing System) framework.

## Test Coverage

The test suite provides comprehensive coverage for the following shell scripts:

| Script | Test File | Coverage Areas |
|--------|-----------|----------------|
| `version.sh` | `version.bats` | Semantic versioning, git tag management, dry-run mode |
| `credentials.sh` | `credentials.bats` | 1Password CLI integration, template processing, credential cleanup |
| `import.sh` | `import.bats` | OS detection, Homebrew setup, configuration file imports |
| `export.sh` | `export.bats` | Configuration export, OS-specific handling, devcontainer detection |
| `brew-deps.sh` | `brew-deps.bats` | Dependency analysis, package categorization, Brewfile generation |
| `commit_changes.sh` | `commit_changes.bats` | Git operations, change detection, aicommits integration |

## Quick Start

### Running Tests Locally

```bash
# Run all tests
make test

# Run tests with verbose output
make test-verbose

# Run specific test file
make test-filter filter=version

# Check coverage meets requirements
make test-coverage
```

### Manual Test Execution

```bash
# Setup test framework (first time only)
cd test
./setup.sh

# Run all tests
./run-tests.sh

# Run with options
./run-tests.sh --verbose           # Detailed output
./run-tests.sh --filter version    # Run specific tests
./run-tests.sh --tap               # TAP format output
```

## Test Framework

### Bats (Bash Automated Testing System)

The test suite uses Bats v1.x with the following helper libraries:

- **bats-core**: Core testing framework
- **bats-support**: Basic test helpers
- **bats-assert**: Assertion functions
- **bats-file**: File system testing utilities

### Test Structure

Each test file follows this structure:

```bash
#!/usr/bin/env bats

load test_helper

@test "script-name: test description" {
    # Test setup
    
    # Run command
    run command_to_test
    
    # Assertions
    assert_success
    assert_output --partial "expected output"
}
```

### Test Helpers

The `test_helper.bash` file provides:

- **Mock command creation**: Create mock executables for testing
- **Temporary directory management**: Isolated test environments
- **Custom assertions**: Additional assertion functions
- **Fixture management**: Test data creation

## Writing Tests

### Best Practices

1. **Isolation**: Each test runs in a temporary directory
2. **Mocking**: Use mocks for external dependencies
3. **Assertions**: Use clear, specific assertions
4. **Coverage**: Test both success and failure paths
5. **Documentation**: Include descriptive test names

### Example Test

```bash
@test "version.sh: creates tag without dry-run" {
    # Setup test environment
    cd "$TEST_TEMP_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial state
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    git tag v1.0.0
    
    # Run the command
    run bash "$SCRIPT_DIR/version.sh" --type patch
    
    # Assert results
    assert_success
    assert_output --partial "Creating tag v1.0.1"
    
    # Verify side effects
    run git tag -l "v1.0.1"
    assert_output "v1.0.1"
}
```

### Mock Commands

Create mocks for external commands:

```bash
create_mock "brew" '
    if [[ "$1" == "list" ]]; then
        echo "package1"
        echo "package2"
    fi
    exit 0
'

# Use the mock in test
run zsh "$SCRIPT_DIR/brew-deps.sh" leaves

# Clean up
remove_mock "brew"
```

## CI Integration

Tests run automatically in GitHub Actions on:

- Pull requests
- Pushes to main/master branch

The CI pipeline:

1. Installs test dependencies (zsh, git)
2. Sets up Bats framework
3. Runs all tests with verbose output
4. Checks coverage meets 70% threshold

## Coverage Requirements

Per the repository's quality standards:

- **Minimum**: 70% line coverage for all scripts
- **Critical Paths**: 100% coverage required
- **Measurement**: Based on script files with test coverage

Current coverage is calculated as:
- Number of scripts with tests / Total number of scripts
- Each script should have comprehensive test scenarios

## Troubleshooting

### Common Issues

1. **Bats not found**: Run `./setup.sh` to install the framework
2. **zsh not available**: Install with `apt-get install zsh` or `brew install zsh`
3. **Permission denied**: Ensure scripts are executable with `chmod +x`
4. **Mock conflicts**: Check `test/mocks/` directory is cleaned up

### Debug Mode

For debugging test failures:

```bash
# Run single test with verbose output
./run-tests.sh --verbose --filter "specific test name"

# Check test artifacts
ls -la test/mocks/           # Mock commands
ls -la /tmp/tmp.*            # Temporary test directories
```

## Maintenance

### Adding New Tests

1. Create test file: `test/script-name.bats`
2. Load test helper: `load test_helper`
3. Write comprehensive test cases
4. Run locally: `make test-filter filter=script-name`
5. Update this README with coverage details

### Updating Tests

When scripts change:

1. Review test coverage for affected scripts
2. Update test cases to match new behavior
3. Add tests for new functionality
4. Ensure backward compatibility tests exist
5. Run full test suite: `make test`

## Resources

- [Bats Documentation](https://github.com/bats-core/bats-core)
- [Bats Assert Library](https://github.com/bats-core/bats-assert)
- [Bats File Library](https://github.com/bats-core/bats-file)
- [Testing Best Practices](https://github.com/bats-core/bats-core/wiki/Guidelines)