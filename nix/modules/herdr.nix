{ config, pkgs, herdrPkg, ... }:
{
  # herdr — terminal workspace manager for AI coding agents.
  # Package comes from the official herdrdev/herdr flake (latest release).
  programs.herdr = {
    enable = true;
    package = herdrPkg;

    # Managed config at ~/.config/herdr/config.toml.
    settings = {
      # herdr runs its own command prefix; keep it distinct from tmux.
      keys.prefix = "ctrl+b";
      ui = {
        agent_panel_sort = "priority";
        toast.delivery = "herdr";
      };
    };
  };
}
