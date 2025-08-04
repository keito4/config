#!/usr/bin/env bash
# Refactored 1Password credential management script
# Modular version with improved security and maintainability

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
# shellcheck source=./lib/credentials.sh
source "${SCRIPT_DIR}/lib/credentials.sh"

# Configuration
export CREDENTIALS_DIR="${REPO_ROOT}/credentials"
export CREDENTIALS_TEMPLATE_DIR="${CREDENTIALS_DIR}/templates"
export CREDENTIALS_BACKUP_DIR="${CREDENTIALS_DIR}/backups"

# Runtime options
VALIDATE_AFTER_FETCH=true
CREATE_BACKUP=true
FORCE_OVERWRITE=false

# Show usage information
show_usage() {
    cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    fetch, get       Fetch credentials from 1Password
    clean           Remove all generated credential files
    list            List available credential templates
    validate        Validate credential files
    backup          Create backup of current credentials
    restore         Restore credentials from backup
    help            Show this help message

Options:
    --no-backup          Don't create backup before fetching
    --no-validate        Skip validation after fetching
    --force              Force overwrite existing files
    --template <name>    Process specific template only
    -v, --verbose        Enable verbose output
    -h, --help           Show this help message

Examples:
    $0 fetch                           # Fetch all credentials
    $0 fetch --template aws            # Fetch only AWS credentials
    $0 validate                        # Validate all credential files
    $0 backup                          # Create backup
    $0 clean                           # Remove credential files

Security Notes:
    - All credential files are created with 600 permissions
    - Backups are stored in encrypted tar.gz format
    - Templates should use 1Password references: op://vault/item/field

EOF
}

# Fetch credentials from 1Password
fetch_credentials() {
    local template_filter="${1:-}"
    
    check_1password_cli
    check_1password_signin
    
    # Create backup if requested
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        log_info "Creating backup before fetching..."
        backup_credentials "$CREDENTIALS_DIR" "$CREDENTIALS_BACKUP_DIR"
    fi
    
    log_info "Fetching credentials from 1Password..."
    
    local success_count=0
    local fail_count=0
    
    # Process templates
    if [[ -n "$template_filter" ]]; then
        # Process specific template
        local template="${CREDENTIALS_TEMPLATE_DIR}/${template_filter}.env.template"
        if [[ -f "$template" ]]; then
            local output="${CREDENTIALS_DIR}/${template_filter}.env"
            
            if [[ -f "$output" ]] && [[ "$FORCE_OVERWRITE" != "true" ]]; then
                log_warning "File exists: $output (use --force to overwrite)"
            else
                if process_credential_template "$template" "$output"; then
                    ((success_count++))
                    
                    if [[ "$VALIDATE_AFTER_FETCH" == "true" ]]; then
                        validate_credential_file "$output" || true
                    fi
                else
                    ((fail_count++))
                fi
            fi
        else
            die "Template not found: $template_filter"
        fi
    else
        # Process all templates
        for template in "${CREDENTIALS_TEMPLATE_DIR}"/*.env.template; do
            if [[ -f "$template" ]]; then
                local basename
                basename=$(basename "$template" .env.template)
                local output="${CREDENTIALS_DIR}/${basename}.env"
                
                if [[ -f "$output" ]] && [[ "$FORCE_OVERWRITE" != "true" ]]; then
                    log_warning "Skipping existing file: $output (use --force to overwrite)"
                    continue
                fi
                
                if process_credential_template "$template" "$output"; then
                    ((success_count++))
                    
                    if [[ "$VALIDATE_AFTER_FETCH" == "true" ]]; then
                        validate_credential_file "$output" || true
                    fi
                else
                    ((fail_count++))
                fi
            fi
        done
    fi
    
    # Summary
    echo ""
    log_info "Summary: $success_count succeeded, $fail_count failed"
    
    if [[ $fail_count -gt 0 ]]; then
        exit 1
    fi
}

# Validate all credential files
validate_all_credentials() {
    log_info "Validating credential files..."
    
    local valid_count=0
    local invalid_count=0
    
    for file in "${CREDENTIALS_DIR}"/*.env; do
        if [[ -f "$file" ]]; then
            echo ""
            log_info "Validating: $(basename "$file")"
            if validate_credential_file "$file"; then
                ((valid_count++))
            else
                ((invalid_count++))
            fi
        fi
    done
    
    echo ""
    log_info "Validation complete: $valid_count valid, $invalid_count invalid"
    
    if [[ $invalid_count -gt 0 ]]; then
        exit 1
    fi
}

# List available backups
list_backups() {
    log_info "Available backups:"
    
    if [[ -d "$CREDENTIALS_BACKUP_DIR" ]]; then
        find "$CREDENTIALS_BACKUP_DIR" -name "credentials_*.tar.gz" -type f | \
            sort -r | \
            while read -r backup; do
                local size
                size=$(du -h "$backup" | cut -f1)
                local date
                date=$(basename "$backup" | sed 's/credentials_//;s/.tar.gz//')
                echo "  - $date (size: $size)"
            done
    else
        log_warning "No backups found"
    fi
}

# Restore from backup
restore_from_backup() {
    local backup_file="${1:-}"
    
    if [[ -z "$backup_file" ]]; then
        # Show available backups and prompt
        list_backups
        echo ""
        read -r -p "Enter backup date (YYYYMMDD_HHMMSS): " backup_date
        backup_file="${CREDENTIALS_BACKUP_DIR}/credentials_${backup_date}.tar.gz"
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        die "Backup file not found: $backup_file"
    fi
    
    log_info "Restoring from: $backup_file"
    
    # Create current backup first
    backup_credentials "$CREDENTIALS_DIR" "$CREDENTIALS_BACKUP_DIR"
    
    # Clean current files
    clean_credential_files "$CREDENTIALS_DIR"
    
    # Extract backup
    tar xzf "$backup_file" -C "$CREDENTIALS_DIR"
    
    log_success "Credentials restored from backup"
    
    # Validate restored files
    if [[ "$VALIDATE_AFTER_FETCH" == "true" ]]; then
        validate_all_credentials
    fi
}

# Parse command line arguments
parse_arguments() {
    local command="${1:-}"
    shift || true
    
    case "$command" in
        fetch|get)
            local template_filter=""
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --no-backup)
                        CREATE_BACKUP=false
                        shift
                        ;;
                    --no-validate)
                        VALIDATE_AFTER_FETCH=false
                        shift
                        ;;
                    --force)
                        FORCE_OVERWRITE=true
                        shift
                        ;;
                    --template)
                        template_filter="$2"
                        shift 2
                        ;;
                    -v|--verbose)
                        export LOG_LEVEL=$LOG_LEVEL_DEBUG
                        shift
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done
            
            fetch_credentials "$template_filter"
            ;;
            
        clean)
            if confirm "Remove all generated credential files?"; then
                clean_credential_files "$CREDENTIALS_DIR"
            fi
            ;;
            
        list)
            list_credential_templates "$CREDENTIALS_TEMPLATE_DIR"
            ;;
            
        validate)
            validate_all_credentials
            ;;
            
        backup)
            backup_credentials "$CREDENTIALS_DIR" "$CREDENTIALS_BACKUP_DIR"
            ;;
            
        restore)
            restore_from_backup "$@"
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

# Main execution
main() {
    # Ensure directories exist with proper permissions
    ensure_dir "$CREDENTIALS_DIR"
    ensure_dir "$CREDENTIALS_TEMPLATE_DIR"
    ensure_dir "$CREDENTIALS_BACKUP_DIR"
    
    secure_directory "$CREDENTIALS_DIR"
    secure_directory "$CREDENTIALS_BACKUP_DIR"
    
    # Parse and execute command
    parse_arguments "$@"
}

# Run main function
main "$@"