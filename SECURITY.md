# セキュリティガイド

このドキュメントでは、このconfigリポジトリを安全に使用するためのガイドラインを説明します。

## 🔒 重要なセキュリティ原則

1. **認証情報をハードコード化しない**
2. **環境変数やシークレット管理ツールを使用する**
3. **最小権限の原則を適用する**
4. **定期的に認証情報をローテーションする**

## Git設定のセキュリティ

### 問題
以前のバージョンでは、`git/gitconfig`ファイルに個人情報（メールアドレス、SSH公開鍵）がハードコード化されていました。

### 解決策

#### 方法1: 環境変数を使用
```bash
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="your.email@example.com"
export GIT_COMMITTER_NAME="Your Name"
export GIT_COMMITTER_EMAIL="your.email@example.com"
```

#### 方法2: Gitコマンドで設定
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global user.signingkey "your-ssh-public-key"
```

#### 方法3: ローカル設定ファイルを使用
```bash
# ~/.gitconfig.local を作成し、git/gitconfig にincludeパスを追加
echo "[include]\n    path = ~/.gitconfig.local" >> ~/.gitconfig
```

## Docker Compose のセキュリティ

### パスワード設定

#### 問題
デフォルトパスワード「changeme」が使用されていました。

#### 解決策
環境変数でパスワードを設定：
```bash
export CODE_SERVER_PASSWORD="$(openssl rand -base64 32)"
docker-compose up
```

### SSH鍵のマウント

#### 問題
`~/.ssh`ディレクトリ全体がマウントされていました。

#### 解決策

1. **最小権限マウント**（推奨）:
```yaml
volumes:
  - ~/.ssh/id_rsa.pub:/home/coder/.ssh/id_rsa.pub:ro
  - ~/.ssh/config:/home/coder/.ssh/config:ro
```

2. **SSH Agent Forwarding**（最も安全）:
```bash
# ホストでSSHエージェントを開始
ssh-add ~/.ssh/id_rsa

# Docker Composeでエージェントフォワーディングを有効化
# docker-compose.yamlに追加:
# volumes:
#   - $SSH_AUTH_SOCK:/ssh-agent
# environment:
#   - SSH_AUTH_SOCK=/ssh-agent
```

## 環境変数の管理

### .envファイルの使用

1. `.env.example`をコピー:
```bash
cp .env.example .env
```

2. 実際の値を設定:
```bash
# .envファイルを編集
CODE_SERVER_PASSWORD="your-secure-password"
```

3. `.env`ファイルを`.gitignore`に追加することを確認

### シークレット管理ツール

本番環境では以下のツールの使用を推奨：

- **1Password CLI**: `op run -- docker-compose up`
- **HashiCorp Vault**: `vault kv get -field=password secret/myapp`
- **AWS Secrets Manager**: `aws secretsmanager get-secret-value`
- **Azure Key Vault**: `az keyvault secret show`

## ベストプラクティス

### パスワード生成
```bash
# 強力なパスワードを生成
openssl rand -base64 32
```

### 権限の確認
```bash
# SSH鍵の権限を確認
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 定期的なローテーション
- パスワード: 3ヶ月ごと
- SSH鍵: 6ヶ月ごと
- API키: 用途に応じて

## セキュリティチェックリスト

- [ ] 個人情報がハードコード化されていない
- [ ] 強力なパスワードが設定されている
- [ ] SSH鍵が適切に保護されている
- [ ] 環境変数が適切に設定されている
- [ ] `.env`ファイルが`.gitignore`に含まれている
- [ ] 最小権限の原則が適用されている

## 問題の報告

セキュリティ問題を発見した場合は、Issueを作成してください。機密性の高い問題については、プライベートチャンネルで報告してください。