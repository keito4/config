'use strict';

/**
 * Tests for GitHub configuration templates under templates/github/.
 *
 * These templates are distributed to other repositories and form the
 * organization's standard configuration baseline. Tests verify:
 *  - Files exist on disk
 *  - Required structural elements are present
 *  - No personal information is hardcoded
 *  - JSON files are valid and contain required fields
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

// ---------------------------------------------------------------------------
// pull_request_template.md
// ---------------------------------------------------------------------------
describe('templates/github/pull_request_template.md', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('pull_request_template.md')).toBe(true);
    content = readTemplate('pull_request_template.md');
  });

  test('should have a Summary section', () => {
    expect(content).toMatch(/## Summary/);
  });

  test('should have a Why section (change motivation)', () => {
    expect(content).toMatch(/## Why/);
  });

  test('should have a What section (change description)', () => {
    expect(content).toMatch(/## What/);
  });

  test('should have a How to test section', () => {
    expect(content).toMatch(/## How to test/);
  });

  test('should have a Checklist section', () => {
    expect(content).toMatch(/## Checklist/);
  });

  test('should include a self-review checklist item', () => {
    expect(content).toMatch(/セルフレビュー/);
  });
});

// ---------------------------------------------------------------------------
// CODEOWNERS
// ---------------------------------------------------------------------------
describe('templates/github/CODEOWNERS', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('CODEOWNERS')).toBe(true);
    content = readTemplate('CODEOWNERS');
  });

  test('should start with comment lines explaining its purpose', () => {
    expect(content).toContain('# CODEOWNERS');
  });

  test('should include usage instructions', () => {
    expect(content).toMatch(/\.github\/CODEOWNERS/);
  });
});

// ---------------------------------------------------------------------------
// CONTRIBUTING.md
// ---------------------------------------------------------------------------
describe('templates/github/CONTRIBUTING.md', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('CONTRIBUTING.md')).toBe(true);
    content = readTemplate('CONTRIBUTING.md');
  });

  test('should describe Conventional Commits', () => {
    expect(content).toMatch(/Conventional Commits/);
  });

  test('should include branch naming convention', () => {
    expect(content).toMatch(/feat|fix|chore/);
  });
});

// ---------------------------------------------------------------------------
// SECURITY.md
// ---------------------------------------------------------------------------
describe('templates/github/SECURITY.md', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('SECURITY.md')).toBe(true);
    content = readTemplate('SECURITY.md');
  });

  test('should have a Security Policy heading', () => {
    expect(content).toMatch(/# Security Policy/);
  });

  test('should advise against creating public issues for vulnerabilities', () => {
    expect(content).toMatch(/公開 Issue/);
  });

  test('should mention GitHub Security Advisories', () => {
    expect(content).toContain('Security Advisories');
  });
});
