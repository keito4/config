'use strict';

/**
 * Tests for GitHub documentation templates under templates/github/.
 *
 * Covers pull_request_template.md, CODEOWNERS, CONTRIBUTING.md, and SECURITY.md.
 * These files define the human-facing collaboration standards distributed to
 * other repositories. Tests verify required sections and policy statements exist.
 */

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const githubTemplateDir = path.join(repoRoot, 'templates', 'github');

function readTemplate(relativePath) {
  return fs.readFileSync(path.join(githubTemplateDir, relativePath), 'utf8');
}

function templateExists(relativePath) {
  return fs.existsSync(path.join(githubTemplateDir, relativePath));
}

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
