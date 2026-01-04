#!/bin/bash
# Language Server Protocol Setup Script
# Installs language servers required for Claude Code LSP integration

set -e

echo "=== Installing Language Servers ==="

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed"
    exit 1
fi

# Define language servers to install
LANGUAGE_SERVERS=(
    "typescript"
    "typescript-language-server"
    "bash-language-server"
    "vscode-langservers-extracted"
    "yaml-language-server"
)

# Install language servers globally
echo "Installing language servers globally..."
npm install -g "${LANGUAGE_SERVERS[@]}"

# Verify installation
echo ""
echo "=== Verifying Language Server Installation ==="

verify_command() {
    local cmd=$1
    local name=$2
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>/dev/null | head -1 || echo "installed")
        echo "[OK] $name: $version"
        return 0
    else
        echo "[MISSING] $name"
        return 1
    fi
}

errors=0
verify_command "typescript-language-server" "TypeScript LSP" || ((errors++))
verify_command "bash-language-server" "Bash LSP" || ((errors++))
verify_command "yaml-language-server" "YAML LSP" || ((errors++))
verify_command "vscode-json-language-server" "JSON LSP" || ((errors++))
verify_command "tsc" "TypeScript Compiler" || ((errors++))

echo ""
if [ $errors -eq 0 ]; then
    echo "=== All Language Servers installed successfully ==="
else
    echo "=== Warning: $errors language server(s) missing ==="
fi

exit 0
