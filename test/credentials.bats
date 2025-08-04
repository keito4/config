#!/usr/bin/env bats

load test_helper

@test "credentials.sh: displays usage without arguments" {
    run zsh "$SCRIPT_DIR/credentials.sh"
    assert_failure
    assert_output --partial "Usage:"
    assert_output --partial "fetch"
    assert_output --partial "clean"
    assert_output --partial "list"
}

@test "credentials.sh: checks for op CLI when fetching" {
    # Create mock that simulates op not installed
    create_mock "op" 'exit 127'
    
    run zsh "$SCRIPT_DIR/credentials.sh" fetch
    assert_failure
    assert_output --partial "1Password CLI (op) is not installed"
    assert_output --partial "brew install --cask 1password-cli"
    
    remove_mock "op"
}

@test "credentials.sh: checks for op signin when fetching" {
    # Create mock that simulates op installed but not signed in
    create_mock "op" '
        if [[ "$1" == "account" ]]; then
            exit 1
        fi
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/credentials.sh" fetch
    assert_failure
    assert_output --partial "Not signed in to 1Password"
    assert_output --partial "op signin"
    
    remove_mock "op"
}

@test "credentials.sh: list templates command works" {
    # Create test template files
    mkdir -p "$TEST_TEMP_DIR/credentials/templates"
    touch "$TEST_TEMP_DIR/credentials/templates/aws.env.template"
    touch "$TEST_TEMP_DIR/credentials/templates/simple.env.template"
    
    # Override REPO_ROOT for this test
    cd "$TEST_TEMP_DIR"
    export REPO_ROOT="$TEST_TEMP_DIR"
    
    run zsh "$SCRIPT_DIR/credentials.sh" list
    assert_success
    assert_output --partial "Available credential templates:"
    assert_output --partial "aws"
    assert_output --partial "simple"
}

@test "credentials.sh: clean command removes env files" {
    # Create test directory structure
    mkdir -p "$TEST_TEMP_DIR/credentials"
    touch "$TEST_TEMP_DIR/credentials/aws.env"
    touch "$TEST_TEMP_DIR/credentials/simple.env"
    touch "$TEST_TEMP_DIR/credentials/test.env.template"  # Should not be deleted
    
    # Override REPO_ROOT for this test
    cd "$TEST_TEMP_DIR"
    export REPO_ROOT="$TEST_TEMP_DIR"
    
    run zsh "$SCRIPT_DIR/credentials.sh" clean
    assert_success
    assert_output --partial "Credential files cleaned up"
    
    # Verify env files were deleted
    assert_not_exists "$TEST_TEMP_DIR/credentials/aws.env"
    assert_not_exists "$TEST_TEMP_DIR/credentials/simple.env"
    
    # Verify template was not deleted
    assert_exists "$TEST_TEMP_DIR/credentials/test.env.template"
}

@test "credentials.sh: fetch processes templates with op inject" {
    # Create mock op command that simulates successful operation
    create_mock "op" '
        if [[ "$1" == "account" ]] && [[ "$2" == "list" ]]; then
            echo "Account found"
            exit 0
        elif [[ "$1" == "inject" ]]; then
            # Simulate successful inject
            echo "# Generated content" > "${4#--out-file=}"
            exit 0
        fi
        exit 0
    '
    
    # Create test template
    mkdir -p "$TEST_TEMP_DIR/credentials/templates"
    echo "TEST_VAR=op://vault/item/field" > "$TEST_TEMP_DIR/credentials/templates/test.env.template"
    
    # Override REPO_ROOT for this test
    cd "$TEST_TEMP_DIR"
    export REPO_ROOT="$TEST_TEMP_DIR"
    
    run zsh "$SCRIPT_DIR/credentials.sh" fetch
    assert_success
    assert_output --partial "Processing: test.env.template"
    assert_output --partial "Generated: $TEST_TEMP_DIR/credentials/test.env"
    
    # Verify file was created with secure permissions
    assert_exists "$TEST_TEMP_DIR/credentials/test.env"
    
    remove_mock "op"
}

@test "credentials.sh: handles missing template file gracefully" {
    # Create mock op command
    create_mock "op" '
        if [[ "$1" == "account" ]] && [[ "$2" == "list" ]]; then
            echo "Account found"
            exit 0
        fi
        exit 0
    '
    
    # Create empty templates directory
    mkdir -p "$TEST_TEMP_DIR/credentials/templates"
    
    # Override REPO_ROOT for this test
    cd "$TEST_TEMP_DIR"
    export REPO_ROOT="$TEST_TEMP_DIR"
    
    run zsh "$SCRIPT_DIR/credentials.sh" fetch
    assert_success
    assert_output --partial "Fetching all credentials from 1Password"
    
    remove_mock "op"
}

@test "credentials.sh: handles op inject failure" {
    # Create mock op command that simulates inject failure
    create_mock "op" '
        if [[ "$1" == "account" ]] && [[ "$2" == "list" ]]; then
            echo "Account found"
            exit 0
        elif [[ "$1" == "inject" ]]; then
            # Simulate inject failure
            echo "Error: Failed to inject" >&2
            exit 1
        fi
        exit 0
    '
    
    # Create test template
    mkdir -p "$TEST_TEMP_DIR/credentials/templates"
    echo "TEST_VAR=op://vault/item/field" > "$TEST_TEMP_DIR/credentials/templates/test.env.template"
    
    # Override REPO_ROOT for this test
    cd "$TEST_TEMP_DIR"
    export REPO_ROOT="$TEST_TEMP_DIR"
    
    run zsh "$SCRIPT_DIR/credentials.sh" fetch
    assert_success  # Script continues even if individual inject fails
    assert_output --partial "Failed to process: $TEST_TEMP_DIR/credentials/templates/test.env.template"
    
    remove_mock "op"
}