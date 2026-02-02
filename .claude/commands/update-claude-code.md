# Update Claude Code

Claude Code の最新バージョンに更新します（ネイティブインストーラー使用）。

## 実行内容

1. 現在のClaude Codeバージョンを確認
2. `claude update` コマンドで最新版に更新
3. 更新に失敗した場合は再インストールを試行
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

- このコマンドは Claude Code がインストールされている環境で実行する必要があります
- ネイティブインストーラーを使用しているため、npm は不要です
- 自動更新が有効な場合、手動更新は不要な場合があります

## インストール方法

Claude Code が未インストールの場合:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

## 参考リンク

- [Claude Code Getting Started](https://docs.anthropic.com/en/docs/claude-code/getting-started)
- [Claude Code Releases](https://github.com/anthropics/claude-code/releases)
