#!/usr/bin/env python3
"""Basic tests for Claude Code hooks"""
import subprocess
import sys
import os
from pathlib import Path

# Get repo root
REPO_ROOT = Path(__file__).parent.parent.parent


def test_hooks_valid_python():
    """Test that all hook scripts are valid Python"""
    hooks_dir = REPO_ROOT / ".claude" / "hooks"
    assert hooks_dir.exists(), f"Hooks directory not found: {hooks_dir}"

    hook_files = list(hooks_dir.glob("*.py"))
    assert len(hook_files) > 0, "No Python hook files found"

    for hook_file in hook_files:
        result = subprocess.run(
            [sys.executable, "-m", "py_compile", str(hook_file)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, \
            f"Syntax error in {hook_file.name}: {result.stderr}"


def test_pre_git_quality_gates_has_required_functions():
    """Test pre_git_quality_gates.py has required functions"""
    hook_file = REPO_ROOT / ".claude" / "hooks" / "pre_git_quality_gates.py"
    content = hook_file.read_text()

    # Functions defined locally in pre_git_quality_gates.py
    required_functions = [
        "has_biome",
        "get_package_scripts",
        "run_with_retry",
        "detect_linter_conflicts",
    ]

    for func in required_functions:
        assert f"def {func}" in content, \
            f"Missing function: {func} in pre_git_quality_gates.py"

    # detect_package_manager and build_run_command are imported from common.py
    assert "from common import" in content, "Missing common import"
    assert "detect_package_manager" in content, "detect_package_manager not imported from common"
    assert "build_run_command" in content, "build_run_command not imported from common"


def test_common_has_shared_functions():
    """Test common.py has shared utility functions"""
    common_file = REPO_ROOT / ".claude" / "hooks" / "common.py"
    content = common_file.read_text()

    required_functions = [
        "detect_package_manager",
        "build_run_command",
        "get_git_root",
        "load_hook_input",
    ]

    for func in required_functions:
        assert f"def {func}" in content, \
            f"Missing function: {func} in common.py"


def test_hook_files_have_shebang():
    """Test all hooks have proper shebang"""
    hooks_dir = REPO_ROOT / ".claude" / "hooks"
    for hook_file in hooks_dir.glob("*.py"):
        first_line = hook_file.read_text().split("\n")[0]
        assert first_line.startswith("#!/usr/bin/env python3"), \
            f"Missing shebang in {hook_file.name}"


if __name__ == "__main__":
    test_hooks_valid_python()
    test_pre_git_quality_gates_has_required_functions()
    test_hook_files_have_shebang()
    print("All tests passed!")
