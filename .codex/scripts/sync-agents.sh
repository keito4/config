#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
sync-agents.sh - keep Claude/Codex assets in sync with the repository

Usage:
  sync-agents.sh [--repo PATH] [--dry-run] [--update] [--verbose]

Options:
  --repo PATH   Explicit path to the config repository (defaults to REPO_PATH or the path recorded by setup-agents.sh)
  --dry-run     Show the planned synchronization actions and exit with status 1 if drift is detected
  --update      Apply synchronization changes immediately
  --verbose     Print the detailed rsync output (implied for --dry-run)
  -h, --help    Show this help message
EOF
}

MODE="check"
VERBOSE=false
REPO_ROOT="${REPO_PATH:-}"
TARGET_CODEX="${CODEX_HOME:-$HOME/.codex}"
TARGET_CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      if [[ -z "${2:-}" ]]; then
        echo "--repo requires a path argument" >&2
        exit 2
      fi
      REPO_ROOT="$2"
      shift 2
      ;;
    --dry-run)
      MODE="dry-run"
      VERBOSE=true
      shift
      ;;
    --update|--apply|--fix)
      MODE="apply"
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

resolve_repo_root() {
  if [[ -n "$REPO_ROOT" ]]; then
    return
  fi

  local candidate
  candidate="$(cd "$SCRIPT_DIR/../.." && pwd)"
  if [[ -f "$candidate/package.json" ]]; then
    REPO_ROOT="$candidate"
    return
  fi

  local recorded="$TARGET_CODEX/.agent-source"
  if [[ -f "$recorded" ]]; then
    local stored
    stored="$(<"$recorded")"
    if [[ -n "$stored" ]]; then
      REPO_ROOT="$stored"
    fi
  fi
}

resolve_repo_root

if [[ -z "$REPO_ROOT" ]]; then
  echo "Unable to determine repository root. Pass --repo or set REPO_PATH." >&2
  exit 2
fi

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Repository path '$REPO_ROOT' does not exist." >&2
  exit 2
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required but not installed." >&2
  exit 2
fi

dir_opts=(-a --delete)
file_opts=(-a)

if [[ "$MODE" != "apply" ]]; then
  dir_opts+=(--dry-run --itemize-changes)
  file_opts+=(--dry-run --itemize-changes)
fi

clean_output() {
  # shellcheck disable=SC2016
  grep -Ev '^(sending incremental file list|sent [0-9]+ bytes.*|total size is .*)$' | sed '/^$/d' || true
}

changes_detected=false

sync_dir() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -d "$src" ]]; then
    echo "⚠️  Skipping $label; source directory missing at $src"
    return
  fi

  mkdir -p "$dest"

  local output
  if [[ "$MODE" == "apply" ]]; then
    rsync "${dir_opts[@]}" "$src/" "$dest/"
    echo "✅ Synced $label"
    return
  fi

  output="$(rsync "${dir_opts[@]}" "$src/" "$dest/" | clean_output)"
  if [[ -n "$output" ]]; then
    changes_detected=true
    echo "❌ Drift detected in $label"
    if [[ "$VERBOSE" == true ]]; then
      echo "$output"
    fi
  else
    echo "✅ $label already in sync"
  fi
}

sync_file() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -f "$src" ]]; then
    echo "⚠️  Skipping $label; source file missing at $src"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ "$MODE" == "apply" ]]; then
    rsync "${file_opts[@]}" "$src" "$dest"
    echo "✅ Synced $label"
    return
  fi

  local output
  output="$(rsync "${file_opts[@]}" "$src" "$dest" | clean_output)"
  if [[ -n "$output" ]]; then
    changes_detected=true
    echo "❌ Drift detected in $label"
    if [[ "$VERBOSE" == true ]]; then
      echo "$output"
    fi
  else
    echo "✅ $label already in sync"
  fi
}

resources=(
  "$REPO_ROOT/.claude/agents|$TARGET_CLAUDE/agents|Claude specialized agents"
  "$REPO_ROOT/.claude/commands|$TARGET_CLAUDE/commands|Claude automation commands"
  "$REPO_ROOT/.codex/prompts|$TARGET_CODEX/prompts|Codex prompt library"
)

files=(
  "$REPO_ROOT/.codex/config.toml|$TARGET_CODEX/config.toml|Codex MCP configuration"
)

for entry in "${resources[@]}"; do
  IFS='|' read -r src dest label <<<"$entry"
  sync_dir "$src" "$dest" "$label"
done

for entry in "${files[@]}"; do
  IFS='|' read -r src dest label <<<"$entry"
  sync_file "$src" "$dest" "$label"
done

if [[ "$MODE" == "apply" ]]; then
  echo "Agent assets synchronized successfully."
  exit 0
fi

if [[ "$changes_detected" == true ]]; then
  echo "Agent assets are out of sync."
  exit 1
fi

echo "All agent assets are already synchronized."
