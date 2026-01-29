# セキュリティガイド

このドキュメントは、リポジトリのセキュアな設定方法について説明します。

## Git設定のセキュア化

### 1. 個人情報の設定

ハードコードされた個人情報を避け、以下のコマンドで安全に設定してください：

```bash
# ユーザー名の設定
git config --global user.name "Your Name"

# メールアドレスの設定
git config --global user.email "your.email@example.com"
```

### 2. SSH署名鍵の設定

SSH鍵をgitconfigに直接記載せず、以下の方法で設定してください：

```bash
# SSH鍵を生成（まだ持っていない場合）
ssh-keygen -t ed25519 -C "your.email@example.com"

# 公開鍵を署名鍵として設定
git config --global user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"

# GPG形式の署名を使用する場合
# git config --global user.signingkey YOUR_GPG_KEY_ID
```

### 3. コミット署名の有効化

```bash
# SSH鍵でコミットに署名する
git config --global commit.gpgsign true
git config --global gpg.format ssh
```

## 認証情報管理

### 1Password CLI の使用

このリポジトリでは `script/credentials.sh` を使用して、1Password CLIから安全に認証情報を取得できます：

```bash
# 認証情報をフェッチ
./script/credentials.sh fetch

# 利用可能なテンプレートを表示
./script/credentials.sh list

# 認証情報をクリーンアップ
./script/credentials.sh clean
```

### 環境変数テンプレート

`credentials/templates/` ディレクトリには、機密情報用のテンプレートファイルが含まれています。これらのファイルは1Password CLIの `op inject` コマンドで処理されます。

## セキュリティベストプラクティス

### DO ✅

- 環境変数やシークレット管理ツールを使用
- SSH鍵は適切な権限（600）で保護
- 強力で一意なパスワードを使用
- 定期的な認証情報のローテーション
- `.gitignore` で機密ファイルを除外

### DON'T ❌

- リポジトリに平文の認証情報をコミット
- デフォルトパスワードの使用
- SSH鍵の直接埋め込み
- 個人情報のハードコード
- 機密情報の共有コミット

## トラブルシューティング

### 依存関係の脆弱性

`semantic-release` が内部で利用する `@semantic-release/npm` は `npm` を依存として含みます。現時点の `npm` 最新版 (11.8.0) は `tar` の修正済みバージョンを含んでおらず、`npm audit` で高リスクが表示されることがあります。これは上流の更新待ちです。

- 対応: `npm` のリリース更新を確認し、修正版が出たら依存関係を更新
- 回避策: 当面は `npm audit` の警告を記録し、CIの動作に影響しないことを確認

### Git設定の確認

```bash
# 現在の設定を確認
git config --global --list

# 特定の設定を確認
git config --global user.name
git config --global user.email
git config --global user.signingkey
```

### 署名の確認

```bash
# 署名付きコミットをテスト
git commit --allow-empty -m "Test signed commit"

# 署名を確認
git log --show-signature -1
```

## サポート

設定に問題がある場合は、以下を確認してください：

1. SSH鍵が正しく生成されているか
2. Git設定が正しく設定されているか
3. 1Password CLIが正しくインストール・認証されているか

詳細については、リポジトリのREADMEまたはissueを参照してください。
