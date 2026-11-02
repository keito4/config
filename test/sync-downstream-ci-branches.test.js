'use strict';

const fs = require('fs');
const path = require('path');
const { loadManifest, validateManifest, resolveFilesForRepo, syncFiles } = require('../script/sync-downstream');

const source = 'templates/workflows/quality-gate-fallback.yml';
const target = '.github/workflows/quality-gate-fallback.yml';
const manifestFor = (ciBranches) => ({
  groups: { fallback: [{ source, target }] },
  repos: [{ name: 'fixture/repo', groups: ['fallback'], ciBranches }],
});

describe('downstream ciBranches', () => {
  test.each(
    [null, [], 'main', ['main', 'main'], ['*'], ['feature/x'], ['main\nproduction'], [1], {}].map((value) => [value]),
  )('rejects invalid branch policy %j', (branches) =>
    expect(() => validateManifest(manifestFor(branches))).toThrow(/ciBranches/u),
  );

  test('accepts only the documented literal branch names or an omitted policy', () => {
    expect(() =>
      validateManifest(manifestFor(['main', 'master', 'develop', 'pre-production', 'production'])),
    ).not.toThrow();
    expect(() => validateManifest(manifestFor(undefined))).not.toThrow();
  });

  test('the manifest limits branch overrides to the three reviewed repositories', () => {
    expect(
      loadManifest()
        .repos.filter((repo) => repo.ciBranches !== undefined)
        .map(({ name, ciBranches }) => ({ name, ciBranches })),
    ).toEqual([
      { name: 'keito4/calendar_alerm', ciBranches: ['main', 'master'] },
      { name: 'keito4/intent-gate-android', ciBranches: ['main'] },
      { name: 'keito4/ohana', ciBranches: ['main', 'develop'] },
    ]);
  });
});

describe('CI branch rendering through the real sync operation', () => {
  let configRoot;
  let targetRoot;
  const original =
    'name: fallback\non:\n  push:\n    branches: [production]\n  pull_request:\n    branches: [main, master, pre-production, production]\njobs:\n  audit:\n    steps:\n      - run: |\n          on:\n            pull_request:\n              branches: [production]\n';
  const write = (root, file, content) => {
    fs.mkdirSync(path.dirname(path.join(root, file)), { recursive: true });
    fs.writeFileSync(path.join(root, file), content);
  };
  beforeEach(() => {
    const context = path.join(__dirname, '..', '.context');
    fs.mkdirSync(context, { recursive: true });
    configRoot = fs.mkdtempSync(path.join(context, 'ci-branches-source-'));
    targetRoot = fs.mkdtempSync(path.join(context, 'ci-branches-target-'));
    write(configRoot, source, original);
  });
  afterEach(() => {
    fs.rmSync(configRoot, { recursive: true, force: true });
    fs.rmSync(targetRoot, { recursive: true, force: true });
  });

  test.each([
    [['main', 'master'], '[main, master]'],
    [['main'], '[main]'],
    [['main', 'develop'], '[main, develop]'],
  ])('changes only fallback PR branches for %j', (branches, expected) => {
    const manifest = manifestFor(branches);
    manifest.groups.fallback.push(
      { source, target: '.github/workflows/other.yml' },
      { source: 'app.yml', target: '.github/workflows/ci.yml' },
    );
    write(configRoot, 'app.yml', 'name: application CI\n');
    validateManifest(manifest);
    syncFiles(configRoot, targetRoot, resolveFilesForRepo(manifest, 'fixture/repo'));
    expect(fs.readFileSync(path.join(targetRoot, target), 'utf8')).toBe(
      original.replace('branches: [main, master, pre-production, production]', `branches: ${expected}`),
    );
    expect(fs.readFileSync(path.join(targetRoot, '.github/workflows/other.yml'), 'utf8')).toBe(original);
    expect(fs.readFileSync(path.join(targetRoot, '.github/workflows/ci.yml'), 'utf8')).toBe('name: application CI\n');
  });

  test('check mode reports drift without writing and repeated sync is unchanged', () => {
    const resolved = resolveFilesForRepo(manifestFor(['main']), 'fixture/repo');
    write(targetRoot, target, original);
    expect(syncFiles(configRoot, targetRoot, resolved, { check: true }).copied).toEqual([target]);
    expect(fs.readFileSync(path.join(targetRoot, target), 'utf8')).toBe(original);
    syncFiles(configRoot, targetRoot, resolved);
    const before = fs.statSync(path.join(targetRoot, target)).mtimeMs;
    expect(syncFiles(configRoot, targetRoot, resolved).unchanged).toEqual([target]);
    expect(syncFiles(configRoot, targetRoot, resolved, { check: true }).copied).toEqual([]);
    expect(fs.statSync(path.join(targetRoot, target)).mtimeMs).toBe(before);
  });

  test('omitting the policy keeps literal template copies unchanged', () => {
    syncFiles(configRoot, targetRoot, resolveFilesForRepo(manifestFor(undefined), 'fixture/repo'));
    expect(fs.readFileSync(path.join(targetRoot, target), 'utf8')).toBe(original);
  });

  test('actual manifest sync changes only the three fallback branch policies', () => {
    const manifest = loadManifest();
    const expected = new Set(['keito4/calendar_alerm', 'keito4/intent-gate-android', 'keito4/ohana']);
    const tree = (root) =>
      fs
        .readdirSync(root, { recursive: true })
        .filter((file) => fs.statSync(path.join(root, file)).isFile())
        .sort();
    for (const repo of manifest.repos) {
      const before = path.join(targetRoot, repo.name, 'before');
      const after = path.join(targetRoot, repo.name, 'after');
      const resolved = resolveFilesForRepo(manifest, repo.name);
      syncFiles(path.resolve(__dirname, '..'), before, { ...resolved, ciBranches: undefined });
      syncFiles(path.resolve(__dirname, '..'), after, resolved);
      expect(tree(after)).toEqual(tree(before));
      const changed = tree(before).filter(
        (file) => !fs.readFileSync(path.join(before, file)).equals(fs.readFileSync(path.join(after, file))),
      );
      expect(changed).toEqual(expected.has(repo.name) ? [target] : []);
    }
  });

  test.each([
    'name: missing on\njobs:\n  pull_request:\n    branches: [main]\n',
    'on:\n  push:\n    branches: [main]\n',
    'on:\n  pull_request:\n    branches:\n      - main\n',
    'on:\n  pull_request:\n    branches: [main]\n    branches: [production]\n',
    'on:\n  pull_request:\n    branches: [main]\n  pull_request:\n    paths: ["*.js"]\n',
    'on:\n  pull_request:\n    branches: [main]\n  pull_request:\n    branches: [master]\n',
    'on:\n  pull_request:\n    branches: [main]\non:\n  pull_request:\n    branches: [master]\n',
  ])('rejects missing or ambiguous canonical scope before copying files: %j', (content) => {
    write(configRoot, source, content);
    write(targetRoot, target, 'existing target');
    write(configRoot, 'other.txt', 'new content');
    const manifest = manifestFor(['main']);
    manifest.groups.fallback.unshift({ source: 'other.txt', target: 'other.txt' });
    const resolved = resolveFilesForRepo(manifest, 'fixture/repo');
    for (const check of [false, true]) {
      expect(() => syncFiles(configRoot, targetRoot, resolved, { check })).toThrow(/exactly one canonical/u);
      expect(fs.readFileSync(path.join(targetRoot, target), 'utf8')).toBe('existing target');
      expect(fs.existsSync(path.join(targetRoot, 'other.txt'))).toBe(false);
    }
  });

  test.each(['missing', 'duplicate', 'excluded', 'different source'])('rejects %s fallback mapping', (kind) => {
    const manifest = manifestFor(['main']);
    if (kind === 'missing') manifest.groups.fallback[0].target = 'other.yml';
    if (kind === 'duplicate') manifest.groups.fallback.push({ source, target });
    if (kind === 'excluded') manifest.repos[0].exclude = [target];
    if (kind === 'different source') {
      write(configRoot, 'other.yml', original);
      manifest.groups.fallback[0].source = 'other.yml';
    }
    expect(() => syncFiles(configRoot, targetRoot, resolveFilesForRepo(manifest, 'fixture/repo'))).toThrow(
      /exactly one included/u,
    );
    expect(fs.readdirSync(targetRoot)).toEqual([]);
  });
});
