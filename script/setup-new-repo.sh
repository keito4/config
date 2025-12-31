#!/usr/bin/env bash
# Setup New Repository - Bootstrap new repo with config

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Get config repository path
CONFIG_REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Options
MINIMAL=false
NO_DEVCONTAINER=false
LICENSE="MIT"
NO_INSTALL=false
INTERACTIVE=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --minimal)
      MINIMAL=true
      shift
      ;;
    --no-devcontainer)
      NO_DEVCONTAINER=true
      shift
      ;;
    --license)
      LICENSE="$2"
      shift 2
      ;;
    --no-install)
      NO_INSTALL=true
      shift
      ;;
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    --help)
      echo "Usage: $0 TARGET_DIR [OPTIONS]"
      echo ""
      echo "Arguments:"
      echo "  TARGET_DIR           Path to new repository"
      echo ""
      echo "Options:"
      echo "  --minimal            Minimal setup (no GitHub Actions)"
      echo "  --no-devcontainer    Skip DevContainer setup"
      echo "  --license TYPE       License type (default: MIT)"
      echo "  --no-install         Skip npm install"
      echo "  --interactive        Prompt for each step"
      echo "  --help               Show this help message"
      exit 0
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
      else
        echo "Unknown option: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo "Error: TARGET_DIR required"
  echo "Usage: $0 TARGET_DIR [OPTIONS]"
  exit 1
fi

echo -e "${BLUE}🚀 Setting up new repository${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "📁 Target: ${GREEN}$TARGET_DIR${NC}"
echo -e "📋 Configuration source: ${BLUE}$CONFIG_REPO${NC}"
echo ""

# Create directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

cd "$TARGET_DIR"
TARGET_ABS=$(pwd)

# Step 1: Initialize Git
echo -e "${BLUE}✅ Step 1: Initialize Git repository${NC}"
if [ ! -d ".git" ]; then
  git init > /dev/null 2>&1
  echo -e "  ${GREEN}✓${NC} Git repository initialized"
else
  echo "  • Git repository already exists"
fi
echo ""

# Step 2: DevContainer (unless skipped)
if [ "$NO_DEVCONTAINER" = false ]; then
  echo -e "${BLUE}✅ Step 2: Copy DevContainer configuration${NC}"

  # Copy .devcontainer
  if [ -d "$CONFIG_REPO/.devcontainer" ]; then
    cp -r "$CONFIG_REPO/.devcontainer" .
    echo -e "  ${GREEN}✓${NC} Copied .devcontainer/"
  fi

  # Copy .vscode
  if [ -d "$CONFIG_REPO/.vscode" ]; then
    cp -r "$CONFIG_REPO/.vscode" .
    echo -e "  ${GREEN}✓${NC} Copied .vscode/"
  fi

  echo ""
fi

# Step 3: Git configuration
echo -e "${BLUE}✅ Step 3: Setup Git configuration${NC}"

# Commitlint
if [ -f "$CONFIG_REPO/git/commitlint.config.js" ]; then
  cp "$CONFIG_REPO/git/commitlint.config.js" commitlint.config.js
  echo -e "  ${GREEN}✓${NC} Copied commitlint.config.js"
fi

# Gitignore
cat > .gitignore <<'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
*.lcov

# Production
build/
dist/
*.tgz

# Misc
.DS_Store
.env
.env.local
.env.*.local

# Logs
logs
*.log
npm-debug.log*

# IDE
.idea/
*.swp
*.swo
*~
.vscode/settings.local.json

# OS
Thumbs.db
EOF

echo -e "  ${GREEN}✓${NC} Created .gitignore"
echo ""

# Step 4: GitHub Actions (unless minimal)
if [ "$MINIMAL" = false ]; then
  echo -e "${BLUE}✅ Step 4: Copy GitHub Actions${NC}"

  # Copy workflows
  if [ -d "$CONFIG_REPO/.github/workflows" ]; then
    mkdir -p .github/workflows
    cp "$CONFIG_REPO/.github/workflows/ci.yml" .github/workflows/ 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Copied CI workflow"
  fi

  # Copy issue templates
  if [ -d "$CONFIG_REPO/.github/ISSUE_TEMPLATE" ]; then
    mkdir -p .github/ISSUE_TEMPLATE
    cp -r "$CONFIG_REPO/.github/ISSUE_TEMPLATE/"* .github/ISSUE_TEMPLATE/ 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Copied issue templates"
  fi

  # Copy PR template
  if [ -f "$CONFIG_REPO/.github/PULL_REQUEST_TEMPLATE.md" ]; then
    cp "$CONFIG_REPO/.github/PULL_REQUEST_TEMPLATE.md" .github/
    echo -e "  ${GREEN}✓${NC} Copied PR template"
  fi

  echo ""
fi

# Step 5: Development tools
echo -e "${BLUE}✅ Step 5: Setup development tools${NC}"

# Package.json
cat > package.json <<'EOF'
{
  "name": "new-project",
  "version": "1.0.0",
  "description": "New project bootstrapped from config repository",
  "scripts": {
    "lint": "eslint . --ext .js",
    "lint:fix": "npm run lint -- --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "prepare": "husky"
  },
  "devDependencies": {
    "@commitlint/cli": "^18.0.0",
    "@commitlint/config-conventional": "^18.0.0",
    "eslint": "^8.0.0",
    "husky": "^9.0.0",
    "jest": "^29.0.0",
    "prettier": "^3.0.0"
  }
}
EOF

echo -e "  ${GREEN}✓${NC} Created package.json"

# ESLint
if [ -f "$CONFIG_REPO/eslint.config.mjs" ]; then
  cp "$CONFIG_REPO/eslint.config.mjs" .
  echo -e "  ${GREEN}✓${NC} Copied ESLint config"
fi

# Prettier
if [ -f "$CONFIG_REPO/.prettierrc" ]; then
  cp "$CONFIG_REPO/.prettierrc" .
  echo -e "  ${GREEN}✓${NC} Copied Prettier config"
fi

# Jest
if [ -f "$CONFIG_REPO/jest.config.js" ]; then
  cp "$CONFIG_REPO/jest.config.js" .
  echo -e "  ${GREEN}✓${NC} Copied Jest config"
fi

echo ""

# Step 6: Documentation
echo -e "${BLUE}✅ Step 6: Create documentation${NC}"

# README.md
cat > README.md <<EOF
# $(basename "$TARGET_ABS")

<!-- TODO: Add project description -->

## Features

<!-- TODO: List key features -->

## Getting Started

### Prerequisites

- Node.js 22+
- npm or pnpm

### Installation

\`\`\`bash
npm install
\`\`\`

### Development

\`\`\`bash
npm run dev
\`\`\`

### Testing

\`\`\`bash
npm test
npm run test:coverage
\`\`\`

## Contributing

Please read [CLAUDE.md](./CLAUDE.md) for development guidelines.

## License

This project is licensed under the $LICENSE License.
EOF

echo -e "  ${GREEN}✓${NC} Created README.md"

# CLAUDE.md (simplified version)
if [ -f "$CONFIG_REPO/.claude/CLAUDE.md" ]; then
  cp "$CONFIG_REPO/.claude/CLAUDE.md" CLAUDE.md
  echo -e "  ${GREEN}✓${NC} Created CLAUDE.md"
fi

# SECURITY.md
cat > SECURITY.md <<'EOF'
# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities to: security@example.com

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Security Best Practices

- Keep dependencies up-to-date
- Run security audits regularly (`npm audit`)
- Follow principle of least privilege
- Never commit secrets or credentials
EOF

echo -e "  ${GREEN}✓${NC} Created SECURITY.md"

echo ""

# Step 7: Install dependencies
if [ "$NO_INSTALL" = false ]; then
  echo -e "${BLUE}✅ Step 7: Install dependencies${NC}"
  if npm install > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} npm install completed"

    if npx husky init > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Husky hooks installed"
    fi
  else
    echo -e "  ${YELLOW}⚠${NC} npm install failed (run manually)"
  fi
  echo ""
fi

# Summary
echo -e "${GREEN}✨ Repository setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_ABS"
echo "  2. Update README.md with project details"
echo "  3. Update package.json (name, description, etc.)"
echo "  4. Create first commit: git commit -m \"chore: initial setup\""
if command -v gh > /dev/null 2>&1; then
  echo "  5. Create GitHub repo: gh repo create"
  echo "  6. Push to GitHub: git push -u origin main"
fi
