# ADR 0006: バージョン更新の Dependabot 一本化

## Status

Accepted

## Context

ADR 0002 で定義された自動更新の仕組みが、運用上 5 系統に分岐しており、責務が重複していた。

| 仕組み                      | 対象                                     | 頻度         | 動作                                                       |
| --------------------------- | ---------------------------------------- | ------------ | ---------------------------------------------------------- |
| Dependabot                  | `package.json` / GH Actions / Dockerfile | 毎週月       | パッチは group、minor も group、major は個別 PR            |
| `update-libraries.yml`      | `package.json` + `npm/global.json`       | 毎週月 03:00 | `npm-check-updates --target latest -u` で **全部** 最新化  |
| `update-dev-tools.yml`      | `.devcontainer/Dockerfile` の ARG        | **毎日**     | GitHub Releases API から `sed` 置換                        |
| `update-claude-plugins.yml` | `.claude/plugins/plugins.txt`            | 毎週月 06:00 | **空実装**（`has_updates=false` ハードコード）             |
| `scheduled-maintenance.yml` | リポ全体（`/repo-maintenance` 実行）     | 毎週月 06:00 | Claude Code Action 経由で `npm run update:libs` ほかを実行 |

具体的な不整合：

1. **Dependabot と `update-libraries.yml` が `package.json` を奪い合う**。Dependabot の reject ルール（semantic-release major を除外）を `npm-check-updates --target latest -u` が回避してしまい、ADR 0002 の "Mitigation: 重要な更新は手動レビューを推奨" が実質バイパスされていた。
2. **`update-claude-plugins.yml` は死にコード**。バージョン取得は未実装で、毎週走るのに PR は決して作られない。
3. 月曜 03:00 と 06:00 に複数のワークフローが連鎖し、生成 PR が互いを上書きする可能性があった。
4. グローバル CLI が `npm/global.json`（`update-libraries.yml` 管理）と Dockerfile ARG（`update-dev-tools.yml` 管理）の 2 箇所に分散しており、どちらが正かが曖昧。

## Decision

**npm devDependencies / GitHub Actions / Docker base image の更新は Dependabot に一本化する。**

| 対象                                      | 担当                                                            |
| ----------------------------------------- | --------------------------------------------------------------- |
| `package.json` / `package-lock.json`      | Dependabot (`.github/dependabot.yml`)                           |
| `.github/workflows/*.yml`（Actions ピン） | Dependabot                                                      |
| `.devcontainer/Dockerfile`（FROM 行）     | Dependabot                                                      |
| `.devcontainer/Dockerfile`（ARG 行）      | `update-dev-tools.yml`（Dependabot は ARG を読まない）          |
| `npm/global.json`                         | `update-libraries.yml`（Dependabot は読めない custom manifest） |
| `.claude/plugins/plugins.txt`             | 当面手動（自動化は claude CLI が対応してから再検討）            |

### 具体変更

- `update-libraries.yml` の責務を `npm/global.json` のみに縮小。`script/update-libraries.sh` から `npm-check-updates`/`npm install` 部分を削除。
- `update-claude-plugins.yml` を削除。
- ADR 0002 を本 ADR で上書き（superseded by 0006）。
- `update-dev-tools.yml` の cron を毎日 → 毎週月曜（`'0 5 * * 1'`）に変更。DevContainer 再ビルドのコストと patch 追従の必要性を勘案し、Dependabot と同じ週次サイクルに揃える。
- `update-dev-tools.yml` の 1Password CLI 取得元から `1Password/connect` フォールバックを削除（別プロダクトの Connect サーバーを誤参照していた）。`agilebits.com` の取得に失敗した場合は現在バージョンを維持する既存ロジックに任せる。

## Consequences

### Positive

- Dependabot の reject / ignore ルールが効くようになり、major 更新が自動マージされなくなる。
- PR の発生源が予測可能になる（同じパッケージで 2 つの PR が立たない）。
- 死にワークフローの実行が止まり、Actions 利用時間が減る。

### Negative

- `npm run update:libs` の挙動が変わる。今まで `package.json` も更新されていたが今後は `npm/global.json` のみ。ローカルで `package.json` を最新化したい場合は `npx npm-check-updates -u && npm install` を直接実行する。

### Mitigation

- `script/README.md` と本 ADR で挙動の変更を明示。
- `update-libraries.yml` のヘッダーコメントで責務の境界を明文化。
