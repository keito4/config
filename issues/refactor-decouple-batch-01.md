# Refactor: Decouple Findings (Batch 01)

Tracked with `.codex/prompts/refactor:decouple.md`. Each issue captures one decoupling plan (5 per batch).

---

## Issue 1: Consolidate OS adapters for import/export

- **Files**: `script/import.sh:5-54`, `script/export.sh:9-38`
- **Coupling problem**: Both scripts inline the same OS detection, Homebrew/VSC installs, and environment toggles. This hardwires the scripts to macOS/Linux specifics and makes it impossible to reuse the logic (e.g., for Windows or future package managers) without copying and editing shell blocks.
- **Plan**:
  1. Introduce a shared helper (e.g., `script/lib/os.sh`) that resolves the host platform, DevContainer state, and exposes per-OS install hooks.
  2. Move package/extension installation commands into adapter functions (e.g., `install_packages_linux`, `install_packages_darwin`) so new platforms can be added without touchpoints in both scripts.
  3. Update `import.sh` and `export.sh` to call the shared helpers and add minimal smoke tests (shellcheck + unit via bats) to keep the abstraction stable.
- **Definition of Done**: No duplicated OS branching across the scripts, adapters are unit-testable, and adding a new platform no longer requires editing multiple files.

---

## Issue 2: Isolate DevContainer-specific git/1Password setup

- **File**: `script/import.sh:65-91`
- **Coupling problem**: DevContainer detection, git config overrides, and the Linux-specific 1Password CLI installation are embedded directly inside the main import routine. That couples workstation bootstrap with a single credential provider and prevents reuse from other environments (Codespaces, GitHub Actions) that might need a different secret backend.
- **Plan**:
  1. Extract the DevContainer conditionals into a dedicated helper script (e.g., `script/lib/devcontainer.sh`) that exposes `configure_git_identity` and `ensure_secret_backend`.
  2. Represent credential provider choice (1Password CLI vs. other) via environment variables or config so the helper can swap adapters without modifying the import flow.
  3. Make the helper injectable (sourced) so future pipelines can reuse it without running the entire import script.
- **Definition of Done**: `import.sh` only orchestrates high-level steps; DevContainer-specific side effects live behind helper functions with configurable secret providers.

---

## Issue 3: ✅ Removed redundant Node build/validate scripts

- **Status**: Completed by removing `scripts/build.js` and `scripts/validate.js`, along with their `npm` hooks and CI steps.
- **Context**: The two files duplicated the Jest tests, re-running lint/test pipelines and generating unused `dist/` artifacts. Keeping both copies introduced maintenance overhead without delivering additional coverage.
- **Follow-up**: Configuration verification now relies on the Jest suite plus shell scripts. No further action needed unless a new Node-based CLI is reintroduced.

---

## Issue 4: Abstract credential backend in credentials script

- **File**: `script/credentials.sh:3-127`
- **Coupling problem**: The credential workflow assumes the presence of the 1Password CLI (`op`), hardcodes install instructions, and calls `op inject` directly. No other secret manager (sops, env files, AWS Secrets Manager) can reuse the flow, and the script exits if `op` is missing even when another backend could satisfy the request.
- **Plan**:
  1. Define a provider interface (env vars describing `fetch`, `inject`, `clean`) and move the 1Password implementation into `script/credentials/providers/op.sh`.
  2. Allow the main script to select a provider via config/env (`CREDENTIAL_PROVIDER=op|sops|env`) and dispatch commands through the interface.
  3. Add minimal contract tests to ensure each provider honors the same function signatures so swapping providers does not change the CLI surface.
- **Definition of Done**: `credentials.sh` no longer shells directly into `op`; it delegates through provider functions and can be extended without rewriting the script.

---

## Issue 5: Data-drive brew category definitions

- **File**: `script/brew-deps.sh:50-198`
- **Coupling problem**: Category membership for formulae/casks is encoded inside large `grep -E` expressions. Any change to categories requires editing and redeploying the script, and there is no way to reuse the taxonomy from other tooling (e.g., generating docs). The script is tightly coupled to Brew CLI output parsing rules.
- **Plan**:
  1. Move category metadata into a JSON/YAML manifest (`brew/categories.yaml`) describing groups and regex/prefix rules.
  2. Update `brew-deps.sh` to parse the manifest (via `yq`/`jq`) and iterate over categories generically, so adding/removing entries is a data change.
  3. Introduce an adapter layer for command execution (`brew leaves`, `brew uses`) so the logic can be mocked in tests without invoking Brew.
- **Definition of Done**: The script reads categories from data, has thin adapters around Brew commands, and can be extended without modifying shell logic.
