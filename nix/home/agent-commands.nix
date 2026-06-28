{ configRoot, ... }:

let
  managedCommand = source: {
    inherit source;
    executable = true;
    force = true;
  };
in
{
  home.file = {
    ".local/bin/agent-collect-local-configs" = managedCommand (
      configRoot + /script/agent/collect-local-configs.sh
    );
  };
}
