{
  description = "prm home manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cliamp.url = "github:bjarneo/cliamp";
  };

  outputs = { self, nixpkgs, home-manager, nix-index-database, cliamp, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."prm" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-index-database.homeModules.nix-index
          ./home.nix
        ];
      };
    };
}
