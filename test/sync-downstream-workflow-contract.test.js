const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');
const workflowPath = '.github/workflows/sync-downstream.yml';

function readWorkflow() {
  return fs.readFileSync(path.join(repoPath, workflowPath), 'utf8');
}

// keito4/config#1188 の再発防止。CLAUDE_PAT が 2026-05 頃に失効してから、
// sync-downstream は保持期間内の全 run が failure だったのに誰も気付けなかった。
// 落ちるのは downstream checkout の中なので、ログに出るのは 5 job 分の
// `Bad credentials` だけで、どのシークレットを直せばよいか読み取れなかった。
describe('sync-downstream workflow contracts', () => {
  test('validates the downstream token before any matrix job runs', () => {
    const workflow = readWorkflow();

    expect(workflow).toContain('preflight:');
    expect(workflow).toContain('name: Validate downstream token');
    // 失効しているのか未設定なのかを名指しできないと、対処が分からない。
    expect(workflow).toContain('CLAUDE_PAT');
    expect(workflow).toMatch(/api\.github\.com\/user/);
    expect(workflow).toMatch(/::error::/);
  });

  test('gates plan and sync behind the preflight check', () => {
    const workflow = readWorkflow();

    expect(workflow).toMatch(/plan:\n(?:.*\n)*?\s+needs: preflight/);
    expect(workflow).toMatch(/needs: \[preflight, plan\]/);
  });

  test('detects token expiry without waiting for a template push', () => {
    const workflow = readWorkflow();

    expect(workflow).toContain('schedule:');
    expect(workflow).toMatch(/cron: '[^']+'/);
    // 定期実行は生存確認だけ。勝手に downstream PR を作らせない。
    expect(workflow).toMatch(/if: github\.event_name != 'schedule'/);
  });

  test('reports a failure instead of staying silently red', () => {
    const workflow = readWorkflow();

    expect(workflow).toContain('notify:');
    expect(workflow).toContain('gh issue create');
    // 同じ失敗で issue を積み上げない。
    expect(workflow).toContain('gh issue list');
    expect(workflow).toContain('issues: write');
  });

  test('keeps the downstream checkout and PR creation on the validated secret', () => {
    const workflow = readWorkflow();

    const patUses = workflow.match(/token: \$\{\{ secrets\.CLAUDE_PAT \}\}/g) || [];
    expect(patUses).toHaveLength(2);
  });
});
