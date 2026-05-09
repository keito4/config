const fs = require('fs');
const path = require('path');

describe('Policy Templates', () => {
  const repoPath = path.resolve(__dirname, '..');
  const policiesDir = path.join(repoPath, 'templates', 'github', 'policies');

  describe('allowed-licenses.json', () => {
    let policy;

    beforeAll(() => {
      const filePath = path.join(policiesDir, 'allowed-licenses.json');
      expect(fs.existsSync(filePath)).toBe(true);
      policy = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    });

    test('should have allowed array', () => {
      expect(Array.isArray(policy.allowed)).toBe(true);
      expect(policy.allowed.length).toBeGreaterThan(0);
    });

    test('should have blocked array', () => {
      expect(Array.isArray(policy.blocked)).toBe(true);
      expect(policy.blocked.length).toBeGreaterThan(0);
    });

    test('should have exceptions array', () => {
      expect(Array.isArray(policy.exceptions)).toBe(true);
    });

    test('should have notes object', () => {
      expect(typeof policy.notes).toBe('object');
      expect(policy.notes).toHaveProperty('allowed');
      expect(policy.notes).toHaveProperty('blocked');
    });

    test('allowed and blocked lists should not overlap', () => {
      const overlap = policy.allowed.filter((lic) => policy.blocked.includes(lic));
      expect(overlap).toHaveLength(0);
    });

    test('blocked list should include major copyleft licenses', () => {
      expect(policy.blocked).toContain('GPL-3.0');
      expect(policy.blocked).toContain('AGPL-3.0');
    });

    test('allowed list should include permissive licenses', () => {
      expect(policy.allowed).toContain('MIT');
      expect(policy.allowed).toContain('Apache-2.0');
      expect(policy.allowed).toContain('ISC');
    });
  });

  describe('complexity-thresholds.json', () => {
    let thresholds;

    beforeAll(() => {
      const filePath = path.join(policiesDir, 'complexity-thresholds.json');
      expect(fs.existsSync(filePath)).toBe(true);
      thresholds = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    });

    test('should have cyclomatic complexity thresholds', () => {
      expect(thresholds).toHaveProperty('cyclomatic');
      expect(typeof thresholds.cyclomatic.warning).toBe('number');
      expect(typeof thresholds.cyclomatic.error).toBe('number');
      expect(thresholds.cyclomatic.warning).toBeLessThan(thresholds.cyclomatic.error);
    });

    test('should have cognitive complexity thresholds', () => {
      expect(thresholds).toHaveProperty('cognitive');
      expect(typeof thresholds.cognitive.warning).toBe('number');
      expect(typeof thresholds.cognitive.error).toBe('number');
      expect(thresholds.cognitive.warning).toBeLessThan(thresholds.cognitive.error);
    });

    test('should have linesPerFunction thresholds', () => {
      expect(thresholds).toHaveProperty('linesPerFunction');
      expect(thresholds.linesPerFunction.warning).toBeLessThan(thresholds.linesPerFunction.error);
    });

    test('should have nestingDepth thresholds', () => {
      expect(thresholds).toHaveProperty('nestingDepth');
      expect(thresholds.nestingDepth.warning).toBeLessThan(thresholds.nestingDepth.error);
    });

    test('should have fileLines thresholds', () => {
      expect(thresholds).toHaveProperty('fileLines');
      expect(thresholds.fileLines.warning).toBeLessThan(thresholds.fileLines.error);
    });

    test('should have excludePatterns array', () => {
      expect(Array.isArray(thresholds.excludePatterns)).toBe(true);
      expect(thresholds.excludePatterns.length).toBeGreaterThan(0);
    });

    test('warning thresholds should be positive numbers', () => {
      const metricKeys = ['cyclomatic', 'cognitive', 'linesPerFunction', 'nestingDepth', 'fileLines'];
      metricKeys.forEach((key) => {
        expect(thresholds[key].warning).toBeGreaterThan(0);
        expect(thresholds[key].error).toBeGreaterThan(0);
      });
    });
  });

  describe('severity-definitions.md', () => {
    let content;

    beforeAll(() => {
      const filePath = path.join(policiesDir, 'severity-definitions.md');
      expect(fs.existsSync(filePath)).toBe(true);
      content = fs.readFileSync(filePath, 'utf8');
    });

    test('should define Critical severity', () => {
      expect(content).toMatch(/Critical|CRITICAL/);
    });

    test('should define High severity', () => {
      expect(content).toMatch(/High|HIGH/);
    });

    test('should define Medium severity', () => {
      expect(content).toMatch(/Medium|MEDIUM/);
    });

    test('should define Low severity', () => {
      expect(content).toMatch(/Low|LOW/);
    });

    test('should define SLA timelines', () => {
      expect(content).toMatch(/24h|24時間/);
    });
  });
});
