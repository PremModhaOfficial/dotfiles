{ config, pkgs, inputs, ... }:
{
  home.username = "prm";
  home.homeDirectory = "/home/prm";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  home.packages = [ inputs.cliamp.packages.${pkgs.system}.default ];

  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/tools.nix
    ./modules/editor.nix
  ];

  # After each switch, symlink Nix .desktop files into the standard
  # XDG location so DMS launcher finds them.
  home.activation.linkDesktopFiles = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.local/share/applications"
    for f in "${config.home.homeDirectory}/.nix-profile/share/applications"/*.desktop; do
      [ -f "$f" ] || continue
      ln -sf "$f" "${config.home.homeDirectory}/.local/share/applications/$(basename "$f")"
    done
  '';

  # !! niri and DMS are intentionally absent from this entire config !!
}
