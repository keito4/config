'use strict';

/**
 * Tests for dependency management configuration templates under templates/github/.
 *
 * Covers renovate.json and dependabot.yml, which control automated dependency
 * updates across repositories. Tests verify:
 *  - Files exist on disk
 *  - Required structural elements are present
 *  - Throttling / schedule fields are configured
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const repoRoot = path.resolve(__dirname, '..');
const githubTemplateDir = path.join(repoRoot, 'templates', 'github');

function readTemplate(relativePath) {
  return fs.readFileSync(path.join(githubTemplateDir, relativePath), 'utf8');
}

function templateExists(relativePath) {
  return fs.existsSync(path.join(githubTemplateDir, relativePath));
}

// ---------------------------------------------------------------------------
// renovate.json
// ---------------------------------------------------------------------------
describe('templates/github/renovate.json', () => {
  let config;

  beforeAll(() => {
    expect(templateExists('renovate.json')).toBe(true);
    const content = readTemplate('renovate.json');
    config = JSON.parse(content);
  });

  test('should have a $schema field pointing to the official Renovate schema', () => {
    expect(config.$schema).toContain('renovate-schema.json');
  });

  test('should extend from a recommended config preset', () => {
    expect(Array.isArray(config.extends)).toBe(true);
    expect(config.extends.length).toBeGreaterThan(0);
    expect(config.extends.some((e) => e.includes('config:'))).toBe(true);
  });

  test('should define a timezone', () => {
    expect(typeof config.timezone).toBe('string');
    expect(config.timezone.length).toBeGreaterThan(0);
  });

  test('should define a schedule', () => {
    expect(Array.isArray(config.schedule)).toBe(true);
    expect(config.schedule.length).toBeGreaterThan(0);
  });

  test('should define packageRules array', () => {
    expect(Array.isArray(config.packageRules)).toBe(true);
    expect(config.packageRules.length).toBeGreaterThan(0);
  });

  test('should have prHourlyLimit to throttle PR creation', () => {
    expect(typeof config.prHourlyLimit).toBe('number');
    expect(config.prHourlyLimit).toBeGreaterThan(0);
  });
});

// ---------------------------------------------------------------------------
// dependabot.yml
// ---------------------------------------------------------------------------
describe('templates/github/dependabot.yml', () => {
  let config;

  beforeAll(() => {
    expect(templateExists('dependabot.yml')).toBe(true);
    const content = readTemplate('dependabot.yml');
    config = yaml.load(content);
  });

  test('should declare schema version 2', () => {
    expect(config.version).toBe(2);
  });

  test('should define at least one update ecosystem', () => {
    expect(Array.isArray(config.updates)).toBe(true);
    expect(config.updates.length).toBeGreaterThan(0);
  });

  test('every update entry should have package-ecosystem and directory', () => {
    config.updates.forEach((update) => {
      expect(typeof update['package-ecosystem']).toBe('string');
      expect(typeof update.directory).toBe('string');
    });
  });

  test('every update entry should have a schedule with interval', () => {
    config.updates.forEach((update) => {
      expect(update.schedule).toBeDefined();
      expect(typeof update.schedule.interval).toBe('string');
    });
  });

  test('should include npm ecosystem', () => {
    const ecosystems = config.updates.map((u) => u['package-ecosystem']);
    expect(ecosystems).toContain('npm');
  });

  test('should include github-actions ecosystem', () => {
    const ecosystems = config.updates.map((u) => u['package-ecosystem']);
    expect(ecosystems).toContain('github-actions');
  });
});
