'use strict';

const path = require('path');
const { spawnSync } = require('child_process');

test('hook behavior regressions pass through their real entry points', () => {
  const result = spawnSync('python3', ['-m', 'unittest', 'discover', '-s', '.claude/hooks/tests', '-v'], {
    cwd: path.resolve(__dirname, '..'),
    encoding: 'utf8',
    timeout: 30000,
  });
  if (result.status !== 0) throw new Error(`${result.stdout}\n${result.stderr}`);
  expect(result.status).toBe(0);
});
