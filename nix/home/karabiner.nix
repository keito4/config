{ ... }:

let
  cmuxBundleCondition = {
    type = "frontmost_application_if";
    bundle_identifiers = [ "^com\\.cmuxterm\\.app$" ];
  };

  cmuxImeShortcut = fromKey: toKey: {
    type = "basic";
    from = {
      key_code = fromKey;
      modifiers = {
        mandatory = [
          "control"
          "shift"
        ];
        optional = [ "any" ];
      };
    };
    to = [ { key_code = toKey; } ];
    conditions = [ cmuxBundleCondition ];
  };

  karabinerConfig = {
    profiles = [
      {
        name = "Default profile";
        selected = true;

        virtual_hid_keyboard = {
          keyboard_type_v2 = "jis";
        };

        simple_modifications = [
          {
            from = {
              key_code = "caps_lock";
            };
            to = [ { key_code = "left_control"; } ];
          }
        ];

        complex_modifications = {
          parameters = {
            "basic.to_if_alone_timeout_milliseconds" = 500;
            "mouse_motion_to_scroll.speed" = 300;
          };

          rules = [
            {
              description = "cmux: keep Google Japanese IME shortcuts out of terminal";
              manipulators = [
                (cmuxImeShortcut "j" "japanese_kana")
                (cmuxImeShortcut "semicolon" "japanese_eisuu")
                (cmuxImeShortcut "quote" "japanese_eisuu")
              ];
            }
          ];
        };
      }
    ];
  };
in
{
  home.file.".config/karabiner/karabiner.json" = {
    force = true;
    text = builtins.toJSON karabinerConfig + "\n";
  };
}
