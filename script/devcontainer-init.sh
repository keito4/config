#!/usr/bin/env bash

# Cross-platform initialization script for devcontainer
# Creates necessary directories on the host system before container startup

# Function to create directory cross-platform
create_directory() {
    local dir_path="$1"
    
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        # Windows environment
        local win_path="${dir_path//\//\\}"
        cmd //c "if not exist \"$win_path\" mkdir \"$win_path\""
    else
        # Unix-like environment (Linux, macOS, WSL)
        mkdir -p "$dir_path"
    fi
}

# Determine the home directory based on platform
if [[ -n "$WINDIR" ]] || [[ -n "$SYSTEMROOT" ]]; then
    # Windows
    HOME_DIR="${USERPROFILE:-$HOME}"
else
    # Unix-like systems
    HOME_DIR="$HOME"
fi

echo "Initializing devcontainer environment..."
echo "Detected platform: $OSTYPE"
echo "Home directory: $HOME_DIR"

# Create necessary directories
echo "Creating Claude configuration directory..."
create_directory "$HOME_DIR/.claude"

echo "Creating Cursor configuration directory..."
create_directory "$HOME_DIR/.cursor"

# Verify directories were created
if [[ -d "$HOME_DIR/.claude" ]]; then
    echo "✓ .claude directory created successfully"
else
    echo "⚠ Warning: Failed to create .claude directory"
fi

if [[ -d "$HOME_DIR/.cursor" ]]; then
    echo "✓ .cursor directory created successfully"
else
    echo "⚠ Warning: Failed to create .cursor directory"
fi

# Create .claude.json if it doesn't exist
CLAUDE_CONFIG="$HOME_DIR/.claude.json"
if [[ ! -f "$CLAUDE_CONFIG" ]]; then
    echo "Creating default .claude.json configuration..."
    cat > "$CLAUDE_CONFIG" << 'EOF'
{
  "version": "1.0",
  "created": "$(date -Iseconds)",
  "platform": "$(uname -s)"
}
EOF
    echo "✓ Default .claude.json created"
else
    echo "✓ .claude.json already exists"
fi

echo "Devcontainer initialization completed!"