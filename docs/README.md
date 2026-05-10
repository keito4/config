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

| コマンド                   | 関連ドキュメント                                                 |
| -------------------------- | ---------------------------------------------------------------- |
| `/setup-new-repo`          | [setup/README.md](./setup/README.md)                             |
| `/setup-ci`                | [setup/README.md](./setup/README.md)                             |
| `/setup-tests`             | [../templates/testing/README.md](../templates/testing/README.md) |
| `/config-base-sync-update` | [using-config-base-image.md](./using-config-base-image.md)       |
| `/repo-maintenance`        | [tool-catalog.md](./tool-catalog.md)                             |
| `/setup-doppler`           | [doppler-setup-guide.md](./doppler-setup-guide.md)               |

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
├── doppler-setup-guide.md      # Doppler シークレット管理
└── tool-catalog.md             # ツールカタログ

templates/
├── biome.json                   # Biome 統合フォーマッタ+リンタ設定
├── commitlint.config.js         # Conventional Commits (日本語緩和)
├── editorconfig                 # エディタ間スタイル統一
├── eslint/
│   └── eslint.config.mjs       # ESLint flat config (TypeScript + 複雑度)
├── github/
│   ├── policies/               # ポリシー設定テンプレート
│   │   ├── complexity-thresholds.json  # 複雑度閾値
│   │   ├── allowed-licenses.json       # ライセンス許可/禁止リスト
│   │   └── severity-definitions.md     # セキュリティ SLA 定義
│   ├── dependabot.yml          # Dependabot 設定
│   ├── labels.yml              # ラベル定義
│   ├── pull_request_template.md
│   └── SECURITY.md
├── testing/                     # テスト設定テンプレート
│   ├── README.md               # テストテンプレートガイド（21種類）
│   ├── jest.config.js          # Jest 基本設定
│   ├── vitest.config.ts        # Vitest 設定 (jsdom + v8 coverage)
│   ├── playwright.config.ts    # Playwright E2E 設定
│   └── examples/               # 各テスト種別のサンプルコード
└── workflows/                   # GitHub Actions ワークフローテンプレート
    ├── quality-gate-fallback.yml # CI パス保証 (fallback)
    ├── claude.yml               # Claude Code 連携
    ├── dependabot-auto-merge.yml
    └── ...
```

## 関連リソース

- [AGENTS.md](../AGENTS.md) - AI エージェント向け開発ガイドライン
- [.claude/commands/README.md](../.claude/commands/README.md) - Claude Code コマンド一覧
- [credentials/README.md](../credentials/README.md) - 認証情報管理ガイド
- [script/README.md](../script/README.md) - スクリプト一覧
