# モバイル (Flutter) セットアップガイド

## 現状サマリー

[docs/tool-catalog.md](../tool-catalog.md) セクション 4.1 および `calendar_alerm` リポジトリの実態調査に基づく。

- [x] Flutter 3.27 + Dart (SDK >=3.6.0) 構成済み
- [x] flutter_riverpod + riverpod_annotation で状態管理
- [x] Drift (SQLite) + Freezed + go_router 導入済み
- [x] flutter_test + mockito + mocktail でユニットテストあり（3 層: domain/data/presentation）
- [x] Patrol 3.13 + integration_test で E2E テストあり
- [x] very_good_analysis 6.0 で lint 設定あり (`analysis_options.yaml`)
- [x] dart format 使用可能（`editor.formatOnSave: true` 設定済み）
- [x] CI/CD ワークフロー（Lint → Test → Build Android/iOS → Release）
- [x] CD ワークフロー（Firebase App Distribution + TestFlight via Fastlane）
- [x] release-please 導入済み（`release-type: dart`）
- [x] CLAUDE.md 作成済み（技術スタック・アーキテクチャルール記載）
- [x] fpdart で Either 型エラー処理
- [x] 多言語対応 (l10n)
- [ ] CI にカバレッジ閾値強制（テスト実行はあるが閾値チェックなし）
- [ ] CI に `dart format --set-exit-if-changed`（フォーマット検証なし）
- [ ] commitlint / Git hooks（未設定）
- [ ] claude.yml ワークフロー（未追加）
- [ ] CodeQL / SAST（未追加）

**現在の品質ゲート達成率: 中〜高（テスト・CI 基盤は充実、CI での閾値強制と Git hooks が不足）**

## セットアップ項目

### 優先度: 高

#### 1. CI にカバレッジ閾値強制を追加

**何を**: 既存の CI Test ジョブにカバレッジ閾値チェックを追加する。

**なぜ**: `flutter test --coverage` は CI で実行されているが、閾値の強制がない。テストが書かれていても品質基準（70%）を下回るコードがマージされるリスクがある。

**既存の CI Test ジョブに追加**:

```yaml
- name: Check coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 \
      | grep "lines" | grep -oP '[\d.]+%' | head -1 | tr -d '%')
    if (( $(echo "$COVERAGE < 70" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 70% threshold"
      exit 1
    fi
    echo "Coverage: $COVERAGE%"
```

> 代替: `very_good_cli` の `very_good test --min-coverage 70` も利用可能。

#### 2. CI に `dart format --set-exit-if-changed` を追加

**何を**: 既存の CI Lint ジョブにフォーマット検証ステップを追加する。

**なぜ**: DevContainer で `editor.formatOnSave: true` が設定されているが、CI で検証していないため確実性がない。

**既存の CI Lint ジョブに追加**:

```yaml
- name: Format check
  run: dart format --set-exit-if-changed .
```

### 優先度: 中

#### 3. commitlint 相当の仕組み導入

**何を**: Conventional Commits を強制する Git hooks を導入する。

**なぜ**: release-please が `release-type: dart` でコミットメッセージに基づくバージョン決定を行うため、不正なメッセージがあると自動リリースが正しく動作しない。

**推奨**: lefthook（Go 製、Node.js 非依存で Flutter プロジェクトに適合）

```bash
brew install lefthook
```

**設定例** (`lefthook.yml`):

```yaml
commit-msg:
  commands:
    commitlint:
      run: 'echo "{1}" | npx commitlint --edit'

pre-commit:
  commands:
    format:
      run: dart format --set-exit-if-changed .
    analyze:
      run: flutter analyze
```

#### 4. claude.yml ワークフロー追加

**何を**: `@claude` メンション対応の GitHub Actions ワークフローを追加する。

**なぜ**: CLAUDE.md は作成済みだが、GitHub 上での AI 支援インタラクション基盤がない。

**参考**: config リポジトリの `.github/workflows/claude.yml` をテンプレートとして使用。

#### 5. CodeQL / SAST 追加

**何を**: 静的セキュリティ解析を CI に追加する。

**なぜ**: SAST は Static Quality Gates の必須要件（Critical 検知で Fail）。Dart 向けの CodeQL は限定的だが、依存関係スキャンは有効。

### 優先度: 低

#### 6. release-please のブランチ名修正（`master` → `main`）

**何を**: `release-please.yml` のトリガーブランチを確認し、実際のデフォルトブランチと一致させる。

**現在の設定**:

```yaml
on:
  push:
    branches: [master]
```

**確認事項**: リポジトリのデフォルトブランチが `main` か `master` かを確認し、不一致があれば修正。

#### 7. ベースイメージ更新（1.0.13 → latest）

**何を**: DevContainer のベースイメージを最新版に更新する。

**なぜ**: AI CLI ツールやセキュリティパッチが大幅に遅れている（1.0.13 → 1.58.0+）。

**参考**: `/config-base-sync-update` コマンドで更新 + PR 作成が可能。

## DevContainer 最適化

- **ベースイメージ**: `ghcr.io/keito4/config-base:1.0.13` → `ghcr.io/keito4/config-base:latest`
- **既存 Features**: `flutter(3.27.4)`, `java(17)` — Flutter 固有のため維持
- **postCreateCommand**: `flutter pub get && dart run build_runner build --delete-conflicting-outputs` — 維持
