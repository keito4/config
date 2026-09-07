#!/usr/bin/env bats

# Integration tests for script/lib/claude_plugins.sh
#
# claude_plugins.sh backs install-claude-plugins.sh (Docker image plugin
# provisioning) but previously had no direct test coverage — only
# install_claude_plugins.bats existed, and it merely greps the caller
# script for keywords without exercising any library function.

load ../test_helper/test_helper

# claude_plugins.sh relies on log_info/log_success/log_warn from output.sh,
# exactly like the real callers (install-claude-plugins.sh) source both.
source_plugins_lib() {
  source "${REPO_ROOT}/script/lib/output.sh"
  source "${REPO_ROOT}/script/lib/claude_plugins.sh"
}

@test "claude_plugins.sh script exists" {
  # Unlike most script/lib/*.sh files, claude_plugins.sh is only ever
  # sourced (never executed directly), so it intentionally has no +x bit.
  assert_file_exists "${REPO_ROOT}/script/lib/claude_plugins.sh"
}

@test "claude_plugins.sh uses strict error handling" {
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/lib/claude_plugins.sh"
}

# ---------------------------------------------------------------------------
# plugins::_sync_directory
# ---------------------------------------------------------------------------

@test "plugins::_sync_directory copies files matching a pattern" {
  source_plugins_lib

  local src="${TEST_TEMP_DIR}/commands"
  local dst="${TEST_TEMP_DIR}/out/commands"
  mkdir -p "$src"
  echo "hello" > "${src}/a.md"
  echo "world" > "${src}/b.md"
  echo "skip" > "${src}/c.txt"

  plugins::_sync_directory "$src" "$dst" "コマンド" "*.md"

  [ -f "${dst}/a.md" ]
  [ -f "${dst}/b.md" ]
  [ ! -f "${dst}/c.txt" ]
}

@test "plugins::_sync_directory copies the whole directory when no pattern is given" {
  source_plugins_lib

  local src="${TEST_TEMP_DIR}/hooks"
  local dst="${TEST_TEMP_DIR}/out/hooks"
  mkdir -p "$src"
  echo "hook" > "${src}/hook.py"

  plugins::_sync_directory "$src" "$dst" "フック"

  [ -f "${dst}/hook.py" ]
}

@test "plugins::_sync_directory is a no-op when the source directory is missing" {
  source_plugins_lib

  local dst="${TEST_TEMP_DIR}/out/missing"

  run plugins::_sync_directory "${TEST_TEMP_DIR}/does-not-exist" "$dst" "エージェント"
  [ "$status" -eq 0 ]
  [ ! -d "$dst" ]
}

@test "plugins::_sync_directory is a no-op when the source directory is empty" {
  source_plugins_lib

  local src="${TEST_TEMP_DIR}/empty-src"
  local dst="${TEST_TEMP_DIR}/out/empty"
  mkdir -p "$src"

  run plugins::_sync_directory "$src" "$dst" "エージェント"
  [ "$status" -eq 0 ]
  [ ! -d "$dst" ]
}

@test "plugins::_sync_directory skips copying when the target is a symlink to the source" {
  source_plugins_lib

  local src="${TEST_TEMP_DIR}/commands"
  local dst="${TEST_TEMP_DIR}/out/commands"
  mkdir -p "$src" "${TEST_TEMP_DIR}/out"
  echo "hello" > "${src}/a.md"
  ln -s "$src" "$dst"

  run plugins::_sync_directory "$src" "$dst" "コマンド" "*.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"コピーに失敗"* ]]
  [[ "$output" == *"同期をスキップ"* ]]
  [ -f "${src}/a.md" ]
  grep -q "hello" "${src}/a.md"
}

@test "plugins::_sync_directory skips the whole-directory copy when the target is a symlink to the source" {
  source_plugins_lib

  local src="${TEST_TEMP_DIR}/hooks"
  local dst="${TEST_TEMP_DIR}/out/hooks"
  mkdir -p "$src" "${TEST_TEMP_DIR}/out"
  echo "hook" > "${src}/hook.py"
  ln -s "$src" "$dst"

  run plugins::_sync_directory "$src" "$dst" "フック"
  [ "$status" -eq 0 ]
  [[ "$output" != *"コピーに失敗"* ]]
  [[ "$output" == *"同期をスキップ"* ]]
  grep -q "hook" "${src}/hook.py"
}

# ---------------------------------------------------------------------------
# plugins::copy_config_files
# ---------------------------------------------------------------------------

@test "plugins::copy_config_files copies plugins.txt and expands {{HOME}} in the marketplace template" {
  source_plugins_lib

  local repo_plugins_dir="${TEST_TEMP_DIR}/repo-plugins"
  local plugins_dir="${TEST_TEMP_DIR}/out-plugins"
  mkdir -p "$repo_plugins_dir"
  echo "some-plugin@some-marketplace" > "${repo_plugins_dir}/plugins.txt"
  echo '{"marketplaces": ["{{HOME}}/.claude"]}' > "${repo_plugins_dir}/known_marketplaces.json.template"

  HOME="/home/testuser" plugins::copy_config_files "$repo_plugins_dir" "$plugins_dir"

  [ -f "${plugins_dir}/plugins.txt" ]
  grep -q "some-plugin@some-marketplace" "${plugins_dir}/plugins.txt"
  [ -f "${plugins_dir}/known_marketplaces.json.template" ]
  [ -f "${plugins_dir}/known_marketplaces.json" ]
  grep -q "/home/testuser/.claude" "${plugins_dir}/known_marketplaces.json"
  ! grep -q "{{HOME}}" "${plugins_dir}/known_marketplaces.json"
}

@test "plugins::copy_config_files warns but does not fail when plugins.txt is absent" {
  source_plugins_lib

  local repo_plugins_dir="${TEST_TEMP_DIR}/repo-plugins-empty"
  local plugins_dir="${TEST_TEMP_DIR}/out-plugins-empty"
  mkdir -p "$repo_plugins_dir"

  run plugins::copy_config_files "$repo_plugins_dir" "$plugins_dir"
  [ "$status" -eq 0 ]
  [ ! -f "${plugins_dir}/plugins.txt" ]
}

# ---------------------------------------------------------------------------
# plugins::_fix_shebang / plugins::_ensure_hookify_init
# ---------------------------------------------------------------------------

@test "plugins::_fix_shebang normalizes an existing python shebang" {
  source_plugins_lib

  local py_file="${TEST_TEMP_DIR}/hook.py"
  printf '#!/usr/bin/python\nprint("hi")\n' > "$py_file"

  plugins::_fix_shebang "$py_file"

  [ "$(head -n1 "$py_file")" = "#!/usr/bin/env python3" ]
  [ -x "$py_file" ]
}

@test "plugins::_fix_shebang prepends a shebang when none exists" {
  source_plugins_lib

  local py_file="${TEST_TEMP_DIR}/no_shebang.py"
  printf 'print("hi")\n' > "$py_file"

  plugins::_fix_shebang "$py_file"

  [ "$(head -n1 "$py_file")" = "#!/usr/bin/env python3" ]
  [ "$(sed -n '2p' "$py_file")" = 'print("hi")' ]
  [ -x "$py_file" ]
}

@test "plugins::_ensure_hookify_init creates __init__.py when missing" {
  source_plugins_lib

  local hookify_dir="${TEST_TEMP_DIR}/hookify"
  mkdir -p "$hookify_dir"

  plugins::_ensure_hookify_init "$hookify_dir"

  [ -f "${hookify_dir}/__init__.py" ]
  grep -q "Hookify plugin package" "${hookify_dir}/__init__.py"
}

@test "plugins::_ensure_hookify_init leaves an existing __init__.py untouched" {
  source_plugins_lib

  local hookify_dir="${TEST_TEMP_DIR}/hookify-existing"
  mkdir -p "$hookify_dir"
  echo "# custom init" > "${hookify_dir}/__init__.py"

  plugins::_ensure_hookify_init "$hookify_dir"

  [ "$(cat "${hookify_dir}/__init__.py")" = "# custom init" ]
}

@test "plugins::apply_hookify_patch is a no-op when no hookify plugin is installed" {
  source_plugins_lib

  local claude_dir="${TEST_TEMP_DIR}/claude-empty"
  mkdir -p "$claude_dir"

  run plugins::apply_hookify_patch "$claude_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"見つかりません"* ]]
}

@test "plugins::apply_hookify_patch patches shebangs and adds __init__.py when hookify is present" {
  source_plugins_lib

  # Note: plugins::apply_hookify_patch iterates a *non-local* `hookify_dir`
  # loop variable, so bash's dynamic scoping lets it clobber a same-named
  # local in the caller. Use a differently-named variable here to avoid that.
  local claude_dir="${TEST_TEMP_DIR}/claude-with-hookify"
  local installed_hookify_dir="${claude_dir}/plugins/marketplaces/claude-code-plugins/plugins/hookify"
  mkdir -p "${installed_hookify_dir}/hooks"
  printf 'from hookify.core import Matcher\n' > "${installed_hookify_dir}/hooks/handler.py"

  plugins::apply_hookify_patch "$claude_dir"

  [ "$(head -n1 "${installed_hookify_dir}/hooks/handler.py")" = "#!/usr/bin/env python3" ]
  [ -f "${installed_hookify_dir}/__init__.py" ]
}

# ---------------------------------------------------------------------------
# plugins::detect_and_add_marketplaces
# ---------------------------------------------------------------------------

@test "plugins::detect_and_add_marketplaces extracts marketplace names and adds known ones via the fallback list" {
  source_plugins_lib

  # Stub the claude CLI so no network call is made; record invocations instead.
  local calls_log="${TEST_TEMP_DIR}/claude_calls.log"
  claude() { echo "$*" >> "$calls_log"; }
  export -f claude

  local plugins_file="${TEST_TEMP_DIR}/plugins.txt"
  cat > "$plugins_file" <<'EOF'
# comment line, should be skipped
some-plugin@claude-code-plugins
EOF

  plugins::detect_and_add_marketplaces "$plugins_file" ""

  grep -q "marketplace add https://github.com/anthropics/claude-code.git" "$calls_log"
}

@test "plugins::detect_and_add_marketplaces warns on an unknown marketplace" {
  source_plugins_lib

  local calls_log="${TEST_TEMP_DIR}/claude_calls_unknown.log"
  claude() { echo "$*" >> "$calls_log"; }
  export -f claude

  local plugins_file="${TEST_TEMP_DIR}/plugins-unknown.txt"
  echo "some-plugin@totally-unknown-marketplace" > "$plugins_file"

  run plugins::detect_and_add_marketplaces "$plugins_file" ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"未知のマーケットプレイス"* ]]
  [ ! -f "$calls_log" ]
}

@test "plugins::detect_and_add_marketplaces fails when plugins.txt is missing" {
  source_plugins_lib

  run plugins::detect_and_add_marketplaces "${TEST_TEMP_DIR}/does-not-exist.txt" ""
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# plugins::sweep_orphan_marketplace_temp_dirs
#
# Deletes directories, so every guard is covered: only the two known temp
# naming schemes are eligible, referenced installLocations are preserved,
# recently touched clones (another process may still be cloning into them)
# are preserved, and an unreadable protection list aborts the sweep entirely.
# ---------------------------------------------------------------------------

# Builds a plugins dir with one stale orphan, one fresh orphan, one referenced
# temp dir and two names that must never match. Echoes the plugins dir.
make_sweep_fixture() {
  local plugins_dir="$1"
  local marketplaces="${plugins_dir}/marketplaces"
  mkdir -p "$marketplaces"

  mkdir -p "${marketplaces}/temp_1786586447348"          # old format, stale
  mkdir -p "${marketplaces}/temp_git_1788683458768_ab12cd" # new format, stale
  mkdir -p "${marketplaces}/temp_1799999999999"          # referenced
  mkdir -p "${marketplaces}/temp_1788000000000"          # fresh (just created)
  mkdir -p "${marketplaces}/temp_1234"                   # too few digits
  mkdir -p "${marketplaces}/temp_notatimestamp"          # not a timestamp
  mkdir -p "${marketplaces}/real-marketplace"

  touch -t 202001010000 "${marketplaces}/temp_1786586447348" \
    "${marketplaces}/temp_git_1788683458768_ab12cd" \
    "${marketplaces}/temp_1799999999999"

  cat > "${plugins_dir}/known_marketplaces.json" <<EOF
{
  "real": {
    "source": { "source": "git", "url": "https://example.com/real.git" },
    "installLocation": "${marketplaces}/real-marketplace",
    "lastUpdated": "2025-01-01T00:00:00.000Z"
  },
  "referenced-temp": {
    "source": { "source": "git", "url": "https://example.com/other.git" },
    "installLocation": "${marketplaces}/temp_1799999999999",
    "lastUpdated": "2025-01-01T00:00:00.000Z"
  }
}
EOF
}

@test "plugins::sweep_orphan_marketplace_temp_dirs removes stale orphans in both naming formats" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-basic"
  make_sweep_fixture "$plugins_dir"

  plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"

  [ ! -d "${plugins_dir}/marketplaces/temp_1786586447348" ]
  [ ! -d "${plugins_dir}/marketplaces/temp_git_1788683458768_ab12cd" ]
}

@test "plugins::sweep_orphan_marketplace_temp_dirs preserves referenced, fresh and non-matching directories" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-preserve"
  make_sweep_fixture "$plugins_dir"

  plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"

  # Referenced by known_marketplaces.json even though the name matches.
  [ -d "${plugins_dir}/marketplaces/temp_1799999999999" ]
  # Touched just now: another process may still be cloning into it.
  [ -d "${plugins_dir}/marketplaces/temp_1788000000000" ]
  # Names that must never be treated as sweep targets.
  [ -d "${plugins_dir}/marketplaces/temp_1234" ]
  [ -d "${plugins_dir}/marketplaces/temp_notatimestamp" ]
  [ -d "${plugins_dir}/marketplaces/real-marketplace" ]
}

@test "plugins::sweep_orphan_marketplace_temp_dirs dry mode reports without deleting" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-dry"
  make_sweep_fixture "$plugins_dir"

  CLAUDE_PLUGINS_TEMP_SWEEP=dry run plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [ -d "${plugins_dir}/marketplaces/temp_1786586447348" ]
}

@test "plugins::sweep_orphan_marketplace_temp_dirs off mode skips entirely" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-off"
  make_sweep_fixture "$plugins_dir"

  CLAUDE_PLUGINS_TEMP_SWEEP=off run plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"
  [ "$status" -eq 0 ]
  [ -d "${plugins_dir}/marketplaces/temp_1786586447348" ]
}

@test "plugins::sweep_orphan_marketplace_temp_dirs skips the sweep when known_marketplaces.json is unreadable" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-badjson"
  make_sweep_fixture "$plugins_dir"
  echo "this is not json" > "${plugins_dir}/known_marketplaces.json"

  run plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"スキップ"* ]]
  # Nothing may be deleted while the protection list cannot be resolved.
  [ -d "${plugins_dir}/marketplaces/temp_1786586447348" ]
  [ -d "${plugins_dir}/marketplaces/temp_git_1788683458768_ab12cd" ]
}

@test "plugins::sweep_orphan_marketplace_temp_dirs skips the sweep when jq is unavailable" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-nojq"
  make_sweep_fixture "$plugins_dir"

  # command -v must not find jq; shadow it with a function returning failure.
  command() {
    if [[ "$1" == "-v" && "$2" == "jq" ]]; then
      return 1
    fi
    builtin command "$@"
  }

  run plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"
  unset -f command

  [ "$status" -eq 0 ]
  [[ "$output" == *"jq"* ]]
  [ -d "${plugins_dir}/marketplaces/temp_1786586447348" ]
}

@test "plugins::sweep_orphan_marketplace_temp_dirs falls back to the default grace period on a non-numeric value" {
  source_plugins_lib

  local plugins_dir="${TEST_TEMP_DIR}/sweep-badage"
  make_sweep_fixture "$plugins_dir"

  CLAUDE_PLUGINS_TEMP_MIN_AGE_S=not-a-number run plugins::sweep_orphan_marketplace_temp_dirs "$plugins_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"数値ではありません"* ]]
  # The grace period must still protect the freshly created directory.
  [ -d "${plugins_dir}/marketplaces/temp_1788000000000" ]
}

@test "plugins::_mtime returns an epoch timestamp on this platform" {
  source_plugins_lib

  local probe="${TEST_TEMP_DIR}/mtime-probe"
  touch "$probe"

  run plugins::_mtime "$probe"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}
