#!/usr/bin/env bash
# Team Repository Protection Setup entrypoint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# shellcheck source=script/lib/setup_team_protection.sh
source "$SCRIPT_DIR/lib/setup_team_protection.sh"

setup_team_protection_main "$@"
