#!/usr/bin/env node
// Renders release notes with the presets configured in .releaserc.json.
//
// conventional-changelog-conventionalcommits@10 needs conventional-changelog-writer@9,
// while @semantic-release/release-notes-generator still depends on writer@8. That
// mismatch is invisible to `npm ls` and `npm audit`: it only surfaces during a real
// release as `Missing helper: ...`, which broke every Build and Release run between
// 2026-09-07 and 2026-09-09. Exercising the presets keeps the failure in CI instead.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { analyzeCommits } from '@semantic-release/commit-analyzer';
import { generateNotes } from '@semantic-release/release-notes-generator';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function pluginOptions(name) {
  const releaserc = JSON.parse(fs.readFileSync(path.join(repoRoot, '.releaserc.json'), 'utf8'));
  const entry = releaserc.plugins.find((plugin) => plugin === name || (Array.isArray(plugin) && plugin[0] === name));
  if (entry === undefined) {
    // Falling back to {} here would render with the Angular default preset and
    // report success for a release configuration that no longer uses the plugin.
    throw new Error(`${name} is not configured in .releaserc.json`);
  }
  return Array.isArray(entry) ? (entry[1] ?? {}) : {};
}

const commits = [
  { hash: 'a'.repeat(40), message: 'feat(scope): 新機能を追加する\n\n本文', committerDate: '2026-09-10' },
  { hash: 'b'.repeat(40), message: 'fix(scope): 不具合を修正する', committerDate: '2026-09-10' },
];

const context = {
  cwd: repoRoot,
  options: { repositoryUrl: 'https://github.com/keito4/config' },
  lastRelease: { gitTag: 'v1.0.0', version: '1.0.0' },
  nextRelease: { gitTag: 'v1.1.0', version: '1.1.0', channel: null },
  commits,
  logger: { log() {}, error() {} },
};

const releaseType = await analyzeCommits(pluginOptions('@semantic-release/commit-analyzer'), context);
const notes = await generateNotes(pluginOptions('@semantic-release/release-notes-generator'), context);

console.log(JSON.stringify({ releaseType, notes }));
