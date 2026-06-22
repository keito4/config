#!/usr/bin/env bash
# Setup or report CI/CD workflow configuration for a repository.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"
# shellcheck source=script/lib/project-detect.sh
source "$SCRIPT_DIR/lib/project-detect.sh"

TYPE=""
LEVEL="standard"
DRY_RUN=false
TARGET_DIR="${TARGET_DIR:-$(pwd)}"

usage() {
  cat <<'EOF'
Usage: script/setup-ci.sh [--type nextjs|nodejs|terraform|monorepo] [--level minimal|standard|comprehensive] [--dry-run] [--target DIR]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="${2:?--type requires a value}"
      shift 2
      ;;
    --level)
      LEVEL="${2:?--level requires a value}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --target)
      TARGET_DIR="${2:?--target requires a value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      output::fatal "Unknown argument: $1"
      ;;
  esac
done

case "$LEVEL" in
  minimal|standard|comprehensive) ;;
  *) output::fatal "Unsupported CI level: $LEVEL" ;;
esac

mkdir -p "$TARGET_DIR"
TYPE="${TYPE:-$(project::detect_type "$TARGET_DIR")}"
PACKAGE_MANAGER="$(project::detect_package_manager "$TARGET_DIR")"

package_install_command() {
  case "$PACKAGE_MANAGER" in
    pnpm) echo "pnpm install --frozen-lockfile" ;;
    yarn) echo "yarn install --frozen-lockfile" ;;
    npm) echo "npm ci" ;;
    *) echo "npm ci" ;;
  esac
}

package_run_command() {
  local script="${1:?Script required}"

  case "$PACKAGE_MANAGER" in
    pnpm) echo "pnpm run --if-present $script" ;;
    yarn) echo "yarn run $script || true" ;;
    npm) echo "npm run $script --if-present" ;;
    *) echo "npm run $script --if-present" ;;
  esac
}

workflow_exists() {
  [[ -f "$TARGET_DIR/.github/workflows/ci.yml" || -f "$TARGET_DIR/.github/workflows/ci.yaml" ]]
}

print_detection() {
  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $TYPE
Package Manager: $PACKAGE_MANAGER
CI Level: $LEVEL
Target: $TARGET_DIR
Workflow exists: $(workflow_exists && echo "yes" || echo "no")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

write_node_workflow() {
  local workflow="$TARGET_DIR/.github/workflows/ci.yml"
  local install_cmd
  install_cmd="$(package_install_command)"
  local format_cmd lint_cmd test_cmd build_cmd typecheck_cmd
  format_cmd="$(package_run_command "format:check")"
  lint_cmd="$(package_run_command "lint")"
  test_cmd="$(package_run_command "test")"
  build_cmd="$(package_run_command "build")"
  typecheck_cmd="$(package_run_command "typecheck")"

  cat > "$workflow" <<EOF
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: '$PACKAGE_MANAGER'
      - run: $install_cmd
      - name: Format Check
        run: $format_cmd
      - name: Lint
        run: $lint_cmd
      - name: Type Check
        run: $typecheck_cmd

  test:
    runs-on: ubuntu-latest
    needs: quality
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: '$PACKAGE_MANAGER'
      - run: $install_cmd
      - name: Test
        run: $test_cmd

  build:
    runs-on: ubuntu-latest
    needs: [quality, test]
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: '$PACKAGE_MANAGER'
      - run: $install_cmd
      - name: Build
        run: $build_cmd
EOF

  if [[ "$LEVEL" != "minimal" ]]; then
    cat >> "$workflow" <<EOF

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: '$PACKAGE_MANAGER'
      - run: $install_cmd
      - name: Security Audit
        run: npm audit --audit-level=high
        continue-on-error: true
EOF
  fi
}

write_terraform_workflow() {
  local workflow="$TARGET_DIR/.github/workflows/ci.yml"

  cat > "$workflow" <<'EOF'
name: Terraform CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: hashicorp/setup-terraform@v4
      - run: terraform fmt -check -recursive
      - run: terraform init -backend=false
      - run: terraform validate
EOF
}

copy_supporting_templates() {
  mkdir -p "$TARGET_DIR/.github/workflows" "$TARGET_DIR/.github"

  local template
  for template in dependabot-auto-merge label-sync quality-gate-fallback; do
    local source="$CONFIG_REPO/templates/workflows/$template.yml"
    local target="$TARGET_DIR/.github/workflows/$template.yml"
    if [[ -f "$source" && ! -f "$target" ]]; then
      cp "$source" "$target"
    fi
  done

  if [[ -f "$CONFIG_REPO/templates/github/pull_request_template.md" && ! -f "$TARGET_DIR/.github/pull_request_template.md" ]]; then
    cp "$CONFIG_REPO/templates/github/pull_request_template.md" "$TARGET_DIR/.github/pull_request_template.md"
  fi
}

print_detection

if [[ "$DRY_RUN" == "true" ]]; then
  output::info "Dry run only. No files written."
  exit 0
fi

copy_supporting_templates
case "$TYPE" in
  terraform) write_terraform_workflow ;;
  nextjs|nodejs|npm-library|monorepo|spa-react|raycast|unknown) write_node_workflow ;;
  *) output::warning "Unsupported project type '$TYPE'; writing Node.js CI fallback"; write_node_workflow ;;
esac

output::success "CI workflow setup completed"
