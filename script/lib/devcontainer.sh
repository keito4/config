#!/usr/bin/env zsh

# DevContainer-specific helpers for bootstrap scripts.

if [[ -n "${DEVCONTAINER_LIB_SOURCED:-}" ]]; then
    return
fi
typeset -g DEVCONTAINER_LIB_SOURCED=1

devcontainer::is_active() {
    [[ "${PLATFORM_IN_DEVCONTAINER:-false}" = true ]]
}

devcontainer::configure_git_identity() {
    local name="$1"
    local email="$2"

    git config --global user.name "$name"
    git config --global user.email "$email"

    # Remove problematic GitHub aliases that expect host key helpers
    git config --global --remove-section url."github:" 2>/dev/null || true
    git config --global --unset-all url."github:".insteadof 2>/dev/null || true
}

devcontainer::ensure_secret_backend() {
    local provider="${1:-${DEVCONTAINER_SECRET_PROVIDER:-op}}"
    case "$provider" in
        op|1password)
            devcontainer::setup_op_backend
            ;;
        none|"")
            ;;
        *)
            echo "Unsupported secret provider: $provider" >&2
            return 1
            ;;
    esac
}

devcontainer::setup_op_backend() {
    if ! command -v op >/dev/null 2>&1; then
        echo "Installing 1Password CLI..."
        curl -sS https://downloads.1password.com/linux/debian/amd64/stable/1password-cli-amd64-latest.deb -o /tmp/1password-cli.deb
        if command -v sudo >/dev/null 2>&1; then
            sudo dpkg -i /tmp/1password-cli.deb
        else
            dpkg -i /tmp/1password-cli.deb
        fi
        rm /tmp/1password-cli.deb
    fi

    if command -v op >/dev/null 2>&1; then
        git config --global gpg.ssh.program "op-ssh-sign"
        echo "1Password SSH signing configured"
    else
        echo "Warning: 1Password CLI installation failed, disabling GPG signing" >&2
        git config --global commit.gpgsign false
    fi
}

devcontainer::bootstrap() {
    local name="${DEVCONTAINER_GIT_NAME:-keito4}"
    local email="${DEVCONTAINER_GIT_EMAIL:-newton30000@gmail.com}"
    local provider="${DEVCONTAINER_SECRET_PROVIDER:-op}"

    devcontainer::configure_git_identity "$name" "$email"
    devcontainer::ensure_secret_backend "$provider"
}
