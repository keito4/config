#!/usr/bin/env python3
"""Stop Hook: エージェント完了前にテストを実行して検証

エージェントが作業完了を宣言する前に、利用可能なテストスイートを
自動実行し、失敗があればエージェントに修正を促す。

無限ループ防止: STOP_HOOK_ACTIVE 環境変数で再帰実行を防ぐ。
Git 変更がない場合はスキップ（新規セッションでの空実行を防止）。
"""
import sys
import json
import subprocess
import os
from pathlib import Path
from common import get_git_root, detect_package_manager

# 無限ループ防止
if os.environ.get("STOP_HOOK_ACTIVE") == "1":
    sys.exit(0)

os.environ["STOP_HOOK_ACTIVE"] = "1"

repo_root = get_git_root()
if not repo_root:
    sys.exit(0)

# ── Git 変更の有無を確認 ──────────────────────────────────
# ステージング済み or 未ステージングの変更がなければスキップ
try:
    diff_result = subprocess.run(
        ["git", "diff", "--name-only", "HEAD"],
        capture_output=True, text=True, timeout=10, cwd=repo_root
    )
    staged_result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        capture_output=True, text=True, timeout=10, cwd=repo_root
    )
    untracked_result = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard"],
        capture_output=True, text=True, timeout=10, cwd=repo_root
    )
    has_changes = bool(
        (diff_result.stdout or "").strip()
        or (staged_result.stdout or "").strip()
        or (untracked_result.stdout or "").strip()
    )
    if not has_changes:
        sys.exit(0)
except (subprocess.TimeoutExpired, FileNotFoundError):
    sys.exit(0)

# ── package.json からテストスクリプトを検出 ────────────────
pkg_json = repo_root / "package.json"
if not pkg_json.exists():
    sys.exit(0)

try:
    with open(pkg_json) as f:
        pkg = json.load(f)
except (json.JSONDecodeError, OSError):
    sys.exit(0)

scripts = pkg.get("scripts", {})

# パッケージマネージャーを判定
PM = detect_package_manager(repo_root)

# ── テスト実行 ────────────────────────────────────────────
TEST_SCRIPTS = ["test", "test:unit"]
test_script = None
for s in TEST_SCRIPTS:
    if s in scripts:
        test_script = s
        break

if not test_script:
    sys.exit(0)

try:
    result = subprocess.run(
        [PM, "run", test_script],
        capture_output=True, text=True, timeout=300, cwd=repo_root,
        env={**os.environ, "CI": "true", "STOP_HOOK_ACTIVE": "1"},
    )
except subprocess.TimeoutExpired:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "Stop",
            "additionalContext": (
                "[stop-verification] テストがタイムアウトしました（5分）。\n"
                "テストを確認してから再度完了してください。"
            ),
        }
    }
    json.dump(output, sys.stdout)
    sys.exit(0)

if result.returncode != 0:
    # テスト失敗 → エージェントにフィードバック
    stderr_lines = (result.stderr or "").strip().splitlines()
    stdout_lines = (result.stdout or "").strip().splitlines()
    # 最後の 30 行を取得
    all_lines = stdout_lines + stderr_lines
    tail = all_lines[-30:] if len(all_lines) > 30 else all_lines
    failure_output = "\n".join(tail)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "Stop",
            "additionalContext": (
                "[stop-verification] テストが失敗しています。修正してから再度完了してください:\n"
                f"{failure_output}"
            ),
        }
    }
    json.dump(output, sys.stdout)

sys.exit(0)
