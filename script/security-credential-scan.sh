#!/usr/bin/env bash
# Security Credential Scan entrypoint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# shellcheck source=script/lib/security_credential_scan.sh
source "$SCRIPT_DIR/lib/security_credential_scan.sh"

security_credential_scan_main "$@"
