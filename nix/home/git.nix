{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    # user.name / user.email / user.signingkey are intentionally omitted
    # Configure per-machine:
    #   git config --global user.name "Your Name"
    #   git config --global user.email "your.email@example.com"
    #   git config --global user.signingkey ~/.ssh/id_ed25519.pub

    settings = {
      url."https://github.com/".insteadOf = "git@github.com:";

      ghq.root = "~/develop";

      core = {
        excludesfile = "~/.gitignore";
        attributesfile = "~/.gitattributes";
        editor = "emacs -nw";
      };

      pull.rebase = false;
      init.defaultBranch = "main";
      push.default = "simple";

      credential = {
        "https://github.com" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
        "https://gist.github.com" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
      };

      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
  };

  home.packages = [ pkgs.git-lfs ];
}
