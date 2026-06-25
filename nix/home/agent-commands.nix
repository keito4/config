{ ... }:

let
  managedCommand = source: {
    inherit source;
    executable = true;
    force = true;
  };
in
{
  home.file = {
    ".local/bin/agent-collect-local-configs" =
      managedCommand ../../script/agent/collect-local-configs.sh;
  };
}
