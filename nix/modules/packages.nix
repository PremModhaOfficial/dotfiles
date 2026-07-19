{ pkgs, ... }:
{
  # Tell HM to make fonts available to the host OS (Arch)
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Fonts (made available to system via fontconfig.enable above)
    nerd-fonts.caskaydia-cove
    nerd-fonts.victor-mono
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts-color-emoji

    # CLI essentials
    ripgrep fd bat eza fzf jq yq
    htop btop
    wget curl
    unzip zip

    # Nix tooling
    nh
    nix-output-monitor
    nixfmt-rfc-style

    # Dev
    git
    gh
    neovim
    fish

    # Shell
    starship
    zoxide


    ## terminals
    ghostty
  ];
}
