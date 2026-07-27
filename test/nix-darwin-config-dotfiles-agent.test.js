const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('home-manager dotfiles and agent tooling', () => {
  test('portable user dotfiles are managed without credential state', () => {
    const dotfilesModule = readRepoFile('nix/home/dotfiles.nix');

    [
      'dot/aerospace.toml',
      'dot/config/act/actrc',
      'dot/config/graphite/aliases',
      'git/gitignore',
      'dot/.peco/config.json',
      '.zsh/configs/aliases.zsh',
      '.zsh/configs/virtual/go.zsh',
      '.zsh/configs/virtual/php.zsh',
      '.zsh/configs/virtual/python.zsh',
      '.zsh/functions/git',
    ].forEach((relativePath) => {
      expect(fs.existsSync(path.join(repoPath, relativePath))).toBe(true);
    });

    expect(dotfilesModule).toContain('managedSource');
    expect(dotfilesModule).toContain('".aerospace.toml"');
    expect(dotfilesModule).toContain('".config/act/actrc"');
    // 組織情報を含む設定は keito4/private-config から out-of-store symlink で参照する
    expect(dotfilesModule).toContain('privateConfig');
    expect(dotfilesModule).toContain('mkOutOfStoreSymlink');
    expect(dotfilesModule).toContain('".config/agent-deck/config.toml"');
    expect(dotfilesModule).toContain('".config/codespaces-secrets/repos.txt"');
    expect(dotfilesModule).toContain('".config/graphite/aliases"');

    // 組織情報を含む設定は private-config（非公開リポジトリ）の out-of-store symlink で管理する
    expect(dotfilesModule).toContain('mkOutOfStoreSymlink');
    expect(dotfilesModule).toContain('keito4/private-config');
    expect(dotfilesModule).toContain('".config/agent-deck/config.toml" = privateConfig');
    expect(dotfilesModule).toContain('".config/codespaces-secrets/repos.txt" = privateConfig');
    expect(dotfilesModule).toContain('".config/devcontainer-env-keys.txt" = privateConfig');
    expect(dotfilesModule).toContain('".gitignore"');
    expect(dotfilesModule).toContain('".peco/config.json"');
    expect(dotfilesModule).toContain('".zsh/configs/virtual/go.zsh"');
    expect(dotfilesModule).toContain('".zsh/configs/virtual/php.zsh"');
    expect(dotfilesModule).toContain('".zsh/configs/virtual/python.zsh"');

    expect(dotfilesModule).not.toContain('user_config');
    expect(dotfilesModule).not.toContain('hosts.yml');
    expect(dotfilesModule).not.toContain('.npmrc');
    expect(dotfilesModule).not.toContain('.ssh');
    expect(dotfilesModule).not.toContain('.env.secret"');
  });

  test('devcontainer env loader reads approved credential keys from private allowlist', () => {
    const zshModule = readRepoFile('nix/home/zsh.nix');
    const devcontainerEnvLoader = readRepoFile('.zsh/configs/pre/devcontainer-env.zsh');

    [zshModule, devcontainerEnvLoader].forEach((loader) => {
      // 許可キーはインライン列挙せず private-config 管理の外部ファイルから読む
      expect(loader).toContain('devcontainer-env-keys.txt');
      expect(loader).toContain('.devcontainer.env');

      // 組織名を含むキーや 1Password サービストークンを公開リポジトリに残さない
      ['ELU_SENTRY_TOKEN', 'ELU_NOTION_API_KEY', 'OYKOT_NOTION_API_KEY', 'OP_SERVICE_ACCOUNT_TOKEN'].forEach(
        (envKey) => {
          expect(loader).not.toContain(envKey);
        },
      );
    });
  });

  test('agent local config collector is installed as a safe command', () => {
    const agentCommandsModule = readRepoFile('nix/home/agent-commands.nix');
    const packagesModule = readRepoFile('nix/home/packages.nix');
    const collectorScript = readRepoFile('script/agent/collect-local-configs.sh');
    const collectorPath = path.join(repoPath, 'script/agent/collect-local-configs.sh');

    expect(packagesModule).toContain('nodejs_24');
    expect(agentCommandsModule).toContain('".local/bin/agent-deck"');
    expect(agentCommandsModule).toContain('mkOutOfStoreSymlink "/opt/homebrew/bin/agent-deck"');
    expect(fs.statSync(collectorPath).mode & 0o111).toBeTruthy();
    expect(agentCommandsModule).toContain('".local/bin/agent-collect-local-configs"');
    expect(agentCommandsModule).toContain('configRoot + /script/agent/collect-local-configs.sh');
    expect(agentCommandsModule).toContain('executable = true;');
    expect(agentCommandsModule).toContain('force = true;');

    expect(collectorScript).toContain('config.local.json');
    expect(collectorScript).toContain('settings.local.json');
    expect(collectorScript).toContain('.env.local');
    expect(collectorScript).toContain('auth.json');
    expect(collectorScript).toContain('credentials*.json');
    expect(collectorScript).toContain('category\\tbytes\\tmtime\\tpath');
    expect(collectorScript).toContain('intentionally does not copy or print file contents');
  });

  test('claude-lmstudio launcher is installed as an executable command', () => {
    const agentCommandsModule = readRepoFile('nix/home/agent-commands.nix');
    const launcherScript = readRepoFile('script/agent/claude-lmstudio.sh');
    const launcherPath = path.join(repoPath, 'script/agent/claude-lmstudio.sh');

    expect(agentCommandsModule).toContain('".local/bin/claude-lmstudio"');
    expect(agentCommandsModule).toContain('configRoot + /script/agent/claude-lmstudio.sh');
    expect(fs.statSync(launcherPath).mode & 0o111).toBeTruthy();

    // Points Claude Code at the local LM Studio Anthropic-compatible endpoint.
    expect(launcherScript).toContain('ANTHROPIC_BASE_URL');
    expect(launcherScript).toContain('http://localhost:1234');
    expect(launcherScript).toContain('exec claude --model');
    // Default to an MLX build; GGUF fails Claude Code tool use on the llama.cpp grammar parser.
    expect(launcherScript).toContain('qwen/qwen3-coder-next');
    expect(launcherScript).toContain('MLX');

    // LM Studio's JIT loader defaults to an 8k context, too small for Claude Code's
    // system prompt, so the launcher must load the model with a usable window itself.
    expect(launcherScript).toContain('LMSTUDIO_CONTEXT_LENGTH');
    expect(launcherScript).toContain('--context-length');

    // Loading alongside a stale small-context copy is not enough: LM Studio routes by
    // model key and serves the stale copy, so the small copies must be unloaded first.
    expect(launcherScript).toContain('lms unload');
  });
});
