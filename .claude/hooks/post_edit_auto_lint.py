#!/usr/bin/env python3
"""PostToolUse Hook: ファイル編集後に自動フォーマット＋リントを実行

Write/Edit ツールでファイルが編集された後、対応するフォーマッター・リンターを
自動実行し、残った違反を additionalContext として返す。
エージェントは即座に自己修正できる。

対応言語:
  - TypeScript/JavaScript: biome format + oxlint (フォールバック: prettier + eslint)
  - Python: ruff check --fix + ruff format
  - Shell: shellcheck (修正指示のみ)
"""
import sys
import json
import subprocess
import shutil
from pathlib import Path

data = json.load(sys.stdin)
tool_input = data.get("tool_input", {}) or {}
file_path = tool_input.get("file_path") or tool_input.get("path") or ""

if not file_path:
    sys.exit(0)

path = Path(file_path)
if not path.exists():
    sys.exit(0)

suffix = path.suffix.lower()

# ── 言語判定 ──────────────────────────────────────────────
TS_JS = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"}
PYTHON = {".py"}
SHELL = {".sh", ".bash"}

if suffix not in TS_JS | PYTHON | SHELL:
    sys.exit(0)


def run_silent(cmd: list[str]) -> None:
    """コマンドをサイレント実行（失敗しても無視）"""
    try:
        subprocess.run(cmd, capture_output=True, timeout=30)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass


def run_capture(cmd: list[str], max_lines: int = 20) -> str:
    """コマンドを実行し出力を取得"""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        output = (result.stdout or "") + (result.stderr or "")
        lines = output.strip().splitlines()
        if len(lines) > max_lines:
            lines = lines[:max_lines] + [f"... ({len(lines) - max_lines} more lines)"]
        return "\n".join(lines)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


diagnostics = ""
file_str = str(file_path)

if suffix in TS_JS:
    # Phase 1: 自動修正（サイレント）
    if shutil.which("biome"):
        run_silent(["biome", "format", "--write", file_str])
        run_silent(["biome", "check", "--fix", file_str])
    elif shutil.which("prettier"):
        run_silent(["prettier", "--write", file_str])

    if shutil.which("oxlint"):
        run_silent(["oxlint", "--fix", file_str])
    elif shutil.which("npx"):
        run_silent(["npx", "--yes", "oxlint", "--fix", file_str])

    # Phase 2: 残った違反を取得
    if shutil.which("oxlint"):
        diagnostics = run_capture(["oxlint", file_str])
    elif shutil.which("npx"):
        diagnostics = run_capture(["npx", "--yes", "oxlint", file_str])

elif suffix in PYTHON:
    if shutil.which("ruff"):
        run_silent(["ruff", "check", "--fix", file_str])
        run_silent(["ruff", "format", file_str])
        diagnostics = run_capture(["ruff", "check", file_str])

elif suffix in SHELL:
    if shutil.which("shellcheck"):
        diagnostics = run_capture(["shellcheck", "-f", "gcc", file_str])

# ── 結果を返す ────────────────────────────────────────────
# 問題がない場合はスキップ（oxlint の "Found 0 warnings and 0 errors" 等）
if diagnostics:
    lower = diagnostics.lower()
    if "0 warnings and 0 errors" in lower or "found 0 " in lower:
        diagnostics = ""
    # ruff: "All checks passed!" をスキップ
    if "all checks passed" in lower:
        diagnostics = ""

if diagnostics and diagnostics.strip():
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": (
                f"[auto-lint] {path.name} に以下の問題が残っています。修正してください:\n"
                f"{diagnostics}"
            ),
        }
    }
    json.dump(output, sys.stdout)

sys.exit(0)
