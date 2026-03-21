---
description: Setup Doppler secret management with dev/dev_personal configuration
allowed-tools: Read, Write, Edit, Bash(doppler:*), Bash(npm:*), Bash(pnpm:*), Bash(jq:*), Bash(cat:*), Bash(test:*), Bash(echo:*), Bash(grep:*), Bash(node:*), AskUserQuestion
argument-hint: '[--project PROJECT_NAME] [--check]'
---

# Doppler Setup Command

Doppler のシークレット管理を dev / dev_personal 構成でセットアップする。

## Step 1: Parse Arguments and Check Prerequisites

引数を解析:

- `--project NAME`: Doppler プロジェクト名を指定（省略時は対話的に確認）
- `--check`: 現在の設定状況を確認するだけ（変更なし）

### 前提条件の確認

```bash
# Doppler CLI がインストールされているか
command -v doppler >/dev/null 2>&1

# ログイン状態の確認
doppler me 2>/dev/null
```

**結果:**

- Doppler CLI 未インストール → インストール手順を表示して終了
- 未ログイン → `doppler login` の実行を提案

## Step 2: Determine Project Name

プロジェクト名の決定:

1. `--project` 引数が指定されていればそれを使用
2. 既存の `doppler.yaml` があればそこから読み取り
3. いずれもなければユーザーに質問

```bash
# 既存の doppler.yaml からプロジェクト名を読み取り
if [ -f "doppler.yaml" ]; then
  grep 'project:' doppler.yaml | awk '{print $2}'
fi
```

ユーザーに質問する場合は AskUserQuestion ツールを使用:

- 質問: 「Doppler のプロジェクト名を入力してください」
- Doppler に存在するプロジェクト一覧を `doppler projects` で取得し選択肢として提示

## Step 3: Check Current Status (`--check` mode)

`--check` が指定された場合、以下を確認して結果を報告:

```bash
# doppler.yaml の存在と内容
test -f doppler.yaml && cat doppler.yaml

# 現在の設定
doppler configure

# 利用可能な config 一覧
doppler configs --project $PROJECT_NAME

# Personal Config が有効か
doppler configs --project $PROJECT_NAME | grep personal
```

**レポート:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Doppler Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project:         {project_name}
doppler.yaml:    {exists / not found}
Default Config:  {config_name}
Personal Config: {enabled / disabled}
Configs:         {list}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

`--check` の場合はここで終了。

## Step 4: Create or Update doppler.yaml

`doppler.yaml` が存在しない場合は作成、存在する場合は更新:

```yaml
setup:
  project: { PROJECT_NAME }
  config: dev_personal
```

既に存在し、内容が正しければスキップ。

## Step 5: Update package.json Scripts

`package.json` が存在する場合、Doppler 用のスクリプトを追加:

```bash
# package.json が存在するか確認
test -f package.json
```

以下のスクリプトを追加（既存の scripts を壊さない）:

```json
{
  "scripts": {
    "dev:doppler": "doppler run -- npm run dev",
    "dev:doppler:shared": "doppler run --config dev -- npm run dev"
  }
}
```

**パッケージマネージャーの判定:**

- `pnpm-lock.yaml` → `doppler run -- pnpm dev`
- `yarn.lock` → `doppler run -- yarn dev`
- `bun.lockb` / `bun.lock` → `doppler run -- bun dev`
- それ以外 → `doppler run -- npm run dev`

既に `dev:doppler` が存在する場合はスキップ。

## Step 6: Update .gitignore

`.gitignore` に Doppler 関連のエントリを追加:

```bash
# .doppler.yaml（個人設定）が含まれていない場合のみ追加
grep -q '.doppler.yaml' .gitignore 2>/dev/null
```

追加するエントリ:

```
# Doppler
.doppler.yaml
```

> `doppler.yaml`（プロジェクト共通設定）はコミット対象。
> `.doppler.yaml`（`doppler setup` が生成するローカル設定）は gitignore。

## Step 7: DevContainer Integration

DevContainer 環境の場合、追加の設定を提案:

```bash
# DevContainer 環境かどうか判定
test -f .devcontainer/devcontainer.json
```

DevContainer が存在する場合:

1. `containerEnv` に `DOPPLER_TOKEN` が設定されているか確認
2. 未設定なら追加を提案

```json
{
  "containerEnv": {
    "DOPPLER_TOKEN": "${localEnv:DOPPLER_TOKEN}"
  }
}
```

**注意:** `DOPPLER_TOKEN` はホストマシンの環境変数から注入する。
Personal Token (`dp.pt.*`) を使用する場合はホスト側で事前に設定が必要。

## Step 8: GitHub Actions Integration

GitHub Actions ワークフローが存在する場合、Doppler 統合を提案:

```bash
# CI ワークフローの存在確認
test -f .github/workflows/ci.yml
```

提案する設定:

1. GitHub Secrets に `DOPPLER_TOKEN`（Service Token）を追加
2. ワークフローで `dopplerhq/secrets-fetch-action@v2` を使用

```yaml
- name: Fetch secrets from Doppler
  uses: dopplerhq/secrets-fetch-action@v2
  with:
    doppler-token: ${{ secrets.DOPPLER_TOKEN }}
    doppler-project: { PROJECT_NAME }
    doppler-config: stg
```

**この手順は提案のみで自動適用しない。** ユーザーが判断する。

## Step 9: Codespaces Integration

GitHub Codespaces を使用する場合:

```bash
# Codespaces 用 devcontainer の存在確認
test -f .devcontainer/codespaces/devcontainer.json
```

存在する場合:

1. `secrets` に `DOPPLER_TOKEN` が含まれているか確認
2. 未設定なら追加を提案

```json
{
  "secrets": {
    "DOPPLER_TOKEN": {
      "description": "Doppler Personal Token for secret injection"
    }
  }
}
```

また、Codespaces のシークレットにリポジトリを紐付ける手順を提示:

```bash
gh codespace secret set DOPPLER_TOKEN --repos owner/repo
```

## Step 10: Verify Setup

セットアップの検証:

```bash
# doppler.yaml が正しいか
doppler configure --project $PROJECT_NAME --config dev_personal

# シークレットが取得できるか（キー名のみ表示）
doppler secrets --project $PROJECT_NAME --config dev --only-names 2>/dev/null
```

## Step 11: Final Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Doppler Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:         {PROJECT_NAME}
doppler.yaml:    Created / Updated
Default Config:  dev_personal
package.json:    dev:doppler script added
.gitignore:      .doppler.yaml added

次のステップ:
1. doppler run -- pnpm dev で開発サーバーを起動
2. 個人差分を追加: doppler secrets set KEY=VALUE --config dev_personal
3. CI/CD 統合が必要な場合は GitHub Secrets に DOPPLER_TOKEN を追加

詳細: docs/doppler-setup-guide.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

- Doppler CLI 未インストール → インストール手順を表示
- 未ログイン → `doppler login` を促す
- プロジェクトが存在しない → `doppler projects create` を提案
- Personal Config が無効 → Dashboard での有効化手順を表示
- ネットワークエラー → オフラインでも doppler.yaml の作成は可能と案内
