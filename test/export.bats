#!/usr/bin/env bats

load test_helper

@test "export.sh: creates required directories" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    run zsh "$SCRIPT_DIR/export.sh"
    
    # Check directories were created
    assert_exists "$TEST_TEMP_DIR/brew"
    assert_exists "$TEST_TEMP_DIR/vscode"
    assert_exists "$TEST_TEMP_DIR/git"
    assert_exists "$TEST_TEMP_DIR/npm"
    assert_exists "$TEST_TEMP_DIR/.zsh"
    
    remove_mock "uname"
}

@test "export.sh: detects Linux OS correctly" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # Create mock brew to verify Linux-specific behavior
    create_mock "brew" '
        if [[ "$3" == *"LinuxBrewfile"* ]]; then
            echo "Linux Brewfile dump"
            exit 0
        fi
        exit 1
    '
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    assert_output --partial "Linux Brewfile dump"
    
    remove_mock "uname"
    remove_mock "brew"
}

@test "export.sh: detects Darwin OS correctly" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Darwin"'
    
    # Create mock cursor for VS Code extensions
    create_mock "cursor" '
        if [[ "$1" == "--list-extensions" ]]; then
            echo "extension1"
            echo "extension2"
            exit 0
        fi
        exit 1
    '
    
    # Create mock brew
    create_mock "brew" '
        if [[ "$3" == *"MacOSBrewfile"* ]]; then
            echo "macOS Brewfile dump"
            exit 0
        fi
        exit 1
    '
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    
    # Check VS Code extensions were exported
    assert_exists "$TEST_TEMP_DIR/vscode/extensions.txt"
    run cat "$TEST_TEMP_DIR/vscode/extensions.txt"
    assert_output --partial "extension1"
    assert_output --partial "extension2"
    
    remove_mock "uname"
    remove_mock "cursor"
    remove_mock "brew"
}

@test "export.sh: detects devcontainer environment" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create .dockerenv to simulate container
    touch "$TEST_TEMP_DIR/.dockerenv"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # Mock brew should not be called in devcontainer
    create_mock "brew" '
        echo "brew should not be called in devcontainer"
        exit 1
    '
    
    # Run export in devcontainer context
    cd "$TEST_TEMP_DIR"
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    assert_not_contains "$output" "brew should not be called"
    
    remove_mock "uname"
    remove_mock "brew"
}

@test "export.sh: exports git configuration files" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # Create source git config files in HOME
    echo "test gitconfig content" > "$HOME/.gitconfig"
    echo "test gitignore content" > "$HOME/.gitignore"
    echo "test gitattributes content" > "$HOME/.gitattributes"
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    
    # Check files were exported
    assert_exists "$TEST_TEMP_DIR/git/gitconfig"
    assert_exists "$TEST_TEMP_DIR/git/gitignore"
    assert_exists "$TEST_TEMP_DIR/git/gitattributes"
    
    # Verify content
    run cat "$TEST_TEMP_DIR/git/gitconfig"
    assert_output "test gitconfig content"
    
    # Clean up
    rm -f "$HOME/.gitconfig" "$HOME/.gitignore" "$HOME/.gitattributes"
    
    remove_mock "uname"
}

@test "export.sh: skips missing git configuration files" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # Ensure no git config files exist in HOME
    rm -f "$HOME/.gitconfig" "$HOME/.gitignore" "$HOME/.gitattributes"
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    
    # Files should not be created if they don't exist in HOME
    assert_not_exists "$TEST_TEMP_DIR/git/gitconfig"
    assert_not_exists "$TEST_TEMP_DIR/git/gitignore"
    assert_not_exists "$TEST_TEMP_DIR/git/gitattributes"
    
    remove_mock "uname"
}

@test "export.sh: exports npm global packages" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # Create mock npm
    create_mock "npm" '
        if [[ "$1" == "list" ]] && [[ "$2" == "-g" ]]; then
            echo "{\"dependencies\": {\"package1\": \"1.0.0\"}}"
            exit 0
        fi
        exit 1
    '
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    
    # Check npm packages were exported
    assert_exists "$TEST_TEMP_DIR/npm/global.json"
    run cat "$TEST_TEMP_DIR/npm/global.json"
    assert_output --partial "package1"
    
    remove_mock "uname"
    remove_mock "npm"
}

@test "export.sh: handles npm not installed" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # No npm mock means command not found
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    
    # Should not create npm file if npm is not available
    assert_not_exists "$TEST_TEMP_DIR/npm/global.json"
    
    remove_mock "uname"
}

@test "export.sh: exports .zsh directory" {
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create mock uname
    create_mock "uname" 'echo "Linux"'
    
    # Create source .zsh directory in HOME
    mkdir -p "$HOME/.zsh/custom"
    echo "test zsh config" > "$HOME/.zsh/custom/config.zsh"
    
    run zsh "$SCRIPT_DIR/export.sh"
    assert_success
    
    # Check .zsh was exported
    assert_exists "$TEST_TEMP_DIR/.zsh/custom/config.zsh"
    
    # Clean up
    rm -rf "$HOME/.zsh/custom"
    
    remove_mock "uname"
}