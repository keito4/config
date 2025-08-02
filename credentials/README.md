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
