# MCP Servers Configuration Guide

Claude CodeのMCPサーバー設定ガイドです。

## 概要

MCPサーバーは `.mcp.json` ファイルで設定します。このファイルには機密情報（APIキー等）が含まれるため、`.gitignore` に含まれており、バージョン管理されません。

## 設定ファイルの場所

プロジェクトルートに `.mcp.json` を作成します：

```json
{
  "mcpServers": {
    // サーバー設定をここに追加
  }
}
```

## 利用可能なMCPサーバー

### Linear

Linearプロジェクト管理ツールとの統合。Issue/Project操作が可能になります。

**設定:**

```json
{
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    }
  }
}
```

**必要な環境変数:**

- `LINEAR_API_KEY`: Linear APIキー（Settings > API > Personal API keysで取得）

**利用可能な操作:**

- Issueの作成・更新・検索
- Projectの管理
- Cycleの操作
- チームメンバーの確認

### Playwright

ブラウザ自動化とE2Eテスト支援。

**設定:**

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {}
    }
  }
}
```

**利用可能な操作:**

- ブラウザのナビゲーション
- 要素のクリック・入力
- スクリーンショット取得
- アクセシビリティスナップショット

### o3-search (OpenAI)

高度なWeb検索とリサーチ機能。

**設定:**

```json
{
  "mcpServers": {
    "o3": {
      "type": "stdio",
      "command": "npx",
      "args": ["o3-search-mcp"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "SEARCH_CONTEXT_SIZE": "medium",
        "REASONING_EFFORT": "medium"
      }
    }
  }
}
```

**必要な環境変数:**

- `OPENAI_API_KEY`: OpenAI APIキー

**オプション設定:**

- `SEARCH_CONTEXT_SIZE`: `small`, `medium`, `large`
- `REASONING_EFFORT`: `low`, `medium`, `high`

### GitHub

GitHub操作の統合。

**設定:**

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

**利用可能な操作:**

- リポジトリの操作
- Issue/PRの管理
- GitHub Copilot連携

**注意:** Claude Codeには GitHub MCP が組み込まれているため、`gh` CLI認証があれば追加設定不要です。

### Figma

Figmaデザインツールとの統合。

**設定:**

```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp",
      "headers": {}
    }
  }
}
```

**利用可能な操作:**

- デザインファイルの読み取り
- コンポーネント情報の取得
- デザインからコード生成のサポート

### Supabase

Supabaseデータベースとの統合。

**設定:**

```json
{
  "mcpServers": {
    "supabase": {
      "type": "stdio",
      "command": "npx",
      "args": ["@supabase/mcp@latest"],
      "env": {
        "SUPABASE_URL": "${SUPABASE_URL}",
        "SUPABASE_KEY": "${SUPABASE_KEY}"
      }
    }
  }
}
```

**必要な環境変数:**

- `SUPABASE_URL`: Supabaseプロジェクト URL
- `SUPABASE_KEY`: Supabase Anon/Service Role キー

## 完全な設定例

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {}
    },
    "o3": {
      "type": "stdio",
      "command": "npx",
      "args": ["o3-search-mcp"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "SEARCH_CONTEXT_SIZE": "medium",
        "REASONING_EFFORT": "medium"
      }
    },
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp",
      "headers": {}
    }
  }
}
```

## 環境変数の設定

`.mcp.json`で`${ENV_VAR}`形式を使用すると、環境変数が自動的に展開されます。

環境変数は以下の方法で設定できます：

1. **シェルで直接設定**

   ```bash
   export LINEAR_API_KEY="lin_api_xxx"
   ```

2. **1Passwordなどのシークレット管理ツール**

   ```bash
   export LINEAR_API_KEY=$(op read "op://vault/linear/api-key")
   ```

3. **direnvを使用**
   ```bash
   # .envrc
   export LINEAR_API_KEY="lin_api_xxx"
   ```

## トラブルシューティング

### MCPサーバーが認識されない

1. `.mcp.json` がプロジェクトルートにあるか確認
2. JSON構文が正しいか確認（`jq . .mcp.json`）
3. Claude Codeを再起動

### 認証エラー

1. 環境変数が正しく設定されているか確認
2. APIキーの有効期限を確認
3. 必要な権限があるか確認

### タイムアウトエラー

1. ネットワーク接続を確認
2. `type: "http"` のサーバーはプロキシ設定を確認
3. タイムアウト設定を調整（可能な場合）
