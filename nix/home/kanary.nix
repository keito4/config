{
  config,
  lib,
  configRoot,
  ...
}:

{
  # Helper that enforces Kanary's built-in Caps Lock -> Control remap.
  home.file.".local/bin/kanary-enforce-caps-control" = {
    source = configRoot + /script/macos/kanary-enforce-caps-control.sh;
    executable = true;
    force = true;
  };

  # When Kanary's keyboard features are enabled it intercepts the physical
  # keyboard and re-emits events through a virtual HID device, which bypasses the
  # global hidutil mapping set by `system.keyboard.remapCapsLockToControl`. As a
  # result Caps Lock -> Control only takes effect when Kanary's own
  # `capsLockRemappedToControl` is true. Re-assert it on every activation.
  # The helper is idempotent and a silent no-op once the setting is correct.
  # linkGeneration の後に実行する（初回 activation ではリンク生成前だと
  # ~/.local/bin/kanary-enforce-caps-control がまだ存在しない）
  home.activation.enforceKanaryCapsControl = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD "${config.home.homeDirectory}/.local/bin/kanary-enforce-caps-control" || true
  '';
}
