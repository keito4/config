#!/usr/bin/env zsh

# Credential management script with pluggable secret providers

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
CREDENTIALS_DIR="$REPO_ROOT/credentials"
CREDENTIAL_PROVIDER="${CREDENTIAL_PROVIDER:-op}"
PROVIDER_PATH="$SCRIPT_DIR/credentials/providers/${CREDENTIAL_PROVIDER}.sh"

source "$SCRIPT_DIR/lib/output.sh"

load_provider() {
    if [[ ! -f "$PROVIDER_PATH" ]]; then
        print_error "Unsupported credential provider: $CREDENTIAL_PROVIDER"
        exit 1
    fi

    source "$PROVIDER_PATH"

    if ! type credential_provider::inject >/dev/null 2>&1; then
        print_error "Provider $CREDENTIAL_PROVIDER is missing required functions"
        exit 1
    fi
}

provider_name() {
    if type credential_provider::name >/dev/null 2>&1; then
        credential_provider::name
    else
        echo "$CREDENTIAL_PROVIDER"
    fi
}

provider_ensure_ready() {
    if type credential_provider::ensure_ready >/dev/null 2>&1; then
        credential_provider::ensure_ready
    fi
}

provider_inject() {
    credential_provider::inject "$@"
}

inject_template() {
    local template="$1"
    local output="$2"

    if [[ ! -f "$template" ]]; then
        print_error "Template file not found: $template"
        return 1
    fi

    echo "Processing: $(basename "$template")"
    mkdir -p "$(dirname "$output")"

    if provider_inject "$template" "$output" 2>/dev/null; then
        print_success "Generated: $output"
        chmod 600 "$output"
    else
        print_error "Failed to process: $template"
        return 1
    fi
}

fetch_all_credentials() {
    echo "Fetching all credentials via provider ($(provider_name))..."

    for template in "$CREDENTIALS_DIR"/templates/*.env.template; do
        if [[ -f "$template" ]]; then
            local basename
            basename=$(basename "$template" .env.template)
            local output="$CREDENTIALS_DIR/${basename}.env"
            inject_template "$template" "$output"
        fi
    done
}

clean_credentials() {
    echo "Cleaning up credential files..."
    find "$CREDENTIALS_DIR" -name "*.env" -not -name "*.template" -delete
    print_success "Credential files cleaned up"
}

list_templates() {
    echo "Available credential templates:"
    echo

    for template in "$CREDENTIALS_DIR"/templates/*.env.template; do
        if [[ -f "$template" ]]; then
            local basename
            basename=$(basename "$template" .env.template)
            echo "  - $basename"
        fi
    done
}

load_provider

case "${1:-}" in
    fetch|get)
        provider_ensure_ready
        fetch_all_credentials
        ;;
    clean)
        clean_credentials
        ;;
    list)
        list_templates
        ;;
    *)
        echo "Usage: $0 {fetch|get|clean|list}"
        echo
        echo "Commands:"
        echo "  fetch, get  - Fetch credentials via provider ($(provider_name))"
        echo "  clean       - Remove all generated credential files"
        echo "  list        - List available credential templates"
        exit 1
        ;;
esac
