---
paths:
  - '**/*'
---

# Development Standards

## Test-Driven Development (TDD)

- Red -> Green -> Refactor
- 70%+ line coverage required, critical paths 100%
- Test hierarchy: Unit / Component / E2E

## Static Quality Gates

- Lint errors = CI fail
- Formatting auto-fix disabled = CI fail
- Critical SAST/dependency vulnerabilities = CI fail
- Prohibited licenses = CI fail

## AI Prompt Design

| Scenario       | Required                                        | Prohibited                      |
| -------------- | ----------------------------------------------- | ------------------------------- |
| Requirements   | List assumptions, constraints, success criteria | Jump to code generation         |
| Implementation | Write tests first                               | Tests + implementation together |
| Bug report     | Repro steps -> root cause -> fix proposal       | Patch without confirmed cause   |

## Definition of Ready / Done

- **Ready**: Acceptance criteria documented, dependency tickets resolved
- **Done**: All quality gates pass, docs updated (README / API spec / ADR), monitoring stable, release notes written
