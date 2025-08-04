#!/usr/bin/env bash
# Common library for shell scripts
# Provides shared functions for error handling, logging, and utilities

set -euo pipefail

# Script metadata
readonly COMMON_LIB_VERSION="1.0.0"
readonly COMMON_LIB_NAME="${BASH_SOURCE[0]##*/}"
readonly COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color definitions
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Log levels
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default log level (can be overridden by environment variable)
LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"

# Logging functions
log_error() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then
        echo -e "${COLOR_RED}[ERROR] $*${COLOR_RESET}" >&2
    fi
}

log_warning() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_WARNING ]]; then
        echo -e "${COLOR_YELLOW}[WARNING] $*${COLOR_RESET}" >&2
    fi
}

log_info() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
        echo -e "${COLOR_BLUE}[INFO] $*${COLOR_RESET}"
    fi
}

log_success() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
        echo -e "${COLOR_GREEN}[SUCCESS] $*${COLOR_RESET}"
    fi
}

log_debug() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
        echo -e "[DEBUG] $*" >&2
    fi
}

# Error handling
die() {
    log_error "$@"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check required commands
require_command() {
    local cmd=$1
    local install_msg=${2:-"Please install $cmd"}
    
    if ! command_exists "$cmd"; then
        die "$cmd is not installed. $install_msg"
    fi
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "darwin"
            ;;
        Linux*)
            echo "linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if running in container
is_container() {
    [[ -f /.dockerenv ]] || [[ -n "${REMOTE_CONTAINERS:-}" ]] || [[ -n "${CODESPACES:-}" ]]
}

# Prompt for confirmation
confirm() {
    local prompt="${1:-Are you sure?}"
    local response
    
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Create backup of file
backup_file() {
    local file=$1
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        log_info "Created backup: $backup"
    fi
}

# Ensure directory exists
ensure_dir() {
    local dir=$1
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    fi
}

# Run command with retry
retry_command() {
    local max_attempts=${1:-3}
    local delay=${2:-1}
    local command="${@:3}"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt of $max_attempts: $command"
        
        if eval "$command"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "Command failed, retrying in ${delay}s..."
            sleep "$delay"
        fi
        
        ((attempt++))
    done
    
    log_error "Command failed after $max_attempts attempts"
    return 1
}

# Validate semantic version
validate_semver() {
    local version=$1
    local semver_regex='^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-[0-9A-Za-z-]+)?(\+[0-9A-Za-z-]+)?$'
    
    if [[ $version =~ $semver_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Parse semantic version components
parse_semver() {
    local version=$1
    local semver_regex='^v?([0-9]+)\.([0-9]+)\.([0-9]+)'
    
    if [[ $version =~ $semver_regex ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
    else
        return 1
    fi
}

# Export all functions for use in subshells
export -f log_error log_warning log_info log_success log_debug
export -f die command_exists require_command detect_os is_container
export -f confirm backup_file ensure_dir retry_command
export -f validate_semver parse_semver