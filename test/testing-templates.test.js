'use strict';

/**
 * Tests for testing infrastructure templates under templates/testing/.
 *
 * These templates are distributed to Next.js / TypeScript projects as a
 * ready-to-use testing baseline. Tests verify:
 *  - Required files exist on disk
 *  - Jest / Playwright config files contain required structural elements
 *  - Coverage thresholds meet the organization's 70% minimum
 *  - Example test files exist for each supported test category
 */

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const testingTemplateDir = path.join(repoRoot, 'templates', 'testing');

function readTemplate(relativePath) {
  return fs.readFileSync(path.join(testingTemplateDir, relativePath), 'utf8');
}

function templateExists(relativePath) {
  return fs.existsSync(path.join(testingTemplateDir, relativePath));
}

// ---------------------------------------------------------------------------
// jest.config.js — primary Jest configuration template
// ---------------------------------------------------------------------------
describe('templates/testing/jest.config.js', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('jest.config.js')).toBe(true);
    content = readTemplate('jest.config.js');
  });

  test('should export a function (createJestConfig pattern) or a plain config', () => {
    const exportsConfig = content.includes('module.exports') || content.includes('createJestConfig');
    expect(exportsConfig).toBe(true);
  });

  test('should target jsdom test environment for React components', () => {
    expect(content).toContain("testEnvironment: 'jsdom'");
  });

  test('should configure collectCoverageFrom to cover app source files', () => {
    expect(content).toContain('collectCoverageFrom');
    expect(content).toContain('app/**/*.{js,jsx,ts,tsx}');
  });

  test('should define a 70% minimum coverage threshold on all metrics', () => {
    expect(content).toContain('coverageThreshold');
    // branches, functions, lines, statements must all be 70
    const threshold70 = (content.match(/70/g) || []).length;
    expect(threshold70).toBeGreaterThanOrEqual(4);
  });

  test('should set up path aliases with @/ prefix', () => {
    expect(content).toContain("'^@/(.*)$'");
  });

  test('should ignore .next and node_modules in test paths', () => {
    expect(content).toContain('.next/');
    expect(content).toContain('node_modules/');
  });

  test('should configure setupFilesAfterFramework with jest.setup.js', () => {
    expect(content).toContain('jest.setup.js');
  });

  test('should configure polyfill setup file', () => {
    expect(content).toContain('jest.polyfills.js');
  });
});

// ---------------------------------------------------------------------------
// jest.regression.config.js
// ---------------------------------------------------------------------------
describe('templates/testing/jest.regression.config.js', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('jest.regression.config.js')).toBe(true);
    content = readTemplate('jest.regression.config.js');
  });

  test('should use node test environment (API regression tests)', () => {
    expect(content).toContain("testEnvironment: 'node'");
  });

  test('should target regression test files', () => {
    expect(content).toMatch(/tests\/regression/);
  });

  test('should set a longer timeout for API calls', () => {
    expect(content).toContain('testTimeout');
    // Regression tests need longer timeouts than the 10s default
    const timeoutMatch = content.match(/testTimeout:\s*(\d+)/);
    expect(timeoutMatch).not.toBeNull();
    expect(Number(timeoutMatch[1])).toBeGreaterThan(10000);
  });
});

// ---------------------------------------------------------------------------
// jest.scenario.config.js
// ---------------------------------------------------------------------------
describe('templates/testing/jest.scenario.config.js', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('jest.scenario.config.js')).toBe(true);
    content = readTemplate('jest.scenario.config.js');
  });

  test('should use node test environment', () => {
    expect(content).toContain("testEnvironment: 'node'");
  });

  test('should enforce serial execution via maxWorkers: 1', () => {
    expect(content).toContain('maxWorkers: 1');
  });

  test('should set bail to true so scenario failures stop the run', () => {
    expect(content).toContain('bail: true');
  });

  test('should target scenario test files', () => {
    expect(content).toMatch(/tests\/scenario/);
  });
});

// ---------------------------------------------------------------------------
// jest.setup.js
// ---------------------------------------------------------------------------
describe('templates/testing/jest.setup.js', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('jest.setup.js')).toBe(true);
    content = readTemplate('jest.setup.js');
  });

  test('should import @testing-library/jest-dom for extended matchers', () => {
    expect(content).toContain('@testing-library/jest-dom');
  });

  test('should mock Next.js navigation hooks', () => {
    expect(content).toContain("jest.mock('next/navigation'");
    expect(content).toContain('useRouter');
    expect(content).toContain('useSearchParams');
    expect(content).toContain('usePathname');
  });

  test('should set Supabase environment variables for testing', () => {
    expect(content).toContain('NEXT_PUBLIC_SUPABASE_URL');
    expect(content).toContain('NEXT_PUBLIC_SUPABASE_ANON_KEY');
  });

  test('should not contain production URLs or real credentials', () => {
    // Test values should be obviously fake
    expect(content).not.toMatch(/https:\/\/[a-z]{20,}\.supabase\.co/);
    expect(content).toContain('test');
  });
});

// ---------------------------------------------------------------------------
// jest.polyfills.js
// ---------------------------------------------------------------------------
describe('templates/testing/jest.polyfills.js', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('jest.polyfills.js')).toBe(true);
    content = readTemplate('jest.polyfills.js');
  });

  test('should provide a Headers mock', () => {
    expect(content).toContain('Headers');
  });

  test('should be loaded as a setupFiles entry (not setupFilesAfterFramework)', () => {
    // Polyfills must be available before jest.mock() hoisting
    const jestConfig = readTemplate('jest.config.js');
    expect(jestConfig).toContain('setupFiles');
    expect(jestConfig).toContain('jest.polyfills.js');
  });
});

// ---------------------------------------------------------------------------
// Playwright configuration files
// ---------------------------------------------------------------------------
describe('templates/testing/playwright.config.ts', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('playwright.config.ts')).toBe(true);
    content = readTemplate('playwright.config.ts');
  });

  test('should import defineConfig from @playwright/test', () => {
    expect(content).toContain("from '@playwright/test'");
  });

  test('should export a default config object', () => {
    expect(content).toMatch(/export default/);
  });

  test('should configure a base URL', () => {
    expect(content).toContain('baseURL');
  });
});

describe('templates/testing/playwright.regression.config.ts', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('playwright.regression.config.ts')).toBe(true);
    content = readTemplate('playwright.regression.config.ts');
  });

  test('should import defineConfig from @playwright/test', () => {
    expect(content).toContain("from '@playwright/test'");
  });

  test('should export a default config object', () => {
    expect(content).toMatch(/export default/);
  });
});

// ---------------------------------------------------------------------------
// vitest.config.ts
// ---------------------------------------------------------------------------
describe('templates/testing/vitest.config.ts', () => {
  let content;

  beforeAll(() => {
    expect(templateExists('vitest.config.ts')).toBe(true);
    content = readTemplate('vitest.config.ts');
  });

  test('should import defineConfig from vitest/config', () => {
    expect(content).toMatch(/from ['"]vitest\/config['"]/);
  });

  test('should export a default config', () => {
    expect(content).toMatch(/export default/);
  });
});

// ---------------------------------------------------------------------------
// Example test files existence (spot checks)
// ---------------------------------------------------------------------------
describe('templates/testing/examples — example test files', () => {
  const examplesDir = path.join(testingTemplateDir, 'examples');

  const requiredExamples = [
    'component.test.tsx',
    'api.test.ts',
    'integration.test.ts',
    'security.test.ts',
    'hook.test.ts',
  ];

  test.each(requiredExamples)('%s should exist in examples/', (filename) => {
    expect(fs.existsSync(path.join(examplesDir, filename))).toBe(true);
  });

  test('component.test.tsx should import from @testing-library/react', () => {
    const content = fs.readFileSync(path.join(examplesDir, 'component.test.tsx'), 'utf8');
    expect(content).toContain('@testing-library/react');
  });

  test('api.test.ts should test HTTP status codes', () => {
    const content = fs.readFileSync(path.join(examplesDir, 'api.test.ts'), 'utf8');
    expect(content).toMatch(/200|status|toHaveBeenCalled/);
  });

  test('security.test.ts should test for injection or XSS protection', () => {
    const content = fs.readFileSync(path.join(examplesDir, 'security.test.ts'), 'utf8');
    const hasSecurity =
      content.includes('injection') ||
      content.includes('XSS') ||
      content.includes('sanitize') ||
      content.includes('script');
    expect(hasSecurity).toBe(true);
  });

  test('all example files should have at least one describe or test block', () => {
    const files = fs.readdirSync(examplesDir).filter((f) => f.endsWith('.ts') || f.endsWith('.tsx'));
    expect(files.length).toBeGreaterThan(0);
    files.forEach((file) => {
      const content = fs.readFileSync(path.join(examplesDir, file), 'utf8');
      const hasTests = content.includes('describe(') || content.includes('test(') || content.includes('it(');
      expect(hasTests).toBe(true);
    });
  });
});
