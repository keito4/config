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

# SSH公開鍵のパスを署名鍵として設定
git config --global user.signingkey ~/.ssh/id_ed25519.pub

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

#### npm 内蔵 undici (HIGH) — 解決済み

`npm@11.17.0` は `undici@6.26.0` を内部にバンドル（`inBundle: true`）していたため `npm audit` で HIGH 脆弱性
（GHSA-vxpw-j846-p89q, GHSA-p88m-4jfj-68fv）が検出されていましたが、`npm@11.18.0` で `undici@6.27.0`
（パッチ適用済み）にバンドルが更新され解消しました。`overrides` の `"npm": "^11.17.0"` は 11.18.0 系も許容するため、
今後 `npm install` すればこの修正が自動的に取り込まれます。

#### semantic-release 経由の npm 内蔵 tar / brace-expansion / ip-address / undici (MODERATE / HIGH) — 監視中

`semantic-release@25.0.8` は `@semantic-release/npm` 経由で npm CLI (`npm@11.19.0` 時点) を依存に持ち、npm CLI が
内部にバンドルする以下のパッケージに既知の脆弱性があります：

- GHSA-r292-9mhp-454m (tar, moderate): 細工した長いパスの tar 展開でスタックオーバーフロー DoS
- GHSA-mh99-v99m-4gvg / GHSA-rgw5-rvv9-x895 (brace-expansion, high): 非拡張の展開パターンで OOM DoS
- GHSA-mwp4-54f8-5fhr / GHSA-4xrf-jv44-h6hh / GHSA-22jq-vg5j-6vgg (ip-address, high): IPv4/IPv6 アドレス解析の
  誤判定による SSRF / 信頼境界バイパス
- GHSA-8xcm-r25x-g524 / GHSA-m8rv-5g2x-5cg5 / GHSA-v3r7-h72x-cjcm (undici, moderate): レスポンス非同期化・CRLF
  インジェクション・Cookie 属性インジェクション（2026年に新たに公開された undici の追加脆弱性。上記「解決済み」の
  undici 修正とは別件）

いずれも npm パッケージのバンドル依存 (`node_modules/npm/node_modules/*`) であり、`overrides` による上書きは
効かない（npm の bundleDependencies はトップレベル overrides の対象外。`package.json` の `overrides` に
`tar` / `brace-expansion` / `ip-address` / `undici` の安全な最小バージョンを設定済みだが、バンドル依存には
反映されないことを確認済み）。`npm audit fix --force` が提案する修正は `semantic-release@24.2.9`
（マイナーダウングレード）であり、リリースパイプラインの回帰リスクを伴うため採用しない。

- 対応: npm CLI がバンドル tar / brace-expansion / ip-address / undici を更新するまで監視・待機
  （`SECURITY.md` 更新のたびに再確認）
- 監視: `npm audit --audit-level=high` で確認（CI は `--audit-level=critical` を使用）
- 影響範囲: `semantic-release` 実行時（リリース CI ジョブ内）の npm CLI 内部処理のみ。信頼済みメンテナのみが
  トリガーするリリースワークフロー内でしか実行されず、外部入力を処理しないためプロダクションアプリ・外部公開
  面には直接影響しない

#### takt 経由の @opentelemetry/propagator-jaeger (HIGH) — 監視中

`takt@0.54.1`（TAKT ワークフロー自動化ツール, devDependencies）が依存する `@opentelemetry/sdk-node` 経由で
`@opentelemetry/propagator-jaeger@<2.9.0` に DoS 脆弱性があります：

- GHSA-45rx-2jwx-cxfr (high): 不正な形式のヘッダーによる `JaegerPropagator` の未処理例外 DoS

`npm audit fix --force` が提案する修正は `takt@0.41.0` へのメジャーダウングレードであり、TAKT の機能退行を
伴うため採用しない。

- 対応: takt が opentelemetry 依存を更新するまで監視・待機
- 影響範囲: ローカル/CI での `takt` 実行時のみ。TAKT はスケジュールされたエージェントタスクの自動化に使われる
  開発用ツールであり、外部からのネットワーク入力を受け付けるプロダクションサービスではない

#### Trivy で検出されるコンテナ脆弱性

`.trivyignore` に登録されている脆弱性は、上流ツール (Vercel CLI, Doppler CLI, GitHub CLI 等) の更新待ちです。各エントリにレビュー日付を記録しています。詳細は `.trivyignore` を参照してください。

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
