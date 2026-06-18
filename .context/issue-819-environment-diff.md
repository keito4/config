# Issue #819 Environment Difference Report

Captured at: 2026-06-17

## DevContainer Tool Ownership

Decision: `.devcontainer/Dockerfile` is the source of truth for pinned base-image
tools. DevContainer Features are only for additional capabilities not already
installed by the base image.

| Tool             | Dockerfile/base image | Removed from Features | Reason                         |
| ---------------- | --------------------- | --------------------- | ------------------------------ |
| `git`            | apt package           | yes                   | base VCS tool                  |
| `gh`             | pinned `GH_CLI_VERSION` | yes                 | pinned CLI release             |
| `op`             | pinned `OP_CLI_VERSION` | yes                 | pinned 1Password CLI release   |
| Node.js          | pinned `NODE_VERSION` | yes                   | package runtime source of truth |
| pnpm             | pinned `PNPM_VERSION` | yes                   | global package manager install |
| Supabase CLI     | pnpm global           | yes                   | installed in base image        |

## Linux Brewfile / macOS Nix Overlap

Decision: overlap is intentional because Linux bootstrap and macOS local
bootstrap are separate environments. No shared package-list generator is added.

| Overlap | Linux source           | macOS source              | Reason              |
| ------- | ---------------------- | ------------------------- | ------------------- |
| emacs | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| ffmpeg | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| freetds | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| gawk | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| gh | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| ghq | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| git | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| gnupg | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| openjdk | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| peco | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| tig | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| translate-shell | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| tree | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |
| zsh-completions | `brew/LinuxBrewfile` | `nix/home/packages.nix` | OS-specific install |

## Package Manager

Decision: npm is canonical for this repository.

| File | Role |
| ---- | ---- |
| `package.json` | declares `packageManager: npm@11.16.0` |
| `package-lock.json` | canonical lockfile |
| `pnpm-workspace.yaml` | pnpm `minimumReleaseAge` guardrail only |

## MCP Server Difference

Decision: Codex intentionally keeps the broader operations set; Gemini keeps a
smaller review-oriented set.

| Category | Servers | Reason |
| -------- | ------- | ------ |
| common | `aws-docs`, `chrome-devtools`, `next-devtools`, `playwright`, `supabase`, `vercel` | useful for both coding agents |
| Codex-only | `aws-knowledge`, `o3`, `context7`, `linear`, `doppler` | repo maintenance, broader docs/research, and operations |
| Gemini-only | `github` | Gemini uses GitHub Copilot MCP; Codex uses GitHub plugin/connector |

## Credential Template Coverage

Decision: `credentials/templates/mcp.env.template` must include every token env
var referenced by committed MCP settings.

| Environment variable | Source |
| -------------------- | ------ |
| `OPENAI_API_KEY` | `.codex/config.toml` |
| `SUPABASE_ACCESS_TOKEN` | `.codex/config.toml` |
| `VERCEL_TOKEN` | `.codex/config.toml` |
| `LINEAR_API_KEY` | `.codex/config.toml` |
| `DOPPLER_TOKEN` | `.codex/config.toml` |
| `SUPABASE_MCP_TOKEN` | `.gemini/settings.json` |
| `VERCEL_MCP_TOKEN` | `.gemini/settings.json` |
| `GITHUB_COPILOT_MCP_TOKEN` | `.gemini/settings.json` |
