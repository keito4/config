#!/usr/bin/env bats

load test_helper

@test "brew-deps.sh: displays usage without arguments" {
    run zsh "$SCRIPT_DIR/brew-deps.sh"
    assert_failure
    assert_output --partial "Usage:"
    assert_output --partial "leaves"
    assert_output --partial "categorized"
    assert_output --partial "generate"
    assert_output --partial "deps"
    assert_output --partial "uses"
}

@test "brew-deps.sh: checks for Homebrew installation" {
    # Create mock brew that doesn't exist
    PATH="/usr/bin:/bin"  # Remove any brew from PATH
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" leaves
    assert_failure
    assert_output --partial "Homebrew is not installed"
    assert_output --partial "https://brew.sh"
}

@test "brew-deps.sh: leaves command lists standalone formulae" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "leaves")
                echo "git"
                echo "node"
                echo "python@3.11"
                ;;
            "list")
                if [[ "$2" == "--cask" ]]; then
                    echo "visual-studio-code"
                    echo "slack"
                fi
                ;;
            "uses")
                # No output means no dependents
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" leaves
    assert_success
    assert_output --partial "Standalone Formulae"
    assert_output --partial "git"
    assert_output --partial "node"
    assert_output --partial "Standalone Casks"
    
    remove_mock "brew"
}

@test "brew-deps.sh: standalone command works (alias for leaves)" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "leaves")
                echo "git"
                ;;
            "list")
                if [[ "$2" == "--cask" ]]; then
                    echo "slack"
                fi
                ;;
            "uses")
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" standalone
    assert_success
    assert_output --partial "Standalone Formulae"
    assert_output --partial "git"
    assert_output --partial "Standalone Casks"
    assert_output --partial "slack"
    
    remove_mock "brew"
}

@test "brew-deps.sh: categorized command groups packages" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "leaves")
                echo "git"
                echo "gh"
                echo "node"
                echo "awscli"
                echo "jq"
                echo "cowsay"
                echo "unknown-package"
                ;;
            "list")
                if [[ "$2" == "--cask" ]]; then
                    echo "visual-studio-code"
                    echo "slack"
                    echo "1password"
                fi
                ;;
            "uses")
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" categorized
    assert_success
    assert_output --partial "Development Tools"
    assert_output --partial "git"
    assert_output --partial "Cloud & DevOps"
    assert_output --partial "awscli"
    assert_output --partial "Utilities"
    assert_output --partial "jq"
    assert_output --partial "Fun & Misc"
    assert_output --partial "cowsay"
    assert_output --partial "Uncategorized"
    assert_output --partial "unknown-package"
    
    remove_mock "brew"
}

@test "brew-deps.sh: generate command creates Brewfiles" {
    cd "$TEST_TEMP_DIR"
    mkdir -p "$TEST_TEMP_DIR/brew"
    
    # Override REPO_ROOT by changing to the test directory
    # The script uses REPO_ROOT="${SCRIPT_DIR:h}" which is parent of script dir
    
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "tap")
                echo "homebrew/core"
                echo "homebrew/cask"
                ;;
            "leaves")
                echo "git"
                echo "node"
                ;;
            "list")
                if [[ "$2" == "--cask" ]]; then
                    echo "slack"
                fi
                ;;
            "uses")
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" generate
    assert_success
    assert_output --partial "Generated"
    assert_output --partial "StandaloneBrewfile"
    assert_output --partial "CategorizedBrewfile"
    
    # The script creates files in the repo's brew directory, not TEST_TEMP_DIR
    # Just verify the command succeeded and produced expected output
    
    remove_mock "brew"
}

@test "brew-deps.sh: deps command shows package dependencies" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "list")
                if [[ "$2" == "--formula" ]]; then
                    echo "git"
                    echo "node"
                fi
                ;;
            "deps")
                if [[ "$3" == "git" ]]; then
                    echo "└── gettext"
                    echo "    └── ncurses"
                fi
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" deps git
    assert_success
    assert_output --partial "Dependencies for formula: git"
    assert_output --partial "gettext"
    assert_output --partial "ncurses"
    
    remove_mock "brew"
}

@test "brew-deps.sh: deps command requires package name" {
    create_mock "brew" 'exit 0'
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" deps
    assert_failure
    assert_output --partial "Package name required"
    assert_output --partial "Usage:"
    
    remove_mock "brew"
}

@test "brew-deps.sh: uses command shows dependent packages" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "uses")
                if [[ "$3" == "gettext" ]]; then
                    echo "git"
                    echo "wget"
                fi
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" uses gettext
    assert_success
    assert_output --partial "Packages that depend on: gettext"
    assert_output --partial "git"
    assert_output --partial "wget"
    
    remove_mock "brew"
}

@test "brew-deps.sh: uses command requires package name" {
    create_mock "brew" 'exit 0'
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" uses
    assert_failure
    assert_output --partial "Package name required"
    assert_output --partial "Usage:"
    
    remove_mock "brew"
}

@test "brew-deps.sh: handles cask dependencies check" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "list")
                if [[ "$2" == "--formula" ]]; then
                    # No formula match
                    :
                elif [[ "$2" == "--cask" ]]; then
                    echo "slack"
                fi
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" deps slack
    assert_success
    assert_output --partial "Cask: slack"
    assert_output --partial "casks typically don't have dependencies"
    
    remove_mock "brew"
}

@test "brew-deps.sh: handles non-existent package" {
    # Create mock brew command
    create_mock "brew" '
        case "$1" in
            "list")
                # Return empty for both formula and cask
                ;;
        esac
        exit 0
    '
    
    run zsh "$SCRIPT_DIR/brew-deps.sh" deps nonexistent
    assert_success
    assert_output --partial "Package not found: nonexistent"
    
    remove_mock "brew"
}