# quality-check

## 目的

Lint、Prettier、SCA（Static Code Analysis）等の品質ゲートをチェックし、コード品質を保証する。CIブロッカーレベルのエラーを事前に検出。

## 実行手順

1. **Lintチェック**

   ```bash
   # JavaScript/TypeScript
   npm run lint

   # Pythonの場合
   # flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
   ```

2. **コードフォーマットチェック**

   ```bash
   # Prettierチェック
   npm run format:check

   # 自動修正を実行する場合
   npm run format:fix
   ```

3. **型チェック（TypeScriptプロジェクトの場合）**

   ```bash
   npm run type-check
   ```

4. **依存関係の脆弱性チェック**

   ```bash
   npm audit
   ```

5. **ライセンスチェック**

   ```bash
   npm run license-check
   ```

6. **SAST（静的アプリケーションセキュリティテスト）**

   ```bash
   # Semgrepを使用する場合
   semgrep --config=auto
   ```

7. **統合品質レポート**
   ```bash
   npm run quality:report
   ```

## 成功基準

- ✅ Lintエラーが0件
- ✅ フォーマットの差分がない
- ✅ 型エラーが0件
- ✅ Criticalレベルの脆弱性が0件
- ✅ 禁止ライセンスの混入がない
- ✅ SASTでCriticalレベルの問題が0件

## トラブルシューティング

### Lintエラーが出る場合

1. `npm run lint -- --fix` で自動修正を試す
2. 自動修正できないエラーは手動で修正
3. ルールの無効化が必要な場合は、理由をコメントで記載

### 脆弱性が検出された場合

1. `npm audit fix` で自動修正を試す
2. 互換性の問題がある場合は `npm audit fix --force`
3. 修正できない場合は、代替パッケージを検討

### ライセンス問題が発生した場合

1. 問題のあるパッケージを特定
2. 代替パッケージを検索
3. 必要に応じてホワイトリストに追加（承認が必要）
