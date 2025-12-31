#!/usr/bin/env bash
# Documentation Sync Checker
#
# This script verifies that generated documentation is synchronized with code changes.
# It prevents documentation drift by failing CI if docs are out of sync.
#
# Usage:
#   ./script/check-docs-sync.sh
#
# Configuration:
#   Set DOC_GENERATE_CMD to your documentation generation command
#   Set DOCS_DIR to the directory containing generated documentation

set -euo pipefail

# Configuration
DOC_GENERATE_CMD="${DOC_GENERATE_CMD:-npm run docs:generate}"
DOCS_DIR="${DOCS_DIR:-docs}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📚 Checking documentation sync...${NC}"

# Create temporary directory for generated docs
TEMP_DOCS_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DOCS_DIR"' EXIT

# Copy current docs to temp directory for comparison
if [ -d "$DOCS_DIR" ]; then
  cp -r "$DOCS_DIR" "$TEMP_DOCS_DIR/original"
else
  echo -e "${YELLOW}⚠️  Warning: Documentation directory $DOCS_DIR does not exist${NC}"
  mkdir -p "$TEMP_DOCS_DIR/original"
fi

# Generate fresh documentation
echo -e "${BLUE}📝 Generating documentation...${NC}"
if ! eval "$DOC_GENERATE_CMD" > /dev/null 2>&1; then
  echo -e "${RED}❌ ERROR: Documentation generation failed!${NC}"
  echo -e "${YELLOW}Command: $DOC_GENERATE_CMD${NC}"
  exit 1
fi

# Copy generated docs to temp directory
if [ -d "$DOCS_DIR" ]; then
  cp -r "$DOCS_DIR" "$TEMP_DOCS_DIR/generated"
else
  echo -e "${RED}❌ ERROR: Documentation generation did not create $DOCS_DIR${NC}"
  exit 1
fi

# Compare original and generated docs
echo -e "${BLUE}🔍 Comparing documentation...${NC}"
if diff -r "$TEMP_DOCS_DIR/original" "$TEMP_DOCS_DIR/generated" > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Documentation is in sync!${NC}"
  exit 0
else
  echo -e "${RED}❌ ERROR: Generated documentation is out of sync!${NC}"
  echo ""
  echo -e "${YELLOW}Differences found:${NC}"
  diff -r "$TEMP_DOCS_DIR/original" "$TEMP_DOCS_DIR/generated" || true
  echo ""
  echo -e "${YELLOW}Please run the following command and commit the changes:${NC}"
  echo -e "  ${BLUE}$DOC_GENERATE_CMD${NC}"
  echo ""
  echo -e "${YELLOW}Or use the unified command (if available):${NC}"
  echo -e "  ${BLUE}npm run docs:all${NC}"
  exit 1
fi
