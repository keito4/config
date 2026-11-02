# ADR 0030: Finalize queued Claude Issues from verified results

Date: 2026-11-02
Status: Proposed

## Context

Elu-co-jp/.github-private #323 stopped after denied reads while retaining `claude-working`. Process success and PR existence alone do not establish delivery (ADR 0029). A failed run must leave an actionable queue state, including authentication failure and timeout.

## Decision

- Serialize trusted Issue requests through finalization, retaining pending requests with `queue: max`. Unrelated events have separate groups.
- Immediately before an authenticated Claude invocation, read the current Issue and move an open tracked Issue to `claude-working`, adding that label before removing other queue/result labels. Keep the existing actor/mention guard and use fixed inline workflow code. Leave closed, untracked, and PR requests unchanged. API errors stop the Claude step; finalization still handles the failed job.
- Run finalization in a separate, always-evaluated job using only the workflow's trusted inline code and Issues write permission.
- For open Issues already carrying a Claude queue label, set `claude-review` only when the job succeeds and the existing completion verifier reports true. Otherwise set `claude-blocked` and fail the finalizer. A draft PR never substitutes for completion.
- A verified answer without a PR can enter review. A successfully completed closed Issue has its queue labels removed. Leave unrelated Issues and failed runs on closed Issues untouched.
- Keep organizational read credentials specific to the audit repository. Roll out the shared behavior through representative repositories while retaining their runner, authentication, and action pins.

## Consequences

Issue state reflects delivery, while human review and merging remain separate. Cancellation of an entire workflow can still prevent finalization; this is not a stale-run recovery service. Existing config downstream subscriptions receive the template through their normal PR sync; other repositories require reviewed migration before opting into full-file synchronization.

Queued requests retain the previous result until their turn starts; each start reads the live Issue rather than its original event labels. Missing authentication skips the working transition and Claude, then finalizes tracked open Issues as blocked. Queued or authentication-skipped requests do not acquire a working state. Cancellation after the working transition may leave `claude-working` if finalization cannot run, requiring manual inspection. Actions and the tracking comment remain the source for current execution progress. These result labels do not trigger automatic merging or closing in the pilot repositories.
