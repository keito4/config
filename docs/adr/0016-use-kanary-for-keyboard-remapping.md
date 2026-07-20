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
  the baseline Caps Lock to Control mapping.
- Install Kanary manually from `https://kanary.download/download` until a stable
  package-manager source exists.
- Use Kanary to manage:
  - Left Command tap to alphanumeric input.
  - Right Command tap to kana input.
  - Per-app default input modes where useful.
- Use nix-darwin's `services.skhd` for terminal-friendly IME shortcuts without
  Karabiner:
  - `Ctrl+Shift+J` emits the physical かな key to switch to Japanese hiragana.
  - `Ctrl+Shift+;` emits the physical 英数 key to switch to alphanumeric.
- Drive these shortcuts by emitting the physical かな/英数 keys (`send-ime-key`,
  CGEvent keycodes 104/102) rather than calling `TISSelectInputSource` on an
  input mode. Selecting a mode (`base` <-> `Roman`) of the already-active Google
  Japanese input method only updates the menu-bar indicator; it does not reliably
  notify the running IME to change its conversion mode, so the tooltip shows
  Hiragana while typing still produces alphanumeric. The physical keys are
  handled by macOS at the HID level and switch the IME reliably — the same
  mechanism Kanary's Command taps use. `select-input-source` (TISSelectInputSource)
  is kept for programmatic input-source queries and selection by agents.

## Consequences

`darwin-rebuild switch --flake ~/develop/github.com/keito4/config/nix` no longer
installs or configures Karabiner. Caps Lock to Control is handled by nix-darwin
so the baseline remap works even before Kanary app-level settings are configured.
Kanary must be present before activation, and the nix-darwin configuration fails
early with an actionable message when `Kanary.app` is missing.

Kanary installation and app-level settings are manual for now. The repository
avoids adding a bespoke ZIP download, checksum, and install flow while Kanary is
not available through the normal package sources used by this configuration.

The `Ctrl+Shift+J` and `Ctrl+Shift+;` IME mappings are handled by skhd as a
user-level hotkey daemon, so they work in cmux terminals even when the foreground
process is Claude Code, Codex, zsh, or another TUI instead of tmux. This still
avoids Karabiner and its DriverKit extension, but skhd must be allowed in macOS
Accessibility settings before it can observe keyboard events.

Because the shortcuts now inject synthetic HID events (`send-ime-key`), the
injected events are only delivered when the posting process is permitted in macOS
Accessibility. skhd (the parent) is already granted, and the spawned helper is
expected to run under skhd's responsibility; verify after `darwin-rebuild switch`
by pressing `Ctrl+Shift+J` and confirming typed characters — not just the menu-bar
indicator — become Japanese. Note the switch cannot be validated from a plain
terminal, because a shell that lacks Accessibility silently drops the injected
events. If the shortcuts do not switch after a rebuild, the fallback is to bind
`Ctrl+Shift+J` / `Ctrl+Shift+;` as Kanary app hotkeys that emit かな / 英数, since
Kanary already holds the required permission and uses the same key-injection
mechanism as its Command taps.
