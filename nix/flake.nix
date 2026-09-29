{
  description = "keito's macOS environment managed with nix-darwin and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 端末一覧（ホスト名・ユーザー名）は組織情報を含みうるため非公開リポジトリで持つ。
    # sudo 下の root は GitHub 認証を持たないので、取得はユーザー権限で先に済ませる
    # （make nix-switch が nix flake archive で行う）。
    private-config = {
      url = "git+https://github.com/keito4/private-config.git";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      private-config,
      ...
    }:
    let
      system = "aarch64-darwin";
      configRoot = ../.;

      mkDarwin =
        {
          username,
          # Determinate Nix はデーモンを自前管理するため nix-darwin の Nix 管理と衝突する
          determinateNix ? false,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit username determinateNix;
          };
          modules = [
            ./hosts/darwin

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "before-home-manager";
                extraSpecialArgs = {
                  inherit configRoot username;
                };
                users.${username} = import ./home;
              };
            }
          ];
        };
    in
    {
      # { "<ホスト名>" = { username = "..."; determinateNix = true; }; }
      darwinConfigurations = builtins.mapAttrs (_hostname: host: mkDarwin host) (
        import "${private-config}/nix/hosts.nix"
      );

      # nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
