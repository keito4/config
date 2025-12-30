#!/bin/bash

# Semantic versioning script for devcontainer releases
# This script helps create properly versioned tags for devcontainer images

set -euo pipefail

# Default values
BUMP_TYPE="patch"
DRY_RUN=false
FORCE=false

# Determine script directory and source output library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -t, --type TYPE     Bump type (major|minor|patch) [default: patch]"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo "  -f, --force         Force creation even if tag already exists"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type minor     # Bump minor version (1.2.3 -> 1.3.0)"
    echo "  $0 --type major     # Bump major version (1.2.3 -> 2.0.0)"
    echo "  $0 --dry-run        # Show next version without creating tag"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUMP_TYPE="$2"
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
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Validate bump type
case $BUMP_TYPE in
    major|minor|patch)
        ;;
    *)
        echo -e "${RED}Invalid bump type: $BUMP_TYPE${NC}" >&2
        echo "Valid types: major, minor, patch"
        exit 1
        ;;
esac

# Get the latest tag
LATEST_TAG=$(git tag -l "v*" --sort=-version:refname | head -n1)

if [[ -z "$LATEST_TAG" ]]; then
    # No existing tags, start with v1.0.0
    NEW_VERSION="v1.0.0"
    echo -e "${YELLOW}No existing version tags found. Starting with $NEW_VERSION${NC}"
else
    echo -e "${GREEN}Latest tag: $LATEST_TAG${NC}"
    
    # Extract version numbers (remove 'v' prefix)
    VERSION=${LATEST_TAG#v}
    
    # Split version into components
    IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
    
    # Bump version according to type
    case $BUMP_TYPE in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
    esac
    
    NEW_VERSION="v$MAJOR.$MINOR.$PATCH"
fi

echo -e "${GREEN}New version: $NEW_VERSION${NC}"

# Check if tag already exists
if git tag -l "$NEW_VERSION" | grep -q "$NEW_VERSION"; then
    if [[ "$FORCE" == false ]]; then
        echo -e "${RED}Tag $NEW_VERSION already exists. Use --force to overwrite.${NC}" >&2
        exit 1
    else
        echo -e "${YELLOW}Tag $NEW_VERSION already exists but will be overwritten.${NC}"
    fi
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN: Would create tag $NEW_VERSION${NC}"
    echo "To create this tag, run:"
    echo "  git tag $NEW_VERSION"
    echo "  git push origin $NEW_VERSION"
    exit 0
fi

# Create the tag
echo -e "${GREEN}Creating tag $NEW_VERSION...${NC}"
git tag "$NEW_VERSION"

echo -e "${GREEN}Tag created successfully!${NC}"
echo "To push the tag to remote:"
echo "  git push origin $NEW_VERSION"
echo ""
echo "This will trigger the Docker image build with version $NEW_VERSION"