{ pkgs, ... }:
{
  # Tell HM to make fonts available to the host OS (Arch)
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Fonts (made available to system via fontconfig.enable above)
    nerd-fonts.caskaydia-cove
    # alacritty.toml asks for "Cascadia Mono NF" and ghostty/config asks for
    # "Cascadia Code". Only caskaydia-cove was installed, which registers as
    # "CaskaydiaCove NF" / "CaskaydiaCove Nerd Font" -- neither requested name
    # -- so both terminals silently fell back. caskaydia-mono registers the
    # plain "Caskaydia Mono" family that matches the configs.
    # NOTE: there is no nerd-fonts.cascadia-mono or .cascadia-code attribute;
    # verified via nix eval against the pinned flake. Use the caskaydia-* names.
    nerd-fonts.caskaydia-mono
    nerd-fonts.victor-mono
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts-color-emoji

    # CLI essentials
    ripgrep fd bat eza fzf jq yq
    htop # btop via pacman: nix build can't dlopen host libnvidia-ml (GPU not detected)
    wget curl
    unzip zip

    # Nix tooling
    nh
    nvd
    nix-output-monitor
    nixfmt-rfc-style

    # Dev
    git
    gh
    neovim
    fish

    # Editors
    emacs-pgtk

    # Shell
    starship
    zoxide


    ## helps
  ];

}
