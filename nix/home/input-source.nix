{ configRoot, ... }:

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

  home.file.".local/bin/send-ime-key" = {
    source = configRoot + /script/macos/send-ime-key.sh;
    executable = true;
    force = true;
  };
}
