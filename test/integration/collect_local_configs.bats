#!/usr/bin/env bats

# Integration tests for script/agent/collect-local-configs.sh
#
# The script only inventories file paths/size/mtime (never contents), so it is
# safe to run against a throwaway --root directory populated with fixture
# filenames that exercise classify_path()'s category matching.

load ../test_helper/test_helper

SCRIPT="script/agent/collect-local-configs.sh"

find_row() {
  local path="$1"
  local line

  while IFS= read -r line; do
    [[ "$line" == *$'\t'"$path" ]] && printf '%s\n' "$line" && return 0
  done <<< "$output_tsv"

  return 1
}

assert_category() {
  local path="$1"
  local expected_category="$2"
  local row

  row="$(find_row "$path")" || {
    echo "missing row for path: $path" >&2
    echo "$output_tsv" >&2
    return 1
  }

  local category="${row%%$'\t'*}"
  [ "$category" = "$expected_category" ] || {
    echo "expected category '$expected_category' for $path, got '$category'" >&2
    return 1
  }
}

@test "collect-local-configs.sh script exists and is executable" {
  assert_file_exists "${REPO_ROOT}/${SCRIPT}"
  [ -x "${REPO_ROOT}/${SCRIPT}" ]
}

@test "collect-local-configs.sh --help exits 0 without scanning" {
  run "${REPO_ROOT}/${SCRIPT}" --help
  assert_success
  assert_output --partial "Usage: script/agent/collect-local-configs.sh"
}

@test "collect-local-configs.sh classifies fixture files by category" {
  local fixture_dir="${TEST_TEMP_DIR}/fixture-root"
  local out="${TEST_TEMP_DIR}/report.tsv"
  mkdir -p "$fixture_dir"

  : > "${fixture_dir}/config.local.json"
  : > "${fixture_dir}/settings.local.yaml"
  : > "${fixture_dir}/.env.local"
  : > "${fixture_dir}/secrets.json"
  : > "${fixture_dir}/api_token.json"
  : > "${fixture_dir}/README.md"

  run "${REPO_ROOT}/${SCRIPT}" --root "$fixture_dir" --output "$out"
  assert_success
  [ -f "$out" ]

  output_tsv="$(tail -n +2 "$out")"

  # Exactly one TSV row per matched fixture file. A regression in file_size()
  # or file_mtime() (e.g. a stat(1) format string that fails over incorrectly
  # between GNU and BSD variants) can make stat print multi-line diagnostic
  # output into a field instead of failing cleanly, which silently corrupts
  # the row count here.
  local row_count
  row_count="$(printf '%s\n' "$output_tsv" | grep -c .)"
  [ "$row_count" -eq 5 ]

  assert_category "${fixture_dir}/config.local.json" "local-json"
  assert_category "${fixture_dir}/settings.local.yaml" "local-yaml"
  assert_category "${fixture_dir}/.env.local" "local-env"
  assert_category "${fixture_dir}/secrets.json" "auth-or-secret-candidate"
  assert_category "${fixture_dir}/api_token.json" "auth-or-secret-candidate"

  local bytes_field
  bytes_field="$(find_row "${fixture_dir}/config.local.json")"
  bytes_field="${bytes_field#*$'\t'}"
  bytes_field="${bytes_field%%$'\t'*}"
  [[ "$bytes_field" =~ ^[0-9]+$ ]]

  # README.md does not match any local/secret pattern, so the scan should not
  # even list it (the find -name filter excludes it up front).
  ! find_row "${fixture_dir}/README.md"
}

@test "collect-local-configs.sh rejects unknown arguments" {
  run "${REPO_ROOT}/${SCRIPT}" --bogus-flag
  assert_failure
}
