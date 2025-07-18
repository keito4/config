#!/usr/bin/env zsh

# Brew cleanup script - Remove unused packages

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# List of packages to remove
REMOVE_CASKS=(
    "anaconda"           # Using pyenv instead
    "miniconda"          # Using pyenv instead
    "google-cloud-sdk"   # Duplicate of gcloud-cli
)

REMOVE_FORMULAE=(
    # Add formulae to remove here if needed
)

# Remove casks
echo "=== Removing Unused Casks ==="
for cask in "${REMOVE_CASKS[@]}"; do
    if brew list --cask | grep -q "^$cask$"; then
        print_info "Removing $cask..."
        brew uninstall --cask --force "$cask" || print_error "Failed to remove $cask"
    else
        print_warning "$cask is not installed"
    fi
done

# Remove formulae
if [ ${#REMOVE_FORMULAE[@]} -gt 0 ]; then
    echo -e "\n=== Removing Unused Formulae ==="
    for formula in "${REMOVE_FORMULAE[@]}"; do
        if brew list | grep -q "^$formula$"; then
            print_info "Removing $formula..."
            brew uninstall "$formula" || print_error "Failed to remove $formula"
        else
            print_warning "$formula is not installed"
        fi
    done
fi

# Clean up Python versions
echo -e "\n=== Python Version Check ==="
print_info "Current Python setup:"
echo "pyenv: $(pyenv version)"
echo "which python3: $(which python3)"

# Remove orphaned Python versions from Homebrew
echo -e "\n=== Checking Homebrew Python versions ==="
PYTHON_VERSIONS=(python@3.10 python@3.11 python@3.12 python@3.13)
for py_version in "${PYTHON_VERSIONS[@]}"; do
    if brew uses --installed "$py_version" | grep -q .; then
        print_info "$py_version is used by: $(brew uses --installed "$py_version" | tr '\n' ' ')"
    else
        print_warning "$py_version is not used by any package"
        print_info "To remove it, run: brew uninstall $py_version"
    fi
done

# Clean up
echo -e "\n=== Running Brew Cleanup ==="
brew cleanup --prune=all
brew autoremove

# Show disk space saved
print_success "Cleanup completed!"

# Update PATH if needed
echo -e "\n=== PATH Update Recommendation ==="
if echo $PATH | grep -q "miniconda\|anaconda"; then
    print_warning "Your PATH still contains conda references. Update your .zshrc to remove:"
    echo $PATH | tr ':' '\n' | grep -E "conda|anaconda"
fi