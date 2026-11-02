const fs = require('fs');
const path = require('path');
const { load } = require('js-yaml');

test('every PR gets a CI result without widening push triggers', () => {
  const workflow = load(fs.readFileSync(path.join(__dirname, '..', '.github/workflows/ci.yml'), 'utf8'));
  expect(workflow.on.pull_request.branches).toEqual(['main', 'master', 'pre-production', 'production']);
  expect(workflow.on.pull_request.paths).toBeUndefined();
  expect(workflow.on.pull_request['paths-ignore']).toBeUndefined();
  expect(workflow.on.push.paths).toContain('**.js');
  expect(workflow.on.push.paths).not.toContain('**.md');
});
