# Issue #001: テストカバレッジ不足の解消

## 優先度

🔴 **クリティカル**

## 現状

- **現在のカバレッジ**: 0% (statements/branches/functions/lines)
- **目標カバレッジ**: 70% (jest.config.js で定義)
- **既存テスト**: 2ファイル、35テストケース（設定ファイル検証のみ）

## 問題の詳細

### 未テストの重要コード

1. `script/import.sh` (130行) - 環境セットアップロジック
2. `script/export.sh` (105行) - 設定エクスポートロジック
3. `script/update-libraries.sh` (52行) - 依存関係更新ロジック
4. `commitlint.config.js` (53行) - カスタムルールロジック
5. 全15シェルスクリプト - 統合テストなし

### 影響

- **本番バグ発見率**: リリース後週1-2件の問題報告が想定される
- **手動テスト時間**: 2-3時間/変更（macOS, Linux, DevContainer環境）
- **緊急修正コスト**: 4時間/件
- **月次影響**: 8-10時間の無駄
- **年間コスト**: 14,400-18,000ドル

## 実装計画

### フェーズ1: JavaScriptコードのユニットテスト（Week 1-2）

```javascript
// test/commitlint.test.js
const { execSync } = require('child_process');
const commitlint = require('../commitlint.config.js');

describe('Release type validation', () => {
  test('allows non-release types for non-sensitive files', () => {
    // モック: package.json以外のファイル
    jest.spyOn(commitlint, 'getStagedFiles').mockReturnValue(['README.md']);

    const result = commitlint.rules['codex-release-type'][0]({ type: 'chore' });
    expect(result[0]).toBe(true);
  });

  test('enforces release types for package.json changes', () => {
    // モック: package.jsonを含む
    jest.spyOn(commitlint, 'getStagedFiles').mockReturnValue(['package.json']);

    const result = commitlint.rules['codex-release-type'][0]({ type: 'chore' });
    expect(result[0]).toBe(false);
    expect(result[1]).toContain('release-triggering type');
  });

  test('accepts feat type for package.json changes', () => {
    jest.spyOn(commitlint, 'getStagedFiles').mockReturnValue(['package.json']);

    const result = commitlint.rules['codex-release-type'][0]({ type: 'feat' });
    expect(result[0]).toBe(true);
  });
});
```

### フェーズ2: シェルスクリプトの統合テスト（Week 3-4）

```bash
# test/integration/import.bats
#!/usr/bin/env bats

setup() {
  export REPO_PATH="$(mktemp -d)"
  mkdir -p "$REPO_PATH"/{.claude,brew,git,npm,dot}
}

teardown() {
  rm -rf "$REPO_PATH"
}

@test "import.sh handles missing REPO_PATH gracefully" {
  unset REPO_PATH
  run bash script/import.sh
  [ "$status" -eq 0 ]
}

@test "import.sh creates necessary directories" {
  run bash script/import.sh
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude" ]
}

@test "import.sh copies Claude settings correctly" {
  echo '{"test": true}' > "$REPO_PATH/.claude/settings.json"

  run bash script/import.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.claude/settings.json" ]
}
```

### フェーズ3: エンドツーエンドテスト（Month 2）

```bash
# test/e2e/export-import-roundtrip.bats
@test "export followed by import preserves configuration" {
  # 1. 初期状態をエクスポート
  bash script/export.sh

  # 2. バックアップ
  cp -r "$REPO_PATH" "$REPO_PATH.backup"

  # 3. インポート
  bash script/import.sh

  # 4. 再度エクスポート
  bash script/export.sh

  # 5. 差分確認（credentials除く）
  diff -r "$REPO_PATH" "$REPO_PATH.backup" --exclude="*.secret"
  [ "$?" -eq 0 ]
}
```

## タスクリスト

- [ ] Week 1: batsフレームワークのインストール
- [ ] Week 1: commitlint.config.js のユニットテスト作成
- [ ] Week 2: jest.config.js のユニットテスト作成
- [ ] Week 2: テストヘルパー関数の作成
- [ ] Week 3: import.sh の統合テスト作成
- [ ] Week 4: export.sh の統合テスト作成
- [ ] Week 4: update-libraries.sh の統合テスト作成
- [ ] Month 2: E2Eテストスイートの作成
- [ ] Month 2: CI/CDパイプラインにカバレッジレポート統合
- [ ] Month 2: Codecov連携設定

## 成功基準

- [ ] JavaScriptコード: 80%以上のカバレッジ
- [ ] 重要シェルスクリプト: 60%以上のカバレッジ
- [ ] CI/CDで自動的にカバレッジチェック
- [ ] PRごとにカバレッジレポート表示
- [ ] カバレッジバッジをREADMEに追加

## ROI計算

**投資**

- フェーズ1 (JS): 32時間
- フェーズ2 (Shell): 48時間
- フェーズ3 (E2E): 16時間
- **合計**: 96時間 × $150/h = $14,400

**リターン**

- 手動テスト時間削減: 8-10時間/月 → 96-120時間/年
- バグ修正コスト削減: 70%減 → $10,800-12,600/年
- **年間節約**: $10,800-12,600
- **ROI**: 75-88% (初年度)、175-188% (2年累積)

## 関連ファイル

- `jest.config.js` - テスト設定
- `test/config-validation.test.js` - 既存テスト
- `test/credential-filtering.test.js` - 既存テスト
- `script/import.sh` - テスト対象
- `script/export.sh` - テスト対象
- `commitlint.config.js` - テスト対象

## 参考リンク

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Bats Testing Framework](https://bats-core.readthedocs.io/)
- [Codecov](https://about.codecov.io/)
