# ADR 0024: PR サイズ制限を警告からハード制約に変更する

## Status

Accepted

## Context

CLAUDE.md（全社開発規約 2.3 Git Workflow）は Pull Request ガードとして
**Diff ≤ 400 行 / ファイル数 ≤ 25** を定めているが、これまで CI 上の
`pr-size-check` は `continue-on-error: true` のラベル付け・警告コメントのみで、
違反しても CI は緑のままだった。

エージェントにコードの大半を書かせる運用では、規約をプロンプトや
ルールファイル（ソフト層）だけで守らせることはできない。エージェントは
最短経路でタスクを解こうとするため、忘れられる規約は必ず破られる。
ソフト層（rules / スキル / レビュー bot）は補助であり、守らせたい規約は
CI が赤くなるハード層に置く必要がある。この方針転換のきっかけは
Cursor のエンジニア Lauren Tan の講演（2026-08、「コードコメント禁止も
useEffect 禁止もすべて CI で hard fail にする。人間のコードレビューで
規約を守らせている状態はアンチパターン」）である。

一方で、生成コード・lockfile・一括リネームなど、分割が本質的に無意味な
大型 PR は存在する。機械的な上限だけでは運用が破綻するため、
人間が明示的に承認する例外経路が要る。

## Decision

1. `.github/actions/pr-size-check` を**ハードゲート**にする。
   合計変更行数 > 400 または変更ファイル数 > 25 で `core.setFailed` する。
   上限は inputs（`max-lines` / `max-files`）で調整可能とし、既定値を
   CLAUDE.md の 400 行 / 25 ファイルに合わせる。
2. 例外は **`size/override` ラベル**でのみ許可する。ラベルは人間のレビュアーが
   付与する前提とし、付与後にチェックを re-run すると通る。re-run 時に
   イベント payload のラベルは古いスナップショットになるため、
   ラベルは API（`listLabelsOnIssue`）で実行時に取得する。
3. `ci.yml` の `pr-size-check` ジョブから `continue-on-error` を外し、
   Quality Gate ジョブの判定対象に加える。これによりブランチ保護の
   必須チェック "Quality Gate" 経由でマージがブロックされる。
4. サイズラベル（XS〜XL）の付与と警告コメントは情報提供として残す。
   ラベル操作 API はフォーク PR で権限がない場合があるため best-effort とし、
   失敗してもゲート判定には影響させない。

## Consequences

- 400 行超の PR は `size/override` を付けて re-run しない限りマージできない。
  エージェントには PR 分割を促す圧力として働く。
- 既存の downstream リポジトリはこのリポジトリの action を直接は共有していない。
  横展開する場合は templates/workflows への追加を別途行う（未実施）。
- サイズラベル (`size/M` ≤500 行) とハード上限 (400 行) は意図的に別の軸である。
  `size/M` が付いていてもゲートで落ちる PR がある。
