#!/bin/bash

# Setup script for Bats test framework
# This script installs Bats and its helper libraries

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/bats-libs"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up Bats test framework...${NC}"

# Install bats-core
if [[ ! -d "$LIBS_DIR/bats-core" ]]; then
    echo "Installing bats-core..."
    git clone https://github.com/bats-core/bats-core.git "$LIBS_DIR/bats-core"
else
    echo "bats-core already installed"
fi

# Install bats-support
if [[ ! -d "$LIBS_DIR/bats-support" ]]; then
    echo "Installing bats-support..."
    git clone https://github.com/bats-core/bats-support.git "$LIBS_DIR/bats-support"
else
    echo "bats-support already installed"
fi

# Install bats-assert
if [[ ! -d "$LIBS_DIR/bats-assert" ]]; then
    echo "Installing bats-assert..."
    git clone https://github.com/bats-core/bats-assert.git "$LIBS_DIR/bats-assert"
else
    echo "bats-assert already installed"
fi

# Install bats-file
if [[ ! -d "$LIBS_DIR/bats-file" ]]; then
    echo "Installing bats-file..."
    git clone https://github.com/bats-core/bats-file.git "$LIBS_DIR/bats-file"
else
    echo "bats-file already installed"
fi

# Create symlink for bats executable
BATS_EXEC="$LIBS_DIR/bats-core/bin/bats"
if [[ -f "$BATS_EXEC" ]]; then
    echo -e "${GREEN}Bats setup complete!${NC}"
    echo "Run tests with: $BATS_EXEC test/*.bats"
else
    echo -e "${YELLOW}Warning: Bats executable not found${NC}"
fi