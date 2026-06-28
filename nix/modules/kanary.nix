{ config, ... }:

{
  system.checks.text = ''
    if [ ! -d "/Applications/Kanary.app" ] && [ ! -d "/Users/${config.system.primaryUser}/Applications/Kanary.app" ]; then
      echo "error: Kanary.app is required for keyboard remapping." >&2
      echo "Install it from https://kanary.download/download before running darwin-rebuild." >&2
      exit 2
    fi
  '';
}
