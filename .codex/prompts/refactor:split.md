# 関心を分離して影響範囲を限定する

## 目的

単一の変更理由に専念するユニットへ分割し、修正の波及・レビュー範囲を局所化する。

## 適用場面

- 1ファイル/関数に複数の変更理由が混在
- I/O・計算・表示が同居
- 外部依存（DB/HTTP/FS）が多系統

## 基本ルール

- 公開面（export/公開API）は最小限
- ファイルは「役割」単位で切る
- 同一関心が3件以上なら専用ディレクトリ化

## 手順（最小リスク）

0. 関心が混在している箇所を全体から洗い出し、5件の単位でGitHub Issueを作成してからリファクタリングに着手（MCP経由を推奨）
1. `refactor:reorganize`で入れ物（ディレクトリ/命名）を先に整える
2. 純粋処理を`refactor:split`（extract-function/module）で分ける
3. I/O/境界を`refactor:split-io-boundary`相当で退避
4. 旧コードを撤去し、公開面を再確認

## 測定指標（改善確認）

- 循環的複雑度（CC）↓、ネスト深度↓
- ファイル行数↓、依存グラフの循環減
- 1ユニット=1変更理由の説明可能性↑

## アンチパターン

- 目的の異なる修正を1PRに混在
- 公開面の肥大化（境界が漏れる）
- 細片化しすぎて探索性が低下

## 関連タグ（refactor）

`refactor:split`[`-by-reason`|`-by-layer`|`-by-feature`|`-io-boundary`|`-cqrs`], `refactor:reorganize`

## コミット例

```
refactor:split-by-reason checkout (parse/validate/execute)
```
