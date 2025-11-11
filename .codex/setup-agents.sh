#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
setup-agents.sh - install Claude/Codex assets into the current user profile

Usage:
  bash .codex/setup-agents.sh [--force] [--codex-dir PATH] [--claude-dir PATH]

Options:
  --force         Overwrite and delete existing files inside the target directories
  --codex-dir     Override the destination for Codex assets (default: ~/.codex)
  --claude-dir    Override the destination for Claude assets (default: ~/.claude)
  -h, --help      Show this help message
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_CODEX="${CODEX_HOME:-$HOME/.codex}"
TARGET_CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    --codex-dir)
      if [[ -z "${2:-}" ]]; then
        echo "--codex-dir requires a path argument" >&2
        exit 2
      fi
      TARGET_CODEX="$2"
      shift 2
      ;;
    --claude-dir)
      if [[ -z "${2:-}" ]]; then
        echo "--claude-dir requires a path argument" >&2
        exit 2
      fi
      TARGET_CLAUDE="$2"
      shift 2
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

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required but not installed." >&2
  exit 2
fi

sync_opts=(-a)
rsync_desc="synchronizing"
if [[ "$FORCE" == true ]]; then
  sync_opts+=(--delete)
  rsync_desc="force-synchronizing"
fi

echo "➡️  $rsync_desc Claude/Codex assets from $REPO_ROOT"

copy_tree() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -d "$src" ]]; then
    echo "⚠️  Skipping $label; source directory missing at $src"
    return
  fi

  mkdir -p "$dest"
  rsync "${sync_opts[@]}" "$src/" "$dest/"
  echo "✅ Installed $label → $dest"
}

copy_file() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -f "$src" ]]; then
    echo "⚠️  Skipping $label; source file missing at $src"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  rsync "${sync_opts[@]}" "$src" "$dest"
  echo "✅ Installed $label → $dest"
}

copy_tree "$REPO_ROOT/.claude/agents" "$TARGET_CLAUDE/agents" "Claude specialized agents"
copy_tree "$REPO_ROOT/.claude/commands" "$TARGET_CLAUDE/commands" "Claude automation commands"
copy_tree "$REPO_ROOT/.codex/prompts" "$TARGET_CODEX/prompts" "Codex prompt library"
copy_file "$REPO_ROOT/.codex/config.toml" "$TARGET_CODEX/config.toml" "Codex MCP configuration"

mkdir -p "$TARGET_CODEX/scripts"
install -m 0755 "$REPO_ROOT/.codex/scripts/validate-agents.sh" "$TARGET_CODEX/scripts/validate-agents.sh"
install -m 0755 "$REPO_ROOT/.codex/scripts/sync-agents.sh" "$TARGET_CODEX/scripts/sync-agents.sh"
echo "$REPO_ROOT" > "$TARGET_CODEX/.agent-source"

echo "🏁 Agent assets installed. Run:"
echo "   bash \"$TARGET_CODEX/scripts/validate-agents.sh\""
echo "   bash \"$TARGET_CODEX/scripts/sync-agents.sh\" --dry-run"
