# Claude Code Plugin Management

このディレクトリはClaude Codeのプラグイン管理設定を含みます。

## ファイル構成

### Git管理対象

- `config.json` - カスタムプラグインリポジトリの設定
- `known_marketplaces.json.template` - マーケットプレイス設定のテンプレート（環境非依存）
- `plugins.txt` - インストールするプラグインのリスト
- `README.md` - このドキュメント

### Git管理対象外（.gitignore）

- `known_marketplaces.json` - 環境固有のマーケットプレイス設定（テンプレートから自動生成）
- `installed_plugins.json` - インストール済みプラグインのメタデータ（環境依存）
- `marketplaces/` - マーケットプレイスからダウンロードされたプラグイン実体
- `repos/` - カスタムリポジトリのプラグイン

## プラグイン管理の仕組み

### 1. 環境非依存のマーケットプレイス設定

`known_marketplaces.json.template`でマーケットプレイスを定義します。`{{HOME}}`プレースホルダーを使用することで、macOS/Linux/DevContainer環境すべてで動作します：

```json
{
  "claude-code-plugins": {
    "source": {
      "source": "github",
      "repo": "anthropics/claude-code"
    },
    "installLocation": "{{HOME}}/.claude/plugins/marketplaces/claude-code-plugins"
  }
}
```

`setup-claude.sh`実行時に、テンプレートから環境固有の`known_marketplaces.json`が自動生成されます。

### 2. プラグインの有効化

`.claude/settings.local.json`（git管理対象外）でどのプラグインを有効にするか設定：

```json
{
  "enabledPlugins": {
    "frontend-design@claude-code-plugins": true,
    "feature-dev@claude-code-plugins": true
  }
}
```

## セットアップ手順

### 新しい環境でのセットアップ（推奨）

リポジトリの自動セットアップスクリプトを使用：

```bash
# すべてセットアップ（設定同期 + プラグインインストール）
make claude-setup

# または、プラグインのみインストール
make claude-plugins
```

このコマンドにより：

1. リポジトリの`plugins.txt`と`known_marketplaces.json.template`を`~/.claude/plugins/`にコピー
2. テンプレートから環境固有の`known_marketplaces.json`を生成
3. 必要なマーケットプレイスを自動追加
4. `plugins.txt`に記載されたすべてのプラグインをインストール

### 手動セットアップ

1. **マーケットプレイス設定の生成**

   ```bash
   # テンプレートから環境固有の設定を生成
   sed "s|{{HOME}}|${HOME}|g" .claude/plugins/known_marketplaces.json.template > ~/.claude/plugins/known_marketplaces.json
   ```

2. **マーケットプレイスの追加**

   ```bash
   claude plugin marketplace add anthropics/claude-plugins-official
   claude plugin marketplace add wshobson/agents
   ```

3. **プラグインのインストール**

   ```bash
   # 個別インストール
   claude plugin install commit-commands@claude-plugins-official

   # または一括インストール
   make claude-plugins
   ```

## 利用可能なマーケットプレイス

現在このリポジトリで管理されているマーケットプレイス：

- **anthropics/claude-code** - 公式Claude Codeプラグイン
- **davila7/claude-code-templates** - コミュニティテンプレート
- **wshobson/agents** - ワークフロー自動化プラグイン

## 推奨プラグイン

開発効率向上のために以下のプラグインを推奨：

- `frontend-design@claude-code-plugins` - フロントエンド設計支援
- `feature-dev@claude-code-plugins` - 機能開発サポート
- `security-guidance@claude-code-plugins` - セキュリティガイダンス
- `javascript-typescript@claude-code-workflows` - JS/TS開発ワークフロー

## Docker ビルド時のプラグインインストール

Docker イメージのビルド時にプラグインをインストールするには、BuildKit の secret 機能を使用します。

### ビルドコマンド

```bash
# ANTHROPIC_API_KEY を環境変数として設定してビルド
DOCKER_BUILDKIT=1 docker build \
  --secret id=anthropic_api_key,env=ANTHROPIC_API_KEY \
  -f .devcontainer/Dockerfile \
  -t config-base .

# または、ファイルから読み込む場合
echo "your-api-key" > /tmp/anthropic_key
DOCKER_BUILDKIT=1 docker build \
  --secret id=anthropic_api_key,src=/tmp/anthropic_key \
  -f .devcontainer/Dockerfile \
  -t config-base .
rm /tmp/anthropic_key
```

### セキュリティ

- `--secret` を使用することで、API キーがイメージレイヤーに残りません
- API キーを `--build-arg` で渡さないでください（履歴に残ります）
- ビルド後、一時ファイルは必ず削除してください

### API キーなしでビルド

API キーを指定しない場合、プラグインのインストールはスキップされます：

```bash
docker build -f .devcontainer/Dockerfile -t config-base .
```

この場合、コンテナ起動後に手動でインストールできます：

```bash
make claude-plugins
```

## トラブルシューティング

### プラグインが表示されない

1. マーケットプレイスが正しく追加されているか確認
2. Claude Codeを再起動
3. `~/.claude/plugins/installed_plugins.json`を削除して再インストール

### プラグインの更新

```bash
claude marketplace update
claude plugin update <plugin-name>@<marketplace>
```

### hookify プラグインのインポートエラー

**症状:**

```
Hookify import error: No module named 'hookify'
```

**原因:**

hookify プラグインの Python モジュール構造の問題により、絶対インポート（`from hookify.core.config_loader`）が失敗します。

**解決方法:**

`setup-claude.sh` は自動的にこの問題を修正します。手動で修正する場合：

```bash
# マーケットプレイスのhookifyプラグインにパッチを適用
cd ~/.claude/plugins/marketplaces/claude-code-plugins/plugins/hookify
find . -name "*.py" -type f -exec sed -i '' \
  -e 's/from hookify\.core/from core/g' \
  -e 's/from hookify\.utils/from utils/g' \
  -e 's/from hookify\.matchers/from matchers/g' \
  {} \;

# プラグインを再インストール
claude plugin uninstall hookify@claude-code-plugins
claude plugin install hookify@claude-code-plugins
```

**注意:** マーケットプレイスの更新後は、再度パッチの適用が必要になる場合があります。`make claude-plugins` を実行すれば自動的にパッチが適用されます。
