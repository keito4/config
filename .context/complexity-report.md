# Code Complexity Report

Generated: Thu Jun 05 00:00:00 UTC 2026

## Summary

- Total Files: 25
- Average Complexity: 22/20 (Poor)
- High Complexity (10-20): 12 files
- Critical Complexity (>20): 13 files

## Changes Since Previous Report (2026-05-22)

| File | Previous | Current | Delta |
| ---- | -------- | ------- | ----- |
| script/security-credential-scan.sh | 48 | 65 | +17 (worsened) ⚠️ Issue #798 |
| script/setup-team-protection.sh | 45 | 48 | +3 (worsened) ⚠️ Issue #762 |
| script/wait-ci-checks.sh | N/A | 12 | NEW |

## File Details

### CRITICAL (>20)

| File | Complexity | Lines | Nesting |
| ---- | ---------- | ----- | ------- |
| script/security-credential-scan.sh | 65 | 480 | 2 |
| script/container-health.sh | 57 | 324 | 1 |
| script/install-skills.sh | 52 | 282 | 1 |
| script/update-agents-md.sh | 51 | 293 | 3 |
| script/setup-team-protection.sh | 48 | 551 | 3 |
| script/code-complexity-check.sh | 45 | 282 | 2 |
| script/codespaces-secrets.sh | 43 | 421 | 2 |
| script/branch-cleanup.sh | 39 | 243 | 1 |
| script/dependency-health-check.sh | 38 | 188 | 3 |
| script/update-actions.sh | 35 | 217 | 1 |
| script/pre-pr-checklist.sh | 27 | 215 | 1 |
| script/changelog-generator.sh | 23 | 182 | 1 |
| script/test-coverage-trend.sh | 22 | 263 | 2 |

### HIGH (10-20)

| File | Complexity | Lines | Nesting |
| ---- | ---------- | ----- | ------- |
| script/install-claude-plugins.sh | 19 | 141 | 0 |
| script/import.sh | 19 | 117 | 1 |
| script/update-all.sh | 14 | 130 | 1 |
| script/brew-deps.sh | 14 | 208 | 2 |
| script/export.sh | 14 | 81 | 1 |
| script/create-codespace.sh | 12 | 233 | 1 |
| script/wait-ci-checks.sh | 12 | 94 | 1 |
| script/check-file-length.sh | 11 | 65 | 1 |
| script/version.sh | 11 | 132 | 1 |
| script/setup-claude.sh | 11 | 133 | 1 |
| script/fix-container-plugins.sh | 10 | 78 | 0 |
| script/update-claude-code.sh | 10 | 106 | 1 |
