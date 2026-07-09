const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const inheritedGitEnvKeys = ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX'];

function cleanGitEnv(extra = {}) {
  const env = { ...process.env, ...extra };
  for (const key of inheritedGitEnvKeys) {
    delete env[key];
  }
  return env;
}

function readWorkflow(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

function runUpdateAgentsScriptWithUntrackedDirectory() {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'agents-md-test-'));

  try {
    fs.writeFileSync(
      path.join(tempRoot, 'AGENTS.md'),
      ['# Test Agents', '', '<!-- BEGIN AUTO-GENERATED -->', '<!-- END AUTO-GENERATED -->', ''].join('\n'),
    );
    fs.writeFileSync(
      path.join(tempRoot, 'package.json'),
      JSON.stringify({ scripts: {}, engines: { node: '24.14.1' } }, null, 2),
    );
    fs.mkdirSync(path.join(tempRoot, 'docs'), { recursive: true });
    fs.writeFileSync(path.join(tempRoot, 'docs', 'README.md'), '# Docs\n');
    fs.mkdirSync(path.join(tempRoot, 'next'), { recursive: true });

    execFileSync('git', ['init'], { cwd: tempRoot, env: cleanGitEnv(), stdio: 'ignore' });
    execFileSync('git', ['add', 'AGENTS.md', 'package.json', 'docs/README.md'], {
      cwd: tempRoot,
      env: cleanGitEnv(),
      stdio: 'ignore',
    });

    const scriptPath = path.join(repoPath, 'script', 'update-agents-md.sh');
    execFileSync('bash', [scriptPath], { cwd: tempRoot, env: cleanGitEnv(), encoding: 'utf8' });

    return fs.readFileSync(path.join(tempRoot, 'AGENTS.md'), 'utf8');
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
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
    expect(workflow).toContain('git ls-remote --exit-code --heads origin "$CLAUDE_BRANCH"');
    expect(workflow).toContain('Claude branch $CLAUDE_BRANCH was not pushed.');
    expect(workflow).not.toContain('Claude branch $CLAUDE_BRANCH was not pushed. Skipping PR creation.');
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
    expect(workflow).toContain('anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}');
    expect(workflow).toContain('anthropic_federation_rule_id: ${{ secrets.ANTHROPIC_FEDERATION_RULE_ID }}');
    expect(workflow).toContain('anthropic_organization_id: ${{ secrets.ANTHROPIC_ORGANIZATION_ID }}');
  });

  test('repo-maintenance reports downstream sync when managed files change', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(command).toContain('script/repo-maintenance.sh $ARGUMENTS');
    expect(command).toContain('Downstream sync required');
    expect(script).toContain('Repositories using config-base should run /repo-maintenance or receive a sync PR.');
    expect(script).toContain('script/wait-ci-checks\\.sh');
    expect(script).toContain('git checkout "$CLAUDE_BRANCH" 2>/dev/null || git checkout -b "$CLAUDE_BRANCH"');
  });

  test('large commands delegate to executable scripts', () => {
    const commands = [
      ['.claude/commands/repo-maintenance.md', 'script/repo-maintenance.sh $ARGUMENTS'],
      ['.claude/commands/setup-ci.md', 'script/setup-ci.sh $ARGUMENTS'],
      ['.claude/commands/setup-new-repo.md', 'script/setup-new-repo.sh $ARGUMENTS'],
    ];

    for (const [commandPath, scriptCall] of commands) {
      const command = readWorkflow(commandPath);
      expect(command).toContain('The executable source of truth');
      expect(command).toContain(scriptCall);
      expect(command.split('\n').length).toBeLessThan(80);
    }
  });

  test('repo-maintenance guards archived repositories and private dependency review behavior', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(command).toContain('Repository State Guard');
    expect(script).toContain('isArchived,isPrivate');
    expect(script).toContain('repo_archived="$(echo "$repo_json"');
    expect(script).toContain('if [[ "$repo_archived" == "true" ]]; then');
    expect(script).toContain('CREATE_PR=false');
    expect(script).toContain('Archived repository. Skipping PR creation.');
    expect(script).toContain('REPO_PRIVATE="${repo_private:-false}"');
    expect(script).toContain('Private repo: Dependency Review は optional / skipped を許容');
  });

  test('repo-maintenance validates dependabot safety contracts', () => {
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(script).toContain('templates/workflows/dependabot-auto-merge.yml');
    expect(script).toContain('gh label create "dependabot-minor"');
    expect(script).toContain('gh label create "needs-review"');
    expect(script).toContain('gh label create "breaking-change"');
  });

  test('repo-maintenance syncs managed dependabot and label templates', () => {
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(script).toContain('managed_template_files');
    expect(script).toContain(
      'templates/workflows/dependabot-auto-merge.yml:.github/workflows/dependabot-auto-merge.yml',
    );
    // label-sync.yml is a reusable-workflow caller stub (ADR 0018); copying it
    // over the runnable workflow would break this repository.
    expect(script).not.toContain('templates/workflows/label-sync.yml:.github/workflows/label-sync.yml');
    expect(script).toContain('gh label create "dependabot-minor"');
    expect(script).toContain('gh label create "needs-review"');
    expect(script).toContain('gh label create "breaking-change"');
    expect(script).toContain('差分あり・full modeで更新');
    expect(script).not.toContain('templates/github/labels.yml:.github/labels.yml');
  });

  test('repo-maintenance checks dependency peer compatibility and stores logs under .context', () => {
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(script).toContain('Dependency Peer Compatibility Check');
    expect(script).toContain('npm ls --all --json');
    expect(script).toContain('$CONTEXT_DIR/npm-peer-compat.log');
    expect(script).toContain('$CONTEXT_DIR/pnpm-peer-compat.log');
    expect(script).toContain('--frozen-lockfile');
    expect(script).toContain('dependency compatibility issue');
  });

  test('repo-maintenance stores temporary artifacts in .context instead of os temp directories', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(script).toContain('CONTEXT_DIR="${CONTEXT_DIR:-.context}"');
    expect(command).toContain('Temporary artifacts must stay under `.context/`');
    expect(command).not.toContain('mktemp /tmp/');
    expect(script).not.toContain('mktemp /tmp/');
    expect(command).not.toContain('mktemp -d)');
  });

  test('update-agents-md includes yaml workflows and keeps check artifacts in .context', () => {
    const script = readWorkflow('script/update-agents-md.sh');

    expect(script).toContain('workflow_files()');
    expect(script).toContain("-name '*.yml' -o -name '*.yaml'");
    expect(script).toContain('CONTEXT_DIR="${CONTEXT_DIR:-.context}"');
    expect(script).toContain('mktemp -d "$CONTEXT_DIR/agents-md-check-XXXXX"');
    expect(script).toContain('prettier --write --ignore-path /dev/null "$target"');
    expect(script).not.toContain('mktemp -d -t agents-md-check');
  });

  test('update-agents-md ignores untracked project directories', () => {
    const generated = runUpdateAgentsScriptWithUntrackedDirectory();

    expect(generated).toContain('`docs/`');
    expect(generated).not.toContain('`next/`');
  });

  test('repo-maintenance scans yml and yaml workflows in cross-workflow checks', () => {
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(script).toContain('for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do');
    expect(script).not.toContain('for workflow in .github/workflows/*.yml; do');
    expect(script).not.toContain('ls .github/workflows/*.yml 2>/dev/null');
  });

  test('repo-maintenance validates workflow template actionlint coverage', () => {
    const script = readWorkflow('script/repo-maintenance.sh');
    const workflow = readWorkflow('.github/workflows/ci.yml');

    expect(script).toContain('check_workflow_template_lint_coverage');
    expect(script).toContain('Collect workflow files');
    expect(script).toContain('.context/actionlint-files.txt');
    expect(script).toContain('find .github/workflows/templates');
    expect(script).toContain('find templates/workflows');
    expect(script).toContain("-name '*.yaml'");
    expect(script).toContain('templates/workflows/.*\\*');

    expect(workflow).toContain('name: Collect workflow files');
    expect(workflow).toContain('.context/actionlint-files.txt');
    expect(workflow).toContain('find .github/workflows/templates');
    expect(workflow).toContain('find templates/workflows');
    expect(workflow).toContain('steps.workflow-files.outputs.files');
  });

  test('dependency health script reports peer dependency issues in its json contract', () => {
    const script = readWorkflow('script/dependency-health-check.sh');

    expect(script).toContain('PEER_ISSUES');
    expect(script).toContain('npm list --all --json');
    expect(script).toContain('select(test("peer|invalid|missing"; "i"))');
    expect(script).toContain('"peer_issues": $PEER_ISSUES');
    expect(script).toContain('"$PEER_ISSUES" -gt 0');
  });

  test('repo-maintenance detects required workflow trigger incompatibility', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');
    const script = readWorkflow('script/repo-maintenance.sh');

    expect(command).toContain('Required Workflow Trigger Compatibility Check');
    expect(script).toContain('security-summary.yml');
    expect(script).toContain('security-summary.yaml');
    expect(script).toContain('.github/workflows/*.yaml');
    expect(script).toContain("github\\.event_name == '\\''schedule'\\''");
    expect(script).toContain('/^on:[[:space:]]*');
    expect(script).toContain('/^"on":[[:space:]]*');
    expect(script).toContain('/^\\047on\\047:[[:space:]]*');
    expect(script).toContain('pull_request');
    expect(script).toContain('/^  generate-summary:/');
    expect(script).toContain('/^  [A-Za-z0-9_-]+:/');
  });
});
