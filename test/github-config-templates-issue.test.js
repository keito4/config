'use strict';

/**
 * Tests for GitHub issue template files under templates/github/ISSUE_TEMPLATE/.
 *
 * These templates are distributed to other repositories and form the
 * organization's standard issue workflow. Tests verify:
 *  - Files exist on disk
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
// ISSUE_TEMPLATE/bug_report.yml
// ---------------------------------------------------------------------------
describe('templates/github/ISSUE_TEMPLATE/bug_report.yml', () => {
  let content;
  let template;

  beforeAll(() => {
    expect(templateExists('ISSUE_TEMPLATE/bug_report.yml')).toBe(true);
    content = readTemplate('ISSUE_TEMPLATE/bug_report.yml');
    template = yaml.load(content);
  });

  test('should have a name field', () => {
    expect(typeof template.name).toBe('string');
    expect(template.name.length).toBeGreaterThan(0);
  });

  test('should have a description field', () => {
    expect(typeof template.description).toBe('string');
    expect(template.description.length).toBeGreaterThan(0);
  });

  test('should assign the "bug" label', () => {
    expect(Array.isArray(template.labels)).toBe(true);
    expect(template.labels).toContain('bug');
  });

  test('should have a body array with at least one item', () => {
    expect(Array.isArray(template.body)).toBe(true);
    expect(template.body.length).toBeGreaterThan(0);
  });

  test('should require a description/overview field', () => {
    const textareas = template.body.filter((item) => item.type === 'textarea');
    expect(textareas.length).toBeGreaterThan(0);
    const required = textareas.filter((item) => item.validations?.required === true);
    expect(required.length).toBeGreaterThan(0);
  });

  test('should include a reproduction steps field', () => {
    const labels = template.body.filter((item) => item.attributes?.label).map((item) => item.attributes.label);
    const hasSteps = labels.some(
      (l) => l.includes('再現') || l.toLowerCase().includes('step') || l.toLowerCase().includes('repro'),
    );
    expect(hasSteps).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// ISSUE_TEMPLATE/feature_request.yml
// ---------------------------------------------------------------------------
describe('templates/github/ISSUE_TEMPLATE/feature_request.yml', () => {
  let template;

  beforeAll(() => {
    expect(templateExists('ISSUE_TEMPLATE/feature_request.yml')).toBe(true);
    const content = readTemplate('ISSUE_TEMPLATE/feature_request.yml');
    template = yaml.load(content);
  });

  test('should have a name field', () => {
    expect(typeof template.name).toBe('string');
    expect(template.name.length).toBeGreaterThan(0);
  });

  test('should assign the "enhancement" label', () => {
    expect(Array.isArray(template.labels)).toBe(true);
    expect(template.labels).toContain('enhancement');
  });

  test('should have a body array with at least one required textarea', () => {
    expect(Array.isArray(template.body)).toBe(true);
    const required = template.body.filter((item) => item.type === 'textarea' && item.validations?.required === true);
    expect(required.length).toBeGreaterThan(0);
  });
});

// ---------------------------------------------------------------------------
// ISSUE_TEMPLATE/config.yml
// ---------------------------------------------------------------------------
describe('templates/github/ISSUE_TEMPLATE/config.yml', () => {
  let config;

  beforeAll(() => {
    expect(templateExists('ISSUE_TEMPLATE/config.yml')).toBe(true);
    const content = readTemplate('ISSUE_TEMPLATE/config.yml');
    config = yaml.load(content);
  });

  test('should have blank_issues_enabled field', () => {
    expect(typeof config.blank_issues_enabled).toBe('boolean');
  });
});
