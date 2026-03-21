# Doppler セットアップガイド

Doppler を使ったシークレット管理の構成ガイド。
チーム共通の `dev` と個人用の `dev_personal` を使い分ける運用を推奨する。

## 構成概要

```
Doppler Project: my-app
├── dev              # チーム共通の開発用シークレット
├── dev_personal     # 各開発者の個人差分（Personal Config）
├── stg              # ステージング（CI/CD token で取得）
└── prd              # 本番（CI/CD token で取得）
```

### 各 config の役割

| Config         | 用途                                                 | アクセス      |
| -------------- | ---------------------------------------------------- | ------------- |
| `dev`          | チーム共通の開発用値（共通 DB URL、共通 API key 等） | 開発者全員    |
| `dev_personal` | 個人差分（個人 sandbox API key、個人 DB 名等）       | 本人のみ      |
| `stg`          | ステージング環境                                     | Service Token |
| `prd`          | 本番環境                                             | Service Token |

> `dev_personal` は Doppler の **Personal Config** 機能で自動作成される。
> `dev` の branch config として扱われ、`dev` の値を継承しつつ個人差分だけ override できる。

## セットアップ手順

### 1. Doppler CLI のインストール

DevContainer 環境では Dockerfile に組み込み済み。ローカルの場合：

```bash
# macOS
brew install dopplerhq/cli/doppler

# Linux
curl -sLf --retry 3 --tlsv1.2 --proto "=https" \
  'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" \
  | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install -y doppler
```

### 2. ログインとプロジェクト設定

```bash
# ログイン（ブラウザが開く）
doppler login

# プロジェクトを選択（対話式）
doppler setup
```

`doppler setup` を実行すると、カレントディレクトリに `.doppler.yaml` が生成される。

### 3. Personal Config の有効化

Doppler Dashboard で以下を設定：

1. プロジェクトの **Settings** → **Personal Configs** を有効化
2. `dev` 環境で **Personal Config** が利用可能になる
3. 各開発者が初回アクセス時に `dev_personal` が自動作成される

### 4. 開発サーバーの起動

```bash
# dev_personal を使って起動（個人差分が dev を override）
doppler run --config dev_personal -- pnpm dev

# チーム共通の dev で起動
doppler run --config dev -- pnpm dev

# doppler.yaml で default config が設定されている場合
doppler run -- pnpm dev
```

## doppler.yaml テンプレート

プロジェクトルートに配置：

```yaml
setup:
  project: my-app
  config: dev_personal
```

> `config: dev_personal` をデフォルトにすることで、`doppler run` だけで個人設定が使われる。

## package.json の推奨 scripts

```json
{
  "scripts": {
    "dev": "next dev",
    "dev:doppler": "doppler run -- pnpm dev",
    "dev:doppler:shared": "doppler run --config dev -- pnpm dev"
  }
}
```

## DevContainer での統合

### containerEnv で Doppler を使う

`.devcontainer/devcontainer.json`:

```json
{
  "containerEnv": {
    "DOPPLER_TOKEN": "${localEnv:DOPPLER_TOKEN}"
  },
  "postStartCommand": "doppler setup --no-interactive || true"
}
```

> `DOPPLER_TOKEN` はホストマシンの環境変数から注入。
> Service Token（`dp.st.*`）または Personal Token（`dp.pt.*`）を設定する。

### GitHub Actions での統合

```yaml
- name: Fetch secrets from Doppler
  uses: dopplerhq/secrets-fetch-action@v2
  with:
    doppler-token: ${{ secrets.DOPPLER_TOKEN }}
    doppler-project: my-app
    doppler-config: stg
```

## 運用ルール

### 値の配置ルール

| 値の種類                     | 配置先         | 例                           |
| ---------------------------- | -------------- | ---------------------------- |
| チーム共通の接続先           | `dev`          | `DATABASE_URL`, `REDIS_URL`  |
| 共通 API キー                | `dev`          | `STRIPE_TEST_KEY`            |
| 個人 sandbox の API key      | `dev_personal` | `MY_SANDBOX_API_KEY`         |
| 個人 DB 名                   | `dev_personal` | `DATABASE_NAME=dev_alice`    |
| 個人 ngrok URL               | `dev_personal` | `WEBHOOK_URL`                |
| ステージング・本番の認証情報 | `stg` / `prd`  | `DATABASE_URL`, `SECRET_KEY` |

### NG パターン

- `.env` ファイルにシークレットを直接記述（Doppler に移行する）
- `DOPPLER_CONFIG` を direnv や `.zshrc` でハードコードする（`doppler.yaml` に任せる）
- Personal Token を CI/CD で使う（Service Token を使う）

## トラブルシューティング

### `dev_personal` ではなく `dev` が読まれる

```bash
# 設定の優先順位を確認
doppler configure debug

# シェルに DOPPLER_CONFIG が残っていないか確認
env | grep DOPPLER
```

`DOPPLER_CONFIG` や `--config` は `doppler.yaml` より優先される。

### Personal Config が表示されない

1. Doppler Dashboard でプロジェクトの **Personal Configs** が有効か確認
2. `dev` 環境への書き込み権限があるか確認
3. `doppler configs` で利用可能な config を一覧表示

### DevContainer でログインが必要になる

DevContainer 内では `DOPPLER_TOKEN` 環境変数で認証するのが推奨。
ブラウザ認証は使えないため、Personal Token または Service Token を使う：

```bash
# Personal Token を生成（Doppler Dashboard → Access → Personal Tokens）
export DOPPLER_TOKEN=dp.pt.xxxxx
```

## 既存の 1Password 管理からの移行

このリポジトリでは `script/setup-env.sh` + 1Password CLI でシークレットを管理しているが、
プロジェクトごとに Doppler に移行する場合の手順：

1. 1Password のシークレットを Doppler の `dev` config にインポート
2. 個人差分を `dev_personal` に移動
3. `doppler.yaml` をプロジェクトルートに配置
4. `package.json` に `dev:doppler` スクリプトを追加
5. CI/CD の `secrets` を Doppler の Service Token に置き換え

> 1Password と Doppler は併用可能。1Password は長期保管の認証情報、
> Doppler はアプリケーション実行時のシークレット注入という使い分けが有効。

## 参考リンク

- [Doppler CLI ドキュメント](https://docs.doppler.com/docs/install-cli)
- [Personal Configs](https://docs.doppler.com/docs/personal-configs)
- [Service Tokens](https://docs.doppler.com/docs/service-tokens)
- [GitHub Actions 統合](https://docs.doppler.com/docs/github-actions)
- [DevContainer 統合](https://docs.doppler.com/docs/docker)
