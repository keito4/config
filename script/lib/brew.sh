#!/usr/bin/env bash
# Homebrew utility library

# Source common functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${LIB_DIR}/common.sh"

# Package categories for formulae
declare -A FORMULA_CATEGORIES=(
    ["Development Tools"]="^(git|gh|ghq|act|cmake|go|rust|node|npm|yarn|bun|deno|rbenv|pyenv|pipenv|python@|php|openjdk|dotnet-sdk)$"
    ["Cloud & DevOps"]="^(awscli|aws-sam-cli|aws-sso-util|azure-cli|gcloud-cli|google-cloud-sdk|terraform|tfenv|helm|docker|kubernetes-cli|sops)$"
    ["Database & Backend"]="^(mysql-client|postgresql@|redis|mongodb|supabase)$"
    ["Utilities"]="^(jq|fzf|peco|tree|tig|translate-shell|terminal-notifier|coreutils|trash|mas|cliclick)$"
    ["Media & Graphics"]="^(ffmpeg|imagemagick|graphviz|poppler)$"
    ["Fun & Misc"]="^(cowsay|figlet|toilet|sl)$"
)

# Package categories for casks
declare -A CASK_CATEGORIES=(
    ["Development Tools"]="^(visual-studio-code|cursor|tableplus|postman|orbstack|rancher|parallels-client)$"
    ["Communication"]="^(slack|discord|mattermost|zoom|messenger)$"
    ["Productivity"]="^(notion|notion-calendar|raycast|alfred|bettertouchtool|bartender|karabiner-elements)$"
    ["Security & Privacy"]="^(1password|1password-cli|authy|tailscale|tailscale-app)$"
    ["AI Tools"]="^(chatgpt|claude|cursor)$"
    ["Utilities"]="^(appcleaner|the-unarchiver|qblocker|dropbox|deepl|google-japanese-ime|blackhole-2ch)$"
    ["Browsers"]="^(arc|chrome|firefox|safari)$"
)

# Check if Homebrew is installed
check_brew() {
    require_command "brew" "Install Homebrew from https://brew.sh"
}

# Get formulae that are not dependencies
get_formula_leaves() {
    brew leaves 2>/dev/null || true
}

# Get casks that are not dependencies
get_cask_leaves() {
    local cask
    brew list --cask 2>/dev/null | while read -r cask; do
        if ! brew uses --cask --installed "$cask" 2>/dev/null | grep -q .; then
            echo "$cask"
        fi
    done
}

# Categorize packages
categorize_packages() {
    local package_type=$1  # "formula" or "cask"
    local packages=$2
    local -n categories=$3  # Reference to associative array
    
    local categorized=""
    
    for category in "${!categories[@]}"; do
        local pattern="${categories[$category]}"
        local matched
        matched=$(echo "$packages" | grep -E "$pattern" || true)
        
        if [[ -n "$matched" ]]; then
            echo "# $category"
            echo "$matched" | while read -r pkg; do
                if [[ $package_type == "cask" ]]; then
                    echo "cask \"$pkg\""
                else
                    echo "brew \"$pkg\""
                fi
            done
            echo ""
            categorized="$categorized$matched"$'\n'
        fi
    done
    
    # Find uncategorized packages
    local uncategorized
    uncategorized=$(comm -23 <(echo "$packages" | sort) <(echo "$categorized" | sort) || true)
    
    if [[ -n "$uncategorized" ]]; then
        echo "# Uncategorized"
        echo "$uncategorized" | while read -r pkg; do
            if [[ $package_type == "cask" ]]; then
                echo "cask \"$pkg\""
            else
                echo "brew \"$pkg\""
            fi
        done
    fi
}

# Show package dependencies tree
show_deps_tree() {
    local package=$1
    
    if brew list --formula 2>/dev/null | grep -q "^${package}$"; then
        log_info "Dependencies for formula: $package"
        brew deps --tree "$package"
    elif brew list --cask 2>/dev/null | grep -q "^${package}$"; then
        log_info "Cask: $package (casks typically don't have dependencies)"
    else
        log_error "Package not found: $package"
        return 1
    fi
}

# Show packages that depend on given package
show_dependents() {
    local package=$1
    
    log_info "Packages that depend on: $package"
    brew uses --installed "$package" 2>/dev/null || echo "No dependents found"
}

# Generate taps section for Brewfile
generate_taps() {
    echo "# Taps"
    brew tap | while read -r tap; do
        echo "tap \"$tap\""
    done
    echo ""
}

# Export functions
export -f check_brew get_formula_leaves get_cask_leaves
export -f categorize_packages show_deps_tree show_dependents generate_taps