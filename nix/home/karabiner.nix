{ ... }:

let
  cmuxJapaneseInputSource = "^com\\.google\\.inputmethod\\.Japanese\\.base$";
  cmuxEnglishInputSource = "^com\\.google\\.inputmethod\\.Japanese\\.Roman$";

  cmuxBundleCondition = {
    type = "frontmost_application_if";
    bundle_identifiers = [ "^com\\.cmuxterm\\.app$" ];
  };

  selectInputSource = inputSourceID: {
    select_input_source = {
      input_source_id = inputSourceID;
    };
  };

  cmuxImeShortcutWithModifiers = mandatoryModifiers: fromKey: inputSourceID: {
    type = "basic";
    from = {
      key_code = fromKey;
      modifiers = {
        mandatory = mandatoryModifiers;
        optional = [ "any" ];
      };
    };
    to = [ (selectInputSource inputSourceID) ];
    conditions = [ cmuxBundleCondition ];
  };

  cmuxImeShortcut = cmuxImeShortcutWithModifiers [
    "control"
    "shift"
  ];

  cmuxCapsLockImeShortcut = cmuxImeShortcutWithModifiers [
    "caps_lock"
    "shift"
  ];

  cmuxImeSimultaneousShortcut = modifierKey: fromKey: inputSourceID: {
    type = "basic";
    from = {
      simultaneous = [
        { key_code = modifierKey; }
        { key_code = fromKey; }
      ];
      simultaneous_options = {
        detect_key_down_uninterruptedly = true;
        key_down_order = "insensitive";
        key_up_order = "insensitive";
      };
      modifiers = {
        mandatory = [ "shift" ];
        optional = [ "any" ];
      };
    };
    to = [ (selectInputSource inputSourceID) ];
    conditions = [ cmuxBundleCondition ];
  };

  karabinerConfig = {
    profiles = [
      {
        name = "Default profile";
        selected = true;

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
                (cmuxImeShortcut "j" cmuxJapaneseInputSource)
                (cmuxImeShortcut "semicolon" cmuxEnglishInputSource)
                (cmuxImeShortcut "quote" cmuxEnglishInputSource)
                (cmuxCapsLockImeShortcut "j" cmuxJapaneseInputSource)
                (cmuxCapsLockImeShortcut "semicolon" cmuxEnglishInputSource)
                (cmuxCapsLockImeShortcut "quote" cmuxEnglishInputSource)
                (cmuxImeSimultaneousShortcut "left_control" "j" cmuxJapaneseInputSource)
                (cmuxImeSimultaneousShortcut "right_control" "j" cmuxJapaneseInputSource)
                (cmuxImeSimultaneousShortcut "caps_lock" "j" cmuxJapaneseInputSource)
                (cmuxImeSimultaneousShortcut "left_control" "semicolon" cmuxEnglishInputSource)
                (cmuxImeSimultaneousShortcut "right_control" "semicolon" cmuxEnglishInputSource)
                (cmuxImeSimultaneousShortcut "caps_lock" "semicolon" cmuxEnglishInputSource)
                (cmuxImeSimultaneousShortcut "left_control" "quote" cmuxEnglishInputSource)
                (cmuxImeSimultaneousShortcut "right_control" "quote" cmuxEnglishInputSource)
                (cmuxImeSimultaneousShortcut "caps_lock" "quote" cmuxEnglishInputSource)
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
