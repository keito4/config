# 1Password Credential Setup Guide

## 前提条件

1. 1Password CLIのインストール

   ```bash
   brew install --cask 1password-cli
   ```

2. 1Passwordアカウントへのサインイン
   ```bash
   op signin
   ```

## 1Passwordでの設定

### Vault構造の推奨

1. `Dev` Vaultを作成（開発用クレデンシャル）
2. 各サービスごとにアイテムを作成

### アイテムの作成例

#### AWS

- アイテム名: `AWS`
- フィールド:
  - `AWS_ACCESS_KEY_ID`: アクセスキーID
  - `AWS_SECRET_ACCESS_KEY`: シークレットアクセスキー
  - `AWS_REGION`: デフォルトリージョン

#### その他のクレデンシャル

- アイテム名: `OpenAI`
- フィールド:
  - `OPENAI_API_KEY`: Codex o3 MCP 用

- アイテム名: `Supabase`
- フィールド:
  - `SUPABASE_ACCESS_TOKEN`: Codex Supabase MCP 用
  - `SUPABASE_MCP_TOKEN`: Gemini Supabase MCP 用

- アイテム名: `Vercel`
- フィールド:
  - `VERCEL_TOKEN`: Codex Vercel MCP 用
  - `VERCEL_MCP_TOKEN`: Gemini Vercel MCP 用

- アイテム名: `Linear`
- フィールド:
  - `LINEAR_API_KEY`: Codex Linear MCP 用

- アイテム名: `Doppler`
- フィールド:
  - `DOPPLER_TOKEN`: Codex Doppler MCP 用

- アイテム名: `GitHub`
- フィールド:
  - `GITHUB_COPILOT_MCP_TOKEN`: Gemini GitHub MCP 用

- アイテム名: `N8N_API_URL`, `N8N_API_KEY`
- フィールド:
  - `value`: optional n8n MCP 用

## 使用方法

### 初回セットアップ

```bash
# クレデンシャルテンプレートの一覧表示
make list-credentials

# すべてのクレデンシャルを取得
make credentials
```

### 日常的な使用

```bash
# クレデンシャルの更新
make credentials

# クレデンシャルのクリーンアップ
make clean-credentials
```

### zshrcでの自動読み込み

`.zshrc`に以下を追加することで、自動的にクレデンシャルを読み込めます：

```bash
# Load credentials if available
for env_file in ~/.config/credentials/*.env; do
    if [[ -f "$env_file" ]]; then
        source "$env_file"
    fi
done
```

## セキュリティのベストプラクティス

1. **定期的な更新**: クレデンシャルは定期的に`make credentials`で更新
2. **使用後のクリーンアップ**: 不要になったら`make clean-credentials`
3. **Gitignore**: 生成されたファイルは自動的に無視される
4. **権限管理**: 生成されたファイルは600権限で作成される

## トラブルシューティング

### op: command not found

```bash
brew install --cask 1password-cli
```

### Not signed in to 1Password

```bash
op signin
```

### Template not found

テンプレートファイルが`credentials/templates/`に存在することを確認

### Permission denied

```bash
chmod +x script/credentials.sh
```

### Debug provider injection

`script/credentials.sh` は zsh スクリプトです。shell trace が必要な場合は
`bash -x` ではなく以下を使います。

```bash
zsh -x script/credentials.sh fetch
```
