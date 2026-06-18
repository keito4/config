#!/usr/bin/env python3
"""Shared utilities for Claude Code hooks.

Consolidates common patterns used across hook files:
- JSON input parsing from stdin
- Tool context extraction
- Output formatting (headers, sections, status)
- Git operations
- Package manager detection
"""
import sys
import json
import re
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Callable, Optional, Union


def load_hook_input() -> dict:
    """Load and return JSON input from stdin."""
    return json.load(sys.stdin)


def parse_tool_context(data: dict) -> tuple[str, dict, dict]:
    """Extract standard tool context fields.

    Returns:
        tuple[str, dict, dict]: (tool_name, tool_input, tool_response)
    """
    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}
    tool_response = data.get("tool_response", {}) or {}
    return tool_name, tool_input, tool_response


def get_command(data: dict) -> str:
    """Extract command string from hook input data."""
    tool_input = data.get("tool_input", {}) or {}
    return (tool_input.get("command") or "").strip()


def is_bash_command(tool_name: str) -> bool:
    """Check if the tool is the Bash tool."""
    return tool_name == "Bash"


def is_help_command(command: str) -> bool:
    """Check if command is a help/dry-run command."""
    return "--help" in command or "-h" in command


def extract_pr_url(text: str) -> Optional[tuple]:
    """Extract PR URL and components from text.

    Returns:
        Optional[tuple]: (pr_url, owner, repo, pr_number) or None
    """
    pattern = r"https://github\.com/([^/]+)/([^/]+)/pull/(\d+)"
    match = re.search(pattern, text)
    if match:
        return match.group(0), match.group(1), match.group(2), match.group(3)
    return None


def run_command(
    command: list[str],
    *,
    cwd: Optional[Union[Path, str]] = None,
    timeout: int = 30,
) -> subprocess.CompletedProcess:
    """Run a command with standard hook subprocess defaults."""
    return subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=timeout)


# ============================================================================
# Output formatting
# ============================================================================

def print_header(message: str, width: int = 60) -> None:
    """Print formatted header with separators to stderr."""
    print("", file=sys.stderr, flush=True)
    print("=" * width, file=sys.stderr, flush=True)
    print(message, file=sys.stderr, flush=True)
    print("=" * width, file=sys.stderr, flush=True)


def print_footer(width: int = 60) -> None:
    """Print footer separator to stderr."""
    print("", file=sys.stderr, flush=True)
    print("=" * width, file=sys.stderr, flush=True)


def print_section(title: str, width: int = 40) -> None:
    """Print section header to stderr."""
    print("", file=sys.stderr, flush=True)
    print(f"## {title}", file=sys.stderr, flush=True)
    print("-" * width, file=sys.stderr, flush=True)


def print_status(message: str) -> None:
    """Print status message to stderr."""
    print(message, file=sys.stderr, flush=True)


# ============================================================================
# Git operations
# ============================================================================

def get_git_root() -> Optional[Path]:
    """Get repository root directory, return None if not a git repo."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=10
        )
        root = result.stdout.strip()
        return Path(root) if root and result.returncode == 0 else None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def get_current_branch() -> Optional[str]:
    """Return the current git branch name."""
    try:
        result = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"], timeout=10)
        branch = result.stdout.strip()
        return branch if result.returncode == 0 and branch else None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


# ============================================================================
# GitHub CI monitoring
# ============================================================================

def get_latest_run(branch: Optional[str] = None, delay_seconds: int = 3) -> Optional[dict]:
    """Return the latest GitHub Actions run for a branch."""
    try:
        branch = branch or get_current_branch()
        if not branch:
            return None

        if delay_seconds > 0:
            time.sleep(delay_seconds)

        result = run_command(
            [
                "gh", "run", "list",
                "--branch", branch,
                "--limit", "1",
                "--json", "databaseId,status,conclusion,name,workflowName,headSha,createdAt",
            ],
            timeout=30,
        )
        if result.returncode != 0:
            return None

        runs = json.loads(result.stdout)
        return runs[0] if runs else None
    except Exception as e:
        print(f"⚠️  CI状態取得エラー: {e}", file=sys.stderr, flush=True)
        return None


def watch_ci_run(
    run_id: int,
    timeout_seconds: int = 300,
    check_interval: int = 15,
) -> tuple[str, list]:
    """Watch a GitHub Actions run until completion or timeout."""
    print(f"\n🔄 CI実行を監視中... (最大{timeout_seconds // 60}分)", file=sys.stderr, flush=True)

    start_time = time.time()
    while time.time() - start_time < timeout_seconds:
        try:
            result = run_command(
                ["gh", "run", "view", str(run_id), "--json", "status,conclusion,jobs"],
                timeout=30,
            )
            if result.returncode != 0:
                break

            run_data = json.loads(result.stdout)
            status = run_data.get("status", "")
            conclusion = run_data.get("conclusion", "")

            if status == "completed":
                return conclusion, run_data.get("jobs", [])

            elapsed = int(time.time() - start_time)
            print(f"   ⏳ {elapsed}秒経過... (status: {status})", file=sys.stderr, flush=True)
            time.sleep(check_interval)
        except Exception as e:
            print(f"⚠️  監視エラー: {e}", file=sys.stderr, flush=True)
            break

    return "timeout", []


def get_pr_checks(
    pr_number: str,
    timeout_seconds: int = 600,
    check_interval: int = 15,
) -> tuple[str, list]:
    """Watch PR checks until all are complete, failed, unavailable, or timed out."""
    start_time = time.time()
    last_status = None

    while time.time() - start_time < timeout_seconds:
        try:
            result = run_command(
                ["gh", "pr", "checks", pr_number, "--json", "name,state,conclusion"],
                timeout=30,
            )

            if result.returncode != 0:
                elapsed = int(time.time() - start_time)
                if elapsed < 30:
                    print(f"   ⏳ CIチェック待機中... ({elapsed}秒)", file=sys.stderr, flush=True)
                    time.sleep(check_interval)
                    continue
                return "no_checks", []

            checks = json.loads(result.stdout)
            if not checks:
                elapsed = int(time.time() - start_time)
                if elapsed < 30:
                    print(f"   ⏳ CIチェック待機中... ({elapsed}秒)", file=sys.stderr, flush=True)
                    time.sleep(check_interval)
                    continue
                return "no_checks", []

            completed = [
                c for c in checks
                if c.get("state") in {"SUCCESS", "FAILURE", "SKIPPED"}
            ]
            failed = [
                c for c in checks
                if c.get("conclusion") == "FAILURE" or c.get("state") == "FAILURE"
            ]

            total = len(checks)
            done = len(completed)
            current_status = f"{done}/{total}"
            if current_status != last_status:
                elapsed = int(time.time() - start_time)
                print(f"   ⏳ {elapsed}秒経過... ({done}/{total} 完了)", file=sys.stderr, flush=True)
                last_status = current_status

            if done == total:
                return ("failure", failed) if failed else ("success", checks)

            time.sleep(check_interval)
        except Exception as e:
            print(f"⚠️  監視エラー: {e}", file=sys.stderr, flush=True)
            break

    return "timeout", []


# ============================================================================
# AI review helpers
# ============================================================================

def command_available(command: str) -> bool:
    """Return whether a command is available on PATH."""
    return shutil.which(command) is not None


def run_ai_command(
    label: str,
    command: list[str],
    *,
    cwd: Optional[Union[Path, str]] = None,
    timeout: int = 600,
) -> Optional[str]:
    """Run an external AI CLI command and return stdout when successful."""
    try:
        result = run_command(command, cwd=cwd, timeout=timeout)
        if result.returncode == 0 and result.stdout:
            print(result.stdout, file=sys.stderr, flush=True)
            return result.stdout.strip()

        if result.returncode != 0:
            error_msg = result.stderr[:300] if result.stderr else "不明なエラー"
            print(f"⚠️  {label}エラー: {error_msg}", file=sys.stderr, flush=True)
    except subprocess.TimeoutExpired:
        print(f"⚠️  {label}レビューがタイムアウトしました（{timeout // 60}分）", file=sys.stderr, flush=True)
    except Exception as e:
        print(f"⚠️  {label}レビュー実行エラー: {e}", file=sys.stderr, flush=True)

    return None


def run_parallel_reviews(
    reviewers: dict[str, Callable[[], Optional[str]]],
) -> dict[str, Optional[str]]:
    """Run available review callables in parallel and collect their outputs."""
    results = {name: None for name in reviewers}
    if not reviewers:
        return results

    with ThreadPoolExecutor(max_workers=min(2, len(reviewers))) as executor:
        futures = {executor.submit(fn): name for name, fn in reviewers.items()}
        for future in as_completed(futures):
            reviewer = futures[future]
            try:
                results[reviewer] = future.result()
            except Exception as e:
                print(f"⚠️  {reviewer}レビュー実行エラー: {e}", file=sys.stderr, flush=True)
    return results


# ============================================================================
# Package manager detection
# ============================================================================

def detect_package_manager(root: Union[Path, str]) -> str:
    """Detect package manager from lock files. Prefers ni if available."""
    if shutil.which("nr"):
        return "ni"
    root = Path(root)
    if (root / "bun.lockb").exists() or (root / "bun.lock").exists():
        return "bun"
    if (root / "pnpm-lock.yaml").exists():
        return "pnpm"
    if (root / "yarn.lock").exists():
        return "yarn"
    return "npm"


def build_run_command(pm: str, script_name: str) -> list:
    """Build package manager run command for the given script."""
    if pm == "ni":
        return ["nr", script_name]
    return [pm, "run", script_name]
