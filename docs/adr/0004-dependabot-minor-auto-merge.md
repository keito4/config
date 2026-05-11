# ADR 0004: Dependabot Minor Updates の自動マージ

## Status

Accepted

## Context

`dependabot-auto-merge.yml` ワークフローでは、依存関係の更新種別に応じて以下の処理を行っていた：

| 種別  | 旧動作                                  |
| ----- | --------------------------------------- |
| patch | CI 通過後に自動マージ                   |
| minor | `gh pr review --approve` で自動承認     |
| major | `needs-review` / `breaking-change` ラベル付与 |

minor の「自動承認」は `GITHUB_TOKEN` を使った `gh pr review --approve` で実装していたが、
GitHub Actions に PR 承認権限が付与されていない場合に以下のエラーで失敗する：

```
failed to create review: GraphQL: GitHub Actions is not permitted to approve pull requests.
```

この権限はリポジトリ設定の "Allow GitHub Actions to approve pull requests" で制御されており、
有効化するとセキュリティリスク（悪意ある PR の自動承認）が生じる可能性があるため、
安易に有効化することは適切でない。

## Decision

minor アップデートの処理を「自動承認（手動マージ）」から「CI 通過後の自動マージ」に変更する。

```yaml
# 変更前
gh pr review "$PR_URL" --approve --body "Auto-approved: minor version update"

# 変更後
gh pr merge "$PR_URL" --auto --merge
```

patch と minor を同一扱いにする。major のみレビュー必須を継続する。

## Consequences

### Positive

- GitHub Actions の追加権限付与が不要
- ワークフローが CI 通過後に確実に動作する
- minor 更新の手動マージ作業が不要になる

### Negative

- minor アップデートに対する人間のマージ判断が省略される
- ただし CI（テスト・lint・セキュリティスキャン）は依然として必須

### Mitigation

- CI ゲート（Unit Tests・Integration Tests・Lint・Security Scans）がすべて通過した場合のみマージされる
- major アップデートは引き続きラベル付与 + 手動レビューを要求する
- 問題が発生した場合は `dependabot-auto-merge.yml` の `Auto-merge minor updates` ステップを無効化できる
