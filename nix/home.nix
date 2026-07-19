{ config, pkgs, ... }:
{
  home.username = "prm";
  home.homeDirectory = "/home/prm";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/tools.nix
    ./modules/editor.nix
  ];

  # !! niri and DMS are intentionally absent from this entire config !!
}
