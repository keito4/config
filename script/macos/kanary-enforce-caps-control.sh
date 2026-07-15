#!/usr/bin/env bash
#
# Ensure Kanary's built-in "Caps Lock -> Control" remap is enabled.
#
# Why this exists:
#   nix-darwin's `system.keyboard.remapCapsLockToControl` sets a global hidutil
#   UserKeyMapping. In practice, when Kanary's window-move/resize and
#   input-switching features are enabled, Kanary grabs the physical keyboard and
#   re-emits events through a virtual HID keyboard. Those synthesized events
#   BYPASS the hidutil mapping, so Caps Lock reverts to Caps Lock unless Kanary's
#   own `capsLockRemappedToControl` is true. See ADR 0016.
#
# Behaviour:
#   - No-op (silent, exit 0) when the setting is already true, or when Kanary has
#     never been launched (settings file absent), or when the schema is unknown.
#   - When the setting is false, back up the settings plist, flip only that one
#     field to true, and (if Kanary was running) restart Kanary so it reloads.
#
# Idempotent and safe to run on every `darwin-rebuild switch`.

set -euo pipefail

DOMAIN="download.kanary.settings"
PLIST="${HOME}/Library/Preferences/${DOMAIN}.plist"

log() { printf 'kanary: %s\n' "$*"; }

# Kanary never launched yet -> nothing to enforce.
if [ ! -f "$PLIST" ]; then
  log "settings not found (launch Kanary once to create them); skipping"
  exit 0
fi

read_caps() {
  plutil -extract app_settings raw -o - "$PLIST" 2>/dev/null \
    | base64 -D 2>/dev/null \
    | python3 -c 'import sys, json
try:
    d = json.load(sys.stdin)
    v = d["settings"]["windowMoveResize"]["capsLockRemappedToControl"]
    print("true" if v is True else "false" if v is False else "unknown")
except Exception:
    print("unknown")'
}

current="$(read_caps || echo unknown)"

case "$current" in
  true)
    exit 0
    ;;
  unknown)
    log "could not read capsLockRemappedToControl (schema changed?); skipping"
    exit 0
    ;;
esac

# current == false -> enable it.
log "capsLockRemappedToControl is false; enabling Caps Lock -> Control"

ts="$(date +%Y%m%d%H%M%S 2>/dev/null || echo backup)"
cp "$PLIST" "${PLIST}.bak-${ts}" 2>/dev/null || true

hex="$(python3 - "$PLIST" <<'PY'
import sys, plistlib, json
with open(sys.argv[1], "rb") as f:
    d = plistlib.load(f)
obj = json.loads(d["app_settings"])
obj["settings"]["windowMoveResize"]["capsLockRemappedToControl"] = True
sys.stdout.write(json.dumps(obj, separators=(",", ":")).encode().hex())
PY
)" || { log "failed to build updated settings; aborting"; exit 0; }

was_running=false
if pgrep -x Kanary >/dev/null 2>&1; then
  was_running=true
  osascript -e 'quit app "Kanary"' 2>/dev/null || pkill -x Kanary 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    pgrep -x Kanary >/dev/null 2>&1 || break
    sleep 1
  done
  if pgrep -x Kanary >/dev/null 2>&1; then
    pkill -9 -x Kanary 2>/dev/null || true
  fi
fi

# Write through cfprefsd while Kanary is not running so it is not clobbered.
defaults write "$DOMAIN" app_settings -data "$hex"

if [ "$was_running" = true ]; then
  open -a Kanary 2>/dev/null || true
fi

log "Caps Lock -> Control enabled"
