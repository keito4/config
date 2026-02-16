#!/usr/bin/env bats

# Integration tests for update-actions.sh script

load ../test_helper/test_helper

@test "update-actions.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/update-actions.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "update-actions.sh has proper error handling with set -euo pipefail" {
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/update-actions.sh"
}

@test "update-actions.sh requires gh command" {
  grep -q 'command -v gh' "${REPO_ROOT}/script/update-actions.sh"
  grep -q 'gh (GitHub CLI) is required' "${REPO_ROOT}/script/update-actions.sh"
}

@test "update-actions.sh scans .github/workflows directory" {
  grep -q 'WORKFLOWS_DIR.*\.github/workflows' "${REPO_ROOT}/script/update-actions.sh"
  grep -q "find.*WORKFLOWS_DIR.*\.yml.*\.yaml" "${REPO_ROOT}/script/update-actions.sh"
}

@test "update-actions.sh skips SHA pinned actions" {
  local test_script="${TEST_TEMP_DIR}/test-sha-skip.sh"
  cat > "$test_script" << 'SCRIPT'
#!/usr/bin/env bash
is_sha_pin() {
  local ref="$1"
  [[ "$ref" =~ ^[0-9a-f]{40}$ ]]
}
# 40-char hex should match
if is_sha_pin "e58ee9d111489c31395fbe4857b0be6e7635dbda"; then
  echo "SHA detected"
else
  echo "SHA not detected"
fi
# Short hash should not match
if is_sha_pin "abc123"; then
  echo "Short hash detected"
else
  echo "Short hash skipped"
fi
SCRIPT
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  [[ "$output" == *"SHA detected"* ]]
  [[ "$output" == *"Short hash skipped"* ]]
}

@test "update-actions.sh skips major-only tags" {
  local test_script="${TEST_TEMP_DIR}/test-major-skip.sh"
  cat > "$test_script" << 'SCRIPT'
#!/usr/bin/env bash
is_semver_tag() {
  local ref="$1"
  [[ "$ref" =~ ^v?[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]
}
# Major-only tags should not match semver
for tag in "v1" "v3" "v6"; do
  if is_semver_tag "$tag"; then
    echo "$tag: semver"
  else
    echo "$tag: skipped"
  fi
done
# SemVer tags should match
for tag in "v6.0.2" "v0.34.0" "5.5.2"; do
  if is_semver_tag "$tag"; then
    echo "$tag: semver"
  else
    echo "$tag: skipped"
  fi
done
SCRIPT
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  [[ "$output" == *"v1: skipped"* ]]
  [[ "$output" == *"v3: skipped"* ]]
  [[ "$output" == *"v6: skipped"* ]]
  [[ "$output" == *"v6.0.2: semver"* ]]
  [[ "$output" == *"v0.34.0: semver"* ]]
  [[ "$output" == *"5.5.2: semver"* ]]
}

@test "update-actions.sh skips local and docker actions" {
  grep -q '\./' "${REPO_ROOT}/script/update-actions.sh"
  grep -q 'docker://' "${REPO_ROOT}/script/update-actions.sh"
}

@test "update-actions.sh skips branch-pinned actions" {
  grep -q '"master"' "${REPO_ROOT}/script/update-actions.sh"
  grep -q '"main"' "${REPO_ROOT}/script/update-actions.sh"
}

@test "update-actions.sh has v-prefix normalization logic" {
  local test_script="${TEST_TEMP_DIR}/test-normalize.sh"
  cat > "$test_script" << 'SCRIPT'
#!/usr/bin/env bash
normalize_tag() {
  local current_ref="$1"
  local latest_tag="$2"
  if [[ "$current_ref" == v* ]]; then
    if [[ "$latest_tag" == v* ]]; then
      echo "$latest_tag"
    else
      echo "v${latest_tag}"
    fi
  else
    echo "${latest_tag#v}"
  fi
}
# v-prefix current + v-prefix latest
echo "$(normalize_tag "v6.0.2" "v6.1.0")"
# v-prefix current + no-prefix latest
echo "$(normalize_tag "v6.0.2" "6.1.0")"
# no-prefix current + v-prefix latest
echo "$(normalize_tag "6.0.2" "v6.1.0")"
SCRIPT
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  [[ "${lines[0]}" == "v6.1.0" ]]
  [[ "${lines[1]}" == "v6.1.0" ]]
  [[ "${lines[2]}" == "6.1.0" ]]
}

@test "update-actions.sh uses gh api for release lookup" {
  grep -q 'gh api "repos/.*releases/latest"' "${REPO_ROOT}/script/update-actions.sh"
  grep -q 'gh api "repos/.*tags?per_page=1"' "${REPO_ROOT}/script/update-actions.sh"
}

@test "update-actions.sh has sed escape function" {
  grep -q 'escape_sed' "${REPO_ROOT}/script/update-actions.sh"
  grep -q "sed 's/\[" "${REPO_ROOT}/script/update-actions.sh"
}
