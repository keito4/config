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

### DevContainer / 開発環境

| ドキュメント                                               | 説明                                            |
| ---------------------------------------------------------- | ----------------------------------------------- |
| [using-config-base-image.md](./using-config-base-image.md) | `ghcr.io/keito4/config-base` イメージの使用方法 |
| [tool-catalog.md](./tool-catalog.md)                       | 環境×ツールのマトリクス一覧                     |

### サービス連携

| ドキュメント                                     | 説明                                                  |
| ------------------------------------------------ | ----------------------------------------------------- |
| [mcp-servers-guide.md](./mcp-servers-guide.md)   | MCP サーバー設定ガイド（Linear, Playwright, o3 など） |
| [sentry-setup-guide.md](./sentry-setup-guide.md) | Sentry セットアップガイド（Next.js 14+ 向け）         |

## クイックスタート

### 新規プロジェクトの作成

1. プロジェクト種別に応じた [setup ガイド](./setup/README.md) を参照
2. DevContainer を使用する場合は [config-base イメージ](./using-config-base-image.md) を確認
3. ツール構成の詳細は [tool-catalog](./tool-catalog.md) を参照

### Claude Code コマンドとの連携

| コマンド                   | 関連ドキュメント                                           |
| -------------------------- | ---------------------------------------------------------- |
| `/setup-new-repo`          | [setup/README.md](./setup/README.md)                       |
| `/setup-ci`                | [setup/README.md](./setup/README.md)                       |
| `/config-base-sync-update` | [using-config-base-image.md](./using-config-base-image.md) |
| `/repo-maintenance`        | [tool-catalog.md](./tool-catalog.md)                       |

## ディレクトリ構造

```
docs/
├── README.md                    # このファイル（ドキュメント索引）
├── setup/                       # プロジェクト種別セットアップガイド
│   ├── README.md               # 共通品質ゲート・パターン
│   ├── web-app-nextjs.md       # Next.js
│   ├── spa-react-vite.md       # React + Vite
│   ├── npm-library-cli.md      # npm ライブラリ
│   ├── mobile-flutter.md       # Flutter
│   ├── mobile-android.md       # Android
│   └── desktop-extension-ts.md # デスクトップ拡張
├── using-config-base-image.md  # DevContainer ベースイメージ
├── mcp-servers-guide.md        # MCP サーバー設定
├── sentry-setup-guide.md       # Sentry セットアップ
└── tool-catalog.md             # ツールカタログ
```

## 関連リソース

- [AGENTS.md](../AGENTS.md) - AI エージェント向け開発ガイドライン
- [.claude/commands/README.md](../.claude/commands/README.md) - Claude Code コマンド一覧
- [credentials/README.md](../credentials/README.md) - 認証情報管理ガイド
- [script/README.md](../script/README.md) - スクリプト一覧
