#!/usr/bin/env bats

load test_helper

@test "import.sh: detects Linux OS correctly" {
    # Create mock uname command
    create_mock "uname" 'echo "Linux"'
    
    # Run script and capture OS detection
    run bash -c "source $SCRIPT_DIR/import.sh 2>&1 | head -1 || true"
    
    # The script will fail later due to missing dependencies, but we can check it got past OS detection
    assert_not_contains "$output" "Unsupported OS"
    
    remove_mock "uname"
}

@test "import.sh: detects Darwin OS correctly" {
    # Create mock uname command
    create_mock "uname" 'echo "Darwin"'
    
    # Mock other commands to prevent failures
    create_mock "brew" 'exit 0'
    create_mock "curl" 'exit 0'
    
    # Run script with minimal environment
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required directories and files
    mkdir -p "$TEST_TEMP_DIR/.zsh"
    mkdir -p "$TEST_TEMP_DIR/git"
    mkdir -p "$TEST_TEMP_DIR/brew"
    mkdir -p "$TEST_TEMP_DIR/npm"
    touch "$TEST_TEMP_DIR/git/gitconfig"
    touch "$TEST_TEMP_DIR/git/gitignore"
    touch "$TEST_TEMP_DIR/git/gitattributes"
    echo '{"dependencies": {}}' > "$TEST_TEMP_DIR/npm/global.json"
    
    run bash -c "source $SCRIPT_DIR/import.sh 2>&1 | head -1 || true"
    assert_not_contains "$output" "Unsupported OS"
    
    remove_mock "uname"
    remove_mock "brew"
    remove_mock "curl"
}

@test "import.sh: rejects unsupported OS" {
    # Create mock uname command for unsupported OS
    create_mock "uname" 'echo "Windows"'
    
    run zsh "$SCRIPT_DIR/import.sh"
    assert_failure
    assert_output --partial "Unsupported OS"
    
    remove_mock "uname"
}

@test "import.sh: sets NONINTERACTIVE in Docker environment" {
    # Simulate Docker environment
    touch "$TEST_TEMP_DIR/.dockerenv"
    cd "$TEST_TEMP_DIR"
    
    # Create mocks
    create_mock "uname" 'echo "Linux"'
    create_mock "brew" 'exit 0'
    create_mock "curl" 'exit 0'
    
    # Set REPO_PATH
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create minimal required structure
    mkdir -p "$TEST_TEMP_DIR/.zsh"
    mkdir -p "$TEST_TEMP_DIR/git"
    touch "$TEST_TEMP_DIR/git/gitconfig"
    touch "$TEST_TEMP_DIR/git/gitignore"
    touch "$TEST_TEMP_DIR/git/gitattributes"
    
    # Source the script and check environment variables
    (
        source "$SCRIPT_DIR/import.sh" 2>/dev/null || true
        [[ "$NONINTERACTIVE" == "1" ]]
        [[ "$RUNZSH" == "no" ]]
        [[ "$CHSH" == "no" ]]
        [[ "$KEEP_ZSHRC" == "yes" ]]
    )
    
    assert_success
    
    remove_mock "uname"
    remove_mock "brew"
    remove_mock "curl"
}

@test "import.sh: installs Homebrew when not present" {
    skip "This test requires network access and actual installation"
}

@test "import.sh: skips Homebrew installation when already present" {
    # Create mock commands
    create_mock "uname" 'echo "Linux"'
    create_mock "brew" 'echo "Homebrew 3.0.0"'
    
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create minimal required structure
    mkdir -p "$TEST_TEMP_DIR/.zsh"
    mkdir -p "$TEST_TEMP_DIR/git"
    mkdir -p "$TEST_TEMP_DIR/brew"
    touch "$TEST_TEMP_DIR/git/gitconfig"
    touch "$TEST_TEMP_DIR/git/gitignore"
    touch "$TEST_TEMP_DIR/git/gitattributes"
    touch "$TEST_TEMP_DIR/brew/LinuxBrewfile"
    
    # The script should not attempt to install Homebrew
    run bash -c "source $SCRIPT_DIR/import.sh 2>&1 | grep -c 'raw.githubusercontent.com/Homebrew' || echo 0"
    assert_output "0"
    
    remove_mock "uname"
    remove_mock "brew"
}

@test "import.sh: copies git configuration files" {
    # Create mock commands
    create_mock "uname" 'echo "Linux"'
    create_mock "brew" 'exit 0'
    
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create source files
    mkdir -p "$TEST_TEMP_DIR/git"
    echo "test gitconfig" > "$TEST_TEMP_DIR/git/gitconfig"
    echo "test gitignore" > "$TEST_TEMP_DIR/git/gitignore"
    echo "test gitattributes" > "$TEST_TEMP_DIR/git/gitattributes"
    
    # Create other required directories
    mkdir -p "$TEST_TEMP_DIR/.zsh"
    
    # Run the import script
    zsh "$SCRIPT_DIR/import.sh" 2>/dev/null || true
    
    # Check files were copied to home directory
    assert_exists "$HOME/.gitconfig"
    assert_exists "$HOME/.gitignore"
    assert_exists "$HOME/.gitattributes"
    
    # Clean up
    rm -f "$HOME/.gitconfig" "$HOME/.gitignore" "$HOME/.gitattributes"
    
    remove_mock "uname"
    remove_mock "brew"
}

@test "import.sh: runs brew bundle for Linux" {
    # Create mock commands
    create_mock "uname" 'echo "Linux"'
    create_mock "brew" '
        if [[ "$1" == "bundle" ]]; then
            echo "Running brew bundle with $3"
            exit 0
        fi
        exit 0
    '
    
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required files
    mkdir -p "$TEST_TEMP_DIR/brew"
    touch "$TEST_TEMP_DIR/brew/LinuxBrewfile"
    mkdir -p "$TEST_TEMP_DIR/.zsh"
    mkdir -p "$TEST_TEMP_DIR/git"
    touch "$TEST_TEMP_DIR/git/gitconfig"
    touch "$TEST_TEMP_DIR/git/gitignore"
    touch "$TEST_TEMP_DIR/git/gitattributes"
    
    run zsh "$SCRIPT_DIR/import.sh"
    assert_success
    assert_output --partial "LinuxBrewfile"
    
    remove_mock "uname"
    remove_mock "brew"
}

@test "import.sh: runs brew bundle for macOS" {
    # Create mock commands
    create_mock "uname" 'echo "Darwin"'
    create_mock "brew" '
        if [[ "$1" == "bundle" ]]; then
            echo "Running brew bundle with $3"
            exit 0
        fi
        exit 0
    '
    create_mock "code" 'exit 127'  # Simulate VS Code not installed
    
    cd "$TEST_TEMP_DIR"
    export REPO_PATH="$TEST_TEMP_DIR"
    
    # Create required files
    mkdir -p "$TEST_TEMP_DIR/brew"
    touch "$TEST_TEMP_DIR/brew/MacOSBrewfile"
    mkdir -p "$TEST_TEMP_DIR/.zsh"
    mkdir -p "$TEST_TEMP_DIR/git"
    touch "$TEST_TEMP_DIR/git/gitconfig"
    touch "$TEST_TEMP_DIR/git/gitignore"
    touch "$TEST_TEMP_DIR/git/gitattributes"
    
    run zsh "$SCRIPT_DIR/import.sh"
    assert_success
    assert_output --partial "MacOSBrewfile"
    
    remove_mock "uname"
    remove_mock "brew"
    remove_mock "code"
}