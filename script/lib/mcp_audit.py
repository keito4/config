#!/usr/bin/env python3
"""MCP の定義とプロセスに、平文トークンが argv で載っていないかを検査する。

fix-mcp-token-exposure.sh から呼ばれる。シェル側に埋め込まず独立させているのは、
検査ロジックに分岐が多く、埋め込むと呼び出し元シェルの複雑度計測
(script/code-complexity-check.sh は Python の if/for まで数える) を押し上げるため。

サブコマンド:
  configdir <file> <server>...  config dir の .claude.json を検査する
  projects <root>               root 配下の .mcp.json を検査する (報告のみ)
  processes                     実行中の MCP プロセスの argv を検査する
  audit <root>                  projects と processes をまとめて実行する

⚠️ トークンの値は決して出力しない。検査ログ自体が漏洩源になるため、
   pid と接続先ホスト、サーバー名だけを出す。
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

# シェルが展開する位置 (ダブルクォート内) に $VAR がある = argv に実値が載る
LEAK = re.compile(r'--header\s+"[^"]*\$[A-Za-z_][A-Za-z0-9_]*[^"]*"')
# mcp-remote 自身に展開させる形 (単一引用符 + ${VAR}) = 安全
SAFE = re.compile(r"--header\s+'[^']*\$\{[A-Za-z_][A-Za-z0-9_]*\}[^']*'")
TOKEN_ARG = re.compile(r'--access-token[= ]+"?\$?[A-Za-z_]')

HEADER_VALUE = re.compile(r"--header\s+'?([A-Za-z0-9-]+):\s*([^'\s]+(?:\s+\S+)?)")
TOKEN_VALUE = re.compile(r"--access-token[= ]+(\S+)")
HOST = re.compile(r"https://([A-Za-z0-9.-]+)")

SKIP_PARTS = ("/node_modules/", "/plugins/marketplaces/")

HOWTO = (
    "",
    "  直し方: --header の値を単一引用符の Header:${VAR} 形式にし、",
    "          その VAR を同じコマンド内で export する。",
    "          (コロン直後にスペースを置かないこと)",
    "          雛形: fix-mcp-token-exposure.sh --print <server>",
)

RESTART = (
    "",
    "  定義を直しただけでは消えない。MCP は起動時に spawn されるため、",
    "  該当セッションの再起動が要る (例: agent-deck session restart <id>)。",
)


def leaking_servers(servers: dict) -> list[str]:
    """argv に実トークンが載る定義の名前を返す。"""
    hits = []
    for name, entry in servers.items():
        blob = " ".join(entry.get("args") or [])
        if (LEAK.search(blob) or TOKEN_ARG.search(blob)) and not SAFE.search(blob):
            hits.append(name)
    return sorted(hits)


def scan_config_dir(path: str, names: list[str]) -> int:
    """config dir の .claude.json を検査する (従来 check_config_dir にあった処理)。"""
    servers = json.load(open(path, encoding="utf-8")).get("mcpServers", {})
    leaked = []
    for name in names:
        entry = servers.get(name)
        if entry is None:
            print("  %-12s -- (未設定)" % name)
            continue
        args = entry.get("args") or ["", ""]
        cmd = args[1] if len(args) > 1 else ""
        if "--access-token" in cmd or '--header "Authorization: Bearer' in cmd:
            leaked.append(name)
            print("  %-12s NG (argv にトークン)" % name)
        else:
            print("  %-12s OK" % name)
    return 1 if leaked else 0


def scan_projects(root: str) -> int:
    if not pathlib.Path(root).is_dir():
        print("  スキップ (ディレクトリなし): %s" % root)
        return 0
    bad = 0
    for path in sorted(pathlib.Path(root).rglob(".mcp.json")):
        if any(part in str(path) for part in SKIP_PARTS):
            continue
        try:
            servers = json.load(open(path, encoding="utf-8")).get("mcpServers") or {}
        except Exception as exc:
            print("  ??  読めない: %s (%s)" % (path, exc))
            continue
        hits = leaking_servers(servers)
        if hits:
            bad += 1
            print("  NG  %s -> %s" % (path, ", ".join(hits)))

    if bad:
        print("\n".join(HOWTO))
        return 1
    print("  プロジェクトの .mcp.json に argv 露出はありません。")
    return 0


def scan_processes() -> int:
    out = subprocess.run(
        ["ps", "-eo", "pid=,command="], capture_output=True, text=True
    ).stdout

    leaked = []
    safe = 0
    for line in out.splitlines():
        if "mcp-remote" not in line and "mcp-server" not in line:
            continue
        pid, _, cmd = line.strip().partition(" ")
        match = HEADER_VALUE.search(cmd) or TOKEN_VALUE.search(cmd)
        if not match:
            continue
        if "${" in match.group(match.lastindex):
            safe += 1
            continue
        host = HOST.search(cmd)
        leaked.append((pid, host.group(1) if host else "?"))

    for pid, host in leaked:
        print("  NG  pid=%s %s (argv に実トークン)" % (pid, host))
    print("  プレースホルダ形式で動作中: %d プロセス" % safe)

    if leaked:
        print("\n".join(RESTART))
        return 1
    return 0


def run_audit(root: str) -> int:
    """プロジェクト定義と実行中プロセスを続けて検査する。

    片方が赤でももう片方を必ず実行する (先に止めると全体像が分からない)。
    """
    print("### プロジェクトの .mcp.json (%s)" % root)
    rc = scan_projects(root)
    print("### 実行中プロセスの argv")
    return 1 if scan_processes() or rc else 0


def main(argv: list[str]) -> int:
    cmd = argv[1] if len(argv) > 1 else ""
    arg = argv[2] if len(argv) > 2 else "."
    if cmd == "configdir":
        return scan_config_dir(arg, argv[3:])
    if cmd == "projects":
        return scan_projects(arg)
    if cmd == "processes":
        return scan_processes()
    if cmd == "audit":
        return run_audit(arg)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
