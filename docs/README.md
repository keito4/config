# Documentation

このディレクトリには、開発環境のセットアップ、ツール構成、各種ガイドが含まれています。

## ドキュメント一覧

### プロジェクトセットアップ

新規プロジェクトを立ち上げる際のガイドです。

| ドキュメント                                                     | 説明                                         |
| ---------------------------------------------------------------- | -------------------------------------------- |
| [setup/README.md](./setup/README.md)                             | プロジェクト種別ごとのセットアップガイド索引 |
| [setup/web-app-nextjs.md](./setup/web-app-nextjs.md)             | Next.js Web アプリケーション                 |
| [setup/spa-react-vite.md](./setup/spa-react-vite.md)             | React + Vite SPA                             |
| [setup/npm-library-cli.md](./setup/npm-library-cli.md)           | npm ライブラリ / CLI ツール                  |
| [setup/mobile-flutter.md](./setup/mobile-flutter.md)             | Flutter モバイルアプリ                       |
| [setup/mobile-android.md](./setup/mobile-android.md)             | Android ネイティブアプリ                     |
| [setup/desktop-extension-ts.md](./setup/desktop-extension-ts.md) | デスクトップ拡張（TypeScript）               |
| [setup/windows.md](./setup/windows.md)                           | Windows ネイティブセットアップ               |

### テストテンプレート

| ドキュメント                                                     | 説明                                            |
| ---------------------------------------------------------------- | ----------------------------------------------- |
| [../templates/testing/README.md](../templates/testing/README.md) | 包括的テスト設定テンプレート（21種類、5レベル） |

### DevContainer / 開発環境

| ドキュメント                                               | 説明                                            |
| ---------------------------------------------------------- | ----------------------------------------------- |
| [using-config-base-image.md](./using-config-base-image.md) | `ghcr.io/keito4/config-base` イメージの使用方法 |
| [tool-catalog.md](./tool-catalog.md)                       | 環境×ツールのマトリクス一覧                     |

### サービス連携・シークレット管理

| ドキュメント                                       | 説明                                                    |
| -------------------------------------------------- | ------------------------------------------------------- |
| [mcp-servers-guide.md](./mcp-servers-guide.md)     | MCP サーバー設定ガイド（Linear, Playwright, o3 など）   |
| [sentry-setup-guide.md](./sentry-setup-guide.md)   | Sentry セットアップガイド（Next.js 14+ 向け）           |
| [doppler-setup-guide.md](./doppler-setup-guide.md) | Doppler シークレット管理ガイド（dev/dev_personal 運用） |

## クイックスタート

### 新規プロジェクトの作成

1. プロジェクト種別に応じた [setup ガイド](./setup/README.md) を参照
2. DevContainer を使用する場合は [config-base イメージ](./using-config-base-image.md) を確認
3. ツール構成の詳細は [tool-catalog](./tool-catalog.md) を参照

### Claude Code コマンドとの連携

コマンド一覧は [AGENTS.md](../AGENTS.md) の自動生成セクションを参照してください。
各コマンドの作成規約は [.claude/commands/README.md](../.claude/commands/README.md) にあります。

### 構成情報

リポジトリ全体のディレクトリ一覧は [AGENTS.md](../AGENTS.md) の自動生成セクションを参照してください。
テンプレート配下は [templates/README.md](../templates/README.md)、setup 配下は [setup/README.md](./setup/README.md) が索引です。

## 関連リソース

- [AGENTS.md](../AGENTS.md) - AI エージェント向け開発ガイドライン
- [.claude/commands/README.md](../.claude/commands/README.md) - Claude Code コマンド作成規約
- [credentials/README.md](../credentials/README.md) - 認証情報管理ガイド
- [script/README.md](../script/README.md) - スクリプト一覧
