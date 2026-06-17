# Config Repository

[![CI](https://github.com/keito4/config/actions/workflows/ci.yml/badge.svg)](https://github.com/keito4/config/actions/workflows/ci.yml)
[![Security](https://github.com/keito4/config/actions/workflows/security.yml/badge.svg)](https://github.com/keito4/config/actions/workflows/security.yml)
[![codecov](https://codecov.io/gh/keito4/config/branch/main/graph/badge.svg)](https://codecov.io/gh/keito4/config)

Development infrastructure template repository for DevContainer images, CI/CD workflows, Claude Code/Codex/Gemini settings, reusable scripts, and standard project templates.

## Source Of Truth

Lists that drift easily are generated or centralized. Do not hand-maintain duplicate directory trees, command tables, workflow tables, hook tables, or quality-gate tables in this README.

| Content                                                                                       | Source                                                                                                                 |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Repository overview, directory map, commands, agents, skills, workflows, quality gates, hooks | [AGENTS.md](AGENTS.md) auto-generated section                                                                          |
| Script usage and credential import/export                                                     | [script/README.md](script/README.md)                                                                                   |
| DevContainer and config-base usage                                                            | [.devcontainer/README.md](.devcontainer/README.md), [docs/using-config-base-image.md](docs/using-config-base-image.md) |
| Project setup guides                                                                          | [docs/setup/README.md](docs/setup/README.md)                                                                           |
| Template catalog                                                                              | [templates/README.md](templates/README.md)                                                                             |
| Security policy and credential handling                                                       | [SECURITY.md](SECURITY.md), [credentials/README.md](credentials/README.md)                                             |
| Architecture decisions                                                                        | [docs/adr/README.md](docs/adr/README.md)                                                                               |

## Usage

### Import Existing Configuration

```bash
./script/import.sh
```

This imports shell, Git, npm, VS Code, and related local configuration into this repository. See [script/README.md](script/README.md) for import/export details and credential provider behavior.

### Export Configuration

```bash
./script/export.sh
```

This exports repository-managed configuration back to the local environment.

### Manage Credentials

```bash
./script/credentials.sh fetch
./script/credentials.sh list
./script/credentials.sh clean
```

Credential templates and 1Password provider details live in [credentials/README.md](credentials/README.md).

### Use DevContainer Defaults

Use `ghcr.io/keito4/config-base:latest` for repositories that should inherit the standard toolchain. See [.devcontainer/README.md](.devcontainer/README.md) and [docs/using-config-base-image.md](docs/using-config-base-image.md).

### Set Up New Projects

Use the setup guides instead of copying snippets from this README:

- [Web app: Next.js](docs/setup/web-app-nextjs.md)
- [SPA: React + Vite](docs/setup/spa-react-vite.md)
- [npm library / CLI](docs/setup/npm-library-cli.md)
- [Desktop extension: TypeScript](docs/setup/desktop-extension-ts.md)
- [Mobile: Android](docs/setup/mobile-android.md)
- [Mobile: Flutter](docs/setup/mobile-flutter.md)
- [Windows](docs/setup/windows.md)

## Security

Secrets are not stored in this repository. Local-only credential files are git-ignored, and credential templates are rendered through provider scripts.

Core references:

- [SECURITY.md](SECURITY.md)
- [credentials/README.md](credentials/README.md)
- [credentials/setup.md](credentials/setup.md)
- [docs/doppler-setup-guide.md](docs/doppler-setup-guide.md)

## Development Workflow

Use the generated command catalog in [AGENTS.md](AGENTS.md) and command-authoring conventions in [.claude/commands/README.md](.claude/commands/README.md).

Common local checks:

```bash
npm run format:check
npm run lint
npm test
npm run test:integration
npm run shellcheck
bash script/update-agents-md.sh --check
```

Quality gates and hook behavior are defined by the hook scripts and settings referenced from [AGENTS.md](AGENTS.md). Hook implementation details live in [.claude/hooks/README.md](.claude/hooks/README.md).

## Documentation Rules

- Do not add hand-written directory trees, command lists, workflow lists, hook lists, or quality-gate tables to README files.
- Update the source file and regenerate the generated output when generated content changes.
- Add an ADR in [docs/adr/](docs/adr/) for non-trivial documentation architecture changes.
- Store intermediate review artifacts under `.context/`.

## Glossary

- **Config repository**: This repository, the source for shared development environment assets.
- **config-base**: Pre-built DevContainer image published from this repository.
- **DevContainer**: Containerized development environment consumed by VS Code, Cursor, and Codespaces.
- **Quality Gate**: Local and CI checks that block unsafe or low-quality changes.
- **SSoT**: Single Source of Truth. Lists and tables should have one canonical source.

## Disclaimer

This repository is tailored for the owner's development environment and organization-wide defaults. Review settings before applying them to unrelated projects.
