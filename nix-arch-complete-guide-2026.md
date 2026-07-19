# Nix on Arch Linux — Complete Guide (2026)
## niri + Home Manager + Flakes + Everything

---

## 1. INSTALLATION

```bash
sudo pacman -S nix
sudo systemctl enable --now nix-daemon
sudo gpasswd -a $USER nix-users
# Log out and back in
```

### Enable flakes
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
echo "max-jobs = auto" >> /etc/nix/nix.conf
```

### Add to ~/.zshrc (or .bashrc/.fish)
```bash
export PATH=$HOME/.nix-profile/bin:$PATH
export NIX_PATH=nixpkgs=channel:nixos-unstable
export XDG_DATA_DIRS=$HOME/.nix-profile/share:$XDG_DATA_DIRS
```

---

## 2. HOME MANAGER (Standalone on Arch)

### Install
```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

### Minimal flake.nix → ~/.config/home-manager/flake.nix
```nix
{
  description = "Home Manager configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, home-manager, ... }:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."prm" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
```

### Minimal home.nix → ~/.config/home-manager/home.nix
```nix
{ config, pkgs, ... }:
{
  home.username = "prm";
  home.homeDirectory = "/home/prm";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    htop ripgrep fd jq git direnv
  ];

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = { ll = "ls -la"; gs = "git status"; };
  };

  programs.starship = { enable = true; enableZshIntegration = true; };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # SYMLINK YOUR NVIM CONFIG (not nixvim!)
  programs.neovim.enable = true;
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim/.config/nvim";
}
```

### Apply
```bash
home-manager switch --flake ~/.config/home-manager#prm
```

---

## 3. NVIM — JUST SYMLINK IT (No nixvim needed)

```nix
# In home.nix — Nix installs the binary, your config stays yours
programs.neovim.enable = true;
xdg.configFile."nvim".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/path/to/your/nvim";
```

- `mkOutOfStoreSymlink` creates a direct symlink (not Nix store copy)
- `lazy-lock.json` stays writable
- `:source $MYVIMRC` works
- Zero rebuild for config changes
- You keep your lazy.nvim / plugins as-is

**What you lose vs nixvim:** Nix-native plugin management, declarative keymaps in Nix, type-checked config.
**What you gain:** Keep your existing setup, instant iteration, no nix-flavored Lua.

---

## 4. REBUILD WORKAROUNDS

### The problem
Every `home-manager switch` rebuilds your entire home profile. Slow, annoying.

### Workarounds

**mkOutOfStoreSymlink** — symlink configs directly from your repo. Zero rebuilds for config changes. Use for nvim, fish, tmux, kitty, etc.

**Faster activation** — skip `home-manager switch`:
```bash
nix build .#homeConfigurations."prm@host".activationPackage
./result/activate
```

**Profile GC cleanup** — old generations pile up:
```bash
nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager
```

**nix.conf tuning:**
```
max-jobs = auto
cores = 0
```

---

## 5. NIX-DIRENV + DEV SHELLS

### .envrc (in any project)
```bash
if ! has nix_direnv_version || ! nix_direnv_version 3.1.2; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.1.2/direnvrc" "sha256-Di03ad3a0ueGi6CGrfhrQzydQIg9APXIPCAMNQgWYM="
fi
use flake
```

### flake.nix (per-project dev shell)
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ nodejs python3 rustc cargo git jq ripgrep fd ];
        shellHook = '' echo "🚀 Dev shell loaded" '';
      };
    };
}
```

### devenv (higher-level, language-aware)
```nix
{ pkgs, ... }: {
  languages.python = { enable = true; version = "3.12"; venv.enable = true; };
  languages.javascript = { enable = true; npm.enable = true; };
  languages.rust = { enable = true; channel = "stable"; };
  packages = [ pkgs.git pkgs.jq ];
}
```

---

## 6. NIRI + NIX

### Use sodiboo/niri-flake
```nix
# flake.nix
inputs.niri.url = "github:sodiboo/niri-flake";

outputs = { self, nixpkgs, niri, ... }: {
  nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      niri.nixosModules.niri
      {
        programs.niri.enable = true;
        programs.niri.settings = {
          outputs."eDP-1".scale = 2.0;
          input.touchpad.natural-scroll = true;
          layout.gaps = 8;
        };
      }
    ];
  };
};
```

### Home Manager module (for non-NixOS)
```nix
inputs.niri.url = "github:sodiboo/niri-flake";
# Use niri.homeModules.niri for HM-level config
```

---

## 7. ESSENTIAL TOOLS

| Tool | What | Install |
|------|------|---------|
| **nh** | Pretty nixos-rebuild/home-manager in Rust | `nix shell nixpkgs#nh` |
| **nom** | Live build dependency tree visualization | `nix shell nixpkgs#nix-output-monitor` |
| **nix-weather** | Check cache hit rate before rebuilding | `nix run github:cafkafk/nix-weather` |
| **nix-index** | "Which package has this file?" | `nix run github:nix-community/nix-index` |
| **nix-direnv** | Fast cached per-project dev shells | via home-manager |
| **nix-alien** | Run random non-nix ELF binaries | `nix profile install github:thiagokokada/nix-alien` |
| **nixGL** | OpenGL wrapper for GUI apps on non-NixOS | `nix run --impure github:nix-community/nixGL` |
| **flake-utils** | Flake boilerplate elimination | `inputs.flake-utils.url = "github:numtide/flake-utils"` |

---

## 8. DAILY COMMANDS

```bash
# Install/remove packages
nix profile install nixpkgs#ripgrep
nix profile remove ripgrep
nix profile list
nix profile rollback
nix profile diff-closures

# Run anything without installing
nix run nixpkgs#cowsay -- "Hello!"
nix shell nixpkgs#git

# Project dev shells
nix develop

# Update everything
nix flake update
nix profile upgrade

# Garbage collection
nix-collect-garbage
nix store gc
nix store optimise

# Check store size
nix path-info -S /nix/store

# Nix shebangs in scripts
#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.pillow
```

---

## 9. ARCH GOTCHAS

- **PATH conflicts:** Don't add common pacman packages to home.packages (git, python, node)
- **Man pages:** Add `~/.nix-profile/share/man` to MANPATH
- **allowed-users:** All HM users must be listed in nix.conf (issue #5704)
- **nixGL:** Required for GUI apps to find OpenGL drivers on non-NixOS
- **nix-ld:** Doesn't work on Arch (designed for NixOS only) — use nix-alien instead
- **nix-env:** Don't use it. Use `nix profile` instead. They're incompatible on the same profile.

---

## 10. FLAKES STATUS (2026)

- Still "experimental" de jure in CppNix
- 78.9% of users use them (2025 survey)
- De facto stable, just use them
- Pin your lockfile, have a channel fallback
- Three forks diverging: CppNix, Lix (moving flakes to plugin), Dix

---

## 11. ALTERNATIVES TO HOME MANAGER

| Tool | Best For | Complexity |
|------|----------|------------|
| **chezmoi** | Cross-machine configs with encryption | Medium |
| **GNU Stow** | Simplest symlink manager | Low |
| **YADM** | Git bare repo with templating | Low |
| **Hybrid (Nix packages + Stow)** | Best of both worlds | Low-Med |

---

## TL;DR — Your Stack

1. **Nix** via pacman → `nix profile` for packages
2. **Home Manager** standalone → packages + program configs
3. **Neovim** → `mkOutOfStoreSymlink` (keep your config, nix just installs the binary)
4. **niri** → `sodiboo/niri-flake`
5. **nix-direnv** → per-project dev shells
6. **nh + nom** → pretty build output
7. **Never touch nix-env again**
