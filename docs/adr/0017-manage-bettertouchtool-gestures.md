# ADR 0017: Manage BetterTouchTool Gesture Setup Through GitHub

## Status

Accepted

## Context

BetterTouchTool stores gesture configuration in local application state under the
user profile. Full BetterTouchTool exports and sync stores may contain personal
settings, generated metadata, device-specific identifiers, and backups that are
not suitable as a normal repository source of truth.

The macOS desktop setup now uses:

- AeroSpace for window focus and workspace movement.
- Raycast as the launcher.
- BetterTouchTool for gesture entry points.

The desired BetterTouchTool setup must preserve historical and manually-created
triggers while adding a small managed set of gestures.

## Decision

Manage BetterTouchTool through a JXA setup script:

- `script/macos/setup-bettertouchtool.js` is the GitHub-tracked source.
- The script adds only missing `CODEX-BTT-*` triggers.
- The script does not delete existing triggers, including older manual or backup
  restored triggers.
- BetterTouchTool remains installed and launched through the nix-darwin
  Homebrew and launchd configuration.
- BetterTouchTool preset exports stay local backups, not repository-managed
  artifacts.

The managed gesture set is:

- 3 finger swipe left/right: AeroSpace workspace next/previous.
- 3 finger swipe down: send `Cmd+W`.
- 3 finger tap: AeroSpace workspace back-and-forth.
- 3 finger click: middle click.
- 4 finger swipe left/right/up/down: AeroSpace focus movement.
- 4 finger tap: open Raycast.

## Consequences

### Positive

- The expected gestures can be recreated from GitHub without committing
  BetterTouchTool's full local state.
- Past BetterTouchTool triggers are preserved by default.
- Window-management behavior stays centralized in AeroSpace.
- Launcher behavior stays centralized in Raycast.

### Negative

- Applying the setup still requires BetterTouchTool to be installed and scriptable
  on the local Mac.
- Changes to existing managed triggers require a deliberate manual cleanup or a
  future migration path, because the default script is append-only.

### Mitigation

- Keep local `.bttpreset` and ZIP backups for full restore scenarios.
- Prefer adding new stable `CODEX-BTT-*` UUIDs when introducing new gestures.
- Use the repository script for repeatable setup and BetterTouchTool exports for
  disaster recovery.
