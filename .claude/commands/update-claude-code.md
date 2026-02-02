# Update Claude Code

Claude Code の最新バージョンにアップデートします。

## 実行内容

1. `claude --version` で現在のバージョンを取得
2. `claude update` でネイティブインストーラー経由でアップデート
3. 更新後のバージョンを表示
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

# Claude Code更新スクリプトを実行
if [[ -f "${PROJECT_ROOT}/script/update-claude-code.sh" ]]; then
    bash "${PROJECT_ROOT}/script/update-claude-code.sh"
else
    echo "Error: update-claude-code.sh が見つかりません"
    exit 1
fi
```

## 注意事項

- Claude Code がネイティブインストーラー経由でインストールされている必要があります
- インストール方法: `claude install` または https://docs.anthropic.com/en/docs/claude-code/getting-started を参照
