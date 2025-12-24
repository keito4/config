# Credentials Management

このディレクトリは1Passwordを使用した機密情報管理のためのテンプレートとスクリプトを含みます。

## 構造

```
credentials/
├── README.md              # このファイル
├── setup.md              # 詳細なセットアップガイド
├── templates/             # 各種サービスのテンプレート
│   ├── aws.env.template   # AWS認証情報用テンプレート
│   └── simple.env.template # 汎用環境変数テンプレート
└── .gitignore            # 生成されたファイルを無視
```

## 使用方法

1. 1Password CLIがインストールされていることを確認

   ```bash
   brew install --cask 1password-cli
   ```

2. 1Passwordにサインイン

   ```bash
   op signin
   ```

3. クレデンシャルを取得
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

## 関連ファイル

- `.zsh/configs/pre/.env.secret.template`: シェル環境変数トークンのテンプレート
- `.claude/settings.local.json.template`: Claude Code ローカル設定のテンプレート
- `script/export.sh`: 設定エクスポートスクリプト（フィルタリング機能含む）
- `script/import.sh`: 設定インポートスクリプト（警告表示含む）
