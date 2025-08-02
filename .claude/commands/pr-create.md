# pr-create

## 目的

Pull Request作成時の手順とチェックリストを提供し、Git Workflowの基準（Diff ≤ 400行、ファイル数 ≤ 25）を遵守する。

## 実行手順

1. **ブランチの確認**

   ```bash
   # ブランチ名が規約に沿っているか確認
   git branch --show-current
   # 形式: feat|fix|chore/<issue#>-slug
   ```

2. **変更内容の確認**

   ```bash
   # 変更ファイル数の確認
   git diff --name-only origin/master | wc -l

   # 変更行数の確認
   git diff --shortstat origin/master

   # ファイルごとの変更行数
   git diff --stat origin/master
   ```

3. **コミットメッセージの確認**

   ```bash
   # Conventional Commitsに沿っているか確認
   git log --oneline origin/master..HEAD
   ```

4. **品質チェックの実行**

   ```bash
   # テストと品質チェックを実行
   npm run test:all
   npm run quality:check
   ```

5. **PR作成前の最終チェック**

   ```bash
   # チェックリストを確認
   echo "☑︎ 変更ファイル数が25以下"
   echo "☑︎ 各ファイルの変更行数が400行以下"
   echo "☑︎ Issueがリンクされている"
   echo "☑︎ すべてのテストがパス"
   echo "☑︎ Lintエラーが0件"
   echo "☑︎ コミットメッセージがConventional Commitsに沿っている"
   ```

6. **PRの作成**
   ```bash
   # GitHub CLIを使用してPRを作成
   gh pr create --title "feat: <機能の説明>" \
                --body "Closes #<issue-number>\n\n## 概要\n<変更内容の説明>\n\n## 変更内容\n- [ ] <変更点1>\n- [ ] <変更点2>\n\n## テスト\n- [ ] Unitテスト追加/更新\n- [ ] E2Eテスト確認\n- [ ] カバレッジ70%以上" \
                --assignee @me
   ```

## 成功基準

- ✅ 変更ファイル数が25以下
- ✅ 各ファイルの変更行数が400行以下
- ✅ Issueがリンクされている
- ✅ すべてのテストがグリーン
- ✅ 品質ゲートをパス
- ✅ PRが正常に作成される

## トラブルシューティング

### 変更が大きすぎる場合

1. 機能を分割し、複数のPRに分ける
2. リファクタリングと機能追加を別PRにする
3. 大きなファイルを小さなモジュールに分割

### Issueがリンクされない場合

1. `gh issue create` でIssueを作成
2. PRタイトルまたは本文に `Closes #<issue-number>` を追加

### テストが失敗する場合

1. `npm run test:all` で詳細を確認
2. 失敗しているテストを修正
3. テストが不足している場合は追加
