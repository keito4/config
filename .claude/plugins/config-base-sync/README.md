# config-base-sync

DevContainer設定を最新の`config-base`イメージと同期し、プルリクエストを自動作成するClaude Codeプラグイン。

## 概要

このプラグインは、`ghcr.io/keito4/config-base`イメージを使用しているリポジトリ向けに、DevContainer設定の自動更新を支援します。

### 主な機能

- ✅ 最新のconfig-baseイメージバージョンを自動取得
- ✅ `.devcontainer/devcontainer.json`の完全更新（image、features、mounts等）
- ✅ 変更内容を含むプルリクエストの自動作成
- ✅ バージョン確認のみの軽量コマンド

## インストール

### このリポジトリ内での使用

このリポジトリでビルドされたDevContainerイメージには、プラグインが自動的に含まれています。

### 他のプロジェクトでの使用

```bash
# プラグインディレクトリにコピー
cp -r .claude/plugins/config-base-sync ~/.claude/plugins/
```

## 使用方法

### コマンド

#### `/config-base-sync:update`

最新のconfig-baseイメージに更新し、プルリクエストを作成します。

```
/config-base-sync:update
```

**実行内容:**

1. GitHub Releasesから最新バージョンを取得
2. `.devcontainer/devcontainer.json`を更新
3. 推奨設定（features、mounts、環境変数等）を適用
4. 変更をコミット
5. プルリクエストを作成

#### `/config-base-sync:check`

現在のバージョンと最新バージョンを確認します（更新は行いません）。

```
/config-base-sync:check
```

## 設定

プラグインの動作は`.claude/config-base-sync.local.md`で設定できます。

### デフォルト設定

```yaml
---
baseBranch: main # PRのベースブランch
autoCreatePR: true # 自動PR作成の有効化
updateScope: all # 更新範囲 (all | image-only | minimal)
---
```

### 設定例

```markdown
## <!-- .claude/config-base-sync.local.md -->

baseBranch: develop
autoCreatePR: true
updateScope: all

---

# config-base-sync 設定

カスタム設定の説明やメモをここに記載できます。
```

## 前提条件

- GitHub CLI (`gh`) がインストール・認証済み
- Git設定済み（`user.name`, `user.email`）
- リポジトリがGitHubにホストされている
- `.devcontainer/devcontainer.json`が存在する

## エラーハンドリング

プラグインは以下の場合にエラーを表示し、ユーザーにアクションを求めます：

- 既に最新バージョンの場合
- GitHub API制限に達した場合
- ローカルに未コミットの変更がある場合
- 設定ファイルに不正な値がある場合

## ライセンス

MIT
