# Issue 817 Refactoring Evidence

## Hook Line Count

| File | Before | After |
| --- | ---: | ---: |
| `.claude/hooks/common.py` | 135 | 318 |
| `.claude/hooks/post_git_push_ci.py` | 197 | 111 |
| `.claude/hooks/post_pr_ci_watch.py` | 126 | 61 |
| `.claude/hooks/post_pr_ai_review.py` | 282 | 216 |
| `.claude/hooks/pre_exit_plan_ai_review.py` | 207 | 174 |
| **Total** | **947** | **880** |

The shared helper grew because CI polling and AI command execution moved into
`common.py`; the hook entrypoints now own less local subprocess logic.

## Command Line Count

| Command | Before | After | New executable |
| --- | ---: | ---: | --- |
| `.claude/commands/repo-maintenance.md` | 3887 | 52 | `script/repo-maintenance.sh` |
| `.claude/commands/setup-ci.md` | 800 | 33 | `script/setup-ci.sh` |
| `.claude/commands/setup-new-repo.md` | 805 | 27 | `script/setup-new-repo.sh` |
| **Total** | **5492** | **112** | |

## Agent Inventory

Static search found no active command, hook, or workflow invocation for these
agents outside generated/list documentation and the agent definitions. Individual
follow-up issues were created instead of deleting agents in bulk:

| Agent | Issue |
| --- | --- |
| `act-local-ci-manager` | https://github.com/keito4/config/issues/846 |
| `docs-consistency-checker` | https://github.com/keito4/config/issues/847 |
| `playwright-test-generator` | https://github.com/keito4/config/issues/848 |
| `playwright-test-healer` | https://github.com/keito4/config/issues/849 |
| `playwright-test-planner` | https://github.com/keito4/config/issues/850 |
| `issue-resolver-orchestrator` | https://github.com/keito4/config/issues/851 |

The `issue-resolver-*` subagents were not opened as individual deletion issues
in this PR because they are referenced by `issue-resolver-orchestrator.md`.
Decide the orchestrator first, then review subagents if the orchestrator is
removed.
