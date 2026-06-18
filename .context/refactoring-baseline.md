# Refactoring Baseline

Issue: #812
Captured at: 2026-06-17
Baseline revision: `00f0fe92fb4da4dab1302d428d6209d08064e245`

## CI

Latest `main` CI run at capture time:

- Run: <https://github.com/keito4/config/actions/runs/27680039201>
- Title: `Merge pull request #839 from keito4/fix/workflow-template-validation-...`
- Status: `completed`
- Conclusion: `success`
- Started: `2026-06-17T09:42:10Z`
- Updated: `2026-06-17T09:43:25Z`
- Duration: 75 seconds

Recent `main` CI runs checked: 5 / 5 successful.

## Repository Size

Measured with tracked files only:

```bash
git ls-files | wc -l
git ls-files -z | xargs -0 wc -l | tail -1
```

- Tracked files: 379
- Total LOC: 69,933

## Coverage

Measured with:

```bash
npm run test:coverage
```

Jest coverage summary:

| Metric     | Value  |
| ---------- | ------ |
| Statements | 95.23% |
| Branches   | 100%   |
| Functions  | 100%   |
| Lines      | 94.73% |

Test result:

- Test suites: 17 passed / 17 total
- Tests: 549 passed / 549 total

## Reference Inventory

Reference inventory script added in this phase:

```bash
script/audit-references.sh
script/audit-references.sh --format tsv
```

The script scans tracked files under `script/` and `templates/`, includes `test/`
and documentation sources, and classifies references into:

- `code/ci`
- `test`
- `docs`

## Phase Issues

The phase issue set exists:

- #812: Phase 0 safety net and baseline
- #813: Phase 1 dead asset cleanup
- #814: Phase 2 documentation SSoT
- #815: Phase 3 template/entity sync
- #816: Phase 4 CI/CD workflow consolidation
- #817: Phase 5 scripts/hooks/commands DRY
- #818: Phase 6 test quality recovery
- #819: Phase 7 environment configuration cleanup
