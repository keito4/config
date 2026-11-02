{ config, lib, ... }:

let
  keyboard = config.system.keyboard;
in
{
  # Activation only reaches existing services. Reapply after reconnects and
  # virtual keyboard recreation without restarting the keyboard application.
  launchd.user.agents.keyboard-remapping =
    lib.mkIf (keyboard.enableKeyMapping && keyboard.userKeyMapping != [ ])
      {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/hidutil"
            "property"
            "--matching"
            (builtins.toJSON {
              PrimaryUsagePage = 1;
              PrimaryUsage = 6;
            })
            "--set"
            (builtins.toJSON { UserKeyMapping = keyboard.userKeyMapping; })
          ];
          RunAtLoad = true;
          # An empty calendar entry runs every minute, including after wake.
          StartCalendarInterval = [ { } ];
          ProcessType = "Background";
        };
      };
}
