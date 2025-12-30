# Issue #003: Node.jsバージョンの統一

## 優先度

🟡 **中 (Quick Win)**

## 現状

### 環境ごとのバージョン差異

```yaml
DevContainer (.devcontainer/Dockerfile):
  Node.js: v20.x
  状態: 古いバージョン

CI Pipeline (.github/workflows/ci.yml, update-libraries.yml):
  Node.js: v22
  状態: 最新推奨バージョン

semantic-release v25.0.2 要件:
  必須: ^22.14.0 || >= 24.10.0
  影響: 警告メッセージが出力（機能は動作）
```

## 問題の詳細

### 現在の影響

1. **警告メッセージ**: DevContainerでsemantic-releaseを実行すると警告
2. **環境の不一致**: ローカル開発とCI環境の差異
3. **将来のリスク**: 破壊的変更時の移行コスト増加
4. **開発者体験**: 環境間の動作差異による混乱

### 潜在的な問題

- CI通過してもローカルで失敗（またはその逆）
- Node.js v22+の新機能が使えない
- semantic-releaseの新バージョンへの移行困難

## 実装計画

### Step 1: DevContainerのDockerfile更新（2時間）

```dockerfile
# .devcontainer/Dockerfile

# Before
FROM mcr.microsoft.com/devcontainers/base:ubuntu
# Node.js 20がインストールされている

# After
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Node.js 22のインストール
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# バージョン確認
RUN node --version && npm --version
```

### Step 2: ローカルテストと検証（3時間）

```bash
# 1. DevContainerのリビルド
# VS Code: Cmd+Shift+P → "Dev Containers: Rebuild Container"

# 2. Node.jsバージョン確認
node --version  # v22.x.x であることを確認

# 3. 依存関係の再インストール
npm clean-install

# 4. すべてのスクリプトのテスト
npm run lint
npm run format:check
npm test
npm run update:libs

# 5. semantic-release動作確認
npx semantic-release --dry-run
```

### Step 3: ドキュメント更新（1時間）

```markdown
# README.md

## 環境要件

- Node.js: v22.14.0以上（推奨: v22.x LTS）
- npm: v10.x以上

## DevContainer

このプロジェクトはDevContainerをサポートしています：

- Node.js v22
- すべての開発ツールがプリインストール済み
- VS Code拡張機能の自動インストール

## 互換性ノート（更新前）

~~現在のsemantic-release (v25.0.2) はNode.js ^22.14.0 || >= 24.10.0を要求しますが、
DevContainerではNode.js v20.xを使用しています。これは警告を生成しますが、
動作は継続します。将来のバージョンでNode.js v22に統一予定です。~~

✅ **2025-01現在**: すべての環境でNode.js v22を使用しています。
```

### Step 4: チーム通知とドキュメント（30分）

````markdown
# .devcontainer/README.md に追加

## Node.js バージョン更新 (2025-01)

DevContainerのNode.jsをv20からv22にアップグレードしました。

### 既存のDevContainerを使用している場合

1. コンテナをリビルドしてください：
   - VS Code: Cmd+Shift+P → "Dev Containers: Rebuild Container"

2. 依存関係を再インストール：
   ```bash
   npm clean-install
   ```
````

3. 動作確認：
   ```bash
   npm test
   npm run lint
   ```

### 破壊的変更

なし。Node.js v22はv20との高い互換性を保っています。

````

## タスクリスト

- [ ] .devcontainer/DockerfileをNode.js v22に更新
- [ ] DevContainerイメージのリビルドとテスト
- [ ] すべてのnpm scriptの動作確認
  - [ ] `npm run lint`
  - [ ] `npm run format:check`
  - [ ] `npm test`
  - [ ] `npm run update:libs`
- [ ] semantic-releaseの警告が消えることを確認
- [ ] README.mdの互換性ノートを更新
- [ ] .devcontainer/README.mdに移行ガイド追加
- [ ] チームに通知（該当する場合）
- [ ] DevContainerイメージの再ビルド（docker-image.yml）

## 成功基準

- [ ] DevContainerでNode.js v22が動作
- [ ] CI環境とローカル環境のNode.jsバージョンが一致
- [ ] semantic-releaseの警告が出ない
- [ ] すべてのCI/CDパイプラインが通過
- [ ] ドキュメントが更新済み

## 検証チェックリスト

### DevContainer内での確認
```bash
# Node.jsバージョン
node --version
# 期待値: v22.14.0 以上

# npmバージョン
npm --version
# 期待値: v10.x 以上

# semantic-releaseの警告チェック
npx semantic-release --dry-run 2>&1 | grep -i warning
# 期待値: Node.js関連の警告なし

# すべてのテストが通過
npm test
# 期待値: All tests passed

# lintが通過
npm run lint
# 期待値: No errors
````

### CIパイプラインの確認

- [ ] `.github/workflows/ci.yml` が通過
- [ ] `.github/workflows/update-libraries.yml` が通過
- [ ] `.github/workflows/docker-image.yml` が通過

## ROI計算

**投資**

- Dockerfile更新: 2時間
- テストと検証: 3時間
- ドキュメント更新: 1.5時間
- **合計**: 6.5時間 × $150/h = $975

**リターン**

- 警告メッセージ解消: 開発者体験向上
- 環境の一貫性: デバッグ時間削減 1時間/月
- 将来の移行コスト削減: $500-1,000/年
- **年間節約**: 12時間 × $150 + $500-1,000 = $2,300-2,800
- **ROI**: 136-187% (初年度)

## リスク評価

### 低リスク ✅

- Node.js v20からv22は安定した移行パス
- 破壊的変更はほぼなし
- 既存のCI環境はすでにv22を使用中

### 軽減策

- [ ] DevContainerを別ブランチで先行テスト
- [ ] 問題発生時のロールバック手順を準備
- [ ] チームメンバーに事前通知

## ロールバック手順

問題が発生した場合：

```dockerfile
# .devcontainer/Dockerfile を元に戻す
FROM mcr.microsoft.com/devcontainers/base:ubuntu
# Node.js 20に戻す（ベースイメージのデフォルト）
```

```bash
# コンテナを再ビルド
# VS Code: Cmd+Shift+P → "Dev Containers: Rebuild Container"
```

## 関連ファイル

- `.devcontainer/Dockerfile` - 主要な変更対象
- `.devcontainer/README.md` - ドキュメント追加
- `README.md` - 互換性ノート更新
- `.github/workflows/ci.yml` - 既にv22使用中（変更不要）
- `.github/workflows/update-libraries.yml` - 既にv22使用中（変更不要）
- `package.json` - engines フィールド追加推奨

## 追加の改善提案

### package.jsonにenginesフィールドを追加

```json
{
  "engines": {
    "node": ">=22.14.0",
    "npm": ">=10.0.0"
  }
}
```

これにより、誤ったNode.jsバージョンでの実行を防止できます。

## 参考リンク

- [Node.js v22 Release Notes](https://nodejs.org/en/blog/release/v22.0.0)
- [semantic-release Node.js Requirements](https://github.com/semantic-release/semantic-release#node-version-requirement)
- [DevContainers Node.js Images](https://github.com/devcontainers/images/tree/main/src/javascript-node)
