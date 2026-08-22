{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "PremModhaOfficial";
      user.email = "PremModhaOfficial@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;

      # SSH Commit Signing
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHN2Yu2NSZ8j8ZAoMdsmUiC9G4c+c3/hkwEUrLfMRZXL";
    };
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.nix-index-database.comma.enable = false;
  programs.command-not-found.enable = false;

  # tldr pages client (rust, fast) with auto-update on use
  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
      updates.update_interval_hours = 168; # refresh if older than 1 week
    };
  };
}
