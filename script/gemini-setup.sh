#!/usr/bin/env bash
#
# Gemini CLI Setup Script
# This script sets up the Gemini CLI environment for AI-assisted development
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in CI environment
is_ci() {
    [ "${CI:-false}" = "true" ] || [ "${GITHUB_ACTIONS:-false}" = "true" ]
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Gemini CLI via npm
install_gemini_npm() {
    print_info "Installing Gemini CLI via npm..."
    if command_exists npm; then
        npm install -g @google/generative-ai-cli
        print_info "Gemini CLI installed successfully via npm"
    else
        print_warning "npm not found, skipping npm installation"
        return 1
    fi
}

# Function to install Gemini CLI via pip
install_gemini_pip() {
    print_info "Installing Gemini CLI via pip..."
    if command_exists pip; then
        pip install google-generativeai-cli
        print_info "Gemini CLI installed successfully via pip"
    elif command_exists pip3; then
        pip3 install google-generativeai-cli
        print_info "Gemini CLI installed successfully via pip3"
    else
        print_warning "pip not found, skipping pip installation"
        return 1
    fi
}

# Function to setup API key
setup_api_key() {
    if [ -z "${GEMINI_API_KEY:-}" ]; then
        if is_ci; then
            print_warning "GEMINI_API_KEY not set. Please set it as a secret in your CI/CD environment."
        else
            print_info "Setting up Gemini API key..."
            echo ""
            echo "Please obtain your API key from: https://makersuite.google.com/app/apikey"
            echo ""
            read -p "Enter your Gemini API key: " -s api_key
            echo ""
            
            if [ -n "$api_key" ]; then
                # Add to shell profile
                shell_profile=""
                if [ -f "$HOME/.bashrc" ]; then
                    shell_profile="$HOME/.bashrc"
                elif [ -f "$HOME/.zshrc" ]; then
                    shell_profile="$HOME/.zshrc"
                elif [ -f "$HOME/.profile" ]; then
                    shell_profile="$HOME/.profile"
                fi
                
                if [ -n "$shell_profile" ]; then
                    echo "" >> "$shell_profile"
                    echo "# Gemini CLI Configuration" >> "$shell_profile"
                    echo "export GEMINI_API_KEY='$api_key'" >> "$shell_profile"
                    print_info "API key added to $shell_profile"
                    print_info "Please run 'source $shell_profile' or restart your terminal"
                else
                    print_warning "Could not find shell profile file"
                    echo "Please add the following to your shell profile manually:"
                    echo "export GEMINI_API_KEY='$api_key'"
                fi
                
                # Export for current session
                export GEMINI_API_KEY="$api_key"
            else
                print_warning "No API key provided. Skipping API key setup."
            fi
        fi
    else
        print_info "GEMINI_API_KEY already set"
    fi
}

# Function to create configuration file
create_config_file() {
    local config_file=".geminirc"
    
    if [ -f "$config_file" ]; then
        print_info "Configuration file $config_file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing configuration"
            return
        fi
    fi
    
    print_info "Creating Gemini configuration file..."
    
    # Check if example file exists and use it as template
    local example_file=".geminirc.example"
    if [ -f "$example_file" ]; then
        print_info "Using $example_file as template"
        cp "$example_file" "$config_file"
        
        # Show available options
        echo ""
        echo "Configuration file created with the following contexts:"
        echo "  • development - For writing new code"
        echo "  • review - For code review and analysis"
        echo "  • testing - For writing tests"
        echo "  • documentation - For creating documentation"
        echo "  • refactoring - For improving existing code"
        echo ""
        echo "Available models:"
        echo "  • gemini-1.5-pro - Most capable (8K tokens)"
        echo "  • gemini-1.5-flash - Fast and efficient (4K tokens)"
        echo "  • gemini-pro - Standard model (2K tokens)"
        echo ""
    else
        # Create minimal config if example doesn't exist
        cat > "$config_file" <<EOF
{
  "defaultModel": "gemini-1.5-pro",
  "models": {
    "gemini-1.5-pro": {
      "temperature": 0.7,
      "maxTokens": 8192,
      "topP": 0.95,
      "topK": 40
    },
    "gemini-1.5-flash": {
      "temperature": 0.5,
      "maxTokens": 4096,
      "topP": 0.9,
      "topK": 32
    }
  },
  "api": {
    "endpoint": "https://generativelanguage.googleapis.com/v1",
    "timeout": 30000,
    "retryConfig": {
      "maxRetries": 3,
      "retryDelay": 1000
    }
  },
  "output": {
    "format": "markdown",
    "colorize": true,
    "verbose": false
  },
  "contexts": {
    "development": {
      "model": "gemini-1.5-pro",
      "temperature": 0.5,
      "maxTokens": 8192
    },
    "review": {
      "model": "gemini-1.5-flash",
      "temperature": 0.3,
      "maxTokens": 4096
    }
  }
}
EOF
    fi
    
    print_info "Configuration file created at $config_file"
}

# Function to verify installation
verify_installation() {
    print_info "Verifying Gemini CLI installation..."
    
    if command_exists gemini; then
        print_info "Gemini CLI is installed"
        gemini --version || true
        
        if [ -n "${GEMINI_API_KEY:-}" ]; then
            print_info "Testing Gemini CLI connection..."
            if gemini test "Hello, Gemini!" 2>/dev/null; then
                print_info "Gemini CLI is working correctly!"
            else
                print_warning "Could not connect to Gemini API. Please check your API key."
            fi
        else
            print_warning "GEMINI_API_KEY not set. Cannot test connection."
        fi
    else
        print_error "Gemini CLI is not installed or not in PATH"
        return 1
    fi
}

# Main setup function
main() {
    print_info "Starting Gemini CLI setup..."
    
    # Check if Gemini CLI is already installed
    if command_exists gemini; then
        print_info "Gemini CLI is already installed"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping installation"
        else
            install_gemini_npm || install_gemini_pip
        fi
    else
        # Try to install via npm first, then pip
        install_gemini_npm || install_gemini_pip || {
            print_error "Failed to install Gemini CLI. Please install npm or pip first."
            exit 1
        }
    fi
    
    # Setup API key
    setup_api_key
    
    # Create configuration file
    if ! is_ci; then
        create_config_file
    fi
    
    # Verify installation
    verify_installation
    
    print_info "Gemini CLI setup completed!"
    echo ""
    echo "Quick start commands:"
    echo "  gemini generate 'Create a REST API endpoint'"
    echo "  gemini review path/to/file.js"
    echo "  gemini explain path/to/complex-code.py"
    echo "  gemini debug 'Error message here'"
    echo ""
    echo "Context-based commands:"
    echo "  gemini generate --context=development 'Create user authentication'"
    echo "  gemini review --context=review src/main.js"
    echo "  gemini test --context=testing src/functions.js"
    echo "  gemini docs --context=documentation src/"
    echo ""
    echo "Custom commands:"
    echo "  gemini optimize src/slow-function.js"
    echo "  gemini security src/api-endpoint.js"
    echo "  gemini accessibility src/components/"
    echo ""
    echo "For more information, see the documentation in CLAUDE.md"
}

# Run main function
main "$@"