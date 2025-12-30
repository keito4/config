# Issue #001: テストカバレッジ不足の解消

## 優先度

**Critical** - 現状0%、目標70%+

## 現状分析

### 現在のテストカバレッジ

```
Test Suites: 2 passed, 2 total
Tests:       35 passed, 35 total
Coverage:    0% (no coverage configured)
```

**既存テスト:**

- `test/config-validation.test.js` (17 tests)
- `test/credential-filtering.test.js` (18 tests)

### 未テストの主要コンポーネント

1. **シェルスクリプト** (15 scripts, ~1,474 lines)
   - script/setup-claude.sh (372 lines)
   - script/brew-deps.sh (207 lines)
   - script/credentials.sh (105 lines)
   - script/import.sh, export.sh, など

2. **JavaScript/設定ファイル**
   - commitlint.config.js
   - eslint.config.mjs
   - jest.config.js

3. **CI/CD Workflows**
   - GitHub Actions workflows (7 files)

## 投資対効果 (ROI)

- **投資時間**: 96時間
- **年間コスト削減**: $14,400-18,000
  - バグ修正時間: $7,200-9,000/年
  - リグレッション防止: $4,800-6,000/年
  - レビュー効率化: $2,400-3,000/年
- **ROI**: 75-88% (1年目)
- **累積ROI**: 225-313% (3年)

## 実装計画

### Phase 1: 既存テストの拡張とカバレッジ設定 (24時間)

**1.1 Jest カバレッジ設定 (4時間)**

- `jest.config.js` にcoverage設定追加
- カバレッジ閾値設定: 70% lines/branches/functions/statements
- CI統合 (`.github/workflows/ci.yml`)

**タスク:**

- [ ] jest.config.js に collectCoverage, coverageThreshold 設定
- [ ] coverage/ ディレクトリを .gitignore に追加
- [ ] npm script に `test:coverage` 追加済み → 実行確認
- [ ] CI workflow にカバレッジチェック追加

**1.2 既存スクリプトのテスト追加 (20時間)**

**優先スクリプト:**

1. **script/update-libraries.sh** (8時間)
   - [ ] 依存関係更新ロジックのテスト
   - [ ] package.json/npm/global.json の解析テスト
   - [ ] git操作のモックテスト

2. **script/credentials.sh** (6時間)
   - [ ] 資格情報フィルタリングロジックのテスト
   - [ ] テンプレート生成テスト
   - [ ] セキュリティ検証テスト

3. **設定ファイルバリデーション** (6時間)
   - [ ] commitlint.config.js の設定テスト
   - [ ] eslint.config.mjs のルールテスト
   - [ ] jest.config.js の設定テスト

### Phase 2: シェルスクリプトの統合テスト拡充 (32時間)

**Issue #004との統合**

2.1 **script/setup-claude.sh テスト** (12時間)

- [ ] プラグインインストールテスト
- [ ] 設定ファイル生成テスト
- [ ] エラーハンドリングテスト

  2.2 **script/brew-deps.sh テスト** (10時間)

- [ ] Brewfile解析テスト
- [ ] 依存関係検証テスト
- [ ] OS別分岐テスト

  2.3 **import/export スクリプトテスト** (10時間)

- [ ] export.sh: 設定エクスポートテスト
- [ ] import.sh: 設定インポートテスト
- [ ] データ整合性テスト

### Phase 3: CI/CD Workflow テスト (20時間)

3.1 **Workflow 構造テスト** (12時間)

- [ ] YAML構文検証
- [ ] 必須ステップ存在確認
- [ ] secrets/環境変数参照検証

  3.2 **Workflow セキュリティテスト** (8時間)

- [ ] コマンドインジェクション検出
- [ ] 信頼できないインプット検証
- [ ] 権限設定確認

### Phase 4: E2Eテストと最終検証 (20時間)

4.1 **統合シナリオテスト** (12時間)

- [ ] 新規環境セットアップシナリオ
- [ ] 設定更新シナリオ
- [ ] リカバリーシナリオ

  4.2 **カバレッジ目標達成** (8時間)

- [ ] カバレッジレポート分析
- [ ] 未カバー領域の追加テスト
- [ ] 70%達成確認

## 成功基準

### 定量的指標

- ✅ Line coverage ≥ 70%
- ✅ Branch coverage ≥ 70%
- ✅ Function coverage ≥ 70%
- ✅ Statement coverage ≥ 70%
- ✅ CI でカバレッジチェックが自動実行
- ✅ 全テストが1分以内に完了

### 定性的指標

- ✅ クリティカルパス（credentials, setup-claude）は100%カバレッジ
- ✅ 各スクリプトに正常系・異常系テストが存在
- ✅ テストドキュメントが整備されている

## リスクと対策

| リスク                       | 影響 | 対策                                 |
| ---------------------------- | ---- | ------------------------------------ |
| シェルスクリプトのテスト困難 | 高   | batsフレームワーク活用（Issue #004） |
| 96時間の大規模投資           | 中   | Phase分割で段階的実装                |
| 既存機能への影響             | 中   | テストファースト、段階的リリース     |

## 実装順序

1. **Phase 1** (Quick Win) - カバレッジ設定 + 主要スクリプトテスト
2. **Phase 2** - Issue #004 と統合してシェルスクリプトテスト
3. **Phase 3** - CI/CD セキュリティ強化
4. **Phase 4** - E2E 統合と目標達成

## 関連Issue

- **Issue #004**: シェルスクリプト統合テスト（Phase 2で統合）
- **Issue #002**: shellcheck導入（静的解析との相乗効果）

## 参考資料

- Jest カバレッジ設定: https://jestjs.io/docs/configuration#collectcoverage-boolean
- Bats テストガイド: https://bats-core.readthedocs.io/
- GitHub Actions テストベストプラクティス: https://docs.github.com/en/actions/automating-builds-and-tests
