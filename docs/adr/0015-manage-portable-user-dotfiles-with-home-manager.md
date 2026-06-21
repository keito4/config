# ADR 0015: Manage Portable User Dotfiles with Home Manager

## Status

Accepted

## Context

The macOS environment should be reproducible without using Apple's default
machine migration flow. ADR 0012 defines `nix/` as the source of truth for
macOS packages and local environment configuration, and ADR 0014 adds cmux and
Karabiner settings.

Several portable text configuration files still lived only in the user home
directory. These files affect daily shell behavior, local workflow tools, and
window management, so losing them during a rebuild would make a new machine feel
incomplete even if packages were installed.

Some home-directory files are not safe to manage in git because they contain
credentials, tokens, session state, app databases, histories, or
machine-specific runtime data.

## Decision

Manage portable, non-secret user dotfiles through `nix/home/dotfiles.nix`.

- Source reusable zsh config fragments and functions from the repository.
- Source AeroSpace configuration from `dot/aerospace.toml`.
- Source small workflow-tool configs for act, Agent Deck, Graphite aliases, and
  Codespaces secret repository selection.
- Source global git ignore and peco configuration from the repository.
- Use `force = true` for these files so home-manager can take ownership of
  existing files during a rebuild.

Do not manage secret or stateful files in git. Specifically keep the following
outside this repository:

- SSH keys and `~/.ssh/config`
- cloud auth files under `~/.aws`, `~/.azure`, and `~/.config/gcloud`
- GitHub auth files such as `~/.config/gh/hosts.yml`
- token-bearing CLI configs such as Graphite `user_config` and npm auth config
- Claude/Codex auth, session, history, cache, and SQLite state
- application databases, browser profiles, and update caches

## Consequences

`darwin-rebuild switch --flake ~/develop/github.com/keito4/config/nix` can
restore a larger portion of the user environment on a new machine without
copying the old machine's home directory.

Manual edits to managed dotfiles will be overwritten on the next home-manager
activation. Changes should be made in this repository first, then applied with
the Nix switch command.

Authentication and app state still require explicit sign-in or a separate
secrets/bootstrap process. This keeps the repository reviewable and avoids
encoding machine-specific runtime state as configuration.
