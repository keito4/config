# Claude Code Plugin Management

このディレクトリはClaude Codeのプラグイン管理設定を含みます。

## ファイル構成

### Git管理対象

- `config.json` - カスタムプラグインリポジトリの設定
- `known_marketplaces.json` - 使用するマーケットプレイスのリスト
- `README.md` - このドキュメント

### Git管理対象外（.gitignore）

- `installed_plugins.json` - インストール済みプラグインのメタデータ（環境依存）
- `marketplaces/` - マーケットプレイスからダウンロードされたプラグイン実体
- `repos/` - カスタムリポジトリのプラグイン

## プラグイン管理の仕組み

### 1. マーケットプレイスの設定

`known_marketplaces.json`でどのマーケットプレイスを使用するか定義します：

```json
{
  "claude-code-plugins": {
    "source": {
      "source": "github",
      "repo": "anthropics/claude-code"
    },
    "installLocation": "/home/vscode/.claude/plugins/marketplaces/claude-code-plugins",
    "lastUpdated": "2025-12-02T07:58:31.073Z"
  }
}
```

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

### 新しい環境でのセットアップ

1. **マーケットプレイスの追加**

   Claude Codeで以下のコマンドを実行してマーケットプレイスを追加：

   ```bash
   # 公式プラグイン
   claude marketplace add anthropics/claude-code

   # コミュニティプラグイン（例）
   claude marketplace add davila7/claude-code-templates
   claude marketplace add wshobson/agents
   ```

2. **プラグインのインストール**

   Claude Code UIまたはコマンドでプラグインをインストール：

   ```bash
   claude plugin install frontend-design@claude-code-plugins
   ```

3. **プラグインの有効化**

   `.claude/settings.local.json`に`enabledPlugins`設定を追加

### 既存環境の設定をエクスポート

現在の環境のマーケットプレイス設定を保存：

```bash
cp ~/.claude/plugins/known_marketplaces.json .claude/plugins/known_marketplaces.json
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
