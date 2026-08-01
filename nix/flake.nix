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
    herdr = {
      url = "github:herdrdev/herdr";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-index-database, herdr, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # herdr from its official flake (latest release build)
      herdrPkg = herdr.packages.${system}.default;
    in {
      homeConfigurations."prm" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit herdrPkg; };
        modules = [
          nix-index-database.homeModules.nix-index
          ./home.nix
        ];
      };
    };
}
