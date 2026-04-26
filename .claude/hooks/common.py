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
from pathlib import Path
from typing import Optional, Union


def load_hook_input() -> dict:
    """Load and return JSON input from stdin."""
    return json.load(sys.stdin)


def parse_tool_context(data: dict) -> tuple:
    """Extract standard tool context fields.

    Returns:
        tuple: (tool_name, tool_input, tool_response)
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


def get_changed_files(ref: str = "HEAD", cwd: Optional[str] = None) -> list:
    """Get list of changed files for given ref."""
    try:
        result = subprocess.run(
            ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", ref],
            capture_output=True, text=True, timeout=5,
            cwd=cwd,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip().split("\n")
        return []
    except (subprocess.TimeoutExpired, OSError):
        return []


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
