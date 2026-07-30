'use strict';

/**
 * prompt_task_reminder.py の挙動テスト。
 *
 * UserPromptSubmit の出力は Claude のコンテキストへ直接注入されるため、
 * 「JSON として妥当か」「壊れた入力でセッションを止めないか」を実起動で検証する。
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/prompt_task_reminder.py');

/** フックに UserPromptSubmit の入力を流し込み、終了コードと stdout を返す */
function runHook(payload) {
  const result = spawnSync('python3', [hookPath], {
    input: typeof payload === 'string' ? payload : JSON.stringify(payload),
    encoding: 'utf8',
    cwd: path.dirname(hookPath), // common.py を import できるようにする
  });

  return { status: result.status, stdout: result.stdout || '' };
}

function runWithPrompt(prompt) {
  return runHook({
    hook_event_name: 'UserPromptSubmit',
    session_id: 'test-session',
    prompt,
  });
}

describe('prompt_task_reminder.py', () => {
  test('should have shebang line', () => {
    const content = fs.readFileSync(hookPath, 'utf8');
    expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
  });

  describe('タスク登録の指示注入', () => {
    test('exit 0 で UserPromptSubmit の additionalContext を返す', () => {
      const { status, stdout } = runWithPrompt('ログイン画面のバグを直して');

      expect(status).toBe(0);
      const output = JSON.parse(stdout);
      expect(output.hookSpecificOutput.hookEventName).toBe('UserPromptSubmit');
      expect(typeof output.hookSpecificOutput.additionalContext).toBe('string');
    });

    test('着手前の TaskCreate と TaskUpdate による状態更新を指示する', () => {
      const { stdout } = runWithPrompt('ログイン画面のバグを直して');
      const context = JSON.parse(stdout).hookSpecificOutput.additionalContext;

      expect(context).toContain('TaskCreate');
      expect(context).toContain('TaskUpdate');
      expect(context).toContain('in_progress');
      expect(context).toContain('completed');
    });

    test('日本語をエスケープせず出力する（コンテキストの可読性のため）', () => {
      const { stdout } = runWithPrompt('ログイン画面のバグを直して');

      expect(stdout).not.toContain('\\u');
    });
  });

  describe('注入しないケース', () => {
    test.each([
      ['空文字', ''],
      ['空白のみ', '   \n  '],
    ])('%s のプロンプトでは何も出力しない', (_label, prompt) => {
      const { status, stdout } = runWithPrompt(prompt);

      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });

    test('prompt フィールドが無い入力でも落ちない', () => {
      const { status, stdout } = runHook({ hook_event_name: 'UserPromptSubmit' });

      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });
  });

  describe('フェイルオープン', () => {
    // 壊れた stdin でフックが exit != 0 になると、プロンプト自体が処理されず作業が止まる。
    test.each([
      ['不正な JSON', 'not json at all'],
      ['空の stdin', ''],
    ])('%s でも exit 0 で終了する', (_label, payload) => {
      const { status, stdout } = runHook(payload);

      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });
  });
});
