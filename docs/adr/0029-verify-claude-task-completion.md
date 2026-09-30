# ADR 0029: Verify Claude's delivered result separately from process success

Date: 2026-09-30
Status: Proposed

## Context

OYKOT-jp/oykot-lp #293 and pbx-operation #413 ended with SDK success while their tracking comments still contained unfinished work. oykot-tools #352 checked every task but never posted its findings. Several other runs returned `subtype: success` with `is_error: true`; the pinned action correctly fails these runs, but hides denial details. Raw execution output can contain credentials and must remain hidden.

oykot-tools #351 explicitly reports that `make test` and `bash tests/script/test_setup_team_protection.sh` were denied. Node package-manager permissions do not cover its shell test suite.

## Decision

- Require the tracking comment for the current run to contain `<!-- claude-task-status: complete -->` only after delivering the requested result and completing delegated work. Blocked work uses `<!-- claude-task-status: blocked -->` with the reason and next action.
- After Claude exits, validate the saved SDK result and current run's comment. An error, missing final marker, or unfinished checklist cannot count as completion. Recovered tool denials alone do not fail completed work.
- Log only denial tool/command families and known assistant error categories. Never print tool arguments, result text, or the raw execution file.
- Preserve pushed changes in a draft PR when the run fails verification. Use `Refs`, not `Closes`, for incomplete work. Do not retry or merge automatically.
- Add only known test entry points (`make test`, `bash tests/*`, `bats`) to the workflow allow list; retain existing actor checks and permission mode.

## Consequences

Process success and delivered-task completion become separately observable. The marker is a delivery signal, not proof of audit quality or CI success. Required checks and review remain necessary. A later failed run's safe diagnostics identify whether a runtime permission or a provider error needs attention without exposing full logs. Existing workflows must receive both the prompt and verification step together.
