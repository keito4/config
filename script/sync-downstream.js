#!/usr/bin/env node
'use strict';

/**
 * Sync config-managed files (templates, .claude assets) into a checked-out
 * downstream repository working tree.
 *
 * Pure file operations only: no git or gh invocations. The GitHub Actions
 * workflow that drives this script is responsible for checkout, commit, and
 * PR creation. This keeps the script fully testable with Jest.
 *
 * Usage:
 *   node script/sync-downstream.js --repo keito4/ohana --target /path/to/checkout [--check]
 */

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const DEFAULT_MANIFEST = path.join(repoRoot, '.github', 'sync-downstream.json');

const IGNORED_PATTERNS = [/(^|\/)__pycache__(\/|$)/u, /\.pyc$/u];

/**
 * @param {string} relativePath - Posix-style path relative to the config root
 * @returns {boolean} Whether the file must never be synced downstream
 */
function isIgnored(relativePath) {
  return IGNORED_PATTERNS.some((pattern) => pattern.test(relativePath));
}

/**
 * @param {string} groupName - Group name used in error messages
 * @param {unknown} entries - Candidate group entry array
 * @throws {Error} When the group is empty or an entry lacks source/target
 */
function validateGroup(groupName, entries) {
  if (!Array.isArray(entries) || entries.length === 0) {
    throw new Error(`manifest: group "${groupName}" must be a non-empty array`);
  }
  for (const entry of entries) {
    if (typeof entry.source !== 'string' || typeof entry.target !== 'string') {
      throw new Error(`manifest: group "${groupName}" has an entry without source/target`);
    }
  }
}

/**
 * @param {object} repo - Candidate repo entry
 * @param {object} groups - Manifest groups keyed by name
 * @throws {Error} When the repo name or group opt-ins are invalid
 */
function validateRepo(repo, groups) {
  if (typeof repo.name !== 'string' || !/^[\w.-]+\/[\w.-]+$/u.test(repo.name)) {
    throw new Error(`manifest: invalid repo name: ${JSON.stringify(repo.name)}`);
  }
  if (!Array.isArray(repo.groups) || repo.groups.length === 0) {
    throw new Error(`manifest: repo ${repo.name} must opt into at least one group`);
  }
  for (const group of repo.groups) {
    if (!Object.hasOwn(groups, group)) {
      throw new Error(`manifest: repo ${repo.name} references unknown group "${group}"`);
    }
  }
}

/**
 * @param {object} manifest - Parsed manifest object
 * @throws {Error} When the manifest violates the expected schema
 */
function validateManifest(manifest) {
  if (manifest === null || typeof manifest !== 'object') {
    throw new Error('manifest: top-level object is required');
  }
  if (manifest.groups === null || typeof manifest.groups !== 'object') {
    throw new Error('manifest: "groups" object is required');
  }
  if (!Array.isArray(manifest.repos)) {
    throw new Error('manifest: "repos" array is required');
  }
  for (const [groupName, entries] of Object.entries(manifest.groups)) {
    validateGroup(groupName, entries);
  }
  for (const repo of manifest.repos) {
    validateRepo(repo, manifest.groups);
  }
}

/**
 * @param {string} manifestPath - Absolute path to the manifest JSON file
 * @returns {object} Validated manifest
 */
function loadManifest(manifestPath = DEFAULT_MANIFEST) {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  validateManifest(manifest);
  return manifest;
}

/**
 * @param {object} manifest - Validated manifest
 * @param {string} repoName - Downstream repository (owner/name)
 * @returns {{ entries: Array<{source: string, target: string}>, exclude: Set<string> }}
 */
function resolveFilesForRepo(manifest, repoName) {
  const repo = manifest.repos.find((entry) => entry.name === repoName);
  if (repo === undefined) {
    throw new Error(`manifest: unknown repo ${repoName}`);
  }
  const entries = repo.groups.flatMap((group) => manifest.groups[group]);
  return { entries, exclude: new Set(repo.exclude ?? []) };
}

/**
 * Expand a manifest entry into concrete file pairs. Directory entries are
 * walked recursively; file entries map one-to-one.
 *
 * @param {string} configRoot - Absolute path to the config repository root
 * @param {{source: string, target: string}} entry - Manifest entry
 * @returns {Array<{source: string, target: string}>} Posix-style file pairs
 */
function listSourceFiles(configRoot, entry) {
  const absSource = path.join(configRoot, entry.source);
  if (fs.statSync(absSource).isFile()) {
    return [{ source: entry.source, target: entry.target }];
  }
  return fs
    .readdirSync(absSource, { recursive: true })
    .map((rel) => String(rel).split(path.sep).join('/'))
    .filter((rel) => fs.statSync(path.join(absSource, rel)).isFile())
    .map((rel) => ({
      source: path.posix.join(entry.source, rel),
      target: path.posix.join(entry.target, rel),
    }));
}

/**
 * Copy resolved files into the downstream working tree.
 *
 * @param {string} configRoot - Absolute path to the config repository root
 * @param {string} targetRoot - Absolute path to the downstream checkout
 * @param {{ entries: Array<{source: string, target: string}>, exclude: Set<string> }} resolved
 * @param {{ check?: boolean }} [options] - check: report differences without writing
 * @returns {{ copied: string[], unchanged: string[], excluded: string[] }}
 */
function syncFiles(configRoot, targetRoot, resolved, options = {}) {
  const check = options.check === true;
  const result = { copied: [], unchanged: [], excluded: [] };

  for (const entry of resolved.entries) {
    for (const file of listSourceFiles(configRoot, entry)) {
      if (isIgnored(file.source)) {
        continue;
      }
      if (resolved.exclude.has(file.target)) {
        result.excluded.push(file.target);
        continue;
      }
      const sourceContent = fs.readFileSync(path.join(configRoot, file.source));
      const targetPath = path.join(targetRoot, file.target);
      if (fs.existsSync(targetPath) && sourceContent.equals(fs.readFileSync(targetPath))) {
        result.unchanged.push(file.target);
        continue;
      }
      if (!check) {
        fs.mkdirSync(path.dirname(targetPath), { recursive: true });
        fs.writeFileSync(targetPath, sourceContent);
      }
      result.copied.push(file.target);
    }
  }

  return result;
}

/**
 * @param {string[]} argv - CLI arguments (without node and script path)
 * @returns {{ repo?: string, target?: string, manifest?: string, check: boolean }}
 */
function parseArgs(argv) {
  const args = { check: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--check') {
      args.check = true;
    } else if (flag === '--repo' || flag === '--target' || flag === '--manifest') {
      args[flag.slice(2)] = argv[index + 1];
      index += 1;
    } else {
      throw new Error(`unknown argument: ${flag}`);
    }
  }
  return args;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.repo === undefined || args.target === undefined) {
    console.error('usage: sync-downstream.js --repo <owner/name> --target <dir> [--check] [--manifest <path>]');
    process.exit(2);
  }

  const manifest = loadManifest(args.manifest ?? DEFAULT_MANIFEST);
  const resolved = resolveFilesForRepo(manifest, args.repo);
  const result = syncFiles(repoRoot, path.resolve(args.target), resolved, { check: args.check });

  const verb = args.check ? 'would sync' : 'synced';
  console.log(
    `${args.repo}: ${verb} ${result.copied.length} file(s), ${result.unchanged.length} unchanged, ${result.excluded.length} excluded`,
  );
  for (const file of result.copied) {
    console.log(`  ${args.check ? 'diff' : 'copy'}: ${file}`);
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  isIgnored,
  loadManifest,
  validateManifest,
  resolveFilesForRepo,
  listSourceFiles,
  syncFiles,
  parseArgs,
};
