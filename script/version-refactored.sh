#!/usr/bin/env bash
# Refactored semantic versioning script
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

# Source libraries
# shellcheck source=./lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=./lib/semver.sh
source "${SCRIPT_DIR}/lib/semver.sh"

# Configuration
DEFAULT_BUMP_TYPE="patch"
DEFAULT_TAG_PREFIX="v"
DRY_RUN=false
FORCE=false
PUSH_TAG=false
CREATE_RELEASE=false

# Show usage information
show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -t, --type TYPE         Bump type (major|minor|patch|prerelease) [default: patch]
    -p, --prefix PREFIX     Version tag prefix [default: v]
    -m, --message MSG       Tag message [default: Release VERSION]
    -d, --dry-run          Show what would be done without making changes
    -f, --force            Force creation even if tag already exists
    --push                 Push tag to remote after creation
    --release              Create GitHub release after tagging
    --changelog            Generate changelog since last version
    -v, --verbose          Enable verbose output
    -h, --help             Show this help message

Examples:
    $0 --type minor                      # Bump minor version
    $0 --type major --push               # Bump major and push
    $0 --dry-run                         # Preview next version
    $0 --type prerelease --prefix beta  # Create prerelease

Version Bump Types:
    major:      1.2.3 -> 2.0.0
    minor:      1.2.3 -> 1.3.0
    patch:      1.2.3 -> 1.2.4
    prerelease: 1.2.3 -> 1.2.3-alpha.1

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--type)
                DEFAULT_BUMP_TYPE="$2"
                shift 2
                ;;
            -p|--prefix)
                DEFAULT_TAG_PREFIX="$2"
                shift 2
                ;;
            -m|--message)
                TAG_MESSAGE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --push)
                PUSH_TAG=true
                shift
                ;;
            --release)
                CREATE_RELEASE=true
                shift
                ;;
            --changelog)
                SHOW_CHANGELOG=true
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
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Validate bump type
validate_bump_type() {
    case "$DEFAULT_BUMP_TYPE" in
        major|minor|patch|prerelease)
            return 0
            ;;
        *)
            die "Invalid bump type: $DEFAULT_BUMP_TYPE. Valid types: major, minor, patch, prerelease"
            ;;
    esac
}

# Check git repository status
check_git_status() {
    if ! git rev-parse --git-dir &>/dev/null; then
        die "Not in a git repository"
    fi
    
    # Check for uncommitted changes
    if [[ -n "$(git status --porcelain)" ]]; then
        log_warning "You have uncommitted changes"
        if ! confirm "Continue anyway?"; then
            exit 1
        fi
    fi
    
    # Ensure we have the latest tags
    log_debug "Fetching remote tags..."
    git fetch --tags >/dev/null 2>&1 || true
}

# Create GitHub release
create_github_release() {
    local version=$1
    local changelog=${2:-""}
    
    if ! command_exists "gh"; then
        log_warning "GitHub CLI not installed. Skipping release creation."
        return 1
    fi
    
    log_info "Creating GitHub release for $version..."
    
    local release_notes="Release $version"
    if [[ -n "$changelog" ]]; then
        release_notes="$release_notes

## Changes
$changelog"
    fi
    
    if gh release create "$version" \
        --title "$version" \
        --notes "$release_notes" \
        --draft; then
        log_success "Created draft release: $version"
        log_info "Edit and publish at: $(gh release view "$version" --json url -q .url)"
    else
        log_error "Failed to create release"
        return 1
    fi
}

# Main execution
main() {
    parse_arguments "$@"
    validate_bump_type
    check_git_status
    
    # Get current version
    local current_version
    current_version=$(get_latest_version "${DEFAULT_TAG_PREFIX}*")
    
    if [[ -z "$current_version" ]]; then
        # No existing tags, start with initial version
        NEW_VERSION="${DEFAULT_TAG_PREFIX}1.0.0"
        log_warning "No existing version tags found. Starting with $NEW_VERSION"
    else
        log_info "Current version: $current_version"
        
        # Calculate new version
        NEW_VERSION=$(bump_version "$DEFAULT_BUMP_TYPE" "$current_version")
        
        # Add prefix if needed
        if [[ ! "$NEW_VERSION" =~ ^${DEFAULT_TAG_PREFIX} ]]; then
            NEW_VERSION="${DEFAULT_TAG_PREFIX}${NEW_VERSION#v}"
        fi
    fi
    
    log_success "New version: $NEW_VERSION"
    
    # Check if tag already exists
    if version_exists "$NEW_VERSION"; then
        if [[ "$FORCE" != "true" ]]; then
            die "Tag $NEW_VERSION already exists. Use --force to overwrite."
        else
            log_warning "Tag $NEW_VERSION will be overwritten"
        fi
    fi
    
    # Generate changelog if requested
    local changelog=""
    if [[ "${SHOW_CHANGELOG:-false}" == "true" ]] && [[ -n "$current_version" ]]; then
        log_info "Generating changelog..."
        changelog=$(generate_changelog "$current_version" "HEAD")
        if [[ -n "$changelog" ]]; then
            echo ""
            echo "Changes since $current_version:"
            echo "$changelog"
            echo ""
        fi
    fi
    
    # Dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would create tag $NEW_VERSION"
        echo ""
        echo "To create this tag, run:"
        echo "  git tag -a $NEW_VERSION -m \"${TAG_MESSAGE:-Release $NEW_VERSION}\""
        
        if [[ "$PUSH_TAG" == "true" ]]; then
            echo "  git push origin $NEW_VERSION"
        fi
        
        if [[ "$CREATE_RELEASE" == "true" ]]; then
            echo "  gh release create $NEW_VERSION"
        fi
        
        exit 0
    fi
    
    # Create the tag
    local message="${TAG_MESSAGE:-Release $NEW_VERSION}"
    if create_version_tag "$NEW_VERSION" "$message" "$FORCE"; then
        log_success "Tag created successfully!"
        
        # Push tag if requested
        if [[ "$PUSH_TAG" == "true" ]]; then
            log_info "Pushing tag to remote..."
            if git push origin "$NEW_VERSION"; then
                log_success "Tag pushed to remote"
            else
                log_error "Failed to push tag"
                exit 1
            fi
        else
            echo ""
            echo "To push the tag to remote:"
            echo "  git push origin $NEW_VERSION"
        fi
        
        # Create release if requested
        if [[ "$CREATE_RELEASE" == "true" ]]; then
            create_github_release "$NEW_VERSION" "$changelog"
        fi
        
        echo ""
        log_info "Version $NEW_VERSION created successfully!"
    else
        die "Failed to create tag"
    fi
}

# Run main function
main "$@"