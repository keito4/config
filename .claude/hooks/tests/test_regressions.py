"""Behavior checks for hook launchers, command inspection, and PR check polling."""
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
HOOKS = ROOT / '.claude' / 'hooks'
spec = importlib.util.spec_from_file_location('hook_common', HOOKS / 'common.py')
common = importlib.util.module_from_spec(spec)
spec.loader.exec_module(common)


class HookRegressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (ROOT / ".context").mkdir(exist_ok=True)

    def test_launchers_preserve_rejection_and_only_report_missing_files(self):
        settings = json.loads((ROOT / '.claude' / 'settings.json').read_text())
        entries = settings['hooks']['PreToolUse'] + settings['hooks']['Stop']
        with tempfile.TemporaryDirectory(dir=ROOT / '.context') as directory:
            fixture = Path(directory)
            subprocess.run(['git', 'init', '-q', str(fixture)], check=True)
            for entry in entries:
                for hook in entry['hooks']:
                    command = hook['command']
                    match = re.search(r'\.claude/hooks/(\w+\.py)', command)
                    if not match:
                        continue
                    with self.subTest(script=match[1]):
                        target = fixture / '.claude' / 'hooks' / match[1]
                        target.parent.mkdir(parents=True, exist_ok=True)
                        target.write_text('import sys\nsys.exit(2)\n')
                        result = subprocess.run(['bash', '-c', command], cwd=fixture, text=True, capture_output=True)
                        self.assertEqual(result.returncode, 2)
                        self.assertNotIn('not found', result.stdout)
                        target.unlink()
                        missing = subprocess.run(['bash', '-c', command], cwd=fixture, text=True, capture_output=True)
                        self.assertEqual(missing.returncode, 0)
                        self.assertIn('not found', missing.stdout)

    def test_commands_are_inspected_without_executing_them(self):
        cases = [
            ('git reset --hard', 2),
            ("bash -c 'git reset --hard'", 2),
            ('/bin/sh -c "git reset --hard"', 2),
            ("zsh -lc 'git reset --hard'", 2),
            ('bash -c "sh -c \'git reset --hard\'"', 2),
            ("docker run --name 'a;b' --privileged ubuntu", 2),
            ("bash -c 'echo okay' # don't run anything else", 0),
            ('bash -c \'echo okay\' # "comment', 0),
            ("bash -c 'echo okay' # git reset --hard", 0),
            ("bash -c 'echo okay';# git reset --hard", 0),
            ('bash -c \'echo "# git reset --hard"\'', 0),
            ('bash -c \'echo "#"; git reset --hard\'', 2),
            ("bash -c 'echo okay' # don't run anything else\ngit reset --hard", 2),
            ("echo foo#bar && bash -c 'git reset --hard'", 2),
            ("echo foo#bar", 0),
            ('git push origin main && echo -f', 0),
            ("echo 'git reset --hard'", 0),
            ('printf "%s" "git reset --hard"', 0),
            ('echo bash -c "git reset --hard"', 0),
            ('bash -c \'echo "git reset --hard"\'', 0),
        ]
        for command, expected in cases:
            with self.subTest(command=command):
                result = subprocess.run(
                    [sys.executable, str(HOOKS / 'block_dangerous_commands.py')],
                    input=json.dumps({'tool_input': {'command': command}}),
                    capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, expected, result.stderr)

    def test_pr_checks_use_supported_buckets_and_keep_polling_pending(self):
        pending = subprocess.CompletedProcess([], 8, json.dumps([{'name': 'CI', 'bucket': 'pending'}]), '')
        passed = subprocess.CompletedProcess([], 0, json.dumps([{'name': 'CI', 'bucket': 'pass'}]), '')
        with patch.object(common, 'run_command', side_effect=[pending, passed]) as run, patch.object(common.time, 'sleep'):
            result, checks = common.get_pr_checks('66', check_interval=0)
        self.assertEqual(result, 'success')
        self.assertEqual(len(checks), 1)
        self.assertEqual(run.call_count, 2)
        self.assertEqual(run.call_args.args[0][-1], 'name,bucket')

    def test_pr_checks_accept_skipped_checks(self):
        skipped = subprocess.CompletedProcess([], 0, json.dumps([{'name': 'CI', 'bucket': 'skipping'}]), '')
        with patch.object(common, 'run_command', return_value=skipped), patch.object(common.time, 'sleep'), patch.object(common.time, 'time', side_effect=[0, 1, 2, 601]):
            result, checks = common.get_pr_checks('66')
        self.assertEqual(result, 'success')
        self.assertEqual(len(checks), 1)

    def test_pr_checks_report_failure_even_with_nonzero_exit(self):
        for bucket in ['fail', 'cancel']:
            with self.subTest(bucket=bucket):
                failed = subprocess.CompletedProcess([], 1, json.dumps([{'name': 'CI', 'bucket': bucket}]), '')
                with patch.object(common, 'run_command', return_value=failed), patch.object(common.time, 'sleep'), patch.object(common.time, 'time', side_effect=[0, 1, 31]):
                    result, checks = common.get_pr_checks('66')
                self.assertEqual(result, 'failure')
                self.assertEqual(len(checks), 1)


if __name__ == '__main__':
    unittest.main()
