{ config, pkgs, ... }:
{
  # Install neovim package directly instead of using programs.neovim
  # This prevents HM from trying to create its own .config/nvim/init.lua
  home.packages = [ pkgs.neovim ];

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim/.config/nvim";
}

