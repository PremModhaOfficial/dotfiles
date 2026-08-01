{ config, pkgs, herdrPkg, ... }:
{
  # herdr — terminal workspace manager for AI coding agents.
  # Binary comes from the official herdrdev/herdr flake (latest release).
  home.packages = [ herdrPkg ];

  # herdr config lives in the dotfiles repo under a stow-style herdr/ tree that
  # maps onto $HOME. Symlink the whole thing live (same as fish/nvim) so edits
  # hot-reload without a rebuild:
  #   herdr/.config/herdr/                       -> ~/.config/herdr
  #   herdr/.config/television/cable/            -> ~/.config/television/cable
  #   herdr/.local/bin/herdr-sesh                -> ~/.local/bin/herdr-sesh
  xdg.configFile."herdr".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/herdr/.config/herdr";

  xdg.configFile."television/cable/herdr-sesh.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/herdr/.config/television/cable/herdr-sesh.toml";

  home.file.".local/bin/herdr-sesh".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/herdr/.local/bin/herdr-sesh";
}
