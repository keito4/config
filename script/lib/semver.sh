#!/usr/bin/env bash
# Semantic versioning library

# Source common functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${LIB_DIR}/common.sh"

# Semantic version regex pattern
readonly SEMVER_REGEX='^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+))?(\+([0-9A-Za-z-]+))?$'

# Version components
declare -g MAJOR=0
declare -g MINOR=0
declare -g PATCH=0
declare -g PRERELEASE=""
declare -g BUILD=""

# Parse semantic version string
parse_version() {
    local version=$1
    
    if [[ ! $version =~ $SEMVER_REGEX ]]; then
        log_error "Invalid semantic version: $version"
        return 1
    fi
    
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    PRERELEASE="${BASH_REMATCH[5]:-}"
    BUILD="${BASH_REMATCH[7]:-}"
    
    log_debug "Parsed version: MAJOR=$MAJOR, MINOR=$MINOR, PATCH=$PATCH, PRERELEASE=$PRERELEASE, BUILD=$BUILD"
    return 0
}

# Format version string
format_version() {
    local prefix=${1:-"v"}
    local version="${MAJOR}.${MINOR}.${PATCH}"
    
    if [[ -n "$PRERELEASE" ]]; then
        version="${version}-${PRERELEASE}"
    fi
    
    if [[ -n "$BUILD" ]]; then
        version="${version}+${BUILD}"
    fi
    
    echo "${prefix}${version}"
}

# Bump version component
bump_version() {
    local bump_type=$1
    local current_version=$2
    
    # Parse current version
    if ! parse_version "$current_version"; then
        return 1
    fi
    
    # Apply bump
    case "$bump_type" in
        major)
            ((MAJOR++))
            MINOR=0
            PATCH=0
            PRERELEASE=""
            BUILD=""
            ;;
        minor)
            ((MINOR++))
            PATCH=0
            PRERELEASE=""
            BUILD=""
            ;;
        patch)
            ((PATCH++))
            PRERELEASE=""
            BUILD=""
            ;;
        prerelease)
            local prerelease_type=${3:-"alpha"}
            local prerelease_num=1
            
            if [[ -n "$PRERELEASE" ]] && [[ "$PRERELEASE" =~ ^${prerelease_type}\.([0-9]+)$ ]]; then
                prerelease_num=$((BASH_REMATCH[1] + 1))
            fi
            
            PRERELEASE="${prerelease_type}.${prerelease_num}"
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            return 1
            ;;
    esac
    
    format_version
}

# Compare two versions
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
compare_versions() {
    local v1=$1
    local v2=$2
    
    local maj1 min1 pat1 maj2 min2 pat2
    
    # Parse first version
    if ! parse_version "$v1"; then
        return 3
    fi
    maj1=$MAJOR
    min1=$MINOR
    pat1=$PATCH
    
    # Parse second version
    if ! parse_version "$v2"; then
        return 3
    fi
    maj2=$MAJOR
    min2=$MINOR
    pat2=$PATCH
    
    # Compare major
    if [[ $maj1 -gt $maj2 ]]; then
        return 1
    elif [[ $maj1 -lt $maj2 ]]; then
        return 2
    fi
    
    # Compare minor
    if [[ $min1 -gt $min2 ]]; then
        return 1
    elif [[ $min1 -lt $min2 ]]; then
        return 2
    fi
    
    # Compare patch
    if [[ $pat1 -gt $pat2 ]]; then
        return 1
    elif [[ $pat1 -lt $pat2 ]]; then
        return 2
    fi
    
    return 0
}

# Get latest version from git tags
get_latest_version() {
    local tag_pattern=${1:-"v*"}
    local latest_tag
    
    latest_tag=$(git tag -l "$tag_pattern" --sort=-version:refname 2>/dev/null | head -n1)
    
    if [[ -z "$latest_tag" ]]; then
        log_debug "No version tags found matching pattern: $tag_pattern"
        echo ""
        return 1
    fi
    
    echo "$latest_tag"
}

# Check if version tag exists
version_exists() {
    local version=$1
    
    if git tag -l "$version" 2>/dev/null | grep -q "^${version}$"; then
        return 0
    else
        return 1
    fi
}

# Create version tag
create_version_tag() {
    local version=$1
    local message=${2:-"Release $version"}
    local force=${3:-false}
    
    if version_exists "$version" && [[ "$force" != "true" ]]; then
        log_error "Tag $version already exists. Use force=true to overwrite."
        return 1
    fi
    
    if [[ "$force" == "true" ]] && version_exists "$version"; then
        log_warning "Overwriting existing tag: $version"
        git tag -d "$version" >/dev/null 2>&1
    fi
    
    if git tag -a "$version" -m "$message" 2>/dev/null; then
        log_success "Created tag: $version"
        return 0
    else
        log_error "Failed to create tag: $version"
        return 1
    fi
}

# Generate changelog between versions
generate_changelog() {
    local from_version=$1
    local to_version=${2:-"HEAD"}
    
    log_info "Generating changelog from $from_version to $to_version"
    
    git log --pretty=format:"- %s (%h)" "${from_version}..${to_version}" 2>/dev/null
}

# Export functions
export -f parse_version format_version bump_version compare_versions
export -f get_latest_version version_exists create_version_tag generate_changelog