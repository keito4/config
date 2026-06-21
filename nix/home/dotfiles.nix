{ ... }:

let
  managedSource = source: {
    inherit source;
    force = true;
  };
in
{
  home.file = {
    ".aerospace.toml" = managedSource ../../dot/aerospace.toml;

    ".config/act/actrc" = managedSource ../../dot/config/act/actrc;
    ".config/agent-deck/config.toml" = managedSource ../../dot/config/agent-deck/config.toml;
    ".config/codespaces-secrets/repos.txt" =
      managedSource ../../dot/config/codespaces-secrets/repos.txt;
    ".config/graphite/aliases" = managedSource ../../dot/config/graphite/aliases;

    ".gitignore" = managedSource ../../git/gitignore;
    ".peco/config.json" = managedSource ../../dot/.peco/config.json;
    ".zshrc.devcontainer" = managedSource ../../dot/.zshrc.devcontainer;

    ".zsh/configs/aliases.zsh" = managedSource ../../.zsh/configs/aliases.zsh;
    ".zsh/configs/color.zsh" = managedSource ../../.zsh/configs/color.zsh;
    ".zsh/configs/history.zsh" = managedSource ../../.zsh/configs/history.zsh;
    ".zsh/configs/keybindings.zsh" = managedSource ../../.zsh/configs/keybindings.zsh;
    ".zsh/configs/prompt.zsh" = managedSource ../../.zsh/configs/prompt.zsh;

    ".zsh/configs/pre/.env" = managedSource ../../.zsh/configs/pre/.env;
    ".zsh/configs/pre/.env.secret.template" = managedSource ../../.zsh/configs/pre/.env.secret.template;
    ".zsh/configs/pre/.gitignore" = managedSource ../../.zsh/configs/pre/.gitignore;
    ".zsh/configs/pre/envup.zsh" = managedSource ../../.zsh/configs/pre/envup.zsh;
    ".zsh/configs/pre/path.zsh" = managedSource ../../.zsh/configs/pre/path.zsh;

    ".zsh/configs/virtual/dart.zsh" = managedSource ../../.zsh/configs/virtual/dart.zsh;
    ".zsh/configs/virtual/go.zsh" = managedSource ../../.zsh/configs/virtual/go.zsh;
    ".zsh/configs/virtual/java.zsh" = managedSource ../../.zsh/configs/virtual/java.zsh;
    ".zsh/configs/virtual/php.zsh" = managedSource ../../.zsh/configs/virtual/php.zsh;
    ".zsh/configs/virtual/python.zsh" = managedSource ../../.zsh/configs/virtual/python.zsh;
    ".zsh/configs/virtual/ruby.zsh" = managedSource ../../.zsh/configs/virtual/ruby.zsh;

    ".zsh/functions/docker" = managedSource ../../.zsh/functions/docker;
    ".zsh/functions/gcp" = managedSource ../../.zsh/functions/gcp;
    ".zsh/functions/git" = managedSource ../../.zsh/functions/git;
    ".zsh/functions/mkcd" = managedSource ../../.zsh/functions/mkcd;
    ".zsh/functions/op" = managedSource ../../.zsh/functions/op;
    ".zsh/functions/peco" = managedSource ../../.zsh/functions/peco;
    ".zsh/functions/process" = managedSource ../../.zsh/functions/process;
    ".zsh/functions/terraform" = managedSource ../../.zsh/functions/terraform;
    ".zsh/functions/utilities" = managedSource ../../.zsh/functions/utilities;
  };
}
