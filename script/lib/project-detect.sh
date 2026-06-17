#!/usr/bin/env bash
# Shared project detection helpers for setup scripts.

set -euo pipefail

project::has_file_matching() {
  local dir="${1:?Directory required}"
  local pattern="${2:?Pattern required}"

  find "$dir" -maxdepth 1 -name "$pattern" -print -quit | grep -q .
}

project::has_package_dependency() {
  local dir="${1:?Directory required}"
  local dependency="${2:?Dependency required}"
  local package_json="$dir/package.json"

  [[ -f "$package_json" ]] || return 1

  node -e '
const fs = require("fs");
const packagePath = process.argv[1];
const dependency = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(packagePath, "utf8"));
const sections = ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"];
process.exit(sections.some((section) => pkg[section] && pkg[section][dependency]) ? 0 : 1);
' "$package_json" "$dependency"
}

project::has_package_field() {
  local dir="${1:?Directory required}"
  local field="${2:?Field required}"
  local package_json="$dir/package.json"

  [[ -f "$package_json" ]] || return 1

  node -e '
const fs = require("fs");
const packagePath = process.argv[1];
const field = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(packagePath, "utf8"));
process.exit(Object.prototype.hasOwnProperty.call(pkg, field) ? 0 : 1);
' "$package_json" "$field"
}

project::detect_package_manager() {
  local dir="${1:-.}"

  if [[ -f "$dir/pnpm-lock.yaml" || -f "$dir/pnpm-workspace.yaml" ]]; then
    echo "pnpm"
  elif [[ -f "$dir/yarn.lock" ]]; then
    echo "yarn"
  elif [[ -f "$dir/package-lock.json" || -f "$dir/package.json" ]]; then
    echo "npm"
  else
    echo "unknown"
  fi
}

project::detect_type() {
  local dir="${1:-.}"

  if project::has_file_matching "$dir" "next.config.*"; then
    echo "nextjs"
  elif [[ -f "$dir/pubspec.yaml" ]]; then
    echo "flutter"
  elif project::has_file_matching "$dir" "build.gradle*" && [[ -d "$dir/app/src/main" ]]; then
    echo "android"
  elif [[ -f "$dir/vite.config.ts" || -f "$dir/vite.config.js" ]] && project::has_package_dependency "$dir" "@vitejs/plugin-react"; then
    echo "spa-react"
  elif project::has_package_dependency "$dir" "@raycast/api"; then
    echo "raycast"
  elif [[ -f "$dir/pnpm-workspace.yaml" || -f "$dir/lerna.json" ]]; then
    echo "monorepo"
  elif project::has_file_matching "$dir" "*.tf"; then
    echo "terraform"
  elif project::has_package_field "$dir" "bin" || project::has_package_field "$dir" "exports"; then
    echo "npm-library"
  elif [[ -f "$dir/package.json" ]]; then
    echo "nodejs"
  else
    echo "unknown"
  fi
}

project::name() {
  local dir="${1:-.}"
  basename "$(cd "$dir" && pwd)"
}
