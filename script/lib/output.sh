#!/usr/bin/env zsh
# Unified output functions for all scripts
# Usage: source "$SCRIPT_DIR/lib/output.sh"

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

# Standard output functions
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

# Backward compatibility aliases for scripts using different naming conventions
# These can be removed after full migration

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
