#!/usr/bin/env python3
"""
Git操作前のQuality Gatesチェック

git commit や git push の前に以下のチェックを実行：
0. npm install の確認（node_modules の存在チェック）
1. npm run format:check
2. npm run lint
3. npm run test
4. npm run shellcheck
5. ./script/security-credential-scan.sh --strict
6. ./script/code-complexity-check.sh --strict
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
    if token == "git":
        if i + 1 < len(tokens):
            next_token = tokens[i + 1]
            if next_token == "commit":
                is_git_commit = True
            elif next_token == "push":
                is_git_push = True

# git commit または git push でない場合はスルー
if not (is_git_commit or is_git_push):
    sys.exit(0)

# node_modules の存在チェック（npm install が実行されているか確認）
node_modules_path = Path(os.getcwd()) / "node_modules"
if not node_modules_path.exists():
    print("=" * 60, file=sys.stderr, flush=True)
    print("❌ npm install が実行されていません", file=sys.stderr, flush=True)
    print("=" * 60, file=sys.stderr, flush=True)
    print("", file=sys.stderr, flush=True)
    print("node_modules ディレクトリが見つかりません。", file=sys.stderr, flush=True)
    print("以下のコマンドを実行してから再度お試しください：", file=sys.stderr, flush=True)
    print("", file=sys.stderr, flush=True)
    print("  npm install", file=sys.stderr, flush=True)
    print("", file=sys.stderr, flush=True)
    sys.exit(2)

# Quality Gatesを実行
print("🔍 Git操作前のQuality Gatesを実行中...\n", file=sys.stderr, flush=True)

checks = [
    {
        "name": "Format Check",
        "command": ["npm", "run", "format:check"],
        "description": "コードフォーマットの検証",
        "install_hint": "npm install"
    },
    {
        "name": "Lint",
        "command": ["npm", "run", "lint"],
        "description": "コード品質の検証",
        "install_hint": "npm install"
    },
    {
        "name": "Test",
        "command": ["npm", "run", "test"],
        "description": "ユニットテストの実行",
        "install_hint": "npm install"
    },
    {
        "name": "ShellCheck",
        "command": ["npm", "run", "shellcheck"],
        "description": "シェルスクリプトの検証",
        "install_hint": "brew install shellcheck (macOS) / apt install shellcheck (Linux)"
    },
    {
        "name": "Security Credential Scan",
        "command": ["./script/security-credential-scan.sh", "--strict"],
        "description": "認証情報の漏洩チェック",
        "install_hint": None
    },
    {
        "name": "Code Complexity Check",
        "command": ["./script/code-complexity-check.sh", "--strict"],
        "description": "コード複雑度の検証",
        "install_hint": None
    }
]

failed_checks = []

for check in checks:
    print(f"▶ {check['name']}: {check['description']}", file=sys.stderr, flush=True)

    try:
        result = subprocess.run(
            check["command"],
            cwd=os.getcwd(),
            capture_output=True,
            text=True,
            timeout=300  # 5分でタイムアウト
        )

        if result.returncode != 0:
            # returncode 127 またはコマンドが見つからないエラーはスキップ
            is_tool_missing = (
                result.returncode == 127
                or "No such file or directory" in result.stderr
                or "command not found" in result.stderr
            )
            # 出力が実質的に空（ヘッダーのみ）の場合もツール/環境の問題としてスキップ
            stdout_lines = [l for l in result.stdout.strip().split('\n') if l.strip() and not l.startswith('━')]
            is_empty_output = len(stdout_lines) <= 1 and not result.stderr.strip()

            if is_tool_missing or is_empty_output:
                hint = check.get("install_hint")
                if hint:
                    print(f"  ⚠️  スキップ (ツールまたは環境が見つかりません)", file=sys.stderr, flush=True)
                    print(f"      💡 インストール: {hint}", file=sys.stderr, flush=True)
                else:
                    print(f"  ⚠️  スキップ (ツールまたは環境が見つかりません)", file=sys.stderr, flush=True)
            else:
                failed_checks.append({
                    "name": check["name"],
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode
                })
                print(f"  ❌ 失敗 (exit code: {result.returncode})", file=sys.stderr, flush=True)
        else:
            print(f"  ✅ 成功", file=sys.stderr, flush=True)

    except subprocess.TimeoutExpired:
        failed_checks.append({
            "name": check["name"],
            "error": "タイムアウト (5分)"
        })
        print(f"  ❌ タイムアウト", file=sys.stderr, flush=True)

    except FileNotFoundError:
        # スクリプトが存在しない場合はスキップ
        print(f"  ⚠️  スキップ (コマンドが見つかりません)", file=sys.stderr, flush=True)

    except Exception as e:
        failed_checks.append({
            "name": check["name"],
            "error": str(e)
        })
        print(f"  ❌ エラー: {e}", file=sys.stderr, flush=True)

    print("", file=sys.stderr, flush=True)

# 失敗したチェックがある場合はブロック
if failed_checks:
    print("=" * 60, file=sys.stderr, flush=True)
    print("❌ Quality Gatesに失敗しました", file=sys.stderr, flush=True)
    print("=" * 60, file=sys.stderr, flush=True)
    print("", file=sys.stderr, flush=True)

    MAX_LINES = 15  # 失敗時の出力を最大行数に制限

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
                    print(f"  {label} (末尾{MAX_LINES}行 / 全{len(lines)}行):", file=sys.stderr, flush=True)
                    print(truncated, file=sys.stderr, flush=True)

        print("", file=sys.stderr, flush=True)

    print("修正してから再度コミット/プッシュしてください。", file=sys.stderr, flush=True)
    sys.exit(2)

print("✅ すべてのQuality Gatesに合格しました", file=sys.stderr, flush=True)
sys.exit(0)
