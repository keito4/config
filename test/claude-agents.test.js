const fs = require('fs');
const path = require('path');

const repoRoot = path.join(__dirname, '..');
const agentsDir = path.join(repoRoot, '.claude', 'agents');

const onDemandAgents = [
  'act-local-ci-manager',
  'docs-consistency-checker',
  'playwright-test-generator',
  'playwright-test-healer',
  'playwright-test-planner',
  'issue-resolver-orchestrator',
];

function readAgent(name) {
  return fs.readFileSync(path.join(agentsDir, `${name}.md`), 'utf8');
}

function parseFrontmatter(content) {
  expect(content.startsWith('---\n')).toBe(true);
  const end = content.indexOf('\n---', 4);
  expect(end).toBeGreaterThan(0);

  return content
    .slice(4, end)
    .split('\n')
    .filter(Boolean)
    .reduce((frontmatter, line) => {
      const separator = line.indexOf(':');
      if (separator === -1) {
        return frontmatter;
      }
      const key = line.slice(0, separator).trim();
      const value = line.slice(separator + 1).trim();
      return { ...frontmatter, [key]: value };
    }, {});
}

describe('Claude on-demand agent trigger contracts', () => {
  test.each(onDemandAgents)('%s has discoverable agent frontmatter', (agentName) => {
    const frontmatter = parseFrontmatter(readAgent(agentName));

    expect(frontmatter.name).toBe(agentName);
    expect(frontmatter.description).toMatch(/Use this agent/i);
    expect(frontmatter.description.length).toBeGreaterThan(80);
  });

  test('on-demand agents are documented in the trigger registry', () => {
    const readme = fs.readFileSync(path.join(agentsDir, 'README.md'), 'utf8');

    expect(readme).toContain('### On-Demand Trigger Registry');
    onDemandAgents.forEach((agentName) => {
      expect(readme).toContain(`\`${agentName}.md\``);
    });
  });
});
