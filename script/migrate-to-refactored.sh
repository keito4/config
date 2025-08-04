#!/usr/bin/env bash
# Migration script for transitioning to refactored shell scripts
# Maintains backward compatibility while introducing new structure

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library
# shellcheck source=./lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
CREATE_SYMLINKS="${CREATE_SYMLINKS:-true}"
BACKUP_ORIGINALS="${BACKUP_ORIGINALS:-true}"
UPDATE_PERMISSIONS="${UPDATE_PERMISSIONS:-true}"

# Show migration plan
show_migration_plan() {
    cat <<EOF
Migration Plan for Refactored Shell Scripts
============================================

This script will:
1. Back up original scripts to script/legacy/
2. Create symbolic links for backward compatibility
3. Set proper permissions on all scripts
4. Validate the new scripts with shellcheck

Original Scripts -> Refactored Scripts:
  brew-deps.sh     -> brew-deps-refactored.sh
  version.sh       -> version-refactored.sh
  credentials.sh   -> credentials-refactored.sh
  import.sh        -> import-refactored.sh

New Structure:
  lib/             - Shared libraries
    common.sh      - Common functions
    brew.sh        - Homebrew utilities
    credentials.sh - Credential management
    semver.sh      - Semantic versioning
  config/          - Configuration files
    settings.conf  - Shared settings

EOF
}

# Create backups
create_backups() {
    log_info "Creating backups of original scripts..."
    
    local backup_dir="${SCRIPT_DIR}/legacy"
    ensure_dir "$backup_dir"
    
    local scripts=("brew-deps.sh" "version.sh" "credentials.sh" "import.sh")
    
    for script in "${scripts[@]}"; do
        local original="${SCRIPT_DIR}/${script}"
        local backup="${backup_dir}/${script}.backup"
        
        if [[ -f "$original" ]]; then
            cp "$original" "$backup"
            log_success "Backed up: $script"
        else
            log_warning "Original not found: $script"
        fi
    done
}

# Create compatibility symlinks
create_compatibility_links() {
    log_info "Creating compatibility symlinks..."
    
    local links=(
        "brew-deps.sh:brew-deps-refactored.sh"
        "version.sh:version-refactored.sh"
        "credentials.sh:credentials-refactored.sh"
        "import.sh:import-refactored.sh"
    )
    
    for link_spec in "${links[@]}"; do
        IFS=':' read -r old_name new_name <<< "$link_spec"
        
        local old_path="${SCRIPT_DIR}/${old_name}"
        local new_path="${SCRIPT_DIR}/${new_name}"
        
        if [[ -f "$new_path" ]]; then
            # Remove old script if it exists
            if [[ -f "$old_path" ]] && [[ ! -L "$old_path" ]]; then
                rm "$old_path"
            fi
            
            # Create symlink
            ln -sf "$new_name" "$old_path"
            log_success "Created symlink: $old_name -> $new_name"
        else
            log_warning "Refactored script not found: $new_name"
        fi
    done
}

# Update script permissions
update_permissions() {
    log_info "Setting proper permissions on scripts..."
    
    # Make all .sh files executable
    find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Secure credential-related files
    if [[ -d "${SCRIPT_DIR}/../credentials" ]]; then
        chmod 700 "${SCRIPT_DIR}/../credentials"
        find "${SCRIPT_DIR}/../credentials" -type f -exec chmod 600 {} \;
    fi
    
    log_success "Permissions updated"
}

# Validate new scripts
validate_scripts() {
    log_info "Validating refactored scripts..."
    
    if [[ -f "${SCRIPT_DIR}/validate-scripts.sh" ]]; then
        "${SCRIPT_DIR}/validate-scripts.sh" --all || {
            log_warning "Some scripts have validation issues"
            log_info "Run './script/validate-scripts.sh --fix --all' to fix formatting"
        }
    else
        log_warning "Validation script not found"
    fi
}

# Show usage examples
show_usage_examples() {
    cat <<EOF

Migration Complete!
==================

The refactored scripts are now available with improved features:

Enhanced Commands:
  # Brew dependency management
  ./script/brew-deps.sh --help           # Show all options
  ./script/brew-deps.sh categorized      # View categorized packages
  ./script/brew-deps.sh generate         # Generate Brewfiles
  
  # Version management
  ./script/version.sh --help             # Show all options
  ./script/version.sh --type minor       # Bump minor version
  ./script/version.sh --push --release   # Push and create release
  
  # Credential management
  ./script/credentials.sh --help         # Show all options
  ./script/credentials.sh fetch          # Fetch from 1Password
  ./script/credentials.sh validate       # Validate credentials
  
  # Import configuration
  ./script/import.sh --help              # Show all options
  ./script/import.sh --dry-run          # Preview changes
  ./script/import.sh --skip-brew-packages # Selective import

Validation:
  ./script/validate-scripts.sh --all     # Validate all scripts
  ./script/validate-scripts.sh --fix --all # Auto-fix issues

The original commands still work via symbolic links for backward compatibility.

EOF
}

# Main execution
main() {
    log_info "Starting migration to refactored shell scripts"
    
    # Show migration plan
    show_migration_plan
    
    if ! confirm "Proceed with migration?"; then
        log_info "Migration cancelled"
        exit 0
    fi
    
    # Run migration steps
    if [[ "$BACKUP_ORIGINALS" == "true" ]]; then
        create_backups
    fi
    
    if [[ "$CREATE_SYMLINKS" == "true" ]]; then
        create_compatibility_links
    fi
    
    if [[ "$UPDATE_PERMISSIONS" == "true" ]]; then
        update_permissions
    fi
    
    # Validate new scripts
    validate_scripts
    
    # Show completion message
    show_usage_examples
    
    log_success "Migration completed successfully!"
}

# Run main function
main "$@"