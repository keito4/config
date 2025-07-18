#!/usr/bin/env zsh

# 1Password credential management script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine script directory
SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
CREDENTIALS_DIR="$REPO_ROOT/credentials"

# Functions
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

check_op_cli() {
    if ! command -v op &> /dev/null; then
        print_error "1Password CLI (op) is not installed"
        echo "Install it with: brew install --cask 1password-cli"
        exit 1
    fi
}

check_op_signin() {
    if ! op account list &> /dev/null; then
        print_error "Not signed in to 1Password"
        echo "Sign in with: op signin"
        exit 1
    fi
}

inject_template() {
    local template="$1"
    local output="$2"
    
    if [[ ! -f "$template" ]]; then
        print_error "Template file not found: $template"
        return 1
    fi
    
    echo "Processing: $(basename "$template")"
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$output")"
    
    # Use op inject to process the template
    if op inject --in-file "$template" --out-file "$output" 2>/dev/null; then
        print_success "Generated: $output"
        chmod 600 "$output"  # Secure the file
    else
        print_error "Failed to process: $template"
        return 1
    fi
}

fetch_all_credentials() {
    echo "Fetching all credentials from 1Password..."
    
    # Process all template files
    for template in "$CREDENTIALS_DIR"/templates/*.env.template; do
        if [[ -f "$template" ]]; then
            local basename=$(basename "$template" .env.template)
            local output="$CREDENTIALS_DIR/${basename}.env"
            inject_template "$template" "$output"
        fi
    done
    
    # Also process the legacy template if it exists
    if [[ -f "$REPO_ROOT/.zsh/configs/pre/.env.secret.template" ]]; then
        print_warning "Legacy template found, processing..."
        inject_template "$REPO_ROOT/.zsh/configs/pre/.env.secret.template" \
                       "$REPO_ROOT/.zsh/configs/pre/.env.secret"
    fi
}

clean_credentials() {
    echo "Cleaning up credential files..."
    
    # Remove generated credential files
    find "$CREDENTIALS_DIR" -name "*.env" -not -name "*.template" -delete
    
    # Remove legacy secret file
    rm -f "$REPO_ROOT/.zsh/configs/pre/.env.secret"
    
    print_success "Credential files cleaned up"
}

list_templates() {
    echo "Available credential templates:"
    echo
    
    for template in "$CREDENTIALS_DIR"/templates/*.env.template; do
        if [[ -f "$template" ]]; then
            local basename=$(basename "$template" .env.template)
            echo "  - $basename"
        fi
    done
}

# Main command handling
case "${1:-}" in
    fetch|get)
        check_op_cli
        check_op_signin
        fetch_all_credentials
        ;;
    clean)
        clean_credentials
        ;;
    list)
        list_templates
        ;;
    *)
        echo "Usage: $0 {fetch|get|clean|list}"
        echo
        echo "Commands:"
        echo "  fetch, get  - Fetch credentials from 1Password"
        echo "  clean       - Remove all generated credential files"
        echo "  list        - List available credential templates"
        exit 1
        ;;
esac