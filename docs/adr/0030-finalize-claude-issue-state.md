# ADR 0030: Finalize queued Claude Issues from verified results

Date: 2026-11-02
Status: Proposed

## Context

Elu-co-jp/.github-private #323 stopped after denied reads while retaining `claude-working`. Process success and PR existence alone do not establish delivery (ADR 0029). A failed run must leave an actionable queue state, including authentication failure and timeout.

## Decision

- Serialize trusted Issue requests through finalization, retaining pending requests with `queue: max`. Unrelated events have separate groups.
- Run finalization in a separate, always-evaluated job using only the workflow's trusted inline code and Issues write permission.
- For open Issues already carrying a Claude queue label, set `claude-review` only when the job succeeds and the existing completion verifier reports true. Otherwise set `claude-blocked` and fail the finalizer. A draft PR never substitutes for completion.
- A verified answer without a PR can enter review. A successfully completed closed Issue has its queue labels removed. Leave unrelated Issues and failed runs on closed Issues untouched.
- Keep organizational read credentials specific to the audit repository. Roll out the shared behavior through representative repositories while retaining their runner, authentication, and action pins.

## Consequences

Issue state reflects delivery, while human review and merging remain separate. Cancellation of an entire workflow can still prevent finalization; this is not a stale-run recovery service. Existing config downstream subscriptions receive the template through their normal PR sync; other repositories require reviewed migration before opting into full-file synchronization.

This change manages end-of-run result labels. During a retry, the previous result remains visible until finalization; use Actions or the tracking comment for current progress. A guarded transition back to `claude-working` at the start of a retry is follow-up work, including queued requests, authentication skips, and cancellation. These result labels do not trigger automatic merging or closing in the pilot repositories.
