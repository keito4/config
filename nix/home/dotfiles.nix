{ configRoot, ... }:

let
  managedSource = source: {
    inherit source;
    force = true;
  };
in
{
  home.file = {
    ".aerospace.toml" = managedSource (configRoot + /dot/aerospace.toml);

    ".config/act/actrc" = managedSource (configRoot + /dot/config/act/actrc);
    ".config/agent-deck/config.toml" = managedSource (configRoot + /dot/config/agent-deck/config.toml);
    ".config/codespaces-secrets/repos.txt" = managedSource (
      configRoot + /dot/config/codespaces-secrets/repos.txt
    );
    ".config/graphite/aliases" = managedSource (configRoot + /dot/config/graphite/aliases);

    ".gitignore" = managedSource (configRoot + /git/gitignore);
    ".peco/config.json" = managedSource (configRoot + /dot/.peco/config.json);
    ".zshrc.devcontainer" = managedSource (configRoot + /dot/.zshrc.devcontainer);

    ".zsh/configs/aliases.zsh" = managedSource (configRoot + /.zsh/configs/aliases.zsh);
    ".zsh/configs/color.zsh" = managedSource (configRoot + /.zsh/configs/color.zsh);
    ".zsh/configs/history.zsh" = managedSource (configRoot + /.zsh/configs/history.zsh);
    ".zsh/configs/keybindings.zsh" = managedSource (configRoot + /.zsh/configs/keybindings.zsh);
    ".zsh/configs/prompt.zsh" = managedSource (configRoot + /.zsh/configs/prompt.zsh);

    ".zsh/configs/pre/.env" = managedSource (configRoot + /.zsh/configs/pre/.env);
    ".zsh/configs/pre/.env.secret.template" = managedSource (
      configRoot + /.zsh/configs/pre/.env.secret.template
    );
    ".zsh/configs/pre/.gitignore" = managedSource (configRoot + /.zsh/configs/pre/.gitignore);
    ".zsh/configs/pre/envup.zsh" = managedSource (configRoot + /.zsh/configs/pre/envup.zsh);
    ".zsh/configs/pre/path.zsh" = managedSource (configRoot + /.zsh/configs/pre/path.zsh);

    ".zsh/configs/virtual/dart.zsh" = managedSource (configRoot + /.zsh/configs/virtual/dart.zsh);
    ".zsh/configs/virtual/go.zsh" = managedSource (configRoot + /.zsh/configs/virtual/go.zsh);
    ".zsh/configs/virtual/java.zsh" = managedSource (configRoot + /.zsh/configs/virtual/java.zsh);
    ".zsh/configs/virtual/php.zsh" = managedSource (configRoot + /.zsh/configs/virtual/php.zsh);
    ".zsh/configs/virtual/python.zsh" = managedSource (configRoot + /.zsh/configs/virtual/python.zsh);
    ".zsh/configs/virtual/ruby.zsh" = managedSource (configRoot + /.zsh/configs/virtual/ruby.zsh);

    ".zsh/functions/docker" = managedSource (configRoot + /.zsh/functions/docker);
    ".zsh/functions/gcp" = managedSource (configRoot + /.zsh/functions/gcp);
    ".zsh/functions/git" = managedSource (configRoot + /.zsh/functions/git);
    ".zsh/functions/mkcd" = managedSource (configRoot + /.zsh/functions/mkcd);
    ".zsh/functions/peco" = managedSource (configRoot + /.zsh/functions/peco);
    ".zsh/functions/process" = managedSource (configRoot + /.zsh/functions/process);
    ".zsh/functions/terraform" = managedSource (configRoot + /.zsh/functions/terraform);
    ".zsh/functions/utilities" = managedSource (configRoot + /.zsh/functions/utilities);
  };
}
