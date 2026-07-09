# Credentials Management

このディレクトリは1Passwordを使用した機密情報管理のためのテンプレートとスクリプトを含みます。

## 構造

```
credentials/
├── README.md                        # このファイル
├── setup.md                         # 詳細なセットアップガイド
├── templates/                       # 各種サービスのテンプレート
│   ├── devcontainer.env.template    # DevContainer環境変数用
│   └── mcp.env.template             # MCP設定用
└── .gitignore                       # 生成されたファイルを無視
```

## 使用方法

### クイックスタート（推奨）

1. **1Password CLI をインストール**

   ```bash
   brew install --cask 1password-cli
   ```

2. **1Password にサインイン**

   ```bash
   op signin
   ```

3. **環境変数を自動セットアップ**

   ```bash
   ./script/credentials.sh fetch
   cp credentials/devcontainer.env ~/.devcontainer.env && chmod 600 ~/.devcontainer.env
   ```

   このスクリプトは以下を自動生成します：
   - `credentials/devcontainer.env` - DevContainer 環境変数
   - `credentials/mcp.env` - MCP 設定用環境変数

## サポートされているMCPサーバー

このリポジトリは以下のMCP (Model Context Protocol) サーバーをサポートしています：

| MCPサーバー         | 設定ファイル        | 必要な環境変数                                | 説明                      |
| ------------------- | ------------------- | --------------------------------------------- | ------------------------- |
| **Playwright**      | `.codex`, `.gemini` | なし                                          | ブラウザ自動化とテスト    |
| **AWS Docs**        | `.codex`, `.gemini` | なし                                          | AWS ドキュメント検索      |
| **Chrome DevTools** | `.codex`, `.gemini` | なし                                          | ブラウザデバッグ          |
| **Next DevTools**   | `.codex`, `.gemini` | なし                                          | Next.js 開発支援          |
| **Supabase**        | `.codex`, `.gemini` | `SUPABASE_ACCESS_TOKEN`, `SUPABASE_MCP_TOKEN` | Supabase プロジェクト操作 |
| **Vercel**          | `.codex`, `.gemini` | `VERCEL_TOKEN`, `VERCEL_MCP_TOKEN`            | Vercel 操作               |
| **GitHub**          | `.gemini`           | `GITHUB_COPILOT_MCP_TOKEN`                    | Gemini の GitHub MCP 接続 |
| **o3**              | `.codex`            | `OPENAI_API_KEY`                              | Web/検索支援              |
| **Linear**          | `.codex`            | `LINEAR_API_KEY`                              | Linear 課題操作           |
| **Doppler**         | `.codex`            | `DOPPLER_TOKEN`                               | Secret 管理               |
| **n8n**             | optional/manual     | `N8N_API_URL`, `N8N_API_KEY`                  | n8n ワークフロー自動化    |
| **Sentry**          | local tooling       | `ELU_SENTRY_TOKEN`                            | ELU Sentry 操作           |
| **Gemini API**      | local tooling       | `GEMINI_API_KEY`                              | Gemini API 利用           |
| **Notion**          | local tooling       | `ELU_NOTION_API_KEY`, `OYKOT_NOTION_API_KEY`  | Notion integration token  |
| **GitHub Packages** | local tooling       | `GITHUB_TOKEN`, `NODE_AUTH_TOKEN`             | npm/GitHub Packages 認証  |

### MCP環境変数の設定

`credentials/templates/mcp.env.template`に必要な環境変数が定義されています。

1Password CLIを使用する場合、以下の形式で1Passwordボールトに保存してください：

```bash
# 例: 1Password "Dev" ボールトに以下のアイテムを作成
- OpenAI / OPENAI_API_KEY
- Supabase / SUPABASE_ACCESS_TOKEN
- Supabase / SUPABASE_MCP_TOKEN
- Vercel / VERCEL_TOKEN
- Vercel / VERCEL_MCP_TOKEN
- Linear / LINEAR_API_KEY
- Doppler / DOPPLER_TOKEN
- GitHub / GITHUB_COPILOT_MCP_TOKEN
- N8N_API_URL / value
- N8N_API_KEY / value
- Sentry / ELU_SENTRY_TOKEN
- Gemini / GEMINI_API_KEY
- NOTION_SECRET / ELU_NOTION_API_KEY
- NOTION_SECRET / OYKOT_NOTION_API_KEY
- GITHUB_TOKEN / credential
```

`NODE_AUTH_TOKEN` は `GITHUB_TOKEN` と同じ 1Password 参照から生成します。
`OP_SERVICE_ACCOUNT_TOKEN` は 1Password 自身へアクセスするためのトークンなので、
このテンプレートでは管理しません。

### 従来の方法

レガシーな方法でクレデンシャルを取得する場合：

```bash
make credentials
```

## セキュリティ

- 生成されたクレデンシャルファイルは`.gitignore`に追加されています
- クレデンシャルファイルは定期的に更新してください
- 使用後は`make clean-credentials`で削除できます

## export.sh による自動クレデンシャルフィルタリング

`script/export.sh` は設定をリポジトリにエクスポートする際、自動的にクレデンシャルをフィルタリングします：

### Git個人情報のフィルタリング

`~/.gitconfig` の `[user]` セクションから以下の情報を自動でコメントアウト：

- `name`: ユーザー名
- `email`: メールアドレス
- `signingkey`: SSH署名鍵

**エクスポート後の形式**:

```gitconfig
[user]
	# name = # Configure with: git config --global user.name "Your Name"
	# email = # Configure with: git config --global user.email "your.email@example.com"
	# signingkey = # Configure with: git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

### シェル環境変数トークンのフィルタリング

`~/.zshrc` から以下のパターンに一致する環境変数を自動除外：

- `NPM_TOKEN`
- `BUNDLE_RUBYGEMS__*`
- `*_TOKEN`
- `*_SECRET`
- `*_PASSWORD`
- `*_API_KEY`
- `*_CREDENTIAL`

**推奨される管理方法**:

1. トークンを `~/.zshrc` から削除
2. `~/.zsh/configs/pre/.env.secret` に移動
3. テンプレート `~/.zsh/configs/pre/.env.secret.template` を参照

**例**:

```bash
# ~/.zsh/configs/pre/.env.secret
export NPM_TOKEN="your_npm_token_here"
export BUNDLE_RUBYGEMS__PKG__GITHUB__COM="your_github_token_here"

# Or use 1Password references:
export NPM_TOKEN="op://Dev/NPM_TOKEN/credential"
export BUNDLE_RUBYGEMS__PKG__GITHUB__COM="op://Dev/GITHUB_TOKEN/credential"
```

### インポート時の警告

`script/import.sh` を実行すると、フィルタリングされた設定ファイルがインポートされた際に警告メッセージが表示されます：

```
⚠️  注意: ~/.zshrc にトークンがなくなっています
    トークンは ~/.zsh/configs/pre/.env.secret に設定してください

⚠️  注意: ~/.gitconfig に個人情報がコメントアウトされています
    以下のコマンドで設定してください:
    git config --global user.name "Your Name"
    git config --global user.email "your.email@example.com"
    git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

## 1Password Vault 推奨構造

テンプレートが正しく動作するように、1Password の Vault "Dev" に以下の構造でアイテムを作成してください：

```
Vault: Dev
├── AWS (Login)
│   ├── AWS_ACCESS_KEY_ID: AKIA...
│   ├── AWS_SECRET_ACCESS_KEY: ...
│   └── AWS_REGION: ap-northeast-1
└── その他のクレデンシャル
    ├── OpenAI
    │   └── OPENAI_API_KEY
    ├── Supabase
    │   ├── SUPABASE_ACCESS_TOKEN
    │   └── SUPABASE_MCP_TOKEN
    ├── Vercel
    │   ├── VERCEL_TOKEN
    │   └── VERCEL_MCP_TOKEN
    ├── Linear
    │   └── LINEAR_API_KEY
    ├── Doppler
    │   └── DOPPLER_TOKEN
    └── GitHub
        └── GITHUB_COPILOT_MCP_TOKEN
```

### アイテムの作成例

```bash
# AWS クレデンシャルを作成
op item create --category=login \
  --title="AWS" \
  --vault=Dev \
  AWS_ACCESS_KEY_ID="AKIA..." \
  AWS_SECRET_ACCESS_KEY="..." \
  AWS_REGION="ap-northeast-1"

# MCP 用トークンの例
op item create --category=api_credential \
  --title="Supabase" \
  --vault=Dev \
  SUPABASE_ACCESS_TOKEN="..." \
  SUPABASE_MCP_TOKEN="..."
```

## トラブルシューティング

### 1Password CLI が利用できない

**症状**: `op: command not found`

**解決策**:

1. インストール: `brew install --cask 1password-cli`
2. サインイン: `op signin`

または手動設定:

```bash
cp credentials/templates/devcontainer.env.template ~/.devcontainer.env
# エディタで開いて op:// 参照を実際の値に置換
```

### DevContainer 起動時にエラー

**症状**: `postCreateCommand` でエラー

**解決策**:

1. スクリプトの実行権限確認: `ls -l script/setup-*.sh`
2. 手動実行でデバッグ: `zsh -x script/credentials.sh fetch`

### MCP設定を変更したい

Codex は `.codex/config.toml`、Gemini は `.gemini/settings.json` を使用します。
MCP 用の環境変数は `credentials/templates/mcp.env.template` から
`credentials/mcp.env` に展開し、実行環境に読み込ませてください。

## 関連ファイル

- `script/credentials.sh`: クレデンシャル取得スクリプト
- `.zsh/configs/pre/.env.secret.template`: シェル環境変数トークンのテンプレート
- `.claude/settings.local.json.template`: Claude Code ローカル設定のテンプレート
- `script/export.sh`: 設定エクスポートスクリプト（フィルタリング機能含む）
- `script/import.sh`: 設定インポートスクリプト（警告表示含む）
