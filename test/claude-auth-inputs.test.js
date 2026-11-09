'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const yaml = require('js-yaml');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const keys = [
  'CLAUDE_CODE_OAUTH_TOKEN',
  'ANTHROPIC_API_KEY',
  'ANTHROPIC_FEDERATION_RULE_ID',
  'ANTHROPIC_ORGANIZATION_ID',
];
for (const file of ['.github/workflows/claude.yml', 'templates/workflows/claude.yml']) {
  const workflow = yaml.load(fs.readFileSync(path.join(root, file), 'utf8'));
  const job = Object.values(workflow.jobs).find((value) => value.steps?.some((step) => step.id === 'claude-auth'));
  const gate = job.steps.find((step) => step.id === 'claude-auth');
  const action = job.steps.find((step) => step.id === 'claude');
  test(`${file}: preferred credentials reach the pinned Action`, () => {
    for (const key of keys) {
      const expression = '${{ secrets.' + key + ' }}';
      expect(gate.env[key]).toBe(expression);
      expect(action.with[key.toLowerCase()]).toBe(
        key === 'ANTHROPIC_API_KEY'
          ? "${{ secrets.CLAUDE_CODE_OAUTH_TOKEN == '' && secrets.ANTHROPIC_API_KEY || '' }}"
          : expression,
      );
    }
    expect(action.uses).toBe('anthropics/claude-code-action@61a9c274fa7110a66dfafc1bbbced03833eb25fe');
    expect(action.if).toContain("steps.claude-auth.outputs.available == 'true'");
    expect(job.permissions['id-token']).toBe('write');
  });
  for (let mask = 0; mask < 16; mask++) {
    test(`${file}: actual authentication gate combination ${mask}`, () => {
      fs.mkdirSync(path.join(root, '.context'), { recursive: true });
      const dir = fs.mkdtempSync(path.join(root, '.context/auth-input-test-'));
      const output = path.join(dir, 'output');
      const configured = keys.map((_, index) => Boolean(mask & (1 << index)));
      const env = Object.fromEntries(keys.map((key, index) => [key, configured[index] ? 'test-only-placeholder' : '']));
      try {
        for (const key of keys) {
          const forwarded = vm.runInNewContext(action.with[key.toLowerCase()].slice(3, -2), { secrets: env });
          expect(forwarded).toBe(key === 'ANTHROPIC_API_KEY' && configured[0] ? '' : env[key]);
        }
        execFileSync('bash', ['-euo', 'pipefail', '-c', gate.run], {
          env: { ...env, GITHUB_OUTPUT: output },
          stdio: 'pipe',
        });
        const expected = configured[0] || configured[1] || (configured[2] && configured[3]);
        expect(fs.readFileSync(output, 'utf8').trim()).toBe(`available=${expected}`);
      } finally {
        fs.rmSync(dir, { recursive: true, force: true });
      }
    });
  }
}
