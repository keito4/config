#!/usr/bin/env bash
# Refactored Brew dependency management script
# Modular version with improved maintainability

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
# shellcheck source=./lib/brew.sh
source "${SCRIPT_DIR}/lib/brew.sh"

# Configuration
readonly BREW_DIR="${REPO_ROOT}/brew"
readonly STANDALONE_BREWFILE="${BREW_DIR}/StandaloneBrewfile"
readonly CATEGORIZED_BREWFILE="${BREW_DIR}/CategorizedBrewfile"

# Show usage information
show_usage() {
    cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    leaves, standalone    List packages without dependents
    categorized          List packages organized by category
    generate             Generate Brewfiles for standalone packages
    deps <package>       Show dependencies of a package
    uses <package>       Show packages that depend on a package
    help                 Show this help message

Options:
    --verbose, -v        Enable verbose output
    --dry-run            Show what would be done without making changes

Examples:
    $0 leaves                    # List standalone packages
    $0 categorized               # Show categorized packages
    $0 generate                  # Create Brewfiles
    $0 deps git                  # Show git dependencies
    $0 uses openssl              # Show what depends on openssl

EOF
}

# List standalone packages
list_standalone_packages() {
    log_info "=== Standalone Formulae (no dependents) ==="
    get_formula_leaves
    
    echo ""
    log_info "=== Standalone Casks ==="
    get_cask_leaves
}

# List categorized packages
list_categorized_packages() {
    log_info "=== Categorized Standalone Packages ==="
    
    echo ""
    log_info "--- FORMULAE ---"
    local formulae
    formulae=$(get_formula_leaves)
    categorize_packages "formula" "$formulae" FORMULA_CATEGORIES
    
    echo ""
    log_info "--- CASKS ---"
    local casks
    casks=$(get_cask_leaves)
    categorize_packages "cask" "$casks" CASK_CATEGORIES
}

# Generate standalone Brewfile
generate_standalone_brewfile() {
    log_info "Generating standalone Brewfile..."
    
    ensure_dir "$BREW_DIR"
    
    {
        echo "# Homebrew packages without dependencies"
        echo "# Generated on $(date)"
        echo "# This file contains only packages that were explicitly installed"
        echo "# and are not dependencies of other packages"
        echo ""
        
        generate_taps
        
        echo "# Formulae (command-line tools)"
        get_formula_leaves | while read -r formula; do
            echo "brew \"$formula\""
        done
        echo ""
        
        echo "# Casks (GUI applications)"
        get_cask_leaves | while read -r cask; do
            echo "cask \"$cask\""
        done
    } > "$STANDALONE_BREWFILE"
    
    log_success "Generated: $STANDALONE_BREWFILE"
}

# Generate categorized Brewfile
generate_categorized_brewfile() {
    log_info "Generating categorized Brewfile..."
    
    ensure_dir "$BREW_DIR"
    
    {
        echo "# Categorized Homebrew packages without dependencies"
        echo "# Generated on $(date)"
        echo "# Organized by functionality"
        echo ""
        
        generate_taps
        
        echo "# === FORMULAE ==="
        echo ""
        
        local formulae
        formulae=$(get_formula_leaves)
        categorize_packages "formula" "$formulae" FORMULA_CATEGORIES
        
        echo ""
        echo "# === CASKS ==="
        echo ""
        
        local casks
        casks=$(get_cask_leaves)
        categorize_packages "cask" "$casks" CASK_CATEGORIES
    } > "$CATEGORIZED_BREWFILE"
    
    log_success "Generated: $CATEGORIZED_BREWFILE"
}

# Main execution
main() {
    local command="${1:-}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                export LOG_LEVEL=$LOG_LEVEL_DEBUG
                shift
                ;;
            --dry-run)
                export DRY_RUN=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check Homebrew installation
    check_brew
    
    # Execute command
    case "$command" in
        leaves|standalone)
            list_standalone_packages
            ;;
        categorized)
            list_categorized_packages
            ;;
        generate)
            generate_standalone_brewfile
            generate_categorized_brewfile
            ;;
        deps)
            local package="${1:-}"
            if [[ -z "$package" ]]; then
                die "Package name required. Usage: $0 deps <package>"
            fi
            show_deps_tree "$package"
            ;;
        uses)
            local package="${1:-}"
            if [[ -z "$package" ]]; then
                die "Package name required. Usage: $0 uses <package>"
            fi
            show_dependents "$package"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"