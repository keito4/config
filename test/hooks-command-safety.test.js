'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');

describe('Claude Code command-safety hooks', () => {
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
      expect(content).toContain('aws\\s+s3\\s+rm\\s+[^|&;<>]*--recursive');
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

    test('should bound all flag wildcards to a single command (no greedy \\s+.*)', () => {
      // Flag patterns must use [^|&;<>]* instead of .* so a match cannot reach a
      // flag-like token in a chained command, pipe, redirect or heredoc body
      // (normalize() flattens newlines to spaces). See #794 and follow-up.
      expect(content).not.toContain('\\s+.*');
    });

    test('should strip quoted string content to prevent quoted-separator bypass (Codex P1)', () => {
      // Without this, --name 'a;b' would have ';' treated as a real boundary,
      // allowing docker run --name 'a;b' --privileged ubuntu to bypass the check.
      expect(content).toContain("re.sub(r\"'[^']*'\"");
      expect(content).toContain('re.sub(r\'"[^"]*"\'');
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

    test('should detect Google API keys', () => {
      expect(content).toContain('AIza');
    });

    test('should detect GitLab personal access tokens', () => {
      expect(content).toContain('glpat-');
    });

    test('should detect Doppler tokens', () => {
      expect(content).toContain('Doppler token');
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
});
