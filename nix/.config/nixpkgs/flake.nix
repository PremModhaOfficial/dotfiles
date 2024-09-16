{
  description = "Home Manager configuration using Nix Flakes";

  inputs = {
    # Home Manager Flake
    home-manager.url = "github:nix-community/home-manager";
    # Nixpkgs for package management
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # You can choose a different branch or version
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
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
      lib = home-manager.lib;
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
              jujutsu
              nix-output-monitor
              pass-wayland
              proton-pass
              whatsapp-for-linux

              (writeShellScriptBin
                "ShyFoxHook.sh" ''
                mkdir -p ~/.mozilla/shyfox
                rm -rfv ~/.mozilla/shyfox
                git clone https://github.com/Naezr/ShyFox.git ~/.mozilla/shyfox
                rm -vrf ~/.mozilla/firefox/prm-dev/chrome
                rm -vrf ~/.mozilla/firefox/prm-dev/user.js*
                mv -v ~/.mozilla/shyfox/chrome ~/.mozilla/firefox/prm-dev
                mv -v ~/.mozilla/shyfox/user.js ~/.mozilla/firefox/prm-dev
                rm -rfv ~/.mozilla/shyfox
                sudo chmod +w ~/.mozilla/firefox/profiles.ini
              '')
            ];
            home.activation.copyNilPackage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              dest="/home/prm/.local/share/nvim/mason/packages/nil/bin"
              destln="/home/prm/.local/share/nvim/mason/bin/nil"
  
              # Create destination directory if it doesn't exist
              mkdir -p "$dest"
  
              # Copy the derivation to the destination
              echo "Copying nil to $dest"
              cp -rfv ${pkgs.nil}/bin/nil "$dest"
              rm -v $destln
              echo "linking nil to $destln"
              ln -sv "$dest/nil" $destln
            '';



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

            programs.firefox = {
              enable = true;
              profiles = {
                "prm-dev" = {
                  settings = {
                    "browser.startup.homepage" = "about:home";
                  };

                  search.engines = {
                    "Nix Packages" = {
                      urls = [{
                        template = "https://search.nixos.org/packages";
                        params = [
                          { name = "type"; value = "packages"; }
                          { name = "query"; value = "{searchTerms}"; }
                        ];
                      }];

                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@np" ];
                    };
                  };
                  search.force = true;
                  extraConfig = ''
                    user_pref("browser.startup.homepage", "about:blank");
                  '';

                  extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
                    # tridactyl # vimmode
                    darkreader
                    sidebery
                    sponsorblock
                    surfingkeys
                    ublock-origin
                    userchrome-toggle-extended
                    youtube-shorts-block
                  ];
                };
              };
            };


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
        home-manager.backupFileExtension = "home-backup";
      };
    };
}


