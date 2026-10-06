const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const workflow = yaml.load(
  fs.readFileSync(path.join(__dirname, '../.github/workflows/container-security.yml'), 'utf8'),
);

describe('Container security scan triggers', () => {
  test.each(['push', 'pull_request'])('%s scans changes to the scan policy', (event) => {
    expect(workflow.on[event].paths).toEqual(
      expect.arrayContaining(['.trivyignore', '.github/workflows/container-security.yml']),
    );
  });
});
