'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');

/**
 * Execute a snippet of ES module code in a temp file and return the parsed JSON
 * that the snippet writes to stdout via process.stdout.write(JSON.stringify(...)).
 *
 * Jest runs in CJS mode and cannot directly import() ES modules without
 * --experimental-vm-modules. Writing a temporary .mjs file and running it in a
 * Node.js subprocess is the clean, stable alternative — identical to the approach
 * used by eslint-runtime.test.js for testing the ESLint CLI.
 *
 * @param {string} esmCode - ES module code to execute
 * @returns {*} Parsed JSON from stdout
 */
function execEsm(esmCode) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tmpFile = path.join(contextDir, 'esm-probe.mjs');
  try {
    fs.writeFileSync(tmpFile, esmCode, 'utf8');
    const result = spawnSync('node', [tmpFile], {
      cwd: repoPath,
      encoding: 'utf8',
      timeout: 15000,
    });
    if (result.status !== 0) {
      throw new Error(`ESM execution failed (exit ${result.status}):\n${result.stderr}`);
    }
    return JSON.parse(result.stdout);
  } finally {
    fs.rmSync(tmpFile, { force: true });
  }
}

/**
 * Runtime import tests for the ESLint .mjs modules.
 *
 * The existing text-based tests (eslint-complexity-rules.test.js,
 * eslint-main-config.test.js) only read the files as strings and match
 * against expected substrings. They cannot catch:
 *   - Syntax errors that prevent module load
 *   - Wrong export types/shapes (e.g. named vs default)
 *   - Broken imports (missing or misnamed dependency)
 *   - Wrong value types (e.g. max: '15' instead of max: 15)
 *
 * These tests actually execute the modules and assert on the live objects.
 */

describe('ESLint modules — runtime execution validation', () => {
  // ──────────────────────────────────────────────────────────────
  // eslint/complexity-rules.mjs
  // ──────────────────────────────────────────────────────────────
  describe('eslint/complexity-rules.mjs — complexityRules named export', () => {
    const modulePath = path.join(repoPath, 'eslint/complexity-rules.mjs');
    let complexityRules;

    beforeAll(() => {
      complexityRules = execEsm(
        `import { complexityRules } from ${JSON.stringify(modulePath)};\n` +
          `process.stdout.write(JSON.stringify(complexityRules));\n`,
      );
    });

    test('module loads without errors and exports a non-null object', () => {
      expect(typeof complexityRules).toBe('object');
      expect(complexityRules).not.toBeNull();
    });

    test('complexity rule should be [warn, {max: 15}] with max as a number', () => {
      expect(Array.isArray(complexityRules.complexity)).toBe(true);
      const [severity, options] = complexityRules.complexity;
      expect(severity).toBe('warn');
      // Runtime check: max must be the number 15, not the string '15'
      expect(typeof options.max).toBe('number');
      expect(options.max).toBe(15);
    });

    test('max-lines-per-function rule should carry skipBlankLines and skipComments flags', () => {
      const [severity, options] = complexityRules['max-lines-per-function'];
      expect(severity).toBe('warn');
      expect(options.max).toBe(100);
      expect(options.skipBlankLines).toBe(true);
      expect(options.skipComments).toBe(true);
    });

    test('max-lines rule should have max 500 as a number with skip flags', () => {
      const [severity, options] = complexityRules['max-lines'];
      expect(severity).toBe('warn');
      expect(typeof options.max).toBe('number');
      expect(options.max).toBe(500);
      expect(options.skipBlankLines).toBe(true);
      expect(options.skipComments).toBe(true);
    });

    test('max-depth rule should be [warn, 4] with max as a number', () => {
      const [severity, max] = complexityRules['max-depth'];
      expect(severity).toBe('warn');
      expect(typeof max).toBe('number');
      expect(max).toBe(4);
    });

    test('max-params rule should be [warn, 5] with max as a number', () => {
      const [severity, max] = complexityRules['max-params'];
      expect(severity).toBe('warn');
      expect(typeof max).toBe('number');
      expect(max).toBe(5);
    });

    test('should export exactly the 5 documented complexity rules', () => {
      const keys = Object.keys(complexityRules);
      expect(keys).toHaveLength(5);
      expect(keys).toEqual(
        expect.arrayContaining(['complexity', 'max-lines-per-function', 'max-lines', 'max-depth', 'max-params']),
      );
    });

    test('all rule severities must be "warn" (Phase 1 — no "error" level)', () => {
      for (const [ruleName, ruleConfig] of Object.entries(complexityRules)) {
        const severity = Array.isArray(ruleConfig) ? ruleConfig[0] : ruleConfig;
        expect(`${ruleName}: ${severity}`).toBe(`${ruleName}: warn`);
      }
    });
  });

  // ──────────────────────────────────────────────────────────────
  // eslint.config.mjs
  // ──────────────────────────────────────────────────────────────
  describe('eslint.config.mjs — default export (flat config array)', () => {
    const modulePath = path.join(repoPath, 'eslint.config.mjs');
    let config;

    beforeAll(() => {
      config = execEsm(
        `import cfg from ${JSON.stringify(modulePath)};\n` +
          // Strip non-serialisable values (functions, RegExps, etc.) before JSON.stringify
          `process.stdout.write(JSON.stringify(cfg, (_k, v) =>\n` +
          `  typeof v === 'function' ? undefined : v\n` +
          `));\n`,
      );
    });

    test('module loads without errors and exports an array', () => {
      expect(Array.isArray(config)).toBe(true);
      expect(config.length).toBeGreaterThan(0);
    });

    test('should contain an ignores entry listing node_modules, dist, and coverage', () => {
      const ignoresEntry = config.find((entry) => Array.isArray(entry.ignores));
      expect(ignoresEntry).toBeDefined();
      expect(ignoresEntry.ignores).toEqual(expect.arrayContaining(['node_modules/', 'dist/', 'coverage/']));
    });

    test('should contain an entry targeting JS/JSX files with ecmaVersion 2022+', () => {
      const mainEntry = config.find((entry) => entry.languageOptions !== undefined);
      expect(mainEntry).toBeDefined();
      expect(mainEntry.languageOptions.ecmaVersion).toBeGreaterThanOrEqual(2022);
      expect(mainEntry.languageOptions.sourceType).toBe('module');
    });

    test('main rules entry should set no-console to off (string "off", not 0)', () => {
      const rulesEntry = config.find((entry) => entry.rules?.['no-console'] !== undefined);
      expect(rulesEntry).toBeDefined();
      expect(rulesEntry.rules['no-console']).toBe('off');
    });

    test('main rules entry should set no-unused-vars to error with underscore ignore pattern', () => {
      // js.configs.recommended also sets no-unused-vars (as a plain string 'error'), so we
      // look specifically for the entry that uses the array form with options object.
      const rulesEntry = config.find((entry) => Array.isArray(entry.rules?.['no-unused-vars']));
      expect(rulesEntry).toBeDefined();
      const [severity, options] = rulesEntry.rules['no-unused-vars'];
      expect(severity).toBe('error');
      expect(options.argsIgnorePattern).toBe('^_');
    });

    test('main rules entry should include complexity rule with max as the number 15', () => {
      const rulesEntry = config.find((entry) => entry.rules?.complexity !== undefined);
      expect(rulesEntry).toBeDefined();
      const [severity, options] = rulesEntry.rules.complexity;
      expect(severity).toBe('warn');
      expect(typeof options.max).toBe('number');
      expect(options.max).toBe(15);
    });

    test('main rules entry should include max-lines rule with max as the number 500', () => {
      const rulesEntry = config.find((entry) => entry.rules?.['max-lines'] !== undefined);
      expect(rulesEntry).toBeDefined();
      const [, options] = rulesEntry.rules['max-lines'];
      expect(typeof options.max).toBe('number');
      expect(options.max).toBe(500);
    });

    test('test file override entry should disable max-lines-per-function', () => {
      const testOverride = config.find(
        (entry) =>
          Array.isArray(entry.files) &&
          entry.files.some((f) => f.includes('test.js')) &&
          entry.rules?.['max-lines-per-function'] !== undefined,
      );
      expect(testOverride).toBeDefined();
      expect(testOverride.rules['max-lines-per-function']).toBe('off');
    });

    test('test file override entry should relax max-nested-callbacks to 5', () => {
      const testOverride = config.find(
        (entry) =>
          Array.isArray(entry.files) &&
          entry.files.some((f) => f.includes('test.js')) &&
          entry.rules?.['max-nested-callbacks'] !== undefined,
      );
      expect(testOverride).toBeDefined();
      const [severity, max] = testOverride.rules['max-nested-callbacks'];
      expect(severity).toBe('warn');
      expect(max).toBe(5);
    });
  });
});
