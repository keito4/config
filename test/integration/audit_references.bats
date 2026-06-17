#!/usr/bin/env bats

load ../test_helper/test_helper

@test "audit-references reports references as TSV with required categories" {
  run "$REPO_ROOT/script/audit-references.sh" --format tsv
  assert_success

  printf '%s\n' "$output" | grep -Fq $'test\tscript/check-image-version.sh\ttest/integration/core-scripts.bats'
  printf '%s\n' "$output" | grep -Fq $'test\ttemplates/workflows/claude-health-check.yml\ttest/template-workflows.test.js'
  printf '%s\n' "$output" | grep -Fq $'docs\tscript/check-image-version.sh\tscript/README.md'
}

@test "audit-references markdown includes zero code/test summary" {
  run "$REPO_ROOT/script/audit-references.sh"
  assert_success

  printf '%s\n' "$output" | grep -Fq "# Reference Inventory"
  printf '%s\n' "$output" | grep -Fq "## Zero Code/Test References"
}
