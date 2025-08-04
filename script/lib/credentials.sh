#!/usr/bin/env bash
# Secure credentials management library

# Source common functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${LIB_DIR}/common.sh"

# Default paths
readonly CREDENTIALS_DIR="${CREDENTIALS_DIR:-${REPO_ROOT}/credentials}"
readonly CREDENTIALS_TEMPLATE_DIR="${CREDENTIALS_DIR}/templates"
readonly CREDENTIALS_BACKUP_DIR="${CREDENTIALS_DIR}/backups"

# Security settings
readonly DEFAULT_FILE_PERMS="600"
readonly DEFAULT_DIR_PERMS="700"

# Check 1Password CLI availability
check_1password_cli() {
    require_command "op" "Install 1Password CLI with: brew install --cask 1password-cli"
}

# Check 1Password sign-in status
check_1password_signin() {
    if ! op account list &>/dev/null; then
        die "Not signed in to 1Password. Sign in with: op signin"
    fi
}

# Secure file permissions
secure_file() {
    local file=$1
    local perms=${2:-$DEFAULT_FILE_PERMS}
    
    if [[ -f "$file" ]]; then
        chmod "$perms" "$file"
        log_debug "Set permissions $perms on $file"
    fi
}

# Secure directory permissions
secure_directory() {
    local dir=$1
    local perms=${2:-$DEFAULT_DIR_PERMS}
    
    if [[ -d "$dir" ]]; then
        chmod "$perms" "$dir"
        log_debug "Set permissions $perms on $dir"
    fi
}

# Process credential template
process_credential_template() {
    local template=$1
    local output=$2
    
    if [[ ! -f "$template" ]]; then
        log_error "Template file not found: $template"
        return 1
    fi
    
    log_info "Processing: $(basename "$template")"
    
    # Create output directory if needed
    ensure_dir "$(dirname "$output")"
    
    # Process template with 1Password
    if op inject --in-file "$template" --out-file "$output" 2>/dev/null; then
        secure_file "$output"
        log_success "Generated: $output"
        return 0
    else
        log_error "Failed to process: $template"
        return 1
    fi
}

# List available credential templates
list_credential_templates() {
    local template_dir="${1:-$CREDENTIALS_TEMPLATE_DIR}"
    
    if [[ ! -d "$template_dir" ]]; then
        log_warning "Template directory not found: $template_dir"
        return 1
    fi
    
    log_info "Available credential templates:"
    find "$template_dir" -name "*.template" -type f | while read -r template; do
        echo "  - $(basename "$template" .template)"
    done
}

# Backup credentials before processing
backup_credentials() {
    local credentials_dir="${1:-$CREDENTIALS_DIR}"
    local backup_dir="${2:-$CREDENTIALS_BACKUP_DIR}"
    
    ensure_dir "$backup_dir"
    secure_directory "$backup_dir"
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/credentials_${timestamp}.tar.gz"
    
    if find "$credentials_dir" -name "*.env" -type f | grep -q .; then
        tar czf "$backup_file" -C "$credentials_dir" --exclude="*.template" --exclude="backups" .
        secure_file "$backup_file"
        log_info "Created backup: $backup_file"
    else
        log_debug "No credential files to backup"
    fi
}

# Clean generated credential files
clean_credential_files() {
    local credentials_dir="${1:-$CREDENTIALS_DIR}"
    
    log_info "Cleaning credential files in $credentials_dir"
    
    find "$credentials_dir" -type f \( -name "*.env" -o -name "*.key" -o -name "*.pem" \) \
        -not -name "*.template" -delete 2>/dev/null || true
    
    log_success "Credential files cleaned"
}

# Validate credential file format
validate_credential_file() {
    local file=$1
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Check for common issues
    local issues=0
    
    # Check for exposed secrets (basic patterns)
    if grep -qE '(password|secret|key|token)=.{0,3}$' "$file"; then
        log_warning "Potential empty secret values in $file"
        ((issues++))
    fi
    
    # Check for invalid characters in env vars
    if grep -qE '^[^A-Z_]' "$file"; then
        log_warning "Invalid environment variable names in $file"
        ((issues++))
    fi
    
    # Check file permissions
    local perms
    perms=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file")
    if [[ "$perms" != "600" ]]; then
        log_warning "Insecure file permissions on $file: $perms (should be 600)"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "Validation passed for $file"
        return 0
    else
        log_error "Validation failed with $issues issues"
        return 1
    fi
}

# Export functions
export -f check_1password_cli check_1password_signin
export -f secure_file secure_directory
export -f process_credential_template list_credential_templates
export -f backup_credentials clean_credential_files validate_credential_file