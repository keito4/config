'use strict';

/**
 * nix/home/git.nix — home-manager の git 設定テスト。
 *
 * git 設定はすべての開発ワークフローに影響するため、
 * 意図しない変更（認証情報のハードコード、SSH→HTTPS 書き換えの削除など）を
 * 早期に検出することが重要。
 */

const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('home-manager git configuration (nix/home/git.nix)', () => {
  let gitNix;

  beforeAll(() => {
    gitNix = readRepoFile('nix/home/git.nix');
  });

  test('git.nix が存在する', () => {
    expect(fs.existsSync(path.join(repoPath, 'nix/home/git.nix'))).toBe(true);
  });

  test('home-manager programs.git を有効化する', () => {
    expect(gitNix).toContain('programs.git');
    expect(gitNix).toContain('enable = true;');
  });

  describe('認証情報のセキュリティ', () => {
    test('user.name をハードコードしない（マシンごとに設定）', () => {
      expect(gitNix).not.toContain('user.name =');
      expect(gitNix).not.toContain('"name" = ');
    });

    test('user.email をハードコードしない（マシンごとに設定）', () => {
      expect(gitNix).not.toContain('user.email =');
      expect(gitNix).not.toContain('"email" = ');
    });

    test('user.signingkey をハードコードしない（マシンごとに設定）', () => {
      expect(gitNix).not.toContain('user.signingkey =');
      expect(gitNix).not.toContain('"signingkey" = ');
    });
  });

  describe('GitHub 接続設定', () => {
    test('SSH URL を HTTPS に書き換える（CI/企業ネットワーク対応）', () => {
      expect(gitNix).toContain('url."https://github.com/".insteadOf');
      expect(gitNix).toContain('"git@github.com:"');
    });

    test('GitHub の認証に gh CLI を使用する', () => {
      expect(gitNix).toContain('gh auth git-credential');
    });

    test('github.com と gist.github.com の両方に credential helper を設定する', () => {
      expect(gitNix).toContain('"https://github.com"');
      expect(gitNix).toContain('"https://gist.github.com"');
    });
  });

  describe('リポジトリのデフォルト設定', () => {
    test('デフォルトブランチを main に設定する', () => {
      expect(gitNix).toContain('defaultBranch = "main"');
    });

    test('pull.rebase を false に設定する（マージ戦略を明示）', () => {
      expect(gitNix).toContain('rebase = false');
    });

    test('push.default を simple に設定する', () => {
      expect(gitNix).toContain('"simple"');
    });

    test('ghq.root を設定する', () => {
      expect(gitNix).toContain('ghq.root');
      expect(gitNix).toContain('~/develop');
    });
  });

  describe('エディタ設定', () => {
    test('core.editor を設定する', () => {
      expect(gitNix).toContain('editor = ');
    });
  });

  describe('グローバルな gitignore / gitattributes', () => {
    test('excludesfile（グローバル gitignore）を設定する', () => {
      expect(gitNix).toContain('excludesfile = ');
    });

    test('attributesfile（グローバル gitattributes）を設定する', () => {
      expect(gitNix).toContain('attributesfile = ');
    });
  });

  describe('Git LFS', () => {
    test('filter.lfs を設定する', () => {
      expect(gitNix).toContain('filter.lfs');
    });

    test('LFS の clean コマンドを設定する', () => {
      expect(gitNix).toContain('git-lfs clean');
    });

    test('LFS の smudge コマンドを設定する', () => {
      expect(gitNix).toContain('git-lfs smudge');
    });

    test('LFS の filter-process を設定する', () => {
      expect(gitNix).toContain('git-lfs filter-process');
    });

    test('LFS filter を required = true にする', () => {
      expect(gitNix).toContain('required = true');
    });

    test('home.packages に git-lfs を含める', () => {
      expect(gitNix).toContain('pkgs.git-lfs');
    });
  });
});
