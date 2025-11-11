#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
validate-agents.sh - validate that local Claude/Codex assets match the repository

Usage:
  validate-agents.sh [--repo PATH] [--verbose] [--fix]

Options:
  --repo PATH   Explicit path to the config repository (defaults to REPO_PATH or the path recorded by setup-agents.sh)
  --verbose     Print full diffs for drifted assets
  --fix         Automatically synchronize drifted assets by invoking sync-agents.sh --update
  -h, --help    Show this help message
EOF
}

VERBOSE=false
AUTO_FIX=false
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
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --fix|--auto-fix)
      AUTO_FIX=true
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

  # If the script still lives inside the repository use that path
  local candidate
  candidate="$(cd "$SCRIPT_DIR/../.." && pwd)"
  if [[ -f "$candidate/package.json" ]]; then
    REPO_ROOT="$candidate"
    return
  fi

  # Fall back to the path recorded by setup-agents.sh
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

pairs=(
  "$REPO_ROOT/.claude/agents|$TARGET_CLAUDE/agents|dir|Claude specialized agents"
  "$REPO_ROOT/.claude/commands|$TARGET_CLAUDE/commands|dir|Claude automation commands"
  "$REPO_ROOT/.codex/prompts|$TARGET_CODEX/prompts|dir|Codex prompt library"
  "$REPO_ROOT/.codex/config.toml|$TARGET_CODEX/config.toml|file|Codex MCP configuration"
)

mismatches=0

print_diff() {
  local diff_file="$1"
  if [[ "$VERBOSE" == true ]]; then
    cat "$diff_file"
    return
  fi

  local lines
  lines=$(wc -l <"$diff_file")
  if (( lines > 40 )); then
    head -n 40 "$diff_file"
    echo "... (${lines} lines total, re-run with --verbose for the full diff)"
  else
    cat "$diff_file"
  fi
}

compare_dir() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -d "$src" ]]; then
    echo "⚠️  Skipping $label; source directory missing at $src"
    return
  fi

  if [[ ! -d "$dest" ]]; then
    echo "❌ $label missing at $dest"
    mismatches=$((mismatches + 1))
    return
  fi

  local tmp
  tmp="$(mktemp)"
  if diff -ruN "$src" "$dest" >"$tmp"; then
    echo "✅ $label in sync"
  else
    echo "❌ Drift detected in $label"
    print_diff "$tmp"
    mismatches=$((mismatches + 1))
  fi
  rm -f "$tmp"
}

compare_file() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -f "$src" ]]; then
    echo "⚠️  Skipping $label; source file missing at $src"
    return
  fi

  if [[ ! -f "$dest" ]]; then
    echo "❌ $label missing at $dest"
    mismatches=$((mismatches + 1))
    return
  fi

  if cmp -s "$src" "$dest"; then
    echo "✅ $label in sync"
  else
    echo "❌ Drift detected in $label"
    if [[ "$VERBOSE" == true ]]; then
      diff -u "$src" "$dest"
    else
      echo "Run with --verbose to inspect differences."
    fi
    mismatches=$((mismatches + 1))
  fi
}

for entry in "${pairs[@]}"; do
  IFS='|' read -r src dest type label <<<"$entry"
  case "$type" in
    dir)
      compare_dir "$src" "$dest" "$label"
      ;;
    file)
      compare_file "$src" "$dest" "$label"
      ;;
    *)
      echo "Unknown comparison type '$type' for $label" >&2
      exit 2
      ;;
  esac
done

if (( mismatches > 0 )); then
  if [[ "$AUTO_FIX" == true ]]; then
    echo "Attempting to auto-fix drifted assets..."
    "$SCRIPT_DIR/sync-agents.sh" --repo "$REPO_ROOT" --update
    echo "Re-running validation after sync..."
    args=(--repo "$REPO_ROOT")
    if [[ "$VERBOSE" == true ]]; then
      args+=(--verbose)
    fi
    exec "$0" "${args[@]}"
  fi

  echo "Detected $mismatches drifted asset(s)."
  exit 1
fi

echo "All agent assets are in sync."
