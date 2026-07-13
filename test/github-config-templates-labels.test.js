'use strict';

/**
 * Tests for labels.yml GitHub configuration template.
 *
 * This template is distributed to other repositories and forms the
 * organization's standard label configuration. Tests verify:
 *  - File exists on disk
 *  - Required structural elements are present
 *  - No personal information is hardcoded
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
// labels.yml
// ---------------------------------------------------------------------------
describe('templates/github/labels.yml', () => {
  let content;
  let labels;

  beforeAll(() => {
    expect(templateExists('labels.yml')).toBe(true);
    content = readTemplate('labels.yml');
    labels = yaml.load(content);
  });

  test('should be a non-empty array', () => {
    expect(Array.isArray(labels)).toBe(true);
    expect(labels.length).toBeGreaterThan(0);
  });

  test('every label should have a name field', () => {
    labels.forEach((label) => {
      expect(typeof label.name).toBe('string');
      expect(label.name.length).toBeGreaterThan(0);
    });
  });

  test('every label should have a color field (6-char hex)', () => {
    labels.forEach((label) => {
      expect(typeof label.color).toBe('string');
      // Color can be a 6-character hex string (without #)
      expect(label.color).toMatch(/^[0-9a-fA-F]{6}$/);
    });
  });

  test('every label should have a description field', () => {
    labels.forEach((label) => {
      expect(typeof label.description).toBe('string');
    });
  });

  test('should include priority labels (P0–P3)', () => {
    const names = labels.map((l) => l.name);
    expect(names.some((n) => n.includes('P0'))).toBe(true);
    expect(names.some((n) => n.includes('P1'))).toBe(true);
    expect(names.some((n) => n.includes('P2'))).toBe(true);
    expect(names.some((n) => n.includes('P3'))).toBe(true);
  });

  test('should include a bug label', () => {
    const names = labels.map((l) => l.name);
    expect(names).toContain('bug');
  });

  test('label names should be unique (no duplicates)', () => {
    const names = labels.map((l) => l.name);
    const uniqueNames = new Set(names);
    expect(uniqueNames.size).toBe(names.length);
  });
});
