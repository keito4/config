# update-deps

## 目的

依存関係を最新に更新し、脆弱性をチェックする。Criticalレベルの脆弱性が0件であることを保証し、セキュリティリスクを最小化。

## 実行手順

1. **現在の依存関係の状態確認**

   ```bash
   # インストール済みパッケージの一覧
   npm list --depth=0

   # 古いパッケージの確認
   npm outdated
   ```

2. **脆弱性のチェック**

   ```bash
   # 脆弱性の詳細を確認
   npm audit

   # Criticalレベルのみ表示
   npm audit --audit-level=critical
   ```

3. **バックアップの作成**

   ```bash
   # package-lock.jsonのバックアップ
   cp package-lock.json package-lock.json.backup
   ```

4. **脆弱性の自動修正**

   ```bash
   # セキュリティ修正を実行
   npm audit fix

   # 修正結果を確認
   npm audit
   ```

5. **メジャーアップデートの検討**

   ```bash
   # メジャーアップデートが必要な場合の確認
   npm audit fix --dry-run --force

   # テスト環境での確認が必要な場合
   # npm audit fix --force
   ```

6. **通常の依存関係更新**

   ```bash
   # パッチバージョンの更新
   npm update

   # 特定のパッケージを最新に更新
   # npm install <package>@latest
   ```

7. **テストの実行**

   ```bash
   # 更新後の動作確認
   npm run test:all
   npm run build
   ```

8. **ライセンスチェック**

   ```bash
   # 禁止ライセンスの確認
   npm run license-check
   ```

9. **変更のコミット**

   ```bash
   # 変更内容を確認
   git diff package.json package-lock.json

   # コミット
   git add package.json package-lock.json
   git commit -m "chore: 依存関係を更新し脆弱性を修正"
   ```

## 成功基準

- ✅ Criticalレベルの脆弱性が0件
- ✅ Highレベルの脆弱性が最小化されている
- ✅ すべてのテストがパス
- ✅ ビルドが成功
- ✅ 禁止ライセンスが含まれていない

## トラブルシューティング

### 自動修正できない脆弱性がある場合

1. `npm ls <脆弱性のあるパッケージ>` で依存関係を確認
2. 直接依存しているパッケージを更新
3. 代替パッケージを検討
4. `npm audit fix --force` を慎重に実行（テスト必須）

### 更新後にテストが失敗する場合

1. バックアップから復元: `cp package-lock.json.backup package-lock.json`
2. `npm ci` で再インストール
3. 問題のあるパッケージを特定し、個別に更新

### ライセンス問題が発生した場合

1. 問題のあるパッケージを特定
2. ライセンス互換の代替パッケージを検索
3. 承認プロセスを経てホワイトリストに追加

### npm auditがハングする場合

1. npmキャッシュをクリア: `npm cache clean --force`
2. ネットワーク接続を確認
3. npmレジストリの状態を確認: https://status.npmjs.org/
