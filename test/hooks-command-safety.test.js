'use strict';

const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/block_dangerous_commands.py');

/** フックに Bash ツールの入力を流し込み、終了コードを返す */
function runHook(command) {
  const result = spawnSync('python3', [hookPath], {
    input: JSON.stringify({ tool_name: 'Bash', tool_input: { command } }),
    encoding: 'utf8',
    cwd: path.dirname(hookPath), // common.py を import できるようにする
  });
  return result.status;
}

const BLOCKED_EXIT = 2;
const ALLOWED_EXIT = 0;

describe('block_dangerous_commands.py — behavioral tests', () => {
  test.each([
    ['git force push (--force)', 'git push --force origin main'],
    ['git force push (-f)', 'git push -f origin main'],
    ['git reset --hard', 'git reset --hard HEAD~1'],
    ['rm -rf', 'rm -rf /some/dir'],
    ['rm -r -f', 'rm -r -f /some/dir'],
    ['docker system prune', 'docker system prune -a'],
    ['terraform destroy', 'terraform destroy'],
    ['kubectl delete deployment', 'kubectl delete deployment web'],
    ['aws ec2 terminate-instances', 'aws ec2 terminate-instances --instance-ids i-123'],
    ['aws s3 rm --recursive', 'aws s3 rm s3://bucket --recursive'],
    ['gcloud projects delete', 'gcloud projects delete my-proj'],
    ['az group delete', 'az group delete -n rg'],
    ['npm publish', 'npm publish'],
    ['SQL DROP (uppercase)', 'psql -c DROP TABLE users'],
    ['helm uninstall', 'helm uninstall release'],
    ['vercel --prod', 'vercel --prod'],
    ['quoted script passed to bash -c', `bash -c 'git push --force origin main'`],
  ])('should block %s', (_name, command) => {
    expect(runHook(command)).toBe(BLOCKED_EXIT);
  });

  test.each([
    ['empty command', ''],
    ['plain git push', 'git push origin main'],
    ['git status', 'git status'],
    ['-f in a chained command (flag wildcard is bounded)', 'git push origin main && ls -f'],
    ['dangerous text only inside a quoted data argument', `echo 'git reset --hard'`],
  ])('should allow %s', (_name, command) => {
    expect(runHook(command)).toBe(ALLOWED_EXIT);
  });
});
