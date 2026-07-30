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
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      configRoot = ../.;

      mkDarwin =
        {
          hostname,
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
      darwinConfigurations = {
        "keitonoMacBook-Pro" = mkDarwin {
          hostname = "keitonoMacBook-Pro";
          username = "keito";
        };
        "oykotnoMacBook-Air" = mkDarwin {
          hostname = "oykotnoMacBook-Air";
          username = "oykot";
          determinateNix = true;
        };
      };

      # nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
