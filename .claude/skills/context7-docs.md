---
description: ライブラリやフレームワークの使い方、設定方法、最新機能、エラー解決を調べる際に使用。「Prismaの使い方」「Next.jsの設定」「React 19の新機能」「Tailwindエラー解決」などのリクエスト時に自動適用。
---

# Context7 Documentation Skill

ライブラリやフレームワークの最新ドキュメントをContext7 MCPで取得して回答する。

## 使用手順

### 1. ライブラリIDを解決

```
mcp__context7__resolve-library-id でライブラリ名を検索
```

例: "prisma", "next.js", "react", "tailwindcss"

### 2. ドキュメントを取得

```
mcp__context7__get-library-docs でドキュメントを取得
```

パラメータ:

- `context7CompatibleLibraryID`: 解決したライブラリID
- `topic`: 特定のトピック（オプション）

### 3. 回答の作成

取得したドキュメントに基づいて:

- 最新のAPI・設定方法を説明
- コード例を提示
- バージョン固有の注意点を明記

## トリガー例

| リクエスト                           | 対応                                        |
| ------------------------------------ | ------------------------------------------- |
| 「Prismaのマイグレーション方法」     | Prismaドキュメントからmigration手順を取得   |
| 「Next.js 14のApp Router設定」       | Next.jsドキュメントからApp Router情報を取得 |
| 「React 19の新機能は？」             | Reactドキュメントから最新機能を取得         |
| 「このTailwindエラーの解決方法」     | Tailwindドキュメントから該当情報を検索      |
| 「Vite 5の設定ファイル形式」         | Viteドキュメントから設定ガイドを取得        |
| 「TypeScriptのジェネリクスの使い方」 | TypeScriptドキュメントから解説を取得        |

## 注意事項

- 古い知識に頼らず、必ずContext7で最新情報を確認する
- ドキュメントが見つからない場合のみ、既存知識で回答する
- 取得したドキュメントの情報源を明記する
