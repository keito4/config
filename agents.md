# AI Agents Overview

このリポジトリでは、Claude／Codex 両方のエージェントを協調させて開発タスクを自動化しています。`CLAUDE.md` に定義されているポリシーを踏まえ、ここでは各エージェント群の役割と利用方法を簡潔にまとめます。

## ディレクトリ

- `.claude/agents/`: Claude 専用の専門エージェント群（計 13 個）
- `.codex/prompts/`: Codex CLI から呼び出すコマンド／チェックリスト
- `.claude/commands/`: Claude が実行できる自動化コマンド（quality-check 等）

## エージェントカテゴリ

| カテゴリ                    | エージェント例                                                                                               | 主な目的                                               |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ |
| Architecture & Code Quality | DDD Architecture Validator, Performance Analyzer, Concurrency Safety Analyzer, Testability Coverage Analyzer | 設計整合性、性能/並列実装レビュー、テスト容易性評価    |
| Documentation & UX          | Documentation Consistency Checker, Accessibility Design Validator                                            | README/ADR/OpenAPI の整合確認、WCAG 観点の UI チェック |
| Dependencies & Security     | NuGet Dependency Auditor                                                                                     | 依存パッケージのライセンスやメンテ状況チェック         |
| Issue Resolver Suite        | Issue Resolver Orchestrator + Code Quality/Dependencies/Documentation/Security/Test Coverage                 | 課題単位での多段階解決、品質保証付きの自動修正フロー   |

## Codex コマンド連携

| コマンド                     | 目的                                                                           |
| ---------------------------- | ------------------------------------------------------------------------------ |
| `next-security-check`        | Next.js 向けセキュリティ全体レビュー。`next-security:*` サブコマンドに分割済み |
| `next-security:deps-scan`    | 依存関係の脆弱性スキャン（最小権限）                                           |
| `next-security:config-audit` | `next.config.*` / middleware / build 警告の静的監査                            |
| `next-security:authz-review` | RBAC/ABAC、セッション、Server Actions の権限確認                               |
| `refactor:*` シリーズ        | `refactor:decouple`, `refactor:simplify` など、実装改善ガイド                  |

## 利用ガイド

1. **タスクの種類を判定**: 設計・品質は Claude エージェント、具体的変更や検証は Codex コマンドを優先
2. **権限分離**: セキュリティ系コマンドは `next-security:deps-scan` などを個別実行し、必要最低限のファイル/秘密情報アクセスのみ付与
3. **通知**: Claude エージェントが完了時に Slack へ通知（`CLAUDE.md` 参照）
4. **レポート作成**: 各コマンドのテンプレに従って Issue/PR コメントへ結果を貼り付ける

## 非冗長にして重複を排除する

### 目的

同じ知識/意図の複数実装を一本化し、矛盾と修正漏れを防ぐ。

### 適用場面

- 同一ロジックが3箇所以上で再実装
- マジックナンバー/リテラルが散在
- 類似ユーティリティ/ヘルパーの乱立

### 基本ルール

- 真実の所在は一箇所
- 定数・共通ロジックを共有点へ集約
- 使われないコードは削除

### 手順（最小リスク）

1. 重複箇所を洗い出し、唯一実装を決定
2. 参照側を順次置換（小さなPRで段階移行）
3. 旧実装を撤去し、テスト参照を一本化

### 測定指標（改善確認）

- 重複率↓、同義ヘルパー数↓
- 修正時の変更箇所数↓
- マジック値の出現回数↓

### アンチパターン

- 早すぎる共通化で可読性が下がる
- 巨大全能ヘルパーの作成

### 関連タグ（refactor）

`refactor:dedupe`, `refactor:simplify`（定数化・命名整理）

### コミット例

```
refactor:dedupe date range handling across billing/reporting
```

## 参考ドキュメント

- `CLAUDE.md`: 品質基準、AI プロンプト設計ガイド、CI 連携
- `.claude/agents/README.md`: 各エージェントのパラメータや入出力例
- `.codex/prompts/README.md`: Codex コマンドのカタログ

このファイルは、AI エージェントを追加・更新する際の差分説明にも利用してください。
