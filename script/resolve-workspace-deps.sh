#!/usr/bin/env bash
# resolve-workspace-deps.sh - Resolve workspace:* dependencies before publishing
#
# When using pnpm workspaces with semantic-release, workspace:* dependencies
# need to be resolved to actual versions before publishing to npm.
#
# Usage:
#   ./resolve-workspace-deps.sh [--scope SCOPE] [--tag-prefix PREFIX] [--dep-key KEY]
#
# Options:
#   --scope       Package scope name (default: @scope)
#   --tag-prefix  Tag prefix pattern (default: shared-v)
#   --dep-key     Dependency key name (default: shared)
#
# Example:
#   ./resolve-workspace-deps.sh --scope @myorg --tag-prefix shared-v --dep-key shared

set -euo pipefail

# Default configuration
SCOPE="@scope"
TAG_PREFIX="shared-v"
DEP_KEY="shared"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --scope)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --scope requires a value"
                exit 1
            fi
            SCOPE="$2"
            shift 2
            ;;
        --tag-prefix)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --tag-prefix requires a value"
                exit 1
            fi
            TAG_PREFIX="$2"
            shift 2
            ;;
        --dep-key)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --dep-key requires a value"
                exit 1
            fi
            DEP_KEY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--scope SCOPE] [--tag-prefix PREFIX] [--dep-key KEY]"
            echo ""
            echo "Options:"
            echo "  --scope       Package scope name (default: @scope)"
            echo "  --tag-prefix  Tag prefix pattern (default: shared-v)"
            echo "  --dep-key     Dependency key name (default: shared)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get repository root
if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "Error: Must be run inside a git repository"
    exit 1
fi

echo "Resolving workspace:* dependencies..."
echo "  Scope: ${SCOPE}"
echo "  Tag prefix: ${TAG_PREFIX}"
echo "  Dependency key: ${DEP_KEY}"

# Get version from git tag (semantic-release creates tags like shared-v1.0.3)
TAG_WITH_VERSION=$(git describe --tags --match "${TAG_PREFIX}*" --abbrev=0 2>/dev/null || true)
SHARED_VERSION="${TAG_WITH_VERSION#"$TAG_PREFIX"}"

if [ -z "$SHARED_VERSION" ]; then
    echo "No git tag found with prefix '${TAG_PREFIX}', checking package.json..."

    # Fallback to package.json
    SHARED_PACKAGE="${REPO_ROOT}/packages/${DEP_KEY}/package.json"

    if [ -f "$SHARED_PACKAGE" ]; then
        SHARED_VERSION=$(jq -r '.version' "$SHARED_PACKAGE")
        echo "Using version from package.json: ${SHARED_VERSION}"
    else
        echo "Error: Could not find version. No git tag or package.json found."
        exit 1
    fi
else
    echo "Using version from git tag: ${SHARED_VERSION}"
fi

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in current directory"
    exit 1
fi

# Full dependency name
FULL_DEP_NAME="${SCOPE}/${DEP_KEY}"

# Check if the dependency exists and is workspace:*
if jq -e ".dependencies[\"${FULL_DEP_NAME}\"]" package.json > /dev/null 2>&1; then
    CURRENT_VERSION=$(jq -r ".dependencies[\"${FULL_DEP_NAME}\"]" package.json)

    if [[ "$CURRENT_VERSION" == "workspace:"* ]]; then
        echo "Resolving ${FULL_DEP_NAME}: ${CURRENT_VERSION} -> ^${SHARED_VERSION}"

        # Update package.json
        if jq --arg version "^${SHARED_VERSION}" \
            ".dependencies[\"${FULL_DEP_NAME}\"] = \$version" \
            package.json > package.json.tmp; then
            if jq -e . package.json.tmp >/dev/null 2>&1; then
                mv package.json.tmp package.json
                echo "Successfully updated package.json"
            else
                echo "Error: Generated invalid JSON, aborting update"
                rm -f package.json.tmp
                exit 1
            fi
        else
            echo "Error: Failed to update package.json"
            rm -f package.json.tmp
            exit 1
        fi
    else
        echo "${FULL_DEP_NAME} is not a workspace dependency (${CURRENT_VERSION}), skipping..."
    fi
else
    echo "${FULL_DEP_NAME} not found in dependencies, skipping..."
fi

echo "Done!"
