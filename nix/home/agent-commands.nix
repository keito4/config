{ config, configRoot, ... }:

let
  managedCommand = source: {
    inherit source;
    executable = true;
    force = true;
  };
in
{
  home.file = {
    ".local/bin/agent-deck" = {
      source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/agent-deck";
      force = true;
    };

    ".local/bin/agent-collect-local-configs" = managedCommand (
      configRoot + /script/agent/collect-local-configs.sh
    );
  };
}
