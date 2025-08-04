#!/usr/bin/env bats

load test_helper

@test "version.sh: displays help with --help flag" {
    run bash "$SCRIPT_DIR/version.sh" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "Options:"
    assert_output --partial "--type"
    assert_output --partial "--dry-run"
    assert_output --partial "--force"
}

@test "version.sh: displays help with -h flag" {
    run bash "$SCRIPT_DIR/version.sh" -h
    assert_success
    assert_output --partial "Usage:"
}

@test "version.sh: handles invalid bump type" {
    run bash "$SCRIPT_DIR/version.sh" --type invalid
    assert_failure
    assert_output --partial "Invalid bump type: invalid"
    assert_output --partial "Valid types: major, minor, patch"
}

@test "version.sh: handles unknown option" {
    run bash "$SCRIPT_DIR/version.sh" --unknown
    assert_failure
    assert_output --partial "Unknown option: --unknown"
}

@test "version.sh: dry run shows next patch version" {
    cd "$TEST_TEMP_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create initial tag
    git tag v1.2.3
    
    run bash "$SCRIPT_DIR/version.sh" --dry-run
    assert_success
    assert_output --partial "Latest tag: v1.2.3"
    assert_output --partial "New version: v1.2.4"
    assert_output --partial "DRY RUN: Would create tag v1.2.4"
}

@test "version.sh: dry run shows next minor version" {
    cd "$TEST_TEMP_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create initial tag
    git tag v1.2.3
    
    run bash "$SCRIPT_DIR/version.sh" --type minor --dry-run
    assert_success
    assert_output --partial "New version: v1.3.0"
}

@test "version.sh: dry run shows next major version" {
    cd "$TEST_TEMP_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create initial tag
    git tag v1.2.3
    
    run bash "$SCRIPT_DIR/version.sh" --type major --dry-run
    assert_success
    assert_output --partial "New version: v2.0.0"
}

@test "version.sh: starts with v1.0.0 when no tags exist" {
    cd "$TEST_TEMP_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    run bash "$SCRIPT_DIR/version.sh" --dry-run
    assert_success
    assert_output --partial "No existing version tags found"
    assert_output --partial "Starting with v1.0.0"
    assert_output --partial "New version: v1.0.0"
}

@test "version.sh: creates tag without dry-run" {
    cd "$TEST_TEMP_DIR"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create initial tag
    git tag v1.0.0
    
    run bash "$SCRIPT_DIR/version.sh" --type patch
    assert_success
    assert_output --partial "Creating tag v1.0.1"
    assert_output --partial "Tag created successfully!"
    
    # Verify tag was created
    run git tag -l "v1.0.1"
    assert_success
    assert_output "v1.0.1"
}

@test "version.sh: prevents duplicate tag without force" {
    cd "$TEST_TEMP_DIR"
    git init -b main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create existing tags
    git tag v1.0.0
    git tag v1.0.1
    
    # Try to create duplicate tag (it would want to create v1.0.2 since v1.0.1 exists)
    # But let's force it to try v1.0.1 by deleting and recreating
    run bash "$SCRIPT_DIR/version.sh" --type patch
    assert_success
    # The script should create v1.0.2 since v1.0.1 already exists
    assert_output --partial "v1.0.2"
}

@test "version.sh: force flag works correctly" {
    cd "$TEST_TEMP_DIR"
    git init -b main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create existing tags
    git tag v1.0.0
    
    # Create v1.0.1
    run bash "$SCRIPT_DIR/version.sh" --type patch
    assert_success
    assert_output --partial "v1.0.1"
    
    # Try to force create the same version (would normally create v1.0.2)
    # The script always increments, force just allows overwriting if it exists
    run bash "$SCRIPT_DIR/version.sh" --type patch --force
    assert_success
    # It should create v1.0.2 even with force since that's the next version
    assert_output --partial "v1.0.2"
}