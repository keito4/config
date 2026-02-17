# モバイル (Flutter) セットアップガイド

## CI カバレッジ閾値強制

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

## CI フォーマット検証

```yaml
- name: Format check
  run: dart format --set-exit-if-changed .
```

## commitlint（lefthook）

Flutter プロジェクトは Node.js 非依存の lefthook を推奨。

```bash
brew install lefthook
```

```yaml
# lefthook.yml
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

## Claude Code ワークフロー

config リポジトリの `.github/workflows/claude.yml` をテンプレートとして追加。

## CodeQL / SAST

Dart 向けの CodeQL は限定的だが、依存関係スキャンは有効。

## release-please のブランチ名確認

`release-please.yml` のトリガーブランチがリポジトリのデフォルトブランチ（`main` or `master`）と一致していることを確認する。

## DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **Features**: `flutter`, `java(17)` — Flutter 固有のため維持
- **postCreateCommand**: `flutter pub get && dart run build_runner build --delete-conflicting-outputs`
