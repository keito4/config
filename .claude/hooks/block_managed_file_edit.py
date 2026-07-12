#!/usr/bin/env python3
"""PreToolUse Hook: keito4/config 管理ファイルの直接編集をブロック

sync-downstream で下流リポジトリへ配布されるファイル（reusable workflow の
caller スタブ等）には '# Managed by keito4/config' マーカーが付与されている。
下流でこれらを直接編集しても次回の同期 PR で上書きされてしまうため、
config 側での修正か manifest の exclude 追加へ誘導する。

config リポジトリ自身（.github/sync-downstream.json が存在する）では
テンプレート編集が正当な作業なのでチェックしない。

参考: docs/adr/0017-downstream-template-auto-sync.md, 0018-reusable-workflow-distribution.md
"""
import sys
from pathlib import Path

from common import load_hook_input

MARKER = "Managed by keito4/config"
HEAD_LINES = 5
CONFIG_REPO_SENTINEL = ".github/sync-downstream.json"


def head_contains_marker(target: Path) -> bool:
    """Return True when the first HEAD_LINES lines of the file carry the marker."""
    try:
        with target.open(encoding="utf-8", errors="ignore") as handle:
            for _ in range(HEAD_LINES):
                line = handle.readline()
                if not line:
                    return False
                if MARKER in line:
                    return True
    except OSError:
        return False
    return False


def main() -> int:
    data = load_hook_input()
    tool_input = data.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path") or tool_input.get("path") or ""

    if not file_path:
        return 0

    # settings.json のラッパーが git root へ cd 済みなので相対パスで判定できる
    if Path(CONFIG_REPO_SENTINEL).is_file():
        return 0

    target = Path(file_path)
    if not target.is_file():
        return 0

    if head_contains_marker(target):
        print(
            f"BLOCKED: {target.name} は keito4/config が管理する同期ファイルです。\n"
            "ここで編集しても次回の同期 PR で上書きされます。\n"
            "FIX: keito4/config 側のテンプレートを修正してください。リポジトリ固有の"
            "変更を維持したい場合は、keito4/config の .github/sync-downstream.json の"
            " exclude にこのパスを追加してください。",
            file=sys.stderr,
        )
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
