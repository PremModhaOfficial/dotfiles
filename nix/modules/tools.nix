{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "PremModhaOfficial";
      user.email = "PremModhaOfficial@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.nix-index-database.comma.enable = false;
  programs.command-not-found.enable = false;
}
