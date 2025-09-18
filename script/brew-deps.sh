#!/usr/bin/env zsh

# Brew dependency management script
# This script helps manage Homebrew packages by categorizing them based on dependencies

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine script directory
SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
BREW_DIR="$REPO_ROOT/brew"

# Functions
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

check_brew() {
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed"
        echo "Install it from: https://brew.sh"
        exit 1
    fi
}

get_leaves() {
    # Get all formulae that are not dependencies of other formulae
    brew leaves
}

get_leaves_with_categories() {
    # Categorize leaves by type
    local leaves=$(brew leaves)
    
    echo "=== Development Tools ==="
    echo "$leaves" | grep -E '^(git|gh|ghq|act|cmake|go|rust|node|npm|yarn|bun|deno|rbenv|pyenv|pipenv|python@|php|openjdk|dotnet-sdk)$' || true
    
    echo -e "\n=== Cloud & DevOps ==="
    echo "$leaves" | grep -E '^(awscli|aws-sam-cli|aws-sso-util|azure-cli|gcloud-cli|google-cloud-sdk|terraform|tfenv|helm|docker|kubernetes-cli|sops)$' || true
    
    echo -e "\n=== Database & Backend ==="
    echo "$leaves" | grep -E '^(mysql-client|postgresql@|redis|mongodb|supabase)$' || true
    
    echo -e "\n=== Utilities ==="
    echo "$leaves" | grep -E '^(jq|fzf|peco|tree|tig|translate-shell|terminal-notifier|coreutils|trash|mas|cliclick)$' || true
    
    echo -e "\n=== Media & Graphics ==="
    echo "$leaves" | grep -E '^(ffmpeg|imagemagick|graphviz|poppler)$' || true
    
    echo -e "\n=== Fun & Misc ==="
    echo "$leaves" | grep -E '^(cowsay|figlet|toilet|sl)$' || true
    
    echo -e "\n=== Uncategorized ==="
    # Show remaining items
    local categorized=$(echo "$leaves" | grep -E '^(git|gh|ghq|act|cmake|go|rust|node|npm|yarn|bun|deno|rbenv|pyenv|pipenv|python@|php|openjdk|dotnet-sdk|awscli|aws-sam-cli|aws-sso-util|azure-cli|gcloud-cli|google-cloud-sdk|terraform|tfenv|helm|docker|kubernetes-cli|sops|mysql-client|postgresql@|redis|mongodb|supabase|jq|fzf|peco|tree|tig|translate-shell|terminal-notifier|coreutils|trash|mas|cliclick|ffmpeg|imagemagick|graphviz|poppler|cowsay|figlet|toilet|sl)$' || true)
    comm -23 <(echo "$leaves" | sort) <(echo "$categorized" | sort) || true
}

get_cask_leaves() {
    # Get all casks that were explicitly installed (not dependencies)
    brew list --cask | while read cask; do
        # Check if this cask is a dependency of another cask
        if ! brew uses --cask --installed "$cask" | grep -q .; then
            echo "$cask"
        fi
    done
}

get_cask_leaves_with_categories() {
    local leaves=$(get_cask_leaves)
    
    echo "=== Development Tools ==="
    echo "$leaves" | grep -E '^(visual-studio-code|cursor|tableplus|postman|orbstack|rancher|parallels-client)$' || true
    
    echo -e "\n=== Communication ==="
    echo "$leaves" | grep -E '^(slack|discord|mattermost|zoom|messenger)$' || true
    
    echo -e "\n=== Productivity ==="
    echo "$leaves" | grep -E '^(notion|notion-calendar|raycast|alfred|bettertouchtool|bartender|karabiner-elements)$' || true
    
    echo -e "\n=== Security & Privacy ==="
    echo "$leaves" | grep -E '^(1password|1password-cli|authy|tailscale|tailscale-app)$' || true
    
    echo -e "\n=== AI Tools ==="
    echo "$leaves" | grep -E '^(chatgpt|claude|cursor)$' || true
    
    echo -e "\n=== Utilities ==="
    echo "$leaves" | grep -E '^(appcleaner|the-unarchiver|qblocker|dropbox|deepl|google-japanese-ime|blackhole-2ch)$' || true
    
    echo -e "\n=== Browsers ==="
    echo "$leaves" | grep -E '^(arc|chrome|firefox|safari)$' || true
    
    echo -e "\n=== Uncategorized Casks ==="
    local categorized=$(echo "$leaves" | grep -E '^(visual-studio-code|cursor|tableplus|postman|orbstack|rancher|parallels-client|slack|discord|mattermost|zoom|messenger|notion|notion-calendar|raycast|alfred|bettertouchtool|bartender|karabiner-elements|1password|1password-cli|authy|tailscale|tailscale-app|chatgpt|claude|appcleaner|the-unarchiver|qblocker|dropbox|deepl|google-japanese-ime|blackhole-2ch|arc|chrome|firefox|safari)$' || true)
    comm -23 <(echo "$leaves" | sort) <(echo "$categorized" | sort) || true
}

generate_standalone_brewfile() {
    local output="$BREW_DIR/StandaloneBrewfile"
    
    echo "# Homebrew packages without dependencies" > "$output"
    echo "# Generated on $(date)" >> "$output"
    echo "# This file contains only packages that were explicitly installed" >> "$output"
    echo "# and are not dependencies of other packages" >> "$output"
    echo "" >> "$output"
    
    # Add taps
    echo "# Taps" >> "$output"
    brew tap | while read tap; do
        echo "tap \"$tap\"" >> "$output"
    done
    echo "" >> "$output"
    
    # Add formulae
    echo "# Formulae (command-line tools)" >> "$output"
    get_leaves | while read formula; do
        echo "brew \"$formula\"" >> "$output"
    done
    echo "" >> "$output"
    
    # Add casks
    echo "# Casks (GUI applications)" >> "$output"
    get_cask_leaves | while read cask; do
        echo "cask \"$cask\"" >> "$output"
    done
    
    print_success "Generated $output"
}

generate_categorized_brewfile() {
    local output="$BREW_DIR/CategorizedBrewfile"
    
    {
        echo "# Categorized Homebrew packages without dependencies"
        echo "# Generated on $(date)"
        echo "# This file contains only packages that were explicitly installed"
        echo "# and are not dependencies of other packages"
        echo ""
        
        # Add taps
        echo "# Taps"
        brew tap | while read tap; do
            echo "tap \"$tap\""
        done
        echo ""
        
        echo "# === FORMULAE ==="
        echo ""
        
        # Development Tools
        echo "# Development Tools"
        get_leaves | grep -E '^(git|gh|ghq|act|cmake|go|rust|node|npm|yarn|bun|deno|rbenv|pyenv|pipenv|python@|php|openjdk|dotnet-sdk)$' | while read f; do
            echo "brew \"$f\""
        done || true
        echo ""
        
        # Cloud & DevOps
        echo "# Cloud & DevOps"
        get_leaves | grep -E '^(awscli|aws-sam-cli|aws-sso-util|azure-cli|gcloud-cli|google-cloud-sdk|terraform|tfenv|helm|docker|kubernetes-cli|sops)$' | while read f; do
            echo "brew \"$f\""
        done || true
        echo ""
        
        echo ""
        echo "# === CASKS ==="
        echo ""
        
        # Development Tools
        echo "# Development Tools"
        get_cask_leaves | grep -E '^(visual-studio-code|cursor|tableplus|postman|orbstack|rancher)$' | while read c; do
            echo "cask \"$c\""
        done || true
        echo ""
        
    } > "$output"
    
    print_success "Generated $output"
}

show_dependency_tree() {
    local package="$1"
    
    if brew list --formula | grep -q "^${package}$"; then
        echo "Dependencies for formula: $package"
        brew deps --tree "$package"
    elif brew list --cask | grep -q "^${package}$"; then
        echo "Cask: $package (casks typically don't have dependencies)"
    else
        print_error "Package not found: $package"
    fi
}

show_dependents() {
    local package="$1"
    
    echo "Packages that depend on: $package"
    brew uses --installed "$package"
}

# Main command handling
case "${1:-}" in
    leaves|standalone)
        check_brew
        echo "=== Standalone Formulae (no dependents) ==="
        get_leaves
        echo -e "\n=== Standalone Casks ==="
        get_cask_leaves
        ;;
    categorized)
        check_brew
        echo "=== Categorized Standalone Packages ==="
        echo -e "\n--- FORMULAE ---"
        get_leaves_with_categories
        echo -e "\n--- CASKS ---"
        get_cask_leaves_with_categories
        ;;
    generate)
        check_brew
        generate_standalone_brewfile
        generate_categorized_brewfile
        ;;
    deps)
        check_brew
        if [[ -z "${2:-}" ]]; then
            print_error "Package name required"
            echo "Usage: $0 deps <package>"
            exit 1
        fi
        show_dependency_tree "$2"
        ;;
    uses)
        check_brew
        if [[ -z "${2:-}" ]]; then
            print_error "Package name required"
            echo "Usage: $0 uses <package>"
            exit 1
        fi
        show_dependents "$2"
        ;;
    *)
        echo "Usage: $0 {leaves|standalone|categorized|generate|deps|uses} [package]"
        echo
        echo "Commands:"
        echo "  leaves, standalone  - List packages without dependents"
        echo "  categorized        - List packages organized by category"
        echo "  generate           - Generate Brewfiles for standalone packages"
        echo "  deps <package>     - Show dependencies of a package"
        echo "  uses <package>     - Show packages that depend on a package"
        exit 1
        ;;
esac