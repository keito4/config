---
paths:
  - '**/*'
---

# Code Review Standards

## 5観点レビュー

コードレビュー時は以下の5観点で評価する。

| 観点              | チェック内容                                                   |
| ----------------- | -------------------------------------------------------------- |
| **Security**      | SQLインジェクション, XSS, 機密情報露出, 入力バリデーション不足 |
| **Performance**   | N+1クエリ, 不要な再レンダリング, メモリリーク, 不要な再計算    |
| **Quality**       | 命名, 単一責任, テストカバレッジ, エラーハンドリング           |
| **Accessibility** | ARIA属性, キーボードナビゲーション, カラーコントラスト         |
| **AI Residuals**  | モック残骸, ハードコード値, スキップされたテスト, 仮実装       |

## Severity 判定基準

各指摘を以下の severity に分類し、verdict を決定する。

| Severity           | 定義                                                   | Verdict への影響        |
| ------------------ | ------------------------------------------------------ | ----------------------- |
| **critical**       | セキュリティ脆弱性、データ損失リスク、本番障害の可能性 | 1件でも REQUEST_CHANGES |
| **major**          | 既存機能の破壊、仕様との矛盾、テスト不通過             | 1件でも REQUEST_CHANGES |
| **minor**          | 命名改善、コメント不足、スタイル不統一                 | verdict に影響しない    |
| **recommendation** | ベストプラクティス提案、将来の改善案                   | verdict に影響しない    |

minor / recommendation のみの場合は APPROVE を返す。「あったほうが良い改善」は REQUEST_CHANGES の理由にならない。

## AI Residuals 検出パターン

| Severity           | パターン                                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| **major**          | `localhost` / `127.0.0.1` の接続先, `it.skip` / `describe.skip` / `test.skip`, ハードコードされた秘密情報, dev/staging 固定 URL |
| **minor**          | `mockData`, `dummy`, `fakeData`, `TODO`, `FIXME`                                                                                |
| **recommendation** | `temporary implementation`, `replace later`, `placeholder` などの仮実装コメント                                                 |
