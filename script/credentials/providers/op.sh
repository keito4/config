#!/usr/bin/env zsh

# 1Password CLI credential provider

credential_provider::name() {
    echo "1password"
}

credential_provider::ensure_ready() {
    if ! command -v op >/dev/null 2>&1; then
        echo "1Password CLI (op) is not installed. Install with: brew install --cask 1password-cli" >&2
        return 1
    fi

    if ! op account list >/dev/null 2>&1; then
        echo "Not signed in to 1Password. Run: op signin" >&2
        return 1
    fi
}

credential_provider::inject() {
    local template="$1"
    local output="$2"

    op inject --in-file "$template" --out-file "$output"
}
