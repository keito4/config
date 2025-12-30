# Credentials Management

このディレクトリは1Passwordを使用した機密情報管理のためのテンプレートとスクリプトを含みます。

## 構造

```
credentials/
├── README.md                        # このファイル
├── setup.md                         # 詳細なセットアップガイド
├── templates/                       # 各種サービスのテンプレート
│   ├── aws.env.template             # AWS認証情報用テンプレート
│   ├── simple.env.template          # 汎用環境変数テンプレート
│   ├── devcontainer.env.template    # DevContainer環境変数用（新規）
│   └── mcp.env.template             # MCP設定用（新規）
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
   bash script/setup-env.sh
   ```

   このスクリプトは以下を自動生成します：
   - `~/.devcontainer.env` - DevContainer 環境変数
   - `credentials/mcp.env` - MCP 設定用環境変数

4. **MCP 設定を生成**

   ```bash
   bash script/setup-mcp.sh
   ```

   `.mcp.json` が自動生成されます。

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
	# signingkey = # Configure with: git config --global user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"
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
    git config --global user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"
```

## 1Password Vault 推奨構造

テンプレートが正しく動作するように、1Password の Vault "Dev" に以下の構造でアイテムを作成してください：

```
Vault: Dev
├── OPENAI_API_KEY (Login)
│   └── value: sk-proj-...
├── AWS (Login)
│   ├── AWS_ACCESS_KEY_ID: AKIA...
│   ├── AWS_SECRET_ACCESS_KEY: ...
│   └── AWS_REGION: ap-northeast-1
└── その他のクレデンシャル
```

### アイテムの作成例

```bash
# OpenAI API Key を作成
op item create --category=login \
  --title="OPENAI_API_KEY" \
  --vault=Dev \
  value="sk-proj-your-api-key-here"

# AWS クレデンシャルを作成
op item create --category=login \
  --title="AWS" \
  --vault=Dev \
  AWS_ACCESS_KEY_ID="AKIA..." \
  AWS_SECRET_ACCESS_KEY="..." \
  AWS_REGION="ap-northeast-1"
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
2. 手動実行でデバッグ: `bash -x script/setup-env.sh`

### .mcp.json が生成されない

**症状**: `envsubst: command not found` または空の OPENAI_API_KEY

**解決策**:

1. `envsubst` インストール:
   ```bash
   brew install gettext
   brew link --force gettext
   ```
2. `credentials/mcp.env` が正しく生成されているか確認:
   ```bash
   cat credentials/mcp.env
   ```

## 関連ファイル

- `.mcp.json.template`: MCP 設定テンプレート（環境変数参照）
- `script/setup-env.sh`: 環境変数自動セットアップスクリプト
- `script/setup-mcp.sh`: MCP 設定自動生成スクリプト
- `.zsh/configs/pre/.env.secret.template`: シェル環境変数トークンのテンプレート
- `.claude/settings.local.json.template`: Claude Code ローカル設定のテンプレート
- `script/export.sh`: 設定エクスポートスクリプト（フィルタリング機能含む）
- `script/import.sh`: 設定インポートスクリプト（警告表示含む）
