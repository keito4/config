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

# CI ランナー。GitHub ホストランナーが枯渇した OYKOT-jp では 2026-08-30 以降
# ジョブが0ステップのまま即失敗するようになり、8/31 に全リポジトリを Ubicloud へ移行した。
# 新規リポジトリだけ ubuntu-latest に戻るのを防ぐため、導入済みの owner では Ubicloud を既定にする。
# Ubicloud 未導入の owner を巻き込んで壊さないよう、既定は owner ごとに切り替える。
detect_ci_runner() {
  local owner dir

  owner="$(git -C "$TARGET_DIR" remote get-url origin 2>/dev/null |
    sed -E 's#\.git$##; s#.*[:/]([^/]+)/[^/]+$#\1#')"

  # setup-new-repo.sh は git init だけで origin を張らないままここへ来るため、
  # remote からは owner を引けない。新規リポジトリこそ本来の対象なので、
  # <...>/github.com/<owner>/<repo> の配置規約に従って親ディレクトリからも拾う。
  if [[ -z "$owner" ]]; then
    if ! dir="$(cd "$TARGET_DIR" 2>/dev/null && pwd)"; then
      dir="$TARGET_DIR"
    fi
    owner="$(basename "$(dirname "$dir")")"
  fi

  # GitHub の owner は大文字小文字を区別しないので、表記揺れで
  # 取りこぼさないよう小文字へ寄せて比較する
  owner="$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')"

  case "$owner" in
    oykot-jp|elu-co-jp) echo "ubicloud-standard-2" ;;
    *) echo "ubuntu-latest" ;;
  esac
}

CI_RUNNER="${CI_RUNNER:-$(detect_ci_runner)}"

# テンプレート正本は ubuntu-latest のまま置く（配布先の keito4/* が Ubicloud 未導入のため）。
# 配置した時点で、対象リポジトリのランナーへ書き換える。
apply_ci_runner() {
  local file="${1:?File required}"

  if [[ "$CI_RUNNER" == "ubuntu-latest" ]]; then
    return 0
  fi

  # 置換文字列に & \ # が入ると sed の結果が壊れるため、埋め込む前に無害化する
  local replacement
  replacement="$(printf '%s' "$CI_RUNNER" | sed -e 's#[\\&#]#\\&#g')"

  sed -i.bak -E "s#^([[:space:]]*runs-on:)[[:space:]]*ubuntu-latest[[:space:]]*\$#\1 ${replacement}#" "$file"
  rm -f "$file.bak"
}

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
CI Runner: $CI_RUNNER
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
    runs-on: ${CI_RUNNER}
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
    runs-on: ${CI_RUNNER}
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
    runs-on: ${CI_RUNNER}
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
    runs-on: ${CI_RUNNER}
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

  cat > "$workflow" <<EOF
name: Terraform CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  terraform:
    runs-on: ${CI_RUNNER}
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
  for template in dependabot-auto-merge label-sync quality-gate-fallback pr-size-gate; do
    local source="$CONFIG_REPO/templates/workflows/$template.yml"
    local target="$TARGET_DIR/.github/workflows/$template.yml"
    if [[ -f "$source" && ! -f "$target" ]]; then
      cp "$source" "$target"
      apply_ci_runner "$target"
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
