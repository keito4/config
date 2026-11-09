const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const yaml = require('js-yaml');

const read = (name) => yaml.load(fs.readFileSync(path.join(__dirname, '../.github/workflows', name), 'utf8'));
const ci = read('ci.yml');
const security = read('container-security.yml');

describe('Container security as a required CI dependency', () => {
  test('CI selects the same paths as the existing push scan', () => {
    const filter = yaml.load(ci.jobs.changes.steps.find((step) => step.id === 'filter').with.filters);
    expect(filter.container_security).toEqual(security.on.push.paths);
    expect(ci.jobs.changes.outputs.container_security).toBe('${{ steps.filter.outputs.container_security }}');
  });

  test('PR CI invokes both security jobs once, then Quality Gate waits for their result', () => {
    const job = ci.jobs['container-security'];
    expect(security.on).toHaveProperty('workflow_call');
    expect(security.on).not.toHaveProperty('pull_request');
    expect(job.uses).toBe('./.github/workflows/container-security.yml');
    expect(job.needs).toContain('changes');
    expect(job.if).toContain("github.event_name == 'pull_request'");
    expect(job.if).toContain("needs.changes.outputs.container_security == 'true'");
    expect(job.if).toContain('github.event.pull_request.changed_files > 3000');
    expect(ci.jobs['quality-gate'].needs).toContain('container-security');
    expect(security.jobs).toHaveProperty('trivy-scan');
    expect(security.jobs).toHaveProperty('sbom-generation');
    for (const name of ['trivy-scan', 'sbom-generation']) {
      expect(security.jobs[name].if).toBeUndefined();
      expect(security.jobs[name]['continue-on-error']).toBeUndefined();
    }
    expect(security.concurrency.group).not.toBe(ci.concurrency.group);
    const gateEnv = ci.jobs['quality-gate'].steps.find((step) => step.name === 'Verify all checks passed').env;
    expect(gateEnv.CHANGES_RESULT).toBe('${{ needs.changes.result }}');
    expect(gateEnv.CONTAINER_SECURITY_CHANGED).toBe('${{ needs.changes.outputs.container_security }}');
    expect(gateEnv.CONTAINER_SECURITY_RESULT).toBe('${{ needs.container-security.result }}');
    expect(gateEnv.PR_CHANGED_FILES).toBe('${{ github.event.pull_request.changed_files }}');
  });

  const script = ci.jobs['quality-gate'].steps.find((step) => step.name === 'Verify all checks passed').run;
  function verify(overrides) {
    const env = {
      ...process.env,
      LINT_RESULT: 'success',
      TEST_RESULT: 'success',
      INTEGRATION_RESULT: 'success',
      INTEGRATION_MACOS_RESULT: 'skipped',
      ACTIONLINT_RESULT: 'success',
      WORKFLOW_TEMPLATE_SYNC_RESULT: 'success',
      PR_SIZE_RESULT: 'success',
      EVENT_NAME: 'pull_request',
      PR_CHANGED_FILES: '42',
      CHANGES_RESULT: 'success',
      CONTAINER_SECURITY_CHANGED: 'true',
      CONTAINER_SECURITY_RESULT: 'success',
      ...overrides,
    };
    return spawnSync('bash', ['-e', '-c', script], { env, encoding: 'utf8' });
  }

  test('accepts a relevant PR only after both jobs have succeeded', () => {
    expect(verify({}).status).toBe(0);
    for (const result of ['failure', 'cancelled', 'skipped', '']) {
      expect(verify({ CONTAINER_SECURITY_RESULT: result }).status).not.toBe(0);
    }
  });

  test('allows unrelated PRs to skip the scan but rejects missing change detection', () => {
    expect(verify({ CONTAINER_SECURITY_CHANGED: 'false', CONTAINER_SECURITY_RESULT: 'skipped' }).status).toBe(0);
    for (const changes of ['failure', 'cancelled', 'skipped']) {
      expect(verify({ CHANGES_RESULT: changes, CONTAINER_SECURITY_RESULT: 'skipped' }).status).not.toBe(0);
    }
    expect(verify({ CONTAINER_SECURITY_CHANGED: '', CONTAINER_SECURITY_RESULT: 'skipped' }).status).not.toBe(0);
    expect(verify({ CONTAINER_SECURITY_CHANGED: 'false', CONTAINER_SECURITY_RESULT: 'failure' }).status).not.toBe(0);
  });

  test('retains non-PR workflows without requiring the reusable PR scan', () => {
    expect(verify({ EVENT_NAME: 'push', CONTAINER_SECURITY_RESULT: 'skipped' }).status).toBe(0);
    expect(
      verify({ EVENT_NAME: 'schedule', CHANGES_RESULT: 'skipped', CONTAINER_SECURITY_RESULT: 'skipped' }).status,
    ).toBe(0);
  });

  test('forces the scan for PRs beyond the file-list API limit and rejects missing counts', () => {
    const large = { PR_CHANGED_FILES: '3001', CONTAINER_SECURITY_CHANGED: 'false' };
    expect(verify({ ...large, CONTAINER_SECURITY_RESULT: 'skipped' }).status).not.toBe(0);
    expect(verify({ ...large, CONTAINER_SECURITY_RESULT: 'success' }).status).toBe(0);
    expect(verify({ PR_CHANGED_FILES: '', CONTAINER_SECURITY_RESULT: 'skipped' }).status).not.toBe(0);
  });
});
