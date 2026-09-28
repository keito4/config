{
  config,
  lib,
  configRoot,
  ...
}:

{
  home.file.".local/share/input-source/select-input-source.swift" = {
    source = configRoot + /script/macos/select-input-source.swift;
    force = true;
  };

  home.file.".local/bin/select-input-source" = {
    source = configRoot + /script/macos/agent-select-input-source.sh;
    executable = true;
    force = true;
  };

  home.file.".local/bin/agent-select-input-source" = {
    source = configRoot + /script/macos/agent-select-input-source.sh;
    executable = true;
    force = true;
  };

  home.file.".local/share/input-source/send-ime-key.swift" = {
    source = configRoot + /script/macos/send-ime-key.swift;
    force = true;
  };

  home.file.".local/share/input-source/run-cached-swift" = {
    source = configRoot + /script/macos/run-cached-swift.sh;
    executable = true;
    force = true;
  };

  home.file.".local/bin/send-ime-key" = {
    source = configRoot + /script/macos/send-ime-key.sh;
    executable = true;
    force = true;
  };

  # ホットキー実行時に xcrun へ依存しないよう、activation でビルド済みバイナリを
  # 用意しておく（Xcode 更新でライセンス同意が外れると xcrun swift は exit 69）。
  # 失敗しても activation は止めない。
  home.activation.prebuildInputSourceHelpers = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    runner="${config.home.homeDirectory}/.local/share/input-source/run-cached-swift"
    $DRY_RUN_CMD "$runner" --build send-ime-key || true
    $DRY_RUN_CMD "$runner" --build select-input-source || true
  '';
}
