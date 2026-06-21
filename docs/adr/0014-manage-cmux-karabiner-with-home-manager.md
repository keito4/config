# ADR 0014: Manage cmux and Karabiner Configuration with Home Manager

## Status

Accepted

## Context

cmux and Karabiner are part of the local macOS development environment. They
affect terminal input behavior, especially Google Japanese Input shortcuts in
cmux and the Caps Lock to Control mapping.

These settings were previously applied directly under `~/.config/`, which made
them easy to lose during a machine rebuild and hard to review. ADR 0012 already
defines `nix/` as the source of truth for macOS packages and local environment
configuration.

## Decision

Manage cmux and Karabiner user configuration through home-manager modules under
`nix/home/`.

- Install cmux through the nix-darwin Homebrew cask list.
- Keep Karabiner Elements and Google Japanese Input in the Homebrew cask list.
- Generate `~/.config/cmux/config` from home-manager and keep terminal keybind
  overrides empty so input-method shortcuts are not consumed by cmux.
- Generate `~/.config/karabiner/karabiner.json` from home-manager.
- Keep the Karabiner virtual keyboard type as `jis` so Japanese-specific virtual
  keys work.
- Explicitly map Caps Lock to left Control.
- Scope the cmux IME shortcut workaround to `com.cmuxterm.app` only:
  - `Ctrl+Shift+J` sends the virtual Kana key.
  - `Ctrl+Shift+;` and `Ctrl+Shift+'` send the virtual Eisuu key.

## Consequences

`darwin-rebuild switch --flake ~/develop/github.com/keito4/config/nix` becomes
the source of truth for these local input settings.

Manual changes to `~/.config/cmux/config` and
`~/.config/karabiner/karabiner.json` will be overwritten by home-manager. This
is intentional so shortcut behavior stays reproducible across machines.

The Karabiner workaround is app-scoped to avoid changing the same shortcuts in
other applications.
