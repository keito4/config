#!/usr/bin/env bash
# Initialize a repository with config-managed development defaults.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"
# shellcheck source=script/lib/project-detect.sh
source "$SCRIPT_DIR/lib/project-detect.sh"

TARGET_DIR=""
TYPE=""
MINIMAL=false
WITH_DEVCONTAINER=true
WITH_CODESPACES=true
WITH_PROTECTION=true
LICENSE_TYPE="MIT"
INSTALL_DEPS=true

usage() {
  cat <<'EOF'
Usage: script/setup-new-repo.sh TARGET_DIR [--type TYPE] [--minimal] [--no-devcontainer] [--no-codespaces] [--no-protection] [--license MIT|Apache-2.0] [--no-install]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="${2:?--type requires a value}"
      shift 2
      ;;
    --minimal)
      MINIMAL=true
      shift
      ;;
    --no-devcontainer)
      WITH_DEVCONTAINER=false
      shift
      ;;
    --no-codespaces)
      WITH_CODESPACES=false
      shift
      ;;
    --no-protection)
      WITH_PROTECTION=false
      shift
      ;;
    --license)
      LICENSE_TYPE="${2:?--license requires a value}"
      shift 2
      ;;
    --no-install)
      INSTALL_DEPS=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      output::fatal "Unknown argument: $1"
      ;;
    *)
      if [[ -n "$TARGET_DIR" ]]; then
        output::fatal "Only one TARGET_DIR can be provided"
      fi
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

[[ -n "$TARGET_DIR" ]] || output::fatal "TARGET_DIR is required"

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
TYPE="${TYPE:-$(project::detect_type "$TARGET_DIR")}"
PROJECT_NAME="$(project::name "$TARGET_DIR")"

copy_if_missing() {
  local source="${1:?Source required}"
  local target="${2:?Target required}"

  if [[ -e "$target" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

initialize_git() {
  if [[ ! -d "$TARGET_DIR/.git" ]]; then
    git -C "$TARGET_DIR" init
  fi
}

create_devcontainer() {
  mkdir -p "$TARGET_DIR/.devcontainer" "$TARGET_DIR/.devcontainer/codespaces" "$TARGET_DIR/.vscode"

  cat > "$TARGET_DIR/.devcontainer/devcontainer.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "image": "ghcr.io/keito4/config-base:latest",
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp"
  },
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "github.vscode-github-actions"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "files.eol": "\n",
        "files.insertFinalNewline": true,
        "files.trimTrailingWhitespace": true
      }
    }
  }
}
EOF

  if [[ "$WITH_CODESPACES" == "true" ]]; then
    cat > "$TARGET_DIR/.devcontainer/codespaces/devcontainer.json" <<EOF
{
  "name": "$PROJECT_NAME (Codespaces)",
  "image": "ghcr.io/keito4/config-base:latest",
  "features": {
    "ghcr.io/devcontainers/features/sshd:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "remoteEnv": {
    "TMPDIR": "/home/vscode/.claude/tmp",
    "CLAUDE_CONFIG_DIR": "\${containerWorkspaceFolder}/.claude-data"
  },
  "postCreateCommand": "npm install",
  "customizations": {
    "codespaces": {
      "openFiles": ["README.md"]
    }
  },
  "secrets": {
    "ANTHROPIC_API_KEY": {
      "description": "Anthropic API key for Claude Code"
    }
  }
}
EOF
  fi
}

create_git_files() {
  copy_if_missing "$CONFIG_REPO/templates/commitlint.config.js" "$TARGET_DIR/commitlint.config.js"
  copy_if_missing "$CONFIG_REPO/templates/editorconfig" "$TARGET_DIR/.editorconfig"
  copy_if_missing "$CONFIG_REPO/templates/prettierrc-base.json" "$TARGET_DIR/.prettierrc.json"
  copy_if_missing "$CONFIG_REPO/templates/prettierignore" "$TARGET_DIR/.prettierignore"
  copy_if_missing "$CONFIG_REPO/templates/github/SECURITY.md" "$TARGET_DIR/SECURITY.md"

  if [[ ! -f "$TARGET_DIR/.gitignore" ]]; then
    cat > "$TARGET_DIR/.gitignore" <<'EOF'
node_modules/
coverage/
dist/
build/
.env
.env.*
!.env.example
.DS_Store
.context/
EOF
  fi
}

create_claude_config() {
  mkdir -p "$TARGET_DIR/.claude"
  cp -R "$CONFIG_REPO/.claude/hooks" "$TARGET_DIR/.claude/"
  cp -R "$CONFIG_REPO/.claude/rules" "$TARGET_DIR/.claude/" 2>/dev/null || true
  copy_if_missing "$CONFIG_REPO/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"

  if [[ ! -f "$TARGET_DIR/AGENTS.md" ]]; then
    cat > "$TARGET_DIR/AGENTS.md" <<EOF
# Agent Guidelines

Use the repository quality gates before committing changes.

## Repository

- Project: $PROJECT_NAME
- Type: $TYPE
EOF
  fi

  if [[ ! -e "$TARGET_DIR/CLAUDE.md" ]]; then
    ln -s AGENTS.md "$TARGET_DIR/CLAUDE.md"
  fi
}

create_package_json() {
  [[ -f "$TARGET_DIR/package.json" ]] && return 0

  cat > "$TARGET_DIR/package.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "format:check": "prettier --check .",
    "lint": "eslint .",
    "test": "echo \"No tests configured\"",
    "build": "echo \"No build configured\""
  },
  "devDependencies": {}
}
EOF
}

create_docs() {
  if [[ ! -f "$TARGET_DIR/README.md" ]]; then
    cat > "$TARGET_DIR/README.md" <<EOF
# $PROJECT_NAME

## Development

\`\`\`bash
npm install
npm run lint
npm test
\`\`\`

## License

$LICENSE_TYPE
EOF
  fi
}

initialize_git
create_git_files
create_claude_config
create_docs

if [[ "$WITH_DEVCONTAINER" == "true" ]]; then
  create_devcontainer
fi

if [[ "$MINIMAL" != "true" ]]; then
  create_package_json
  "$SCRIPT_DIR/setup-ci.sh" --target "$TARGET_DIR" --type "$TYPE"
fi

if [[ "$INSTALL_DEPS" == "true" && -f "$TARGET_DIR/package.json" ]]; then
  (cd "$TARGET_DIR" && npm install)
fi

if [[ "$WITH_PROTECTION" == "true" && -x "$SCRIPT_DIR/setup-team-protection.sh" ]]; then
  output::info "Branch protection can be applied with: script/setup-team-protection.sh"
fi

output::success "Repository setup completed: $TARGET_DIR"
