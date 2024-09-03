{
  description = "Home Manager configuration using Nix Flakes";

  inputs = {
    # Home Manager Flake
    home-manager.url = "github:nix-community/home-manager";
    # Nixpkgs for package management
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # You can choose a different branch or version
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Define the system architecture
      system = "x86_64-linux";  # Adjust this for your architecture
      # Import the overlay directly
      # Import Nixpkgs
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true; # Enable unfree packages 
        };
      };

      # Define the Home Manager configuration

      homeConfig = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs; # Pass the pkgs variable here
        modules = [
          {
            # Specify the state version
            home.stateVersion = "23.05"; # Use the latest stable version or the version you are targeting
            home.homeDirectory = "/home/prm"; # Replace 'yourusername' with your actual username
            # Specify the username
            home.username = "prm"; # Replace with your actual username

            home.packages = with pkgs; [
              cowsay
              direnv
              jp2a
              jujutsu
              nh
              nix-output-monitor
              zed-editor
            ];

            programs.git = {
              enable = true;
              aliases = {
                # Add custom Git aliases here
                st = "status";
                c = "commit";
                cm = "commit -m";
                cam = "commit -am";
                l = "log --oneline --graph";
              };
            };
            # postInstall = ''
            #   # Run post-install tasks here
            # '';

            home.file.".bashrc".text = ''
              export PATH=$HOME/.local/bin:$PATH
            '';
          }
        ];
      };
    in
    {
      nixpkgs.config = { allowUnfree = true; };
      # Expose the homeConfigurations attribute
      homeConfigurations = {
        # Replace 'yourusername' with your actual username
        prm = homeConfig;
      };
    };
}

