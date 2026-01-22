#!/usr/bin/env zsh

# Shared platform helpers for bootstrap scripts.

if [[ -n "${PLATFORM_LIB_SOURCED:-}" ]]; then
    return
fi
typeset -g PLATFORM_LIB_SOURCED=1

platform::detect_os() {
    local uname_out
    uname_out="$(uname -s 2>/dev/null || echo "")"
    case "$uname_out" in
        Linux) echo "linux" ;;
        Darwin) echo "darwin" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

platform::is_supported() {
    [[ "$PLATFORM_OS" != "unknown" ]]
}

platform::assert_supported() {
    if ! platform::is_supported; then
        echo "Unsupported OS: $(uname -s)" >&2
        return 1
    fi
}

platform::is_linux() {
    [[ "$PLATFORM_OS" = "linux" ]]
}

platform::is_darwin() {
    [[ "$PLATFORM_OS" = "darwin" ]]
}

platform::is_devcontainer() {
    [[ -f /.dockerenv || -n "${REMOTE_CONTAINERS:-}" || -n "${CODESPACES:-}" ]]
}

platform::run_task() {
    local task="$1"
    local os="${2:-$PLATFORM_OS}"
    local fn="${task}_${os}"
    shift || true
    if typeset -f "$fn" >/dev/null 2>&1; then
        "$fn" "$@"
    fi
    return 0
}

typeset -g PLATFORM_OS="$(platform::detect_os)"
typeset -g PLATFORM_IN_DEVCONTAINER=false
if platform::is_devcontainer; then
    PLATFORM_IN_DEVCONTAINER=true
fi
