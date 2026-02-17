# セットアップガイド

プロジェクト種別ごとのセットアップ手順を提供する。
[CLAUDE.md](../../CLAUDE.md) の品質基準に基づく。

## 共通品質ゲート（全プロジェクト必須）

| 品質ゲート   | 基準                                                |
| ------------ | --------------------------------------------------- |
| Unit テスト  | 全プロジェクトで導入必須                            |
| カバレッジ   | 70%+ (lines / branches / functions / statements)    |
| Lint         | Error=Fail、`--max-warnings 0`                      |
| Format 検証  | CI で `format:check` を実行、Auto-fix 無効時は Fail |
| CI/CD        | Lint → Test → Build → SCA → Deploy                  |
| Git hooks    | husky + commitlint + lint-staged（または lefthook） |
| CLAUDE.md    | 技術スタック・テスト戦略・デプロイ先を記載          |
| SAST         | Critical 検知で Fail                                |
| DevContainer | `ghcr.io/keito4/config-base:latest` ベース          |

## プロジェクト別ガイド

| ガイド                                               | 対応種別              |
| ---------------------------------------------------- | --------------------- |
| [spa-react-vite.md](./spa-react-vite.md)             | SPA (React + Vite)    |
| [npm-library-cli.md](./npm-library-cli.md)           | npm ライブラリ (CLI)  |
| [web-app-nextjs.md](./web-app-nextjs.md)             | Web アプリ (Next.js)  |
| [mobile-flutter.md](./mobile-flutter.md)             | モバイル (Flutter)    |
| [mobile-android.md](./mobile-android.md)             | モバイル (Android)    |
| [desktop-extension-ts.md](./desktop-extension-ts.md) | デスクトップ拡張 (TS) |

## 共通コマンド

| コマンド                    | 用途                                            |
| --------------------------- | ----------------------------------------------- |
| `/setup-husky`              | husky + lint-staged + commitlint の最小構成導入 |
| `/setup-ci`                 | CI/CD ワークフローの雛形作成                    |
| `/setup-new-repo`           | 新規リポジトリの初期セットアップ一式            |
| `/config-base-sync-update`  | DevContainer ベースイメージを最新版に更新       |
| `/config-base-sync-check`   | 現在のベースイメージバージョンを確認            |
| `/security-credential-scan` | 認証情報の漏洩スキャン                          |
| `/code-complexity-check`    | コード複雑度チェック                            |
| `/dependency-health-check`  | 依存パッケージの健全性チェック                  |
