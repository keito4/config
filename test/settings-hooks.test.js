'use strict';

const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');
const settingsPath = path.join(repoPath, '.claude', 'settings.json');
const hooksDir = path.join(repoPath, '.claude', 'hooks');

describe('.claude/settings.json — hooks configuration', () => {
  let settings;

  beforeAll(() => {
    settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  });

  describe('Top-level structure', () => {
    test('should be valid JSON with $schema field', () => {
      expect(settings).toHaveProperty('$schema');
      expect(settings.$schema).toContain('claude-code-settings');
    });

    test('should have permissions object', () => {
      expect(settings).toHaveProperty('permissions');
      expect(typeof settings.permissions).toBe('object');
    });

    test('should have hooks object', () => {
      expect(settings).toHaveProperty('hooks');
      expect(typeof settings.hooks).toBe('object');
    });
  });

  describe('Hook event types', () => {
    test('should define PreToolUse hooks', () => {
      expect(settings.hooks).toHaveProperty('PreToolUse');
      expect(Array.isArray(settings.hooks.PreToolUse)).toBe(true);
      expect(settings.hooks.PreToolUse.length).toBeGreaterThan(0);
    });

    test('should define PostToolUse hooks', () => {
      expect(settings.hooks).toHaveProperty('PostToolUse');
      expect(Array.isArray(settings.hooks.PostToolUse)).toBe(true);
      expect(settings.hooks.PostToolUse.length).toBeGreaterThan(0);
    });

    test('should define Stop hooks', () => {
      expect(settings.hooks).toHaveProperty('Stop');
      expect(Array.isArray(settings.hooks.Stop)).toBe(true);
      expect(settings.hooks.Stop.length).toBeGreaterThan(0);
    });
  });

  describe('Hook entry structure', () => {
    function getAllHookEntries() {
      return [
        ...(settings.hooks.PreToolUse || []),
        ...(settings.hooks.PostToolUse || []),
        ...(settings.hooks.Stop || []),
      ];
    }

    test('every hook entry should have a matcher field (string)', () => {
      getAllHookEntries().forEach((entry) => {
        expect(typeof entry.matcher).toBe('string');
      });
    });

    test('every hook entry should have a hooks array with at least one item', () => {
      getAllHookEntries().forEach((entry) => {
        expect(Array.isArray(entry.hooks)).toBe(true);
        expect(entry.hooks.length).toBeGreaterThan(0);
      });
    });

    test('each individual hook should have type and command fields', () => {
      getAllHookEntries().forEach((entry) => {
        entry.hooks.forEach((hook) => {
          expect(hook).toHaveProperty('type');
          expect(hook).toHaveProperty('command');
          expect(typeof hook.command).toBe('string');
          expect(hook.command.length).toBeGreaterThan(0);
        });
      });
    });

    test('all hook types should be "command"', () => {
      getAllHookEntries().forEach((entry) => {
        entry.hooks.forEach((hook) => {
          expect(hook.type).toBe('command');
        });
      });
    });
  });

  describe('PreToolUse security gates', () => {
    test('should have a Bash matcher for dangerous command blocking', () => {
      const bashHooks = settings.hooks.PreToolUse.filter((e) => e.matcher === 'Bash');
      expect(bashHooks.length).toBeGreaterThan(0);
    });

    test('should reference block_dangerous_commands.py in a Bash PreToolUse hook', () => {
      const allCommands = settings.hooks.PreToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('block_dangerous_commands.py'))).toBe(true);
    });

    test('should reference block_inline_secrets.py in a Bash PreToolUse hook', () => {
      const allCommands = settings.hooks.PreToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('block_inline_secrets.py'))).toBe(true);
    });

    test('should reference block_git_no_verify.py in a Bash PreToolUse hook', () => {
      const allCommands = settings.hooks.PreToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('block_git_no_verify.py'))).toBe(true);
    });

    test('should reference pre_git_quality_gates.py in a Bash PreToolUse hook', () => {
      const allCommands = settings.hooks.PreToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('pre_git_quality_gates.py'))).toBe(true);
    });

    test('should have a Write|Edit|MultiEdit matcher for config edit blocking', () => {
      const editHooks = settings.hooks.PreToolUse.filter(
        (e) => e.matcher.includes('Write') || e.matcher.includes('Edit'),
      );
      expect(editHooks.length).toBeGreaterThan(0);
    });

    test('should reference block_config_edit.py in Write/Edit PreToolUse hook', () => {
      const allCommands = settings.hooks.PreToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('block_config_edit.py'))).toBe(true);
    });

    test('should reference block_managed_file_edit.py in Write/Edit PreToolUse hook', () => {
      const allCommands = settings.hooks.PreToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('block_managed_file_edit.py'))).toBe(true);
    });

    test('should reference pre_exit_plan_ai_review.py in ExitPlanMode hook', () => {
      const exitPlanHooks = settings.hooks.PreToolUse.filter((e) => e.matcher === 'ExitPlanMode');
      expect(exitPlanHooks.length).toBeGreaterThan(0);
      const allCommands = exitPlanHooks.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('pre_exit_plan_ai_review.py'))).toBe(true);
    });
  });

  describe('PostToolUse automation hooks', () => {
    test('should reference post_edit_auto_lint.py in Write/Edit PostToolUse hook', () => {
      const allCommands = settings.hooks.PostToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('post_edit_auto_lint.py'))).toBe(true);
    });

    test('should reference post_git_push_ci.py in a Bash PostToolUse hook', () => {
      const allCommands = settings.hooks.PostToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('post_git_push_ci.py'))).toBe(true);
    });

    test('should reference post_pr_ci_watch.py in a Bash PostToolUse hook', () => {
      const allCommands = settings.hooks.PostToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('post_pr_ci_watch.py'))).toBe(true);
    });

    test('should reference post_pr_ai_review.py in a Bash PostToolUse hook', () => {
      const allCommands = settings.hooks.PostToolUse.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('post_pr_ai_review.py'))).toBe(true);
    });
  });

  describe('Stop hooks', () => {
    test('should reference stop_test_verification.py', () => {
      const allCommands = settings.hooks.Stop.flatMap((e) => e.hooks.map((h) => h.command));
      expect(allCommands.some((cmd) => cmd.includes('stop_test_verification.py'))).toBe(true);
    });
  });

  describe('Hook script existence', () => {
    // Verify that every hook script referenced in settings.json actually exists
    function extractScriptNames(commands) {
      const scriptPattern = /\.claude\/hooks\/([\w]+\.py)/g;
      const scripts = new Set();
      commands.forEach((cmd) => {
        let match;
        while ((match = scriptPattern.exec(cmd)) !== null) {
          scripts.add(match[1]);
        }
      });
      return [...scripts];
    }

    test('all hook scripts referenced in settings.json should exist on disk', () => {
      const allCommands = [
        ...(settings.hooks.PreToolUse || []),
        ...(settings.hooks.PostToolUse || []),
        ...(settings.hooks.Stop || []),
      ].flatMap((e) => e.hooks.map((h) => h.command));

      const scriptNames = extractScriptNames(allCommands);
      expect(scriptNames.length).toBeGreaterThan(0);

      scriptNames.forEach((scriptName) => {
        const scriptPath = path.join(hooksDir, scriptName);
        expect(fs.existsSync(scriptPath)).toBe(true);
      });
    });
  });

  describe('Permissions structure', () => {
    test('should have allow array with entries', () => {
      expect(Array.isArray(settings.permissions.allow)).toBe(true);
      expect(settings.permissions.allow.length).toBeGreaterThan(0);
    });

    test('should have deny array with dangerous command blocks', () => {
      expect(Array.isArray(settings.permissions.deny)).toBe(true);
      expect(settings.permissions.deny.length).toBeGreaterThan(0);
    });

    test('deny list should block force push', () => {
      const deniedCommands = settings.permissions.deny;
      const hasForceBlockPush = deniedCommands.some((cmd) => cmd.includes('--force') || cmd.includes('-f:'));
      expect(hasForceBlockPush).toBe(true);
    });

    test('deny list should block git reset --hard', () => {
      const deniedCommands = settings.permissions.deny;
      const hasResetHard = deniedCommands.some((cmd) => cmd.includes('reset --hard'));
      expect(hasResetHard).toBe(true);
    });

    test('deny list should protect sensitive files from being read', () => {
      const deniedCommands = settings.permissions.deny;
      const hasDotEnvBlock = deniedCommands.some((cmd) => cmd.includes('.env'));
      expect(hasDotEnvBlock).toBe(true);
    });

    test('allow list should not contain literal secret values', () => {
      settings.permissions.allow.forEach((permission) => {
        // Permissions should be patterns like "Bash(cmd:*)" not secret values
        expect(permission).not.toMatch(/[A-Za-z0-9_-]{40,}/);
      });
    });
  });
});
