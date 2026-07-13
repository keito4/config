#!/usr/bin/env bats

load ../test_helper/test_helper

@test "export.sh --check creates managed target directories" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh is not installed"
  fi
  local target="${TEST_TEMP_DIR}/export-target"

  run env REPO_PATH="$target" zsh "$REPO_ROOT/script/export.sh" --check

  [ "$status" -eq 0 ]
  [[ "$output" == *"Export target ready"* ]]
  [ -d "$target/git" ]
  [ -d "$target/npm" ]
  [ -d "$target/.claude" ]
  [ -d "$target/.codex" ]
}

@test "export.sh filters gitconfig during execution" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh is not installed"
  fi
  local target="${TEST_TEMP_DIR}/export-run"
  local home="${TEST_TEMP_DIR}/home"
  local bin="${TEST_TEMP_DIR}/bin"
  mkdir -p "$home" "$bin"

  cat > "$home/.gitconfig" <<'EOF'
[user]
	name = Jane Doe
	email = jane@example.com
[core]
	editor = vim
EOF

  cat > "$bin/npm" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  echo '{"dependencies":{}}'
fi
EOF
  chmod +x "$bin/npm"

  run env HOME="$home" REPO_PATH="$target" REMOTE_CONTAINERS=1 PATH="$bin:$PATH" zsh "$REPO_ROOT/script/export.sh"

  [ "$status" -eq 0 ]
  grep -q "# name =" "$target/git/gitconfig"
  grep -q "# email =" "$target/git/gitconfig"
  grep -q "editor = vim" "$target/git/gitconfig"
  grep -q '"dependencies"' "$target/npm/global.json"
}

@test "import.sh --check validates source without bootstrapping tools" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh is not installed"
  fi
  local source_repo="${TEST_TEMP_DIR}/import-source"
  local minimal_path="/usr/bin:/bin"
  mkdir -p "$source_repo/git" "$source_repo/npm" "$source_repo/.claude"
  if PATH="$minimal_path" command -v brew >/dev/null 2>&1; then
    skip "brew is available in the minimal PATH"
  fi

  run env REPO_PATH="$source_repo" PATH="$minimal_path" zsh "$REPO_ROOT/script/import.sh" --check

  [ "$status" -eq 0 ]
  [[ "$output" == *"Import source checked"* ]]
}

@test "credentials.sh list runs without contacting provider" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh is not installed"
  fi
  run zsh "$REPO_ROOT/script/credentials.sh" list

  [ "$status" -eq 0 ]
  [[ "$output" == *"Available credential templates"* ]]
}

@test "credentials.sh rejects unsupported provider" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh is not installed"
  fi
  run env CREDENTIAL_PROVIDER=missing zsh "$REPO_ROOT/script/credentials.sh" list

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported credential provider"* ]]
}
