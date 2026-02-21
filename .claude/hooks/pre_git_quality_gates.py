#!/usr/bin/env python3
"""
グローバル Quality Gates: git commit/push 前にローカル CI チェックを実行

リポジトリの package.json を解析し、利用可能なチェックを自動検出して実行する。
npm / pnpm / yarn / bun に対応。
"""
import sys
import json
import shlex
import subprocess
import os
from pathlib import Path

# Read input from Claude
data = json.load(sys.stdin)
cmd = (data.get("tool_input", {}) or {}).get("command") or ""
tokens = shlex.split(cmd) if cmd else []

if not tokens:
    sys.exit(0)

# Git操作（commit, push）を検出
is_git_commit = False
is_git_push = False

for i, token in enumerate(tokens):
    if token == "git" and i + 1 < len(tokens):
        next_token = tokens[i + 1]
        if next_token == "commit":
            is_git_commit = True
        elif next_token == "push":
            is_git_push = True

if not (is_git_commit or is_git_push):
    sys.exit(0)

# git リポジトリのルートを取得
try:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, timeout=10
    )
    repo_root = result.stdout.strip()
except Exception:
    sys.exit(0)

if not repo_root:
    sys.exit(0)


def detect_package_manager(root: str) -> str:
    """パッケージマネージャーを検出"""
    if (Path(root) / "bun.lockb").exists() or (Path(root) / "bun.lock").exists():
        return "bun"
    if (Path(root) / "pnpm-lock.yaml").exists():
        return "pnpm"
    if (Path(root) / "yarn.lock").exists():
        return "yarn"
    return "npm"


def get_package_scripts(root: str) -> dict:
    """package.json の scripts を取得"""
    pkg_path = Path(root) / "package.json"
    if not pkg_path.exists():
        return {}
    try:
        with open(pkg_path) as f:
            pkg = json.load(f)
        return pkg.get("scripts", {})
    except Exception:
        return {}


def has_node_modules(root: str) -> bool:
    """node_modules の存在チェック"""
    return (Path(root) / "node_modules").exists()


# package.json のスクリプトを取得
scripts = get_package_scripts(repo_root)
if not scripts:
    # package.json がない、または scripts が空 → Node.js プロジェクトでない
    sys.exit(0)

pm = detect_package_manager(repo_root)

# node_modules の存在チェック
if not has_node_modules(repo_root):
    print("=" * 60, file=sys.stderr, flush=True)
    print(f"[Quality Gates] {pm} install が未実行です", file=sys.stderr, flush=True)
    print("=" * 60, file=sys.stderr, flush=True)
    print(f"\n  {pm} install を実行してから再度お試しください\n",
          file=sys.stderr, flush=True)
    sys.exit(2)

# 実行するチェックを自動検出
# 優先度順: format:check > format > lint > test > typecheck > shellcheck
CHECK_CANDIDATES = [
    {
        "script_names": ["format:check"],
        "label": "Format Check",
        "description": "コードフォーマットの検証",
    },
    {
        "script_names": ["lint", "lint:check"],
        "label": "Lint",
        "description": "コード品質の検証",
    },
    {
        "script_names": ["test", "test:unit"],
        "label": "Test",
        "description": "ユニットテストの実行",
    },
    {
        "script_names": ["typecheck", "type-check", "tsc"],
        "label": "Type Check",
        "description": "型チェック",
    },
    {
        "script_names": ["shellcheck"],
        "label": "ShellCheck",
        "description": "シェルスクリプトの検証",
    },
]

checks = []
for candidate in CHECK_CANDIDATES:
    for script_name in candidate["script_names"]:
        if script_name in scripts:
            checks.append({
                "name": candidate["label"],
                "command": [pm, "run", script_name],
                "description": candidate["description"],
            })
            break  # 最初にマッチしたスクリプトを使用

# スクリプトベースのチェック（リポジトリに存在する場合のみ）
SCRIPT_CHECKS = [
    {
        "path": "script/security-credential-scan.sh",
        "args": ["--strict"],
        "label": "Security Credential Scan",
        "description": "認証情報の漏洩チェック",
    },
    {
        "path": "script/code-complexity-check.sh",
        "args": ["--strict"],
        "label": "Code Complexity Check",
        "description": "コード複雑度の検証",
    },
]

for sc in SCRIPT_CHECKS:
    script_path = Path(repo_root) / sc["path"]
    if script_path.exists() and os.access(script_path, os.X_OK):
        checks.append({
            "name": sc["label"],
            "command": [str(script_path)] + sc["args"],
            "description": sc["description"],
        })

if not checks:
    sys.exit(0)

# Quality Gates を実行
op = "commit" if is_git_commit else "push"
print(f"\n[Quality Gates] git {op} 前のチェックを実行中...\n",
      file=sys.stderr, flush=True)

failed_checks = []

for check in checks:
    print(f"  ▶ {check['name']}: {check['description']}",
          file=sys.stderr, flush=True)

    try:
        result = subprocess.run(
            check["command"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=300,
        )

        if result.returncode != 0:
            # ツール未インストール等の場合はスキップ
            is_tool_missing = (
                result.returncode == 127
                or "command not found" in result.stderr
                or "No such file or directory" in result.stderr
            )
            if is_tool_missing:
                print("    ⚠  スキップ (ツール未インストール)",
                      file=sys.stderr, flush=True)
            else:
                failed_checks.append({
                    "name": check["name"],
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode,
                })
                print(f"    ✗  失敗 (exit code: {result.returncode})",
                      file=sys.stderr, flush=True)
        else:
            print("    ✓  成功", file=sys.stderr, flush=True)

    except subprocess.TimeoutExpired:
        failed_checks.append({
            "name": check["name"],
            "error": "タイムアウト (5分)",
        })
        print("    ✗  タイムアウト", file=sys.stderr, flush=True)

    except FileNotFoundError:
        print("    ⚠  スキップ (コマンド未検出)",
              file=sys.stderr, flush=True)

    except Exception as e:
        failed_checks.append({
            "name": check["name"],
            "error": str(e),
        })
        print(f"    ✗  エラー: {e}", file=sys.stderr, flush=True)

# 失敗があればブロック
if failed_checks:
    print("\n" + "=" * 60, file=sys.stderr, flush=True)
    print("[Quality Gates] チェックに失敗しました", file=sys.stderr, flush=True)
    print("=" * 60 + "\n", file=sys.stderr, flush=True)

    MAX_LINES = 20

    for failed in failed_checks:
        print(f"【{failed['name']}】", file=sys.stderr, flush=True)
        if "error" in failed:
            print(f"  エラー: {failed['error']}", file=sys.stderr, flush=True)
        else:
            for label, key in [("stdout", "stdout"), ("stderr", "stderr")]:
                output = failed.get(key, "").strip()
                if not output:
                    continue
                lines = output.splitlines()
                if len(lines) <= MAX_LINES:
                    print(f"  {label}:\n{output}", file=sys.stderr, flush=True)
                else:
                    truncated = "\n".join(lines[-MAX_LINES:])
                    print(
                        f"  {label} (末尾{MAX_LINES}行 / 全{len(lines)}行):",
                        file=sys.stderr, flush=True,
                    )
                    print(truncated, file=sys.stderr, flush=True)
        print("", file=sys.stderr, flush=True)

    print("修正してから再度コミット/プッシュしてください。",
          file=sys.stderr, flush=True)
    sys.exit(2)

print("\n[Quality Gates] すべてのチェックに合格しました\n",
      file=sys.stderr, flush=True)
sys.exit(0)
