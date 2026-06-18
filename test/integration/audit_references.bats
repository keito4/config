#!/usr/bin/env bats

load ../test_helper/test_helper

assert_tsv_row() {
  local expected="$1"$'\t'"$2"$'\t'"$3"
  local line

  while IFS= read -r line; do
    [ "$line" = "$expected" ] && return 0
  done <<< "$output"

  echo "missing TSV row: $expected" >&2
  return 1
}

@test "audit-references reports references as TSV with required categories" {
  run "$REPO_ROOT/script/audit-references.sh" --format tsv
  assert_success

  assert_tsv_row docs script/README.md docs/README.md
  assert_tsv_row test script/audit-references.sh test/integration/core-scripts.bats
  assert_tsv_row code/ci templates/workflows/claude.yml templates/workflows/claude-health-check.yml
  assert_tsv_row test templates/workflows/claude-health-check.yml test/template-workflows.test.js
}

@test "audit-references markdown includes zero code/test summary" {
  run "$REPO_ROOT/script/audit-references.sh"
  assert_success

  printf '%s\n' "$output" | grep -Fq "# Reference Inventory"
  printf '%s\n' "$output" | grep -Fq "## Zero Code/Test References"
}
