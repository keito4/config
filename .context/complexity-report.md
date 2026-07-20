# Code Complexity Report

Generated: Thu Jul 03 00:00:00 UTC 2026

## Summary

- Total Files: 37
- Overall Score: 20/20 (Poor)
- High Complexity (10-20): 12 files
- Critical Complexity (>20): 15 files

## Changes Since Previous Report (2026-06-05)

| File | Previous | Current | Delta | Issue |
| ---- | -------- | ------- | ----- | ----- |
| script/dependency-health-check.sh | 38 | 50 | +12 (悪化) ⚠️ | #886 |
| script/update-agents-md.sh | 51 | 52 | +1 (悪化) | #887 |
| script/import.sh | 19 | 20 | +1 (悪化) | — |
| script/export.sh | 14 | 15 | +1 (悪化) | — |
| script/repo-maintenance.sh | N/A | 71 | NEW 🚨 | #888 |
| script/setup-new-repo.sh | N/A | 25 | NEW | — |
| script/audit-references.sh | N/A | 23 | NEW | — |
| script/setup-ci.sh | N/A | 21 | NEW | — |
| script/check-trivyignore-review.sh | N/A | 15 | NEW | — |
| script/security-credential-scan.sh | 65 | N/A | 改善または削除 ✅ | — |
| script/install-skills.sh | 52 | N/A | 改善または削除 ✅ | — |
| script/setup-team-protection.sh | 48 | N/A | 改善または削除 ✅ | — |

## File Details

### CRITICAL (>20)

| File | Complexity | Lines | Nesting |
| ---- | ---------- | ----- | ------- |
| script/repo-maintenance.sh | 71 | 470 | 2 |
| script/container-health.sh | 57 | 324 | 1 |
| script/update-agents-md.sh | 52 | 305 | 3 |
| script/dependency-health-check.sh | 50 | 227 | 3 |
| script/code-complexity-check.sh | 45 | 282 | 2 |
| script/codespaces-secrets.sh | 43 | 422 | 2 |
| script/branch-cleanup.sh | 39 | 243 | 1 |
| script/update-actions.sh | 35 | 217 | 1 |
| script/pre-pr-checklist.sh | 27 | 215 | 1 |
| script/setup-new-repo.sh | 25 | 266 | 5 |
| script/audit-references.sh | 23 | 181 | 1 |
| script/changelog-generator.sh | 23 | 182 | 1 |
| script/test-coverage-trend.sh | 22 | 263 | 2 |
| script/setup-ci.sh | 21 | 245 | 1 |
| script/import.sh | 20 | 123 | 1 |

### HIGH (10-20)

| File | Complexity | Lines | Nesting |
| ---- | ---------- | ----- | ------- |
| script/install-claude-plugins.sh | 19 | 141 | 1 |
| script/check-trivyignore-review.sh | 15 | 52 | 1 |
| script/export.sh | 15 | 87 | 1 |
| script/brew-deps.sh | 14 | 209 | 2 |
| script/update-all.sh | 14 | 130 | 1 |
| script/create-codespace.sh | 12 | 233 | 1 |
| script/wait-ci-checks.sh | 12 | 94 | 1 |
| script/check-file-length.sh | 11 | 65 | 1 |
| script/version.sh | 11 | 132 | 1 |
| script/setup-claude.sh | 11 | 133 | 1 |
| script/update-claude-code.sh | 10 | 106 | 1 |
