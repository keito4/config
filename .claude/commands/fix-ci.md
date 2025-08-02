# fix-ci

## 目的

CI失敗時の対応手順を提供し、24時間以内修正ルールを遵守する。CI Red → Slack #ci-alerts → 24h以内修正 or Owner Escalateのフローを実行。

## 実行手順

1. **CIエラーの特定**

   ```bash
   # GitHub Actionsのログを確認
   gh run list --limit 5
   gh run view <run-id>

   # 失敗したジョブの詳細を確認
   gh run view <run-id> --log-failed
   ```

2. **エラータイプの分類**

   ```bash
   echo "エラータイプを確認:"
   echo "1. テスト失敗"
   echo "2. Lintエラー"
   echo "3. ビルドエラー"
   echo "4. セキュリティ/脆弱性"
   echo "5. デプロイ失敗"
   ```

3. **ローカルでの再現**

   ```bash
   # CI環境と同じコマンドを実行
   npm ci
   npm run test:all
   npm run quality:check
   npm run build
   ```

4. **修正の実施**

   ### テスト失敗の場合

   ```bash
   # 失敗したテストを特定
   npm run test -- --verbose
   # 修正後、再度テスト
   npm run test -- --watch
   ```

   ### Lintエラーの場合

   ```bash
   # 自動修正を試す
   npm run lint -- --fix
   npm run format:fix
   ```

   ### ビルドエラーの場合

   ```bash
   # キャッシュをクリア
   rm -rf node_modules package-lock.json
   npm install
   npm run build
   ```

   ### セキュリティ問題の場合

   ```bash
   # 脆弱性を修正
   npm audit fix
   # 強制的に修正（注意が必要）
   npm audit fix --force
   ```

5. **修正の確認とプッシュ**

   ```bash
   # ローカルでCIと同じチェックを実行
   npm run ci:check

   # 修正をコミット
   git add .
   git commit -m "fix: CIエラーを修正 (#<issue-number>)"

   # プッシュ
   git push
   ```

6. **CIの再実行を確認**

   ```bash
   # CIがグリーンになるまでモニタリング
   gh run watch
   ```

7. **対応完了の報告**
   ```bash
   # Slack #ci-alertsへの報告テンプレート
   echo "CI修正完了報告:"
   echo "- エラー: <エラー内容>"
   echo "- 原因: <原因>"
   echo "- 対応: <対応内容>"
   echo "- PR: #<PR番号>"
   ```

## 成功基準

- ✅ CIがグリーンになる
- ✅ 24時間以内に修正完了
- ✅ Slack #ci-alertsに報告済み
- ✅ 根本原因が特定され、再発防止策が実施される

## トラブルシューティング

### 24時間以内に修正できない場合

1. Ownerにエスカレーション
2. 一時的なワークアラウンドを検討
3. RevertしてCIをグリーンにし、後日修正

### ローカルで再現しない場合

1. CI環境との差分を確認（Nodeバージョン、環境変数等）
2. DockerでCI環境を再現
3. CIのキャッシュをクリア

### 繰り返しCIが失敗する場合

1. Flakyテストの可能性を確認
2. テストの安定性を改善（タイムアウト設定、非同期処理の改善）
3. CIパイプラインのリトライ設定を追加
