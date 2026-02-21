#!/usr/bin/env bats

# Integration tests for coverage-report reusable workflow

load ../test_helper/test_helper

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export WORKFLOW="${REPO_ROOT}/.github/workflows/coverage-report.yml"
}

@test "coverage-report.yml exists and has valid YAML structure" {
  assert_file_exists "$WORKFLOW"

  grep -q "^name:" "$WORKFLOW"
  grep -q "^on:" "$WORKFLOW"
  grep -q "^jobs:" "$WORKFLOW"
}

@test "coverage-report.yml uses workflow_call trigger" {
  grep -q "workflow_call:" "$WORKFLOW"
}

@test "coverage-report.yml defines required inputs" {
  grep -q "format:" "$WORKFLOW"
  grep -q "report-path:" "$WORKFLOW"
  grep -q "artifact-name:" "$WORKFLOW"
}

@test "coverage-report.yml defines optional inputs with defaults" {
  grep -q "min-coverage-overall:" "$WORKFLOW"
  grep -q "min-coverage-changed-files:" "$WORKFLOW"
  grep -q "title:" "$WORKFLOW"
}

@test "coverage-report.yml declares permissions" {
  grep -q "permissions:" "$WORKFLOW"
  grep -q "pull-requests: write" "$WORKFLOW"
  grep -q "contents: read" "$WORKFLOW"
}

@test "coverage-report.yml has jacoco report job" {
  grep -q "report-jacoco:" "$WORKFLOW"
  grep -q "madrapps/jacoco-report@v" "$WORKFLOW"
}

@test "coverage-report.yml passes GITHUB_TOKEN to jacoco action" {
  grep -q 'token:.*secrets.GITHUB_TOKEN' "$WORKFLOW"
}

@test "coverage-report.yml has jest report job" {
  grep -q "report-jest:" "$WORKFLOW"
  grep -q "actions/github-script@v" "$WORKFLOW"
}

@test "coverage-report.yml uses pinned action versions" {
  ! grep -q "uses:.*@main" "$WORKFLOW"
  ! grep -q "uses:.*@master" "$WORKFLOW"
}

@test "coverage-report.yml downloads artifacts before reporting" {
  grep -q "actions/download-artifact@v" "$WORKFLOW"
}

@test "coverage-report.yml uses env variables for script inputs" {
  grep -q "REPORT_PATH:" "$WORKFLOW"
  grep -q "COMMENT_TITLE:" "$WORKFLOW"
  grep -q "process.env.REPORT_PATH" "$WORKFLOW"
  grep -q "process.env.COMMENT_TITLE" "$WORKFLOW"
}
