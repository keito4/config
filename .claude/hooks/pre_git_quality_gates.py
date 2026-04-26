#!/usr/bin/env python3
"""
グローバル Quality Gates: git commit/push 前にローカル CI チェックを実行

リポジトリの package.json を解析し、利用可能なチェックを自動検出して実行する。
npm / pnpm / yarn / bun / ni に対応。Biome による統合チェックにも対応。
"""
import sys
import json
import shlex
import subprocess
import os
import time
from pathlib import Path
from common import load_hook_input, get_command, detect_package_manager, build_run_command

# 設定
DEFAULT_TIMEOUT = 300  # 5分
MAX_RETRIES = 2  # 最大リトライ回数
RETRY_DELAY = 2  # リトライ間隔（秒）

data = load_hook_input()
cmd = get_command(data)
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


def has_biome(root: str) -> bool:
    """Biome が導入されているか確認"""
    if (Path(root) / "biome.json").exists() or (Path(root) / "biome.jsonc").exists():
        return True
    pkg_path = Path(root) / "package.json"
    if pkg_path.exists():
        try:
            with open(pkg_path) as f:
                pkg = json.load(f)
            all_deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
            return "@biomejs/biome" in all_deps
        except Exception:
            pass
    return False


def detect_linter_conflicts(root: str) -> list:
    """Biome と他の lint/format ツールの競合を検出"""
    conflicts = []
    pkg_path = Path(root) / "package.json"

    if not pkg_path.exists():
        return conflicts

    try:
        with open(pkg_path) as f:
            pkg = json.load(f)
        all_deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
    except Exception:
        return conflicts

    has_biome_installed = "@biomejs/biome" in all_deps
    if not has_biome_installed:
        return conflicts

    # ESLint との競合検出
    eslint_tools = ["eslint", "@eslint/js", "eslint-config-prettier"]
    found_eslint = [t for t in eslint_tools if t in all_deps]
    if found_eslint:
        conflicts.append({
            "type": "eslint",
            "tools": found_eslint,
            "message": "Biome と ESLint が同時に導入されています。"
                       "どちらか一方への統合を検討してください。",
        })

    # Prettier との競合検出
    prettier_tools = ["prettier", "prettier-plugin-tailwindcss"]
    found_prettier = [t for t in prettier_tools if t in all_deps]
    if found_prettier:
        conflicts.append({
            "type": "prettier",
            "tools": found_prettier,
            "message": "Biome と Prettier が同時に導入されています。"
                       "Biome は Prettier 互換のフォーマッタを内蔵しています。",
        })

    return conflicts


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


def is_retryable_error(returncode: int, stderr: str) -> bool:
    """リトライ可能なエラーかどうか判定"""
    # ネットワーク系エラー
    network_errors = [
        "ECONNREFUSED",
        "ETIMEDOUT",
        "ENOTFOUND",
        "network error",
        "socket hang up",
        "EAI_AGAIN",
    ]
    for err in network_errors:
        if err in stderr:
            return True
    # 一時的なファイルロック
    if "EBUSY" in stderr or "resource busy" in stderr.lower():
        return True
    return False


def run_with_retry(
    command: list,
    cwd: str,
    timeout: int = DEFAULT_TIMEOUT,
    max_retries: int = MAX_RETRIES,
) -> tuple:
    """リトライ付きコマンド実行

    Returns:
        tuple: (success: bool, result: dict)
    """
    last_result = None

    for attempt in range(max_retries + 1):
        try:
            result = subprocess.run(
                command,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=timeout,
            )

            if result.returncode == 0:
                return True, {"stdout": result.stdout, "stderr": result.stderr}

            # リトライ可能なエラーかチェック
            if attempt < max_retries and is_retryable_error(
                result.returncode, result.stderr
            ):
                time.sleep(RETRY_DELAY)
                continue

            last_result = {
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode,
            }

            # ツール未インストールの場合はスキップ扱い
            is_tool_missing = (
                result.returncode == 127
                or "command not found" in result.stderr
                or "No such file or directory" in result.stderr
            )
            if is_tool_missing:
                return True, {"skipped": True, "reason": "ツール未インストール"}

            return False, last_result

        except subprocess.TimeoutExpired:
            # タイムアウトはリトライしない（長時間ブロックを防ぐため）
            return False, {"error": f"タイムアウト ({timeout}秒)"}

        except FileNotFoundError:
            return True, {"skipped": True, "reason": "コマンド未検出"}

        except Exception as e:
            last_result = {"error": str(e)}
            if attempt < max_retries:
                time.sleep(RETRY_DELAY)
                continue
            return False, last_result

    return False, last_result or {"error": "Unknown error"}


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

# Biome と他の lint ツールの競合警告
conflicts = detect_linter_conflicts(repo_root)
if conflicts:
    print("", file=sys.stderr, flush=True)
    print("⚠️  [Lint Tool Conflict Warning]", file=sys.stderr, flush=True)
    for conflict in conflicts:
        print(f"   • {conflict['message']}", file=sys.stderr, flush=True)
        print(f"     対象: {', '.join(conflict['tools'])}", file=sys.stderr, flush=True)
    print("", file=sys.stderr, flush=True)

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
                "command": build_run_command(pm, script_name),
                "description": candidate["description"],
            })
            break  # 最初にマッチしたスクリプトを使用

# Biome 対応: biome.json があるが package.json scripts に lint/format:check が定義されていない場合
# node_modules/.bin/biome を直接実行してカバー
if has_biome(repo_root):
    has_lint_check = any(
        c["name"] in ("Lint", "Format Check") for c in checks
    )
    if not has_lint_check:
        biome_bin = Path(repo_root) / "node_modules" / ".bin" / "biome"
        if biome_bin.exists():
            checks.insert(0, {
                "name": "Biome Check (lint + format)",
                "command": [str(biome_bin), "check", "."],
                "description": "Biome による lint + format 統合チェック",
            })

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
        "args": [],
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

    success, result = run_with_retry(check["command"], repo_root)

    if success:
        if result.get("skipped"):
            print(f"    ⚠  スキップ ({result['reason']})",
                  file=sys.stderr, flush=True)
        else:
            print("    ✓  成功", file=sys.stderr, flush=True)
    else:
        failed_checks.append({
            "name": check["name"],
            **result,
        })
        if "error" in result:
            print(f"    ✗  {result['error']}", file=sys.stderr, flush=True)
        else:
            print(f"    ✗  失敗 (exit code: {result.get('returncode', '?')})",
                  file=sys.stderr, flush=True)

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
