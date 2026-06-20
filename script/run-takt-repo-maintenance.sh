#!/usr/bin/env bash
# Narrow TAKT command gate for scheduled repository maintenance.

set -euo pipefail

MODE="${REPO_MAINTENANCE_MODE:-full}"

case "$MODE" in
  full|quick|check-only) ;;
  *)
    echo "Unsupported REPO_MAINTENANCE_MODE: $MODE" >&2
    exit 2
    ;;
esac

script/repo-maintenance.sh --mode "$MODE" --create-pr
