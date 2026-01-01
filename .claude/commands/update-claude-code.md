# Update Claude Code

Claude Code の最新バージョンをチェックして更新します。

## 実行内容

1. npm/global.json から現在の `@anthropic-ai/claude-code` のバージョンを取得
2. npm registry から最新バージョンを取得
3. バージョンを比較して、更新が必要な場合は global.json を更新
4. リリースノートのURLを表示

## 使用方法

```bash
/update-claude-code
```

## 実装

```bash
#!/usr/bin/env bash
set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 環境変数を設定して自動更新を有効化
export AUTO_UPDATE=true
export CI=true

# Claude Code更新スクリプトを実行
if [[ -f "${PROJECT_ROOT}/script/update-claude-code.sh" ]]; then
    bash "${PROJECT_ROOT}/script/update-claude-code.sh"
else
    echo "Error: update-claude-code.sh が見つかりません"
    exit 1
fi

# 更新があった場合の後処理
if git diff --quiet npm/global.json; then
    echo "✓ Claude Code は既に最新です"
else
    echo ""
    echo "更新が完了しました。変更をコミットしてください:"
    echo "  git add npm/global.json"
    echo "  git commit -m 'chore: update Claude Code to latest version'"
    echo ""
    git diff npm/global.json
fi
```

## 注意事項

- このコマンドは config リポジトリ内で実行する必要があります
- 更新後は手動でコミットとプッシュが必要です
- CI環境では自動的に更新されます（確認プロンプトなし）
