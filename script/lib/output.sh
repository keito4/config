#!/usr/bin/env zsh
# ============================================================================
# Unified output and error handling functions for all scripts
# Usage: source "$SCRIPT_DIR/lib/output.sh"
# ============================================================================
# This library consolidates:
# - Standard output functions (info, success, warning, error)
# - Error handling functions (fatal, require_command, require_file, require_directory)
# - Backward compatibility aliases for legacy scripts

if [[ -n "${OUTPUT_LIB_SOURCED:-}" ]]; then
    return
fi
typeset -g OUTPUT_LIB_SOURCED=1

# Color definitions
typeset -g OUTPUT_RED='\033[0;31m'
typeset -g OUTPUT_GREEN='\033[0;32m'
typeset -g OUTPUT_YELLOW='\033[1;33m'
typeset -g OUTPUT_BLUE='\033[0;34m'
typeset -g OUTPUT_NC='\033[0m'

# Short color aliases for backward compatibility
typeset -g RED="$OUTPUT_RED"
typeset -g GREEN="$OUTPUT_GREEN"
typeset -g YELLOW="$OUTPUT_YELLOW"
typeset -g BLUE="$OUTPUT_BLUE"
typeset -g NC="$OUTPUT_NC"

# ============================================================================
# Standard Output Functions
# ============================================================================

output::error() {
    local message="${1:?Error message required}"
    echo -e "${OUTPUT_RED}ERROR: ${message}${OUTPUT_NC}" >&2
}

output::success() {
    local message="${1:?Success message required}"
    echo -e "${OUTPUT_GREEN}✓ ${message}${OUTPUT_NC}"
}

output::warning() {
    local message="${1:?Warning message required}"
    echo -e "${OUTPUT_YELLOW}⚠ ${message}${OUTPUT_NC}"
}

output::info() {
    local message="${1:?Info message required}"
    echo -e "${OUTPUT_BLUE}[INFO]${OUTPUT_NC} ${message}"
}

output::header() {
    local message="${1:?Header message required}"
    echo -e "${OUTPUT_BLUE}=== ${message} ===${OUTPUT_NC}"
}

output::step() {
    local step_num="${1:?Step number required}"
    local message="${2:?Step message required}"
    echo -e "${OUTPUT_BLUE}Step ${step_num}: ${message}${OUTPUT_NC}"
}

# Plain text output (no color prefix)
output::plain() {
    local message="${1:-}"
    echo -e "${message}"
}

# ============================================================================
# Error Handling Functions (migrated from errors.sh)
# ============================================================================

# Fatal error with exit
output::fatal() {
    local message="${1:?Error message required}"
    echo -e "${OUTPUT_RED}❌ FATAL: ${message}${OUTPUT_NC}" >&2
    exit 1
}

# Command existence check
output::require_command() {
    local cmd="${1:?Command name required}"
    local install_hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        local msg="Required command not found: $cmd"
        if [[ -n "$install_hint" ]]; then
            msg="$msg\nInstall with: $install_hint"
        fi
        output::fatal "$msg"
    fi
}

# File existence check
output::require_file() {
    local file="${1:?File path required}"
    local error_msg="${2:-File not found: $file}"

    if [[ ! -f "$file" ]]; then
        output::fatal "$error_msg"
    fi
}

# Directory existence check
output::require_directory() {
    local dir="${1:?Directory path required}"
    local error_msg="${2:-Directory not found: $dir}"

    if [[ ! -d "$dir" ]]; then
        output::fatal "$error_msg"
    fi
}

# ============================================================================
# Backward Compatibility Aliases
# ============================================================================
# These aliases support legacy naming conventions and can be removed after migration

# For scripts using print_* pattern
output::print_error() { output::error "$@"; }
output::print_success() { output::success "$@"; }
output::print_warning() { output::warning "$@"; }
output::print_info() { output::info "$@"; }

# For scripts using log_* pattern
output::log_info() { output::info "$@"; }
output::log_success() { output::success "$@"; }
output::log_warn() { output::warning "$@"; }

# Global function aliases for backward compatibility
# These allow existing scripts to work without code changes
print_error() { output::error "$@"; }
print_success() { output::success "$@"; }
print_warning() { output::warning "$@"; }
print_info() { output::info "$@"; }
log_info() { output::info "$@"; }
log_success() { output::success "$@"; }
log_warn() { output::warning "$@"; }

# errors:: namespace aliases (migrated from errors.sh)
errors::fatal() { output::fatal "$@"; }
errors::warn() { output::warning "$@"; }
errors::info() { output::info "$@"; }
errors::success() { output::success "$@"; }
errors::require_command() { output::require_command "$@"; }
errors::require_file() { output::require_file "$@"; }
errors::require_directory() { output::require_directory "$@"; }

# Bash-compatible short aliases
info() { output::info "$@"; }
success() { output::success "$@"; }
warning() { output::warning "$@"; }
error() { output::error "$@"; }
fatal() { output::fatal "$@"; }
