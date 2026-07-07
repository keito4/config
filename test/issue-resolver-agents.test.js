'use strict';

const fs = require('fs');
const path = require('path');

const repoRoot = path.join(__dirname, '..');
const agentsDir = path.join(repoRoot, '.claude', 'agents');

/**
 * Read an agent file from the agents directory.
 * @param {string} name - Agent name without .md extension
 * @returns {string} File content
 */
function readAgent(name) {
  return fs.readFileSync(path.join(agentsDir, `${name}.md`), 'utf8');
}

const subAgents = [
  'issue-resolver-code-quality',
  'issue-resolver-dependencies',
  'issue-resolver-documentation',
  'issue-resolver-security',
  'issue-resolver-test-coverage',
];

describe('Issue resolver sub-agent structural contracts', () => {
  describe('File existence', () => {
    test.each(subAgents)('%s.md should exist on disk', (agentName) => {
      expect(fs.existsSync(path.join(agentsDir, `${agentName}.md`))).toBe(true);
    });
  });

  describe('Common structure requirements', () => {
    test.each(subAgents)('%s should start with a markdown heading', (agentName) => {
      const content = readAgent(agentName);
      expect(content.trimStart()).toMatch(/^#\s+/);
    });

    test.each(subAgents)('%s should declare a purpose section (## 目的)', (agentName) => {
      const content = readAgent(agentName);
      expect(content).toContain('## 目的');
    });

    test.each(subAgents)('%s should declare execution steps (## 実行手順)', (agentName) => {
      const content = readAgent(agentName);
      expect(content).toContain('## 実行手順');
    });

    test.each(subAgents)('%s should define success criteria (## 成功基準)', (agentName) => {
      const content = readAgent(agentName);
      expect(content).toContain('## 成功基準');
    });

    test.each(subAgents)('%s should include a PR creation step', (agentName) => {
      const content = readAgent(agentName);
      // Agent must create a PR as the final deliverable
      const hasPrStep =
        content.includes('PRを作成') || content.includes('gh pr create') || content.includes('pull request');
      expect(hasPrStep).toBe(true);
    });

    test.each(subAgents)('%s should include a git commit step', (agentName) => {
      const content = readAgent(agentName);
      expect(content).toContain('git commit');
    });

    test.each(subAgents)('%s should include a git add step', (agentName) => {
      const content = readAgent(agentName);
      expect(content).toContain('git add');
    });
  });

  describe('issue-resolver-code-quality — domain-specific requirements', () => {
    let content;

    beforeAll(() => {
      content = readAgent('issue-resolver-code-quality');
    });

    test('should target TODO and FIXME comment resolution', () => {
      expect(content).toMatch(/TODO|FIXME/);
    });

    test('should mention refactoring as a goal', () => {
      const hasRefactor =
        content.includes('refactor') || content.includes('リファクタリング') || content.includes('Refactor');
      expect(hasRefactor).toBe(true);
    });

    test('should reference code style improvement', () => {
      const hasStyle =
        content.includes('コードスタイル') ||
        content.includes('code style') ||
        content.includes('eslint') ||
        content.includes('prettier');
      expect(hasStyle).toBe(true);
    });

    test('purpose section should mention PR creation', () => {
      const purposeMatch = content.match(/## 目的\n+([\s\S]+?)(?=\n##)/);
      expect(purposeMatch).not.toBeNull();
      expect(purposeMatch?.[1]).toContain('PRを作成');
    });
  });

  describe('issue-resolver-dependencies — domain-specific requirements', () => {
    let content;

    beforeAll(() => {
      content = readAgent('issue-resolver-dependencies');
    });

    test('should reference npm or package management', () => {
      const hasNpm = content.includes('npm') || content.includes('package') || content.includes('パッケージ');
      expect(hasNpm).toBe(true);
    });

    test('should reference security vulnerability scanning', () => {
      const hasAudit = content.includes('npm audit') || content.includes('脆弱性') || content.includes('vulnerabilit');
      expect(hasAudit).toBe(true);
    });

    test('should describe the outdated package detection step', () => {
      const hasOutdated =
        content.includes('outdated') || content.includes('古いパッケージ') || content.includes('npm-outdated');
      expect(hasOutdated).toBe(true);
    });

    test('purpose section should mention vulnerability fixes', () => {
      const purposeMatch = content.match(/## 目的\n+([\s\S]+?)(?=\n##)/);
      expect(purposeMatch).not.toBeNull();
      const purpose = purposeMatch?.[1] ?? '';
      const hasVulnContext =
        purpose.includes('脆弱性') || purpose.includes('vulnerabilit') || purpose.includes('古いパッケージ');
      expect(hasVulnContext).toBe(true);
    });
  });

  describe('issue-resolver-documentation — domain-specific requirements', () => {
    let content;

    beforeAll(() => {
      content = readAgent('issue-resolver-documentation');
    });

    test('should reference README generation or updating', () => {
      expect(content).toContain('README');
    });

    test('should reference API documentation', () => {
      const hasApiDoc = content.includes('API') || content.includes('Swagger') || content.includes('OpenAPI');
      expect(hasApiDoc).toBe(true);
    });

    test('should describe the documentation enrichment goal in the purpose section', () => {
      const purposeMatch = content.match(/## 目的\n+([\s\S]+?)(?=\n##)/);
      expect(purposeMatch).not.toBeNull();
      const purpose = purposeMatch?.[1] ?? '';
      expect(purpose).toContain('README');
    });
  });

  describe('issue-resolver-security — domain-specific requirements', () => {
    let content;

    beforeAll(() => {
      content = readAgent('issue-resolver-security');
    });

    test('should address secret / credential removal', () => {
      const hasSecret =
        content.includes('秘密情報') ||
        content.includes('secret') ||
        content.includes('credential') ||
        content.includes('トークン');
      expect(hasSecret).toBe(true);
    });

    test('should address vulnerability remediation', () => {
      const hasVuln = content.includes('脆弱性') || content.includes('vulnerabilit') || content.includes('CVE');
      expect(hasVuln).toBe(true);
    });

    test('should mention SQL injection as a threat class', () => {
      const hasSql =
        content.includes('SQLインジェクション') ||
        content.includes('sql injection') ||
        content.toLowerCase().includes('sql injection');
      expect(hasSql).toBe(true);
    });

    test('purpose section should reference hardcoded secret removal', () => {
      const purposeMatch = content.match(/## 目的\n+([\s\S]+?)(?=\n##)/);
      expect(purposeMatch).not.toBeNull();
      const purpose = purposeMatch?.[1] ?? '';
      const hasSecretRemoval =
        purpose.includes('秘密情報') || purpose.includes('ハードコード') || purpose.includes('secret');
      expect(hasSecretRemoval).toBe(true);
    });
  });

  describe('issue-resolver-test-coverage — domain-specific requirements', () => {
    let content;

    beforeAll(() => {
      content = readAgent('issue-resolver-test-coverage');
    });

    test('should reference 70% coverage threshold', () => {
      expect(content).toContain('70');
    });

    test('should mention unit tests', () => {
      const hasUnit = content.includes('単体テスト') || content.includes('unit test') || content.includes('Unit Test');
      expect(hasUnit).toBe(true);
    });

    test('should describe coverage measurement', () => {
      const hasCoverage = content.includes('coverage') || content.includes('カバレッジ');
      expect(hasCoverage).toBe(true);
    });

    test('purpose section should mention 70% coverage goal', () => {
      const purposeMatch = content.match(/## 目的\n+([\s\S]+?)(?=\n##)/);
      expect(purposeMatch).not.toBeNull();
      expect(purposeMatch?.[1]).toContain('70');
    });
  });

  describe('Orchestrator integration — sub-agent references', () => {
    let orchestratorContent;

    beforeAll(() => {
      orchestratorContent = readAgent('issue-resolver-orchestrator');
    });

    test.each(subAgents)('orchestrator should reference %s', (agentName) => {
      expect(orchestratorContent).toContain(agentName);
    });
  });
});
