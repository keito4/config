# Coverage Comment Action

カバレッジレポートをPRコメントとして自動投稿するGitHub Composite Actionです。

## 機能

- Jest/Istanbul の `coverage-summary.json` からカバレッジ情報を読み取り
- マークダウンテーブル形式で整形して表示
- 既存のカバレッジコメントを更新（重複投稿を防止）
- モノレポ環境で複数パッケージのカバレッジをサポート
- カバレッジ率に応じた絵文字表示（80%以上: ✅、60-80%: ⚠️、60%未満: ❌）

## 使用方法

### 基本的な使い方

`.github/workflows/ci.yml` の test job に以下のステップを追加します:

```yaml
- name: Run tests with coverage
  run: npm run test:coverage

- name: Post Coverage Comment
  if: github.event_name == 'pull_request'
  uses: ./.github/actions/coverage-comment
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### モノレポでの使用例

複数のパッケージがある場合:

```yaml
- name: Post Coverage Comment
  if: github.event_name == 'pull_request'
  uses: ./.github/actions/coverage-comment
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    coverage-path: 'packages/package1/coverage/coverage-summary.json,packages/package2/coverage/coverage-summary.json'
```

## 入力パラメータ

| パラメータ      | 必須 | デフォルト値                     | 説明                                                                  |
| --------------- | ---- | -------------------------------- | --------------------------------------------------------------------- |
| `github-token`  | Yes  | -                                | GitHub API アクセス用トークン（通常は `${{ secrets.GITHUB_TOKEN }}`） |
| `coverage-path` | No   | `coverage/coverage-summary.json` | カバレッジファイルのパス（カンマ区切りで複数指定可）                  |

## カバレッジファイルの生成

このアクションは Jest/Istanbul の `coverage-summary.json` ファイルを使用します。以下の設定が必要です:

### package.json

```json
{
  "scripts": {
    "test:coverage": "jest --coverage"
  }
}
```

### jest.config.js

```javascript
module.exports = {
  coverageReporters: ['json-summary', 'text', 'lcov'],
  // その他の設定...
};
```

## 出力例

```markdown
## Test Coverage Report

| Category      | Coverage | Covered | Total |
| ------------- | -------- | ------- | ----- |
| ✅ Statements | 85.50%   | 342     | 400   |
| ⚠️ Branches   | 75.20%   | 188     | 250   |
| ✅ Functions  | 82.00%   | 82      | 100   |
| ✅ Lines      | 86.30%   | 345     | 400   |

---

_Updated: 2026-01-02T17:00:00.000Z_
```

## 統合手順

1. このアクションは既に `.github/actions/coverage-comment/` に配置されています
2. `.github/workflows/ci.yml` の `test` job に上記の使用例を参考にステップを追加してください
3. カバレッジレポートが生成されるようテスト実行コマンドを確認してください

## 注意事項

- このアクションは `pull_request` イベントでのみ動作します
- カバレッジファイルが存在しない場合はスキップされます
- Bot ユーザーとして投稿されたコメントを自動的に検索・更新します
- 複数のカバレッジファイルを指定する場合、パッケージ名が自動的に表示されます

## トラブルシューティング

### コメントが投稿されない

- `github.event_name == 'pull_request'` の条件を確認
- カバレッジファイルのパスが正しいか確認
- ワークフローログでエラーメッセージを確認

### カバレッジデータが表示されない

- Jest の設定で `json-summary` レポーターが有効か確認
- `coverage/coverage-summary.json` ファイルが生成されているか確認
- ファイルの JSON 形式が正しいか確認

## ライセンス

このアクションは MIT ライセンスの下で提供されています。
