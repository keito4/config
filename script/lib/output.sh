#!/usr/bin/env zsh
# shellcheck disable=SC1071 # zsh-specific script; ShellCheck has no zsh parser.
# ============================================================================
# Unified output and error handling functions for all scripts
# Usage: source "$SCRIPT_DIR/lib/output.sh"
# ============================================================================
# This library consolidates:
# - Standard output functions (info, success, warning, error)
# - Error handling functions (fatal, require_command, require_file, require_directory)
# - Backward compatibility aliases for legacy scripts

if [[ -n "${OUTPUT_LIB_SOURCED:-}" ]]; then
    return
fi

# macOS 標準の bash 3.2 は typeset -g をサポートせず、
# 「typeset: -g: invalid option」という分かりにくいエラーで失敗する。
# PATH で /bin が /opt/homebrew/bin より前にあると `#!/usr/bin/env bash` が
# 3.2 に解決されるため、より新しい bash があればそれで実行し直す。
# ここから下の再実行ブロックは bash 3.2 でも解釈できる構文だけで書くこと。

# PATH 上で最初に見つかった bash 4.0 以降のパスを出力する。
output::find_modern_bash() {
    local dir candidate
    local IFS=':'
    # shellcheck disable=SC2086 # PATH は IFS=':' で意図的に分割する。
    for dir in $PATH; do
        [ -n "$dir" ] || continue
        candidate="${dir}/bash"
        [ -x "$candidate" ] || continue
        if "$candidate" -c '[ "${BASH_VERSINFO[0]}" -ge 4 ]' 2>/dev/null; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

# 再実行してよいかを判定する。
# entry:  source チェーンの最も外側のファイル
# argv0:  $0
# major:  実行中の bash のメジャーバージョン
#
# 再実行先は 4.0 以降であることを確認済みなので、この判定は子で必ず偽になる。
# 別途ループ防止フラグを持つ必要はない。
output::should_reexec_bash() {
    local entry="$1" argv0="$2" major="$3"

    [ "$major" -lt 4 ] || return 1
    # 対話シェルや bats から source された場合、実行し直すべき本体が存在しない。
    [ "$entry" = "$argv0" ] || return 1
    [ -f "$argv0" ] || return 1
    return 0
}

if [[ -n "${BASH_VERSION:-}" ]] &&
    output::should_reexec_bash \
        "${BASH_SOURCE[$((${#BASH_SOURCE[@]} - 1))]}" \
        "$0" \
        "${BASH_VERSINFO[0]}"; then
    if OUTPUT_LIB_MODERN_BASH="$(output::find_modern_bash)"; then
        # 自分だけ作り直しても、子スクリプトの `#!/usr/bin/env bash` が古い bash に
        # 解決されるままでは同じ場所で落ちる。PATH ごと引き継がせる。
        PATH="${OUTPUT_LIB_MODERN_BASH%/*}:$PATH"
        export PATH
        exec "$OUTPUT_LIB_MODERN_BASH" "$0" "$@"
    fi
fi

# 新しい bash が見つからなかった場合は、従来どおり明示的なメッセージで落とす
# (zsh では BASH_VERSION が空なのでスキップ)。
if [[ -n "${BASH_VERSION:-}" && "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "エラー: このライブラリは bash 4.0 以降が必要です (現在: ${BASH_VERSION})" >&2
    echo "macOS の場合: brew install bash を実行し、PATH に /opt/homebrew/bin を追加してください" >&2
    return 1 2>/dev/null || exit 1
fi

typeset -g OUTPUT_LIB_SOURCED=1

# Color definitions
typeset -g OUTPUT_RED='\033[0;31m'
typeset -g OUTPUT_GREEN='\033[0;32m'
typeset -g OUTPUT_YELLOW='\033[1;33m'
typeset -g OUTPUT_BLUE='\033[0;34m'
typeset -g OUTPUT_NC='\033[0m'

# Short color aliases for backward compatibility
typeset -g RED="$OUTPUT_RED"
typeset -g GREEN="$OUTPUT_GREEN"
typeset -g YELLOW="$OUTPUT_YELLOW"
typeset -g BLUE="$OUTPUT_BLUE"
typeset -g NC="$OUTPUT_NC"

# ============================================================================
# Standard Output Functions
# ============================================================================

output::error() {
    local message="${1:?Error message required}"
    echo -e "${OUTPUT_RED}ERROR: ${message}${OUTPUT_NC}" >&2
}

output::success() {
    local message="${1:?Success message required}"
    echo -e "${OUTPUT_GREEN}✓ ${message}${OUTPUT_NC}"
}

output::warning() {
    local message="${1:?Warning message required}"
    echo -e "${OUTPUT_YELLOW}⚠ ${message}${OUTPUT_NC}"
}

output::info() {
    local message="${1:?Info message required}"
    echo -e "${OUTPUT_BLUE}[INFO]${OUTPUT_NC} ${message}"
}

output::header() {
    local message="${1:?Header message required}"
    echo -e "${OUTPUT_BLUE}=== ${message} ===${OUTPUT_NC}"
}

# ============================================================================
# Error Handling Functions (migrated from errors.sh)
# ============================================================================

# Fatal error with exit
output::fatal() {
    local message="${1:?Error message required}"
    echo -e "${OUTPUT_RED}❌ FATAL: ${message}${OUTPUT_NC}" >&2
    exit 1
}

# Command existence check
output::require_command() {
    local cmd="${1:?Command name required}"
    local install_hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        local msg="Required command not found: $cmd"
        if [[ -n "$install_hint" ]]; then
            msg="$msg\nInstall with: $install_hint"
        fi
        output::fatal "$msg"
    fi
}

# File existence check
output::require_file() {
    local file="${1:?File path required}"
    local error_msg="${2:-File not found: $file}"

    if [[ ! -f "$file" ]]; then
        output::fatal "$error_msg"
    fi
}

# Directory existence check
output::require_directory() {
    local dir="${1:?Directory path required}"
    local error_msg="${2:-Directory not found: $dir}"

    if [[ ! -d "$dir" ]]; then
        output::fatal "$error_msg"
    fi
}

# ============================================================================
# Backward Compatibility Aliases
# ============================================================================

# Global function aliases for backward compatibility
# These allow existing scripts to work without code changes
print_error() { output::error "$@"; }
print_success() { output::success "$@"; }
print_warning() { output::warning "$@"; }
print_info() { output::info "$@"; }
log_info() { output::info "$@"; }
log_success() { output::success "$@"; }
log_warn() { output::warning "$@"; }

# Bash-compatible short aliases
info() { output::info "$@"; }
success() { output::success "$@"; }
warning() { output::warning "$@"; }
error() { output::error "$@"; }
fatal() { output::fatal "$@"; }
