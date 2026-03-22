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
      username = "keito";
      hostname = "keitos-MacBook-Pro";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./hosts/darwin

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username} = import ./home;
            };
          }
        ];
      };

      # nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
