const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('nix-darwin desktop and Homebrew configuration', () => {
  test('nix-darwin imports Kanary and Homebrew modules', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('../../modules/kanary.nix');
    expect(darwinHost).toContain('../../modules/homebrew.nix');
    expect(darwinHost).not.toContain('karabiner');
    expect(darwinHost).toContain('enableKeyMapping = true;');
    expect(darwinHost).toContain('remapCapsLockToControl = true;');
  });

  test('Dock shows running apps without pinned or recent apps', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('dock = {');
    expect(darwinHost).toContain('show-recents = false;');
    expect(darwinHost).toContain('persistent-apps = [ ];');
    expect(darwinHost).toContain('persistent-others = [ ];');
    expect(darwinHost).not.toContain('"/Applications/Google Chrome.app"');
    expect(darwinHost).not.toContain('"/Applications/Raycast.app"');
  });

  test('menu bar keeps only work-essential system controls visible', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('controlcenter = {');
    expect(darwinHost).toContain('BatteryShowPercentage = true;');
    expect(darwinHost).toContain('AirDrop = false;');
    expect(darwinHost).toContain('Bluetooth = false;');
    expect(darwinHost).toContain('Display = false;');
    expect(darwinHost).toContain('FocusModes = false;');
    expect(darwinHost).toContain('NowPlaying = false;');
    expect(darwinHost).toContain('Sound = false;');

    expect(darwinHost).toContain('menuExtraClock = {');
    expect(darwinHost).toContain('Show24Hour = true;');
    expect(darwinHost).toContain('ShowAMPM = false;');
    expect(darwinHost).toContain('ShowDate = 1;');
    expect(darwinHost).toContain('ShowDayOfMonth = true;');
    expect(darwinHost).toContain('ShowDayOfWeek = true;');
    expect(darwinHost).toContain('ShowSeconds = false;');

    expect(darwinHost).toContain('"com.apple.Spotlight"');
    expect(darwinHost).toContain('"NSStatusItem VisibleCC Item-0" = false;');
    expect(darwinHost).toContain('"com.jordanbaird.Ice"');
    expect(darwinHost).toContain('HideApplicationMenus = true;');
    expect(darwinHost).toContain('ShowOnClick = true;');
    expect(darwinHost).toContain('ShowOnScroll = true;');
    expect(darwinHost).toContain('UseIceBar = false;');
    expect(darwinHost).toContain('launchd.user.agents = {');
    expect(darwinHost).toContain('bettertouchtool = {');
    expect(darwinHost).toContain('ice = {');
    expect(darwinHost).toContain('raycast = {');
    expect(darwinHost).toContain('"/usr/bin/open"');
    expect(darwinHost).toContain('"-a"');
    expect(darwinHost).toContain('"BetterTouchTool"');
    expect(darwinHost).toContain('"Ice"');
    expect(darwinHost).toContain('"Raycast"');
    expect(darwinHost).toContain('RunAtLoad = true;');
  });

  test('Homebrew casks install cmux and input tooling', () => {
    const homebrewModule = readRepoFile('nix/modules/homebrew.nix');

    expect(homebrewModule).toContain('"android-studio"');
    expect(homebrewModule).toContain('"asheshgoplani/tap/agent-deck"');
    expect(homebrewModule).toContain('"cmux"');
    expect(homebrewModule).toContain('"elgato-stream-deck"');
    expect(homebrewModule).toContain('"flutter"');
    expect(homebrewModule).toContain('"google-chrome"');
    expect(homebrewModule).toContain('"google-japanese-ime"');
    expect(homebrewModule).toContain('"duet"');
    expect(homebrewModule).toContain('"linear"');
    expect(homebrewModule).toContain('"readdle-spark"');
    expect(homebrewModule).toContain('"jordanbaird-ice"');
    expect(homebrewModule).toContain('"aerospace"');
    expect(homebrewModule).toContain('"bettertouchtool"');
    expect(homebrewModule).toContain('"raycast"');
    expect(homebrewModule).not.toContain('"mattermost"');
    expect(homebrewModule).not.toContain('"messenger"');
    expect(homebrewModule).not.toContain('"alfred"');
    expect(homebrewModule).not.toContain('"karabiner-elements"');
    expect(homebrewModule).not.toContain('"bartender"');
    expect(homebrewModule).not.toContain('"rancher"');
    expect(homebrewModule).not.toContain('"google-cloud-sdk"');
    expect(homebrewModule).not.toContain('"tailscale"');
    expect(homebrewModule).not.toContain('"koekeishiya/formulae/yabai"');
  });
});
