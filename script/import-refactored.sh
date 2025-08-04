#!/usr/bin/env bash
# Refactored configuration import script
# Modular version with improved error handling and maintainability

set -euo pipefail

# Determine script directory (handle symlinks)
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
    SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
    [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source libraries
# shellcheck source=./lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
readonly CONFIG_VERSION="2.0.0"
readonly REPO_PATH="${REPO_PATH:-$REPO_ROOT}"

# Component flags (can be overridden)
INSTALL_HOMEBREW=${INSTALL_HOMEBREW:-true}
INSTALL_OH_MY_ZSH=${INSTALL_OH_MY_ZSH:-true}
INSTALL_ZSH_PLUGINS=${INSTALL_ZSH_PLUGINS:-true}
INSTALL_BREW_PACKAGES=${INSTALL_BREW_PACKAGES:-true}
INSTALL_NPM_PACKAGES=${INSTALL_NPM_PACKAGES:-true}
INSTALL_VSCODE_EXTENSIONS=${INSTALL_VSCODE_EXTENSIONS:-true}
CONFIGURE_GIT=${CONFIGURE_GIT:-true}
CLONE_REPOS=${CLONE_REPOS:-false}
DRY_RUN=${DRY_RUN:-false}

# Show usage information
show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --skip-homebrew         Skip Homebrew installation
    --skip-oh-my-zsh       Skip Oh My Zsh installation
    --skip-zsh-plugins     Skip Zsh plugins installation
    --skip-brew-packages   Skip Brew packages installation
    --skip-npm-packages    Skip NPM packages installation
    --skip-vscode          Skip VS Code extensions installation
    --skip-git-config      Skip Git configuration
    --clone-repos          Clone all user repositories with ghq
    --dry-run              Show what would be done without making changes
    -v, --verbose          Enable verbose output
    -h, --help             Show this help message

Environment Variables:
    REPO_PATH              Path to config repository (default: current directory)
    NONINTERACTIVE         Set to 1 for non-interactive mode
    
Examples:
    $0                              # Full installation
    $0 --skip-brew-packages        # Skip Brew packages
    $0 --dry-run                   # Preview changes
    $0 --clone-repos               # Include repository cloning

EOF
}

# Detect environment
detect_environment() {
    local os
    os=$(detect_os)
    
    log_info "Detected OS: $os"
    
    if is_container; then
        log_info "Running in container/devcontainer environment"
        export NONINTERACTIVE=1
        export RUNZSH=no
        export CHSH=no
        export KEEP_ZSHRC=yes
    fi
    
    echo "$os"
}

# Install Homebrew
install_homebrew() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Homebrew"
        return 0
    fi
    
    if command_exists "brew"; then
        log_info "Homebrew already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    if is_container; then
        # Non-interactive installation for containers
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Add Homebrew to PATH for Linux
    if [[ "$(detect_os)" == "linux" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    
    log_success "Homebrew installed successfully"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Oh My Zsh"
        return 0
    fi
    
    if [[ -d ~/.oh-my-zsh ]]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi
    
    log_info "Installing Oh My Zsh..."
    
    env RUNZSH="${RUNZSH:-no}" \
        CHSH="${CHSH:-no}" \
        KEEP_ZSHRC="${KEEP_ZSHRC:-yes}" \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    log_success "Oh My Zsh installed successfully"
}

# Install Zsh plugins
install_zsh_plugins() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Zsh plugins"
        return 0
    fi
    
    local plugins_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins"
    
    # zsh-autosuggestions
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions already installed"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi
    
    log_success "Zsh plugins installed successfully"
}

# Install Brew packages
install_brew_packages() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Brew packages"
        return 0
    fi
    
    if ! command_exists "brew"; then
        log_warning "Homebrew not installed, skipping packages"
        return 1
    fi
    
    local os
    os=$(detect_os)
    local brewfile=""
    
    case "$os" in
        linux)
            brewfile="$REPO_PATH/brew/LinuxBrewfile"
            ;;
        darwin)
            brewfile="$REPO_PATH/brew/MacOSBrewfile"
            ;;
        *)
            log_warning "Unsupported OS for Brew packages: $os"
            return 1
            ;;
    esac
    
    if [[ -f "$brewfile" ]]; then
        log_info "Installing Brew packages from: $brewfile"
        brew bundle --file "$brewfile"
        log_success "Brew packages installed successfully"
    else
        log_warning "Brewfile not found: $brewfile"
    fi
}

# Install NPM packages
install_npm_packages() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install NPM packages"
        return 0
    fi
    
    if ! command_exists "npm"; then
        log_warning "NPM not installed, skipping packages"
        return 1
    fi
    
    if ! command_exists "jq"; then
        log_warning "jq not installed, skipping NPM packages"
        return 1
    fi
    
    local npm_config="$REPO_PATH/npm/global.json"
    
    if [[ -f "$npm_config" ]]; then
        log_info "Installing global NPM packages..."
        local packages
        packages=$(jq -r '.dependencies | keys | .[]' "$npm_config")
        
        if [[ -n "$packages" ]]; then
            echo "$packages" | xargs npm install -g
            log_success "NPM packages installed successfully"
        else
            log_info "No NPM packages to install"
        fi
    else
        log_warning "NPM config not found: $npm_config"
    fi
}

# Install VS Code extensions
install_vscode_extensions() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install VS Code extensions"
        return 0
    fi
    
    local extensions_file="$REPO_PATH/vscode/extensions.txt"
    
    if [[ ! -f "$extensions_file" ]]; then
        log_warning "Extensions file not found: $extensions_file"
        return 1
    fi
    
    # Try different VS Code commands
    local vscode_cmd=""
    if command_exists "cursor"; then
        vscode_cmd="cursor"
    elif command_exists "code"; then
        vscode_cmd="code"
    else
        log_warning "VS Code/Cursor not found, skipping extensions"
        return 1
    fi
    
    log_info "Installing VS Code extensions using $vscode_cmd..."
    while IFS= read -r extension; do
        if [[ -n "$extension" ]] && [[ ! "$extension" =~ ^# ]]; then
            log_debug "Installing extension: $extension"
            $vscode_cmd --install-extension "$extension" || true
        fi
    done < "$extensions_file"
    
    log_success "VS Code extensions installed successfully"
}

# Configure Git
configure_git() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would configure Git"
        return 0
    fi
    
    log_info "Configuring Git..."
    
    # Copy Git configuration files
    for file in gitconfig gitignore gitattributes; do
        local src="$REPO_PATH/git/$file"
        local dst="$HOME/.$file"
        
        if [[ -f "$src" ]]; then
            backup_file "$dst"
            cp "$src" "$dst"
            log_debug "Copied $file to $dst"
        else
            log_warning "Git config not found: $src"
        fi
    done
    
    # Special handling for containers
    if is_container; then
        log_info "Configuring Git for container environment..."
        
        # Set user configuration
        git config --global user.name "${GIT_USER_NAME:-keito4}"
        git config --global user.email "${GIT_USER_EMAIL:-newton30000@gmail.com}"
        
        # Remove problematic URL aliases
        git config --global --remove-section url."github:" 2>/dev/null || true
        
        # Configure 1Password SSH signing if available
        if command_exists "op"; then
            git config --global gpg.ssh.program "op-ssh-sign"
            log_info "1Password SSH signing configured"
        else
            log_info "Installing 1Password CLI..."
            if [[ "$(detect_os)" == "linux" ]]; then
                curl -sS https://downloads.1password.com/linux/debian/amd64/stable/1password-cli-amd64-latest.deb -o /tmp/1password-cli.deb
                sudo dpkg -i /tmp/1password-cli.deb
                rm /tmp/1password-cli.deb
                
                if command_exists "op"; then
                    git config --global gpg.ssh.program "op-ssh-sign"
                    log_success "1Password CLI installed and configured"
                else
                    git config --global commit.gpgsign false
                    log_warning "1Password CLI installation failed, disabling GPG signing"
                fi
            fi
        fi
    fi
    
    log_success "Git configured successfully"
}

# Copy shell configuration
copy_shell_config() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would copy shell configuration"
        return 0
    fi
    
    log_info "Copying shell configuration..."
    
    # Copy .zsh directory
    if [[ -d "$REPO_PATH/.zsh" ]]; then
        cp -r "$REPO_PATH/.zsh" ~/
        log_debug "Copied .zsh directory"
    fi
    
    # Copy git directory (legacy)
    if [[ -d "$REPO_PATH/git" ]]; then
        cp -r "$REPO_PATH/git" ~/
        log_debug "Copied git directory"
    fi
    
    log_success "Shell configuration copied"
}

# Clone user repositories
clone_user_repos() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would clone user repositories"
        return 0
    fi
    
    if ! command_exists "gh"; then
        log_warning "GitHub CLI not installed, skipping repository cloning"
        return 1
    fi
    
    if ! command_exists "ghq"; then
        log_warning "ghq not installed, skipping repository cloning"
        return 1
    fi
    
    log_info "Cloning user repositories..."
    
    if gh auth status &>/dev/null; then
        gh api user/repos --paginate | jq -r '.[].ssh_url' | while read -r repo_url; do
            log_debug "Cloning: $repo_url"
            ghq get "$repo_url" || true
        done
        log_success "Repositories cloned successfully"
    else
        log_warning "Not authenticated with GitHub CLI"
        log_info "Run 'gh auth login' to authenticate"
    fi
}

# Main execution
main() {
    local args=("$@")
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-homebrew)
                INSTALL_HOMEBREW=false
                shift
                ;;
            --skip-oh-my-zsh)
                INSTALL_OH_MY_ZSH=false
                shift
                ;;
            --skip-zsh-plugins)
                INSTALL_ZSH_PLUGINS=false
                shift
                ;;
            --skip-brew-packages)
                INSTALL_BREW_PACKAGES=false
                shift
                ;;
            --skip-npm-packages)
                INSTALL_NPM_PACKAGES=false
                shift
                ;;
            --skip-vscode)
                INSTALL_VSCODE_EXTENSIONS=false
                shift
                ;;
            --skip-git-config)
                CONFIGURE_GIT=false
                shift
                ;;
            --clone-repos)
                CLONE_REPOS=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                export LOG_LEVEL=$LOG_LEVEL_DEBUG
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Start installation
    log_info "Starting configuration import (v$CONFIG_VERSION)"
    log_info "Repository path: $REPO_PATH"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Detect environment
    local os
    os=$(detect_environment)
    
    # Execute installation steps
    local steps_completed=0
    local steps_failed=0
    
    # Homebrew
    if [[ "$INSTALL_HOMEBREW" == "true" ]]; then
        if install_homebrew; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # Oh My Zsh
    if [[ "$INSTALL_OH_MY_ZSH" == "true" ]]; then
        if install_oh_my_zsh; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # Zsh plugins
    if [[ "$INSTALL_ZSH_PLUGINS" == "true" ]]; then
        if install_zsh_plugins; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # Brew packages
    if [[ "$INSTALL_BREW_PACKAGES" == "true" ]]; then
        if install_brew_packages; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # Shell configuration
    if copy_shell_config; then
        ((steps_completed++))
    else
        ((steps_failed++))
    fi
    
    # Git configuration
    if [[ "$CONFIGURE_GIT" == "true" ]]; then
        if configure_git; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # NPM packages
    if [[ "$INSTALL_NPM_PACKAGES" == "true" ]]; then
        if install_npm_packages; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # VS Code extensions
    if [[ "$INSTALL_VSCODE_EXTENSIONS" == "true" ]]; then
        if install_vscode_extensions; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # Clone repositories
    if [[ "$CLONE_REPOS" == "true" ]]; then
        if clone_user_repos; then
            ((steps_completed++))
        else
            ((steps_failed++))
        fi
    fi
    
    # Summary
    echo ""
    log_info "========================================="
    log_info "Configuration import completed!"
    log_info "Steps completed: $steps_completed"
    if [[ $steps_failed -gt 0 ]]; then
        log_warning "Steps failed: $steps_failed"
    fi
    log_info "========================================="
    
    if [[ $steps_failed -gt 0 ]]; then
        exit 1
    fi
}

# Run main function
main "$@"