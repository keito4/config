# ADR 0004: claude-code-action v1.0.85 への更新

## Status

Accepted

## Context

全ワークフロー（`claude.yml`, `claude-code-review.yml` 等）で claude-code-action を古い SHA ピン（`@v1` タグ相当の固定ハッシュ）で参照していた。その結果、以下の問題が生じていた。

- 進捗トラッキング（`track_progress`）が無効のため、長時間タスクの状態が GitHub 上で可視化されなかった
- `synchronize`（追加コミット）や `reopened` イベントへの対応が不十分だった
- 非推奨パラメータ（`assignee_trigger` など）が残存しており、将来の破壊的変更リスクがあった

## Decision

1. **claude-code-action を v1.0.85 に統一** — 全ワークフローの `uses:` を同バージョンの SHA に更新
2. **`track_progress: true` を有効化** — タスク実行中の進捗をコメントでリアルタイム表示
3. **非推奨パラメータを移行** — 公式ドキュメントに従い新パラメータ体系へ切り替え
4. **`synchronize` / `reopened` イベントを追加** — PR 更新時にも自動レビューが走るよう対応

## Consequences

### Positive

- タスク実行中の進捗がスピナー付きコメントで可視化される
- PR に追加コミットがプッシュされた際も自動レビューがトリガーされる
- 非推奨警告が解消され、将来バージョンアップ時の移行コストが低減される

### Negative

- SHA ピンを更新するたびに全ワークフローを同期変更する運用コストが生じる

### Neutral

- v1.0.85 での動作確認は本 Issue（#659）のトリガーテストで実施
