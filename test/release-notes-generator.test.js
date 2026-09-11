const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const checkScript = path.join(repoPath, 'script', 'check-release-notes.mjs');

// Guards the preset/writer mismatch that only shows up during a real release:
// conventional-changelog-conventionalcommits@10 needs conventional-changelog-writer@9,
// which @semantic-release/release-notes-generator does not ship yet.
describe('semantic-release presets', () => {
  let result;

  beforeAll(() => {
    result = JSON.parse(execFileSync(process.execPath, [checkScript], { cwd: repoPath, encoding: 'utf8' }));
  });

  test('generateNotes renders the configured preset', () => {
    expect(result.notes).toContain('新機能を追加する');
    expect(result.notes).toContain('不具合を修正する');
  });

  test('analyzeCommits resolves a release type with the configured preset', () => {
    expect(result.releaseType).toBe('minor');
  });
});
