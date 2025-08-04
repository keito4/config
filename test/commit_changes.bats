#!/usr/bin/env bats

load test_helper

@test "commit_changes.sh: requires REPO_PATH to be set" {
    unset REPO_PATH
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_failure
    assert_output --partial "REPO_PATH is not set"
}

@test "commit_changes.sh: requires REPO_PATH directory to exist" {
    export REPO_PATH="/nonexistent/directory"
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_failure
    assert_output --partial "Directory /nonexistent/directory does not exist"
}

@test "commit_changes.sh: calls export.sh script" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required structure
    mkdir -p "$TEST_TEMP_DIR/script"
    
    # Create mock export.sh
    cat > "$TEST_TEMP_DIR/script/export.sh" << 'EOF'
#!/bin/bash
echo "Export script called"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/script/export.sh"
    
    # Initialize git repo
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create mock git to prevent actual git operations
    create_mock "git" '
        if [[ "$1" == "status" ]] && [[ "$2" == "--porcelain" ]]; then
            # Return empty to indicate no changes
            exit 0
        fi
        exit 0
    '
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_success
    assert_output --partial "Export script called"
    
    remove_mock "git"
}

@test "commit_changes.sh: detects git changes and attempts commit" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required structure
    mkdir -p "$TEST_TEMP_DIR/script"
    
    # Create mock export.sh
    cat > "$TEST_TEMP_DIR/script/export.sh" << 'EOF'
#!/bin/bash
echo "Export script called"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/script/export.sh"
    
    # Initialize git repo
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create a file to have changes
    echo "test" > "$TEST_TEMP_DIR/test.txt"
    
    # Create mock aicommits
    create_mock "aicommits" '
        echo "AI commits called with: $@"
        exit 0
    '
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_success
    assert_output --partial "Export script called"
    assert_output --partial "AI commits called with: --all"
    
    remove_mock "aicommits"
}

@test "commit_changes.sh: skips commit when no changes" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required structure
    mkdir -p "$TEST_TEMP_DIR/script"
    
    # Create mock export.sh
    cat > "$TEST_TEMP_DIR/script/export.sh" << 'EOF'
#!/bin/bash
echo "Export script called"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/script/export.sh"
    
    # Initialize git repo with no changes
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    touch "$TEST_TEMP_DIR/test.txt"
    git add .
    git commit -m "Initial commit"
    
    # Create mock aicommits (should not be called)
    create_mock "aicommits" '
        echo "AI commits should not be called"
        exit 1
    '
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_success
    assert_output --partial "Export script called"
    assert_not_contains "$output" "AI commits"
    
    remove_mock "aicommits"
}

@test "commit_changes.sh: handles export.sh failure" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required structure
    mkdir -p "$TEST_TEMP_DIR/script"
    
    # Create failing export.sh
    cat > "$TEST_TEMP_DIR/script/export.sh" << 'EOF'
#!/bin/bash
echo "Export script failed"
exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/script/export.sh"
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_failure
    assert_output --partial "Export script failed"
}

@test "commit_changes.sh: changes directory to REPO_PATH" {
    # Create a separate directory for REPO_PATH
    mkdir -p "$TEST_TEMP_DIR/repo"
    export REPO_PATH="$TEST_TEMP_DIR/repo"
    
    # Create required structure
    mkdir -p "$REPO_PATH/script"
    
    # Create export.sh that checks current directory
    cat > "$REPO_PATH/script/export.sh" << 'EOF'
#!/bin/bash
echo "Current directory: $(pwd)"
exit 0
EOF
    chmod +x "$REPO_PATH/script/export.sh"
    
    # Initialize git repo
    cd "$REPO_PATH"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Run from different directory
    cd "$TEST_TEMP_DIR"
    
    # Create mock git to prevent actual operations
    create_mock "git" '
        if [[ "$1" == "status" ]] && [[ "$2" == "--porcelain" ]]; then
            exit 0
        fi
        exit 0
    '
    
    run bash "$SCRIPT_DIR/commit_changes.sh"
    assert_success
    assert_output --partial "Current directory: $REPO_PATH"
    
    remove_mock "git"
}