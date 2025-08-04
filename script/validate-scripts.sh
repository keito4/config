#!/usr/bin/env bash
# Script validation tool using shellcheck
# Ensures all shell scripts comply with best practices

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
# shellcheck source=./lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
SHELLCHECK_SEVERITY="${SHELLCHECK_SEVERITY:-warning}"
FIX_FORMATTING="${FIX_FORMATTING:-false}"
VALIDATE_ONLY="${VALIDATE_ONLY:-false}"

# Show usage
show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [SCRIPT_PATH]

Validate shell scripts using shellcheck and other tools.

Options:
    --fix               Auto-fix formatting issues with shfmt
    --severity LEVEL    Set shellcheck severity (error|warning|info|style)
    --all               Validate all scripts in repository
    --lib               Validate library scripts only
    -v, --verbose       Enable verbose output
    -h, --help          Show this help message

Examples:
    $0 --all                    # Validate all scripts
    $0 script/import.sh         # Validate specific script
    $0 --fix --all             # Fix and validate all scripts

EOF
}

# Check required tools
check_tools() {
    local missing_tools=()
    
    if ! command_exists "shellcheck"; then
        missing_tools+=("shellcheck")
    fi
    
    if [[ "$FIX_FORMATTING" == "true" ]] && ! command_exists "shfmt"; then
        missing_tools+=("shfmt")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install with: brew install ${missing_tools[*]}"
        exit 1
    fi
}

# Validate single script
validate_script() {
    local script=$1
    local issues_found=false
    
    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi
    
    log_info "Validating: $script"
    
    # Run shellcheck
    if shellcheck --severity="$SHELLCHECK_SEVERITY" "$script"; then
        log_success "✓ ShellCheck passed"
    else
        log_error "✗ ShellCheck found issues"
        issues_found=true
    fi
    
    # Check formatting with shfmt
    if command_exists "shfmt"; then
        if shfmt -d "$script" >/dev/null 2>&1; then
            log_success "✓ Formatting is correct"
        else
            if [[ "$FIX_FORMATTING" == "true" ]]; then
                log_warning "Fixing formatting..."
                shfmt -w "$script"
                log_success "✓ Formatting fixed"
            else
                log_warning "✗ Formatting issues found (use --fix to auto-fix)"
                issues_found=true
            fi
        fi
    fi
    
    # Check for common issues
    local warnings=()
    
    # Check for missing set options
    if ! grep -q "^set -[euo]" "$script"; then
        warnings+=("Missing 'set -euo pipefail' for safety")
    fi
    
    # Check for unquoted variables
    if grep -qE '\$[A-Za-z_][A-Za-z0-9_]*[^"}]' "$script"; then
        warnings+=("Potentially unquoted variables found")
    fi
    
    # Check for TODO/FIXME comments
    if grep -qE '(TODO|FIXME|XXX|HACK)' "$script"; then
        warnings+=("Contains TODO/FIXME comments")
    fi
    
    # Report warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        log_warning "Additional warnings:"
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
    fi
    
    if [[ "$issues_found" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# Find all shell scripts
find_scripts() {
    local search_path="${1:-$REPO_ROOT}"
    
    find "$search_path" \
        -type f \
        \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/test/bats-libs/*" \
        -print | sort
}

# Validate multiple scripts
validate_all_scripts() {
    local search_path="${1:-$SCRIPT_DIR}"
    local scripts
    scripts=$(find_scripts "$search_path")
    
    local total=0
    local passed=0
    local failed=0
    
    while IFS= read -r script; do
        ((total++))
        echo ""
        if validate_script "$script"; then
            ((passed++))
        else
            ((failed++))
        fi
    done <<< "$scripts"
    
    # Summary
    echo ""
    log_info "========================================="
    log_info "Validation Summary"
    log_info "Total scripts: $total"
    log_success "Passed: $passed"
    if [[ $failed -gt 0 ]]; then
        log_error "Failed: $failed"
    fi
    log_info "========================================="
    
    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    local validate_all=false
    local validate_lib=false
    local script_path=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_FORMATTING=true
                shift
                ;;
            --severity)
                SHELLCHECK_SEVERITY="$2"
                shift 2
                ;;
            --all)
                validate_all=true
                shift
                ;;
            --lib)
                validate_lib=true
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
                script_path="$1"
                shift
                ;;
        esac
    done
    
    # Check required tools
    check_tools
    
    # Execute validation
    if [[ "$validate_all" == "true" ]]; then
        validate_all_scripts "$REPO_ROOT/script"
    elif [[ "$validate_lib" == "true" ]]; then
        validate_all_scripts "$SCRIPT_DIR/lib"
    elif [[ -n "$script_path" ]]; then
        validate_script "$script_path"
    else
        log_error "No script specified"
        show_usage
        exit 1
    fi
}

# Run main function
main "$@"