'use strict';

const { spawnSync } = require('child_process');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

// Rule values of the root config are asserted in eslint-modules-runtime.test.js and
// lint behavior in eslint-config.test.js. This file only verifies what they cannot:
// that the test-file override globs actually resolve for a real test file via the ESLint CLI.
describe('ESLint runtime behavior', () => {
  test('test file overrides resolve for real test files', () => {
    const result = spawnSync('npx', ['--no-install', 'eslint', '--print-config', 'test/commitlint-config.test.js'], {
      cwd: repoPath,
      encoding: 'utf8',
      timeout: 30000,
    });
    expect(result.status).toBe(0);
    const { rules } = JSON.parse(result.stdout);
    const perFunction = rules['max-lines-per-function'];
    expect(Array.isArray(perFunction) ? perFunction[0] : perFunction).toBe(0);
    expect(rules['max-nested-callbacks']).toEqual([1, 5]);
  });
});
