#!/usr/bin/env bash
# Narrow TAKT command gate for scheduled repository maintenance.

set -euo pipefail

MODE_FILE="${TAKT_MAINTENANCE_MODE_FILE:-.context/takt-maintenance-mode}"
if [[ -f "$MODE_FILE" ]]; then
  MODE="$(<"$MODE_FILE")"
else
  MODE="${REPO_MAINTENANCE_MODE:-full}"
fi

case "$MODE" in
  full|quick|check-only) ;;
  *)
    echo "Unsupported maintenance mode: $MODE" >&2
    exit 2
    ;;
esac

script/repo-maintenance.sh --mode "$MODE"
