const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readWorkflow(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('Claude workflow contracts', () => {
  const issueWorkflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];

  test.each(issueWorkflows)('%s creates PRs in a post-Claude Actions step', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);

    expect(workflow).toContain("github.event.sender.type != 'Bot'");
    expect(workflow).toContain('author_association');
    expect(workflow).toContain('OWNER","MEMBER","COLLABORATOR');
    expect(workflow).toContain('name: Create pull request from Claude branch');
    expect(workflow).toContain('GH_TOKEN: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN || github.token }}');
    expect(workflow).toContain('gh pr create');
    expect(workflow).toContain('PR_ASSIGNEE: ${{ vars.CLAUDE_PR_ASSIGNEE }}');
    expect(workflow).toContain('ASSIGNEE_ARGS=(--assignee "$PR_ASSIGNEE")');
    expect(workflow).toContain('"${ASSIGNEE_ARGS[@]}"');
    expect(workflow).toContain('git ls-remote --exit-code --heads origin "$CLAUDE_BRANCH"');
    // 変更なしタスク（ブランチ未push）は正常終了として扱う（false failure 防止）
    expect(workflow).toContain('Claude branch $CLAUDE_BRANCH was not pushed (no code changes). Skipping PR creation.');
    expect(workflow).not.toMatch(/was not pushed\."\n\s*exit 1/);
    expect(workflow).not.toMatch(/Bash\(gh pr create:\*\)/);
    expect(workflow).not.toContain('github_token: ${{ github.token }}');
    expect(workflow).not.toContain('"allowedTools"');
  });

  test.each(issueWorkflows)('%s skips draft PR issue comments through the Pulls API', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);

    expect(workflow).not.toContain('github.event.issue.draft');
    expect(workflow).toContain('name: Check PR draft state');
    expect(workflow).toContain('github.rest.pulls.get');
    expect(workflow).toContain('pull_number: context.issue.number');
    expect(workflow).toContain("core.setOutput('is_draft', pull.draft ? 'true' : 'false')");
    expect(workflow).toContain("if: steps.pr_draft.outputs.is_draft != 'true'");
    expect(workflow).toContain('name: Skip draft PR');
  });

  test('Claude Code Review uses the shared CI wait script', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('script/wait-ci-checks.sh "$REPO" "$HEAD_SHA"');
    expect(workflow).not.toContain('QUALITY_GATE_STATUS=');
    expect(workflow).not.toContain('QUALITY_GATE_CONCLUSION=');
  });

  // synchronize が無いと、指摘を直して push してもレビューは再実行されず、
  // PR には最初の差分に対するレビューだけが残る（close→reopen での手動再実行が必要だった）。
  test('Claude Code Review re-runs when the PR head is updated', () => {
    const expected = 'types: [opened, synchronize, ready_for_review, reopened]';

    expect(readWorkflow('.github/workflows/claude-code-review.yml')).toContain(expected);
    expect(readWorkflow('templates/workflows/claude-code-review.yml')).toContain(expected);
  });

  test('Claude Code Review skips Anthropic action when its review gate changes', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('review_gate_changed: ${{ steps.gate-change.outputs.review_gate_changed }}');
    expect(workflow).toContain('gh pr diff "$PR_NUMBER" --repo "$REPO" --name-only');
    expect(workflow).toContain('grep -Fxq ".github/workflows/claude-code-review.yml"');
    expect(workflow).toContain('grep -Fxq "script/wait-ci-checks.sh"');
    expect(workflow).toContain("if: steps.gate-change.outputs.review_gate_changed != 'true'");
    expect(workflow).toContain("needs.check-ci-status.outputs.review_gate_changed != 'true'");
  });

  test('Claude Code Review skips Anthropic action when authentication is not configured', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('name: Check Claude authentication');
    expect(workflow).toContain('CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}');
    expect(workflow).toContain('ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}');
    expect(workflow).toContain('ANTHROPIC_FEDERATION_RULE_ID: ${{ secrets.ANTHROPIC_FEDERATION_RULE_ID }}');
    expect(workflow).toContain('ANTHROPIC_ORGANIZATION_ID: ${{ secrets.ANTHROPIC_ORGANIZATION_ID }}');
    expect(workflow).toContain('available=false');
    expect(workflow).toContain("if: steps.claude-auth.outputs.available == 'true'");
    expect(workflow).toContain('anthropic_federation_rule_id: ${{ secrets.ANTHROPIC_FEDERATION_RULE_ID }}');
    expect(workflow).toContain('anthropic_organization_id: ${{ secrets.ANTHROPIC_ORGANIZATION_ID }}');
  });

  // Claude CLI は ANTHROPIC_API_KEY を CLAUDE_CODE_OAUTH_TOKEN より優先する（ADR 0013）。
  // 失効した API キーを無条件に渡すと OAuth トークンが握り潰され、レビューは 401 を
  // 約 180 秒リトライしたのち is_error:true / num_turns:1 / cost $0 で無言終了する。
  test('Claude Code Review prefers the OAuth token over a stale API key', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain(
      "anthropic_api_key: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN == '' && secrets.ANTHROPIC_API_KEY || '' }}",
    );
    expect(workflow).not.toContain('anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}');
  });
});
