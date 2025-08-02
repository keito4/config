# test-all

## 目的

すべてのテストを実行し、カバレッジを確認する。TDD原則に基づき、Unit/Component/E2Eテストを網羅的に実行。

## 実行手順

1. **依存関係の確認**

   ```bash
   npm ci
   ```

2. **Unitテストの実行**

   ```bash
   npm run test:unit -- --coverage
   ```

3. **Componentテストの実行**

   ```bash
   npm run test:component -- --coverage
   ```

4. **E2Eテストの実行**

   ```bash
   npm run test:e2e
   ```

5. **統合カバレッジレポートの生成**
   ```bash
   npm run coverage:report
   ```

## 成功基準

- ✅ すべてのテストがグリーン（Pass）
- ✅ 全体の行カバレッジが70%以上
- ✅ クリティカルパスのカバレッジが100%
- ✅ カバレッジレポートが正常に生成される

## トラブルシューティング

### テストが失敗する場合

1. エラーメッセージを確認し、失敗箇所を特定
2. `npm run test:unit -- --watch` で該当テストのみ実行
3. デバッグモードで詳細を確認: `npm run test:debug`

### カバレッジが基準を満たさない場合

1. カバレッジレポートで未カバー箇所を確認
2. 優先度の高い箇所から順にテストを追加
3. `npm run coverage:html` でHTMLレポートを生成し、詳細を確認
