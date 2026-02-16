# Update GitHub Actions

GitHub Actions のバージョンを最新に自動更新します。

## 実行内容

1. `.github/workflows/` 配下の全ワークフローファイル（テンプレート含む）をスキャン
2. `uses:` 行から action/ref ペアを抽出
3. SemVer タグのアクションのみ更新対象（メジャータグ固定・SHA ピンニング・ブランチ固定はスキップ）
4. `gh api` で最新リリースタグを取得
5. `sed` で一括置換
6. 変更サマリを表示

## 使用方法

```bash
/update-actions
```

または npm script として:

```bash
npm run update:actions
```

## 更新対象の判定

| パターン           | 例                         | 対応     |
| ------------------ | -------------------------- | -------- |
| SemVer タグ        | `@v6.0.2`, `@0.34.0`       | 更新対象 |
| メジャータグ固定   | `@v1`, `@v3`               | スキップ |
| ブランチ固定       | `@master`, `@main`         | スキップ |
| SHA ピンニング     | `@e58ee9d1...` (40文字hex) | スキップ |
| ローカルアクション | `./`                       | スキップ |
| Docker アクション  | `docker://`                | スキップ |

## 必須コマンド

- `gh` (GitHub CLI) — リリース/タグ情報の取得に使用

## 一括更新

全依存関係（npm + Claude Code + Actions）を一括更新する場合:

```bash
npm run update:all
npm run update:all -- --skip-libs      # Actions + Claude のみ
npm run update:all -- --skip-claude    # Actions + libs のみ
npm run update:all -- --skip-actions   # libs + Claude のみ
```

## 参考リンク

- [GitHub Actions バージョニング](https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-tags-for-release-management)
