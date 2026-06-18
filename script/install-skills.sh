#!/usr/bin/env bash
# Agent Skills Installer entrypoint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# shellcheck source=script/lib/install_skills.sh
source "$SCRIPT_DIR/lib/install_skills.sh"

install_skills_main "$@"
