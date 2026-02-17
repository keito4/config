# セットアップガイド

プロジェクト種別ごとの品質ゲート整備状況と、セットアップ手順を提供する。
各リポジトリの実態調査（2026-02 時点）に基づく。

## 品質ゲート達成状況マトリクス

[docs/tool-catalog.md](../tool-catalog.md) および各リポジトリの実設定ファイルに基づく。

| 品質ゲート             | SPA (React + Vite) | npm ライブラリ (CLI) | Web アプリ (Next.js) | モバイル (Flutter) | モバイル (Android) | デスクトップ拡張 (TS) |
| ---------------------- | :----------------: | :------------------: | :------------------: | :----------------: | :----------------: | :-------------------: |
| **Unit テスト**        |         x          |          o           |          o           |         o          |         o          |      △ (1 拡張)       |
| **カバレッジ 70%+**    |         x          |   △ (35-45% 設定)    |    △ (8-60% 設定)    |    △ (閾値なし)    |    △ (閾値なし)    |           x           |
| **E2E テスト**         |         x          |          -           |          o           |         o          |    △ (Maestro)     |           x           |
| **ESLint / Lint**      |         x          |     △ (設定重複)     |          o           |    o (dart 用)     |  o (Android Lint)  |           o           |
| **Prettier / fmt**     |         x          |          o           |          o           |  o (dart format)   |         x          |           o           |
| **CI/CD**              |         x          |          o           |          o           |         o          |         o          |     △ (lint のみ)     |
| **husky + commitlint** |         x          |    △ (husky のみ)    |          o           |         x          |         x          |           o           |
| **CLAUDE.md**          |         x          |          x           |          x           |         o          |         x          |           x           |
| **SAST / CodeQL**      |         x          |          o           |    △ (audit のみ)    |         x          |         x          |           x           |

- **o** = 達成済み
- **△** = 部分的に達成（改善が必要）
- **x** = 未達成
- **-** = 対象外

## 優先度別の対応順序

### 1. まず着手すべきプロジェクト（不足が多い順）

1. **SPA (React + Vite)** — 品質ゲートがほぼ未整備（テスト・Lint・CI すべて未設定）
2. **デスクトップ拡張 (TS)** — テスト未設定（n8n 以外）、CI の lint が実質無効化

### 2. 次に着手すべきプロジェクト（閾値強化・補完が必要）

3. **モバイル (Flutter)** — CI の閾値強制・フォーマット検証・Git hooks が不足
4. **モバイル (Android)** — detekt・Kover 未導入、Git hooks 未設定
5. **npm ライブラリ (CLI)** — commitlint 未導入、カバレッジ閾値が低い（35-45%）
6. **Web アプリ (Next.js)** — カバレッジ閾値の段階的引き上げ（8-60% → 70%）

## プロジェクト別ガイド

| ガイド                                               | 対応種別              |
| ---------------------------------------------------- | --------------------- |
| [spa-react-vite.md](./spa-react-vite.md)             | SPA (React + Vite)    |
| [npm-library-cli.md](./npm-library-cli.md)           | npm ライブラリ (CLI)  |
| [web-app-nextjs.md](./web-app-nextjs.md)             | Web アプリ (Next.js)  |
| [mobile-flutter.md](./mobile-flutter.md)             | モバイル (Flutter)    |
| [mobile-android.md](./mobile-android.md)             | モバイル (Android)    |
| [desktop-extension-ts.md](./desktop-extension-ts.md) | デスクトップ拡張 (TS) |

## 共通で使えるコマンド

| コマンド                    | 用途                                            |
| --------------------------- | ----------------------------------------------- |
| `/setup-husky`              | husky + lint-staged + commitlint の最小構成導入 |
| `/setup-ci`                 | CI/CD ワークフローの雛形作成                    |
| `/config-base-sync-update`  | DevContainer ベースイメージを最新版に更新       |
| `/config-base-sync-check`   | 現在のベースイメージバージョンを確認            |
| `/setup-new-repo`           | 新規リポジトリの初期セットアップ一式            |
| `/security-credential-scan` | 認証情報の漏洩スキャン                          |
| `/code-complexity-check`    | コード複雑度チェック                            |
| `/dependency-health-check`  | 依存パッケージの健全性チェック                  |

## 共通ベースライン（全プロジェクト必須）

[CLAUDE.md](../../CLAUDE.md) で定義された品質基準:

- **TDD**: Red → Green → Refactor、70%+ カバレッジ
- **Static Quality Gates**: Lint Error=Fail、Format 検証、SAST、ライセンスチェック
- **Git Workflow**: Conventional Commits、Branch 命名規約、PR ガード
- **CI/CD**: Lint → Test → Build → SCA → Deploy
