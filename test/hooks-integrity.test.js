'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');

describe('Claude Code Hooks integrity', () => {
  const EXPECTED_HOOKS = [
    'common.py',
    'block_config_edit.py',
    'block_dangerous_commands.py',
    'block_inline_secrets.py',
    'block_git_no_verify.py',
    'post_commit_adr_reminder.py',
    'post_edit_auto_lint.py',
    'post_git_push_ci.py',
    'post_pr_ai_review.py',
    'post_pr_ci_watch.py',
    'pre_exit_plan_ai_review.py',
    'pre_git_quality_gates.py',
    'stop_test_verification.py',
  ];

  describe('Hook file existence', () => {
    test.each(EXPECTED_HOOKS)('%s should exist', (hookFile) => {
      expect(fs.existsSync(path.join(hooksDir, hookFile))).toBe(true);
    });
  });

  describe('common.py — shared utility library', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'common.py'), 'utf8');
    });

    test('should define load_hook_input', () => {
      expect(content).toContain('def load_hook_input()');
    });

    test('should define parse_tool_context', () => {
      expect(content).toContain('def parse_tool_context(');
    });

    test('should define get_command', () => {
      expect(content).toContain('def get_command(');
    });

    test('should define get_git_root', () => {
      expect(content).toContain('def get_git_root()');
    });

    test('should define detect_package_manager', () => {
      expect(content).toContain('def detect_package_manager(');
    });

    test('should define build_run_command', () => {
      expect(content).toContain('def build_run_command(');
    });

    test('should support bun as a package manager', () => {
      expect(content).toContain('"bun"');
    });

    test('should support pnpm as a package manager', () => {
      expect(content).toContain('"pnpm"');
    });

    test('should support yarn as a package manager', () => {
      expect(content).toContain('"yarn"');
    });

    test('should default to npm as package manager', () => {
      expect(content).toContain('"npm"');
    });

    test('should define output formatting helpers', () => {
      expect(content).toContain('def print_header(');
      expect(content).toContain('def print_section(');
      expect(content).toContain('def print_status(');
    });

    test('should define extract_pr_url for PR detection', () => {
      expect(content).toContain('def extract_pr_url(');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });
  });

  describe('block_dangerous_commands.py — defense-in-depth', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_dangerous_commands.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should define DANGEROUS_PATTERNS list', () => {
      expect(content).toContain('DANGEROUS_PATTERNS');
    });

    test('should block git force push (--force)', () => {
      expect(content).toContain('git\\s+push\\s+[^|&;<>]*--force');
    });

    test('should block git force push (-f)', () => {
      expect(content).toContain('git\\s+push\\s+[^|&;<>]*-f\\b');
    });

    test('should bound force-push wildcard to avoid chained-command false positives', () => {
      // [^|&;<>]* stops at a pipe/redirect/separator so a later -f in a chained
      // command or flattened heredoc body does not trigger a false positive.
      expect(content).not.toContain('git\\s+push\\s+.*-f\\b');
    });

    test('should block git reset --hard', () => {
      expect(content).toContain('git\\s+reset\\s+--hard');
    });

    test('should block rm -rf', () => {
      // Pattern covers rm -rf, rm -fr, rm -r -f combinations
      expect(content).toContain('rm\\s+-rf');
    });

    test('should block docker system prune', () => {
      expect(content).toContain('docker\\s+system\\s+prune');
    });

    test('should block terraform destroy', () => {
      expect(content).toContain('terraform\\s+destroy');
    });

    test('should block kubectl delete deployments', () => {
      expect(content).toContain('kubectl\\s+delete');
    });

    test('should block AWS EC2 terminate', () => {
      expect(content).toContain('aws\\s+ec2\\s+terminate-instances');
    });

    test('should block AWS S3 recursive delete', () => {
      expect(content).toContain('aws\\s+s3\\s+rm\\s+.*--recursive');
    });

    test('should block gcloud project deletion', () => {
      expect(content).toContain('gcloud\\s+projects\\s+delete');
    });

    test('should block Azure resource group deletion', () => {
      expect(content).toContain('az\\s+group\\s+delete');
    });

    test('should block npm publish', () => {
      expect(content).toContain('npm\\s+publish\\b');
    });

    test('should block SQL DROP statements', () => {
      expect(content).toContain('drop\\s+(database|table|schema');
    });

    test('should block Helm uninstall', () => {
      expect(content).toContain('helm\\s+(uninstall|delete)');
    });

    test('should block Vercel production deploy', () => {
      expect(content).toContain('vercel\\s+--prod\\b');
    });

    test('should exit 2 when dangerous command detected', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 for safe commands', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should normalize command for matching (lowercase)', () => {
      expect(content).toContain('.lower()');
    });
  });

  describe('block_inline_secrets.py — inline credential protection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_inline_secrets.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should define SECRET_PATTERNS list', () => {
      expect(content).toContain('SECRET_PATTERNS');
    });

    test('should detect AWS access key ids (AKIA/ASIA)', () => {
      expect(content).toContain('(AKIA|ASIA)[0-9A-Z]{16}');
    });

    test('should detect GitHub personal access tokens', () => {
      expect(content).toContain('ghp_');
    });

    test('should detect Anthropic API keys', () => {
      expect(content).toContain('sk-ant-');
    });

    test('should detect private key blocks', () => {
      expect(content).toContain('PRIVATE KEY');
    });

    test('should whitelist the public Supabase demo JWT', () => {
      expect(content).toContain('SUPABASE_DEMO_MARKER');
    });

    test('should exit 2 when an inline secret is detected', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 for commands without inline secrets', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should reuse get_command from common', () => {
      expect(content).toContain('from common import');
      expect(content).toContain('get_command');
    });
  });

  describe('block_git_no_verify.py — commit hook protection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_git_no_verify.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should block --no-verify flag', () => {
      expect(content).toContain('--no-verify');
    });

    test('should block HUSKY=0 env variable', () => {
      expect(content).toContain('HUSKY=0');
    });

    test('should block -n shorthand for --no-verify after git commit', () => {
      expect(content).toContain('"-n"');
    });

    test('should use shlex for safe command tokenization', () => {
      expect(content).toContain('shlex.split');
    });

    test('should exit 2 when blocked flag detected', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 for clean commands', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should suggest sanitized alternative command', () => {
      expect(content).toContain('sanitized_cmd');
    });
  });

  describe('pre_git_quality_gates.py — CI quality enforcement', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'pre_git_quality_gates.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should detect git commit', () => {
      expect(content).toContain('is_git_commit');
    });

    test('should detect git push', () => {
      expect(content).toContain('is_git_push');
    });

    test('should check for format:check script', () => {
      expect(content).toContain('format:check');
    });

    test('should check for lint script', () => {
      expect(content).toContain('"lint"');
    });

    test('should check for test script', () => {
      expect(content).toContain('"test"');
    });

    test('should check for typecheck / tsc script', () => {
      expect(content).toContain('typecheck');
    });

    test('should check for shellcheck script', () => {
      expect(content).toContain('shellcheck');
    });

    test('should support Biome linter', () => {
      expect(content).toContain('biome');
    });

    test('should detect package manager', () => {
      expect(content).toContain('detect_package_manager');
    });

    test('should have retry logic for transient failures', () => {
      expect(content).toContain('run_with_retry');
    });

    test('should have a configurable timeout', () => {
      expect(content).toContain('DEFAULT_TIMEOUT');
    });

    test('should check for node_modules before running', () => {
      expect(content).toContain('has_node_modules');
    });

    test('should detect Biome / ESLint conflicts', () => {
      expect(content).toContain('detect_linter_conflicts');
    });

    test('should exit 2 when quality gate fails', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 when all checks pass', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should check security credential scan script', () => {
      expect(content).toContain('security-credential-scan.sh');
    });

    test('should check code complexity script', () => {
      expect(content).toContain('code-complexity-check.sh');
    });
  });

  describe('block_config_edit.py — linter config protection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_config_edit.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should define PROTECTED_BASENAMES set', () => {
      expect(content).toContain('PROTECTED_BASENAMES');
    });

    test('should protect ESLint flat config (eslint.config.mjs)', () => {
      expect(content).toContain('eslint.config.mjs');
    });

    test('should protect legacy ESLint config (.eslintrc)', () => {
      expect(content).toContain('.eslintrc');
    });

    test('should protect Biome config (biome.json)', () => {
      expect(content).toContain('biome.json');
    });

    test('should protect Prettier config (.prettierrc)', () => {
      expect(content).toContain('.prettierrc');
    });

    test('should protect TypeScript config (tsconfig.json)', () => {
      expect(content).toContain('tsconfig.json');
    });

    test('should protect ShellCheck config (.shellcheckrc)', () => {
      expect(content).toContain('.shellcheckrc');
    });

    test('should exit 2 when protected file is edited', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 for unprotected files', () => {
      expect(content).toContain('sys.exit(0)');
    });
  });

  describe('stop_test_verification.py — session-end test runner', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'stop_test_verification.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should prevent infinite loop via STOP_HOOK_ACTIVE env var', () => {
      expect(content).toContain('STOP_HOOK_ACTIVE');
    });

    test('should check git changes before running tests', () => {
      expect(content).toContain('has_changes');
    });

    test('should look for test script in package.json', () => {
      expect(content).toContain('package.json');
    });

    test('should handle timeout gracefully', () => {
      expect(content).toContain('TimeoutExpired');
    });

    test('should send feedback when tests fail', () => {
      expect(content).toContain('hookSpecificOutput');
    });

    test('should use detect_package_manager from common', () => {
      expect(content).toContain('detect_package_manager');
    });
  });

  describe('post_commit_adr_reminder.py — architectural change detection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'post_commit_adr_reminder.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should check for existing ADR files before reminding', () => {
      expect(content).toContain('docs/adr/');
    });

    test('should detect package.json changes as architectural signal', () => {
      expect(content).toContain('package\\.json');
    });

    test('should detect CI/CD workflow changes', () => {
      expect(content).toContain('.github/workflows/');
    });

    test('should detect Dockerfile changes', () => {
      expect(content).toContain('Dockerfile');
    });

    test('should detect docker-compose changes', () => {
      expect(content).toContain('docker-compose');
    });

    test('should detect linter/formatter config changes', () => {
      expect(content).toContain('eslint');
    });

    test('should detect TypeScript config changes', () => {
      expect(content).toContain('tsconfig');
    });

    test('should only trigger on actual git commit (not --help/--dry-run)', () => {
      expect(content).toContain('--help');
      expect(content).toContain('--dry-run');
    });

    test('should verify commit succeeded before reminding', () => {
      expect(content).toContain('exit_code');
    });

    test('should return structured JSON output for the hook framework', () => {
      expect(content).toContain('hookSpecificOutput');
    });
  });
});
