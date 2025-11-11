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

## MCP ツール一覧

`.codex/config.toml` では以下の MCP サーバーが事前登録されており、Claude に「◯◯ MCP を使って … して」と依頼すると明示的に呼び出せます。

| サーバー ID | 依頼テンプレート例 | 主な用途 |
| ----------- | ------------------ | -------- |
| `aws-docs`  | `@claude aws-docs MCP で CloudFront Functions の制約を調べてください` | 公式 AWS ドキュメント検索。サービス仕様や制限の引用に利用 |
| `playwright` | `@claude playwright MCP を使って e2e テストのスクリーンショットを取って` | Playwright ランタイムを用いたブラウザ操作や UI リグレッション検証 |
| `o3`        | `@claude o3 MCP で "<キーワード>" を深掘り調査し、根拠付きでまとめて` | OpenAI o3 Search を用いた高度な調査・根拠集約 |
| `supabase`  | `@claude supabase MCP 経由で プロジェクト <ID> のテーブル定義を教えて` | Supabase プロジェクトの API/DB 操作、メタデータ確認 |
| `vercel`    | `@claude vercel MCP で デプロイ <deploymentId> のログを要約して` | Vercel プロジェクトのデプロイ履歴やログ調査 |
| `github`    | `@claude github MCP を使って issue #123 のコメント履歴を取得して` | GitHub Copilot MCP 経由で Issue/PR/Discussion 情報を取得 |

> 各ツールは `OPENAI_API_KEY`, `SUPABASE_MCP_TOKEN`, `VERCEL_MCP_TOKEN`, `GITHUB_COPILOT_MCP_TOKEN` など `~/.devcontainer.env` から供給されるトークンで認証されます。リクエスト時にどの MCP を使うか明示することで、必要最小限の権限で安全に自動化できます。

## 利用ガイド

1. **タスクの種類を判定**: 設計・品質は Claude エージェント、具体的変更や検証は Codex コマンドを優先
2. **権限分離**: セキュリティ系コマンドは `next-security:deps-scan` などを個別実行し、必要最低限のファイル/秘密情報アクセスのみ付与
3. **通知**: Claude エージェントが完了時に Slack へ通知（`CLAUDE.md` 参照）
4. **レポート作成**: 各コマンドのテンプレに従って Issue/PR コメントへ結果を貼り付ける

## 参考ドキュメント

- `CLAUDE.md`: 品質基準、AI プロンプト設計ガイド、CI 連携
- `.claude/agents/README.md`: 各エージェントのパラメータや入出力例
- `.codex/prompts/README.md`: Codex コマンドのカタログ

このファイルは、AI エージェントを追加・更新する際の差分説明にも利用してください。
