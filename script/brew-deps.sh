#!/usr/bin/env zsh

# Brew dependency management script
# This script helps manage Homebrew packages by categorizing them based on dependencies

set -euo pipefail

# Determine script directory
SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
BREW_DIR="$REPO_ROOT/brew"
CATEGORY_MANIFEST="$BREW_DIR/categories.json"
CATEGORY_SCRIPT="$SCRIPT_DIR/lib/brew_categories.py"

source "$SCRIPT_DIR/lib/output.sh"

check_brew() {
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed"
        echo "Install it from: https://brew.sh"
        exit 1
    fi
}

get_leaves() {
    # Get all formulae that are not dependencies of other formulae
    brew leaves
}

ensure_category_assets() {
    local ok=0
    if ! command -v python3 >/dev/null 2>&1; then
        print_warning "python3 is required for categorization but not installed"
        ok=1
    fi
    if [[ ! -f "$CATEGORY_MANIFEST" ]]; then
        print_warning "Category manifest not found at $CATEGORY_MANIFEST"
        ok=1
    fi
    if [[ ! -f "$CATEGORY_SCRIPT" ]]; then
        print_warning "Category helper script not found at $CATEGORY_SCRIPT"
        ok=1
    fi
    [[ $ok -eq 0 ]]
}

get_leaves_with_categories() {
    if ! ensure_category_assets; then
        get_leaves
        return
    fi
    brew leaves | python3 "$CATEGORY_SCRIPT" --manifest "$CATEGORY_MANIFEST" --type formulae --format human --label-uncategorized
}

get_cask_leaves() {
    # Get all casks that were explicitly installed (not dependencies)
    brew list --cask | while read cask; do
        # Check if this cask is a dependency of another cask
        if ! brew uses --cask --installed "$cask" | grep -q .; then
            echo "$cask"
        fi
    done
}

get_cask_leaves_with_categories() {
    if ! ensure_category_assets; then
        get_cask_leaves
        return
    fi
    get_cask_leaves | python3 "$CATEGORY_SCRIPT" --manifest "$CATEGORY_MANIFEST" --type casks --format human --label-uncategorized
}

generate_standalone_brewfile() {
    local output="$BREW_DIR/StandaloneBrewfile"
    
    echo "# Homebrew packages without dependencies" > "$output"
    echo "# Generated on $(date)" >> "$output"
    echo "# This file contains only packages that were explicitly installed" >> "$output"
    echo "# and are not dependencies of other packages" >> "$output"
    echo "" >> "$output"
    
    # Add taps
    echo "# Taps" >> "$output"
    brew tap | while read tap; do
        echo "tap \"$tap\"" >> "$output"
    done
    echo "" >> "$output"
    
    # Add formulae
    echo "# Formulae (command-line tools)" >> "$output"
    get_leaves | while read formula; do
        echo "brew \"$formula\"" >> "$output"
    done
    echo "" >> "$output"
    
    # Add casks
    echo "# Casks (GUI applications)" >> "$output"
    get_cask_leaves | while read cask; do
        echo "cask \"$cask\"" >> "$output"
    done
    
    print_success "Generated $output"
}

generate_categorized_brewfile() {
    local output="$BREW_DIR/CategorizedBrewfile"
    if ! ensure_category_assets; then
        print_error "Cannot generate categorized Brewfile without category manifest"
        exit 1
    fi

    {
        echo "# Categorized Homebrew packages without dependencies"
        echo "# Generated on $(date)"
        echo "# This file contains only packages that were explicitly installed"
        echo "# and are not dependencies of other packages"
        echo ""
        
        # Add taps
        echo "# Taps"
        brew tap | while read tap; do
            echo "tap \"$tap\""
        done
        echo ""
        echo "# === FORMULAE ==="
        echo ""
        brew leaves | python3 "$CATEGORY_SCRIPT" --manifest "$CATEGORY_MANIFEST" --type formulae --format brew
        echo "# === CASKS ==="
        echo ""
        get_cask_leaves | python3 "$CATEGORY_SCRIPT" --manifest "$CATEGORY_MANIFEST" --type casks --format brew
        
    } > "$output"
    
    print_success "Generated $output"
}

show_dependency_tree() {
    local package="$1"
    
    if brew list --formula | grep -q "^${package}$"; then
        echo "Dependencies for formula: $package"
        brew deps --tree "$package"
    elif brew list --cask | grep -q "^${package}$"; then
        echo "Cask: $package (casks typically don't have dependencies)"
    else
        print_error "Package not found: $package"
    fi
}

show_dependents() {
    local package="$1"
    
    echo "Packages that depend on: $package"
    brew uses --installed "$package"
}

# Main command handling
case "${1:-}" in
    leaves|standalone)
        check_brew
        echo "=== Standalone Formulae (no dependents) ==="
        get_leaves
        echo -e "\n=== Standalone Casks ==="
        get_cask_leaves
        ;;
    categorized)
        check_brew
        echo "=== Categorized Standalone Packages ==="
        echo -e "\n--- FORMULAE ---"
        get_leaves_with_categories
        echo -e "\n--- CASKS ---"
        get_cask_leaves_with_categories
        ;;
    generate)
        check_brew
        generate_standalone_brewfile
        generate_categorized_brewfile
        ;;
    deps)
        check_brew
        if [[ -z "${2:-}" ]]; then
            print_error "Package name required"
            echo "Usage: $0 deps <package>"
            exit 1
        fi
        show_dependency_tree "$2"
        ;;
    uses)
        check_brew
        if [[ -z "${2:-}" ]]; then
            print_error "Package name required"
            echo "Usage: $0 uses <package>"
            exit 1
        fi
        show_dependents "$2"
        ;;
    *)
        echo "Usage: $0 {leaves|standalone|categorized|generate|deps|uses} [package]"
        echo
        echo "Commands:"
        echo "  leaves, standalone  - List packages without dependents"
        echo "  categorized        - List packages organized by category"
        echo "  generate           - Generate Brewfiles for standalone packages"
        echo "  deps <package>     - Show dependencies of a package"
        echo "  uses <package>     - Show packages that depend on a package"
        exit 1
        ;;
esac
