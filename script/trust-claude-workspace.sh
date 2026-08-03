#!/usr/bin/env bash
# Mark a workspace as trusted in ~/.claude.json so headless Claude Code runs
# honour .claude/settings.json permissions.allow instead of ignoring them.
#
# Usage: script/trust-claude-workspace.sh [workspace-path]
set -euo pipefail

WORKSPACE="${1:-$PWD}"

# shellcheck disable=SC2016 # the node script is intentionally not shell-expanded
node -e '
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const workspace = path.resolve(process.argv[1]);
const configPath = path.join(os.homedir(), ".claude.json");

let config = {};
if (fs.existsSync(configPath)) {
  try {
    config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  } catch {
    config = {};
  }
}

config.projects = config.projects ?? {};
config.projects[workspace] = {
  ...(config.projects[workspace] ?? {}),
  hasTrustDialogAccepted: true,
};

fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
console.log(`ok: trusted ${workspace} in ${configPath}`);
' "$WORKSPACE"
