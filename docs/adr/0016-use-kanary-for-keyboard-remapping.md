# ADR 0016: Use Kanary and skhd for Keyboard Remapping

## Status

Accepted

## Context

Karabiner Elements has been used for local macOS keyboard behavior:

- Caps Lock to left Control.
- JIS virtual keyboard behavior.
- cmux-scoped IME shortcuts for Google Japanese Input.

Kanary provides a macOS 14+ Apple Silicon menu bar app for keyboard-focused
workflows, including modifier-key taps, app hotkeys, window movement, input
switching, per-app input defaults, and a built-in Caps Lock to Control remap for
JIS users. cmux uses Ghostty for terminal behavior, but neither cmux nor Ghostty
provides a stable built-in shortcut action for running arbitrary shell commands
from terminal keybindings. tmux `user-keys` only help when the focused terminal
is actually running tmux.

Kanary is distributed from `https://kanary.download/download`, which currently
redirects to a versioned ZIP file such as `Kanary-2.3.8.zip`. It is not available
as a standard Homebrew cask in the public Homebrew cask API at the time of this
decision.

## Decision

Stop using Karabiner Elements for local keyboard remapping.

- Stop installing Karabiner Elements through the nix-darwin Homebrew cask list.
- Stop generating `~/.config/karabiner/karabiner.json` through home-manager.
- Keep Google Japanese Input installed.
- Require Kanary for local keyboard remapping through a nix-darwin system check.
- Use nix-darwin's built-in `system.keyboard.remapCapsLockToControl` option for
  the baseline Caps Lock to Control mapping (hidutil). Note: this baseline is
  only effective while Kanary is not intercepting the keyboard; see below.
- Enable Kanary's own `capsLockRemappedToControl` setting and re-assert it from
  home-manager on every activation
  (`nix/home/kanary.nix` +
  `script/macos/kanary-enforce-caps-control.sh`). Kanary's window-move/resize and
  input-switching features grab the physical keyboard and re-emit events through
  a virtual HID device, which bypasses the hidutil mapping, so Caps Lock to
  Control must be owned by Kanary when those features are enabled.
- Install Kanary manually from `https://kanary.download/download` until a stable
  package-manager source exists.
- Use Kanary to manage:
  - Left Command tap to alphanumeric input.
  - Right Command tap to kana input.
  - Per-app default input modes where useful.
- Use nix-darwin's `services.skhd` for terminal-friendly IME shortcuts without
  Karabiner:
  - `Ctrl+Shift+J` selects Google Japanese Input hiragana.
  - `Ctrl+Shift+;` selects Google Japanese Input alphanumeric.

## Consequences

`darwin-rebuild switch --flake ~/develop/github.com/keito4/config/nix` no longer
installs or configures Karabiner. The nix-darwin `remapCapsLockToControl` hidutil
mapping is kept as a baseline, but it is bypassed once Kanary is running with its
keyboard features enabled, because Kanary re-emits key events through a virtual
HID device below which the hidutil mapping no longer applies. Caps Lock to
Control is therefore owned by Kanary's `capsLockRemappedToControl` setting, which
`nix/home/kanary.nix` re-asserts on every activation via
`script/macos/kanary-enforce-caps-control.sh`. The helper is idempotent: it is a
silent no-op when the setting is already true (or when Kanary has not been
launched yet) and only flips the single field and restarts Kanary when it detects
drift (for example after the setting is toggled off in Kanary's UI).

Kanary must be present before activation, and the nix-darwin configuration fails
early with an actionable message when `Kanary.app` is missing.

Kanary installation is manual for now, and the `capsLockRemappedToControl` field
is the only Kanary app-level setting managed declaratively. The repository avoids
adding a bespoke ZIP download, checksum, and install flow while Kanary is not
available through the normal package sources used by this configuration.

The `Ctrl+Shift+J` and `Ctrl+Shift+;` IME mappings are handled by skhd as a
user-level hotkey daemon, so they work in cmux terminals even when the foreground
process is Claude Code, Codex, zsh, or another TUI instead of tmux. This still
avoids Karabiner and its DriverKit extension, but skhd must be allowed in macOS
Accessibility settings before it can observe keyboard events.
