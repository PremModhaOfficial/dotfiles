# NXPLAN.md — Nix + Home Manager Execution Plan
> Arch Linux · niri (WORKING, DO NOT TOUCH) · NVIDIA open drivers · stow dotfiles
> Generated: 2026-07-19

---

## System Snapshot (verified)

| Thing | State |
|---|---|
| OS | Arch Linux, long-term |
| WM | niri (Wayland, WORKING) — `nvidia-open-dkms 610.43.03` |
| Display | Wayland-1, NVIDIA GA107M RTX 3050 Mobile |
| Shells | fish (main), bash (fallback), nushell (fun, no config yet) |
| Dotfiles | `~/dotfiles/` managed by GNU stow |
| Nix | NOT installed yet — clean slate |
| direnv | NOT installed yet |
| Home Manager | NOT installed yet |
| AUR helper | yay |

### What stow currently manages
```
~/.config/fish      → dotfiles/fish/.config/fish
~/.config/nvim      → dotfiles/nvim/.config/nvim
~/.config/alacritty → dotfiles/alacritty/.config/alacritty
~/.config/kitty     → dotfiles/kitty/.config/kitty
~/.config/kanata    → dotfiles/kanata/.config/kanata
~/.config/tmux      → dotfiles/tmux/.config/tmux
~/.config/wezterm   → dotfiles/wezterm/.config/wezterm
~/.config/mpd       → dotfiles/mpd/.config/mpd
~/.config/ncmpcpp   → dotfiles/ncmpcpp/.config/ncmpcpp
```

### What stow does NOT manage (native dirs — keep them native)
```
~/.config/niri/             ← NEVER TOUCH — working niri + DMS config
~/.config/niri/config.kdl   ← live KDL, includes 8 DMS files from dms/
~/.config/niri/dms/         ← alttab, binds, colors, cursor, layout, outputs, windowrules, wpblur
```

### dotfiles/nix/ — exists, currently empty — this is where we build

---

## Hard Rules (non-negotiable)

1. **niri config is OFF LIMITS** — no HM entries, no flake outputs, nothing touches `~/.config/niri/`
2. **DMS files are OFF LIMITS** — the KDL include system stays native, untouched
3. **NVIDIA drivers are OFF LIMITS** — pacman-managed, Nix never goes near kernel modules or `/etc/modprobe.d`
4. **stow coexists** — HM symlinks and stow symlinks don't conflict if we never double-manage the same file
5. **mkOutOfStoreSymlink everywhere** — configs point at live dotfiles repo, hot-reload without rebuilds
6. **Home Manager standalone** — never NixOS module (we're on Arch, long-term)

---

## Architecture Decision: Zone B

```
pacman          → system packages, NVIDIA drivers, niri binary
nix profile     → global nix tools (nh, nom, nix-weather, etc.)
Home Manager    → user packages + shell config (symlinked → dotfiles/)
stow            → coexists; HM takes over managed files gradually
direnv          → per-project dev shells (nix-direnv cached)
niri/DMS        → native, untouched, forever
```

---

## Phase 1 — Install Nix (pacman, multi-user)
**Time: ~10 min | Risk: zero**

```bash
# Install via pacman (Arch-native, multi-user daemon)
sudo pacman -S nix

# Enable and start the daemon
sudo systemctl enable nix-daemon
sudo systemctl start nix-daemon

# Add yourself to nix-users group
sudo gpasswd -a prm nix-users

# Log out and back in (group membership)
# Then verify:
groups | grep nix-users
```

### nix.conf
Edit `/etc/nix/nix.conf` (create if missing):
```
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
```

Also create user-level config:
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Verify
```bash
nix --version
nix run nixpkgs#hello
```

---

## Phase 2 — Core Nix Tools
**Time: ~15 min | Risk: zero**

```bash
# nh — pretty unified CLI for home-manager switch (replaces bare hm command)
nix profile install nixpkgs#nh

# nix-output-monitor — live build tree visualization
nix profile install nixpkgs#nix-output-monitor

# nix-weather — check binary cache hits before rebuilding
nix run github:cafkafk/nix-weather -- --help   # one-off, or add to profile

# nix-index-database — pre-built index, "which package has this binary?"
# NOTE: requires flake input in home.nix (Phase 4), not just a nix profile install
# The HM module wires it automatically — defer to Phase 4

# Optional one-offs (no install needed):
nix run nixpkgs#fastfetch
nix run nixpkgs#cowsay -- "nix works"
```

### nixGL — for any Nix-installed GUI apps that need OpenGL/Vulkan
```bash
# Your NVIDIA is working via pacman — nixGL is only needed if you install
# GUI apps VIA nix that need OpenGL (e.g. blender, vscode from nix)
# Usage when needed:
nix run --impure github:nix-community/nixGL -- <app>
```
> You almost certainly don't need this now. niri itself is pacman-managed.
> Add only if a nix-installed GUI app fails to render.

---

## Phase 3 — direnv + nix-direnv
**Time: ~10 min | Risk: zero**

```bash
# direnv via pacman (system-level, not nix — avoids chicken-and-egg)
sudo pacman -S direnv

# nix-direnv via nix profile
nix profile install nixpkgs#nix-direnv
```

### Wire nix-direnv into direnv
```bash
mkdir -p ~/.config/direnv
echo 'source $HOME/.nix-profile/share/nix-direnv/direnvrc' > ~/.config/direnv/direnvrc
```

### Fish hook — add to dotfiles/fish/.config/fish/config.fish
```fish
# direnv hook (add once, hot-reloads automatically)
direnv hook fish | source
```
> This file is stow-managed and live — edit it directly, no rebuild.

### Nushell hook (for later, when you set up nushell config)
```nushell
# In your env.nu:
$env.config = { ... }
# In config.nu:
direnv hook nu | from nuon | load-env  # nushell 0.87+
```

### Test with a project
```bash
cd ~/some-project
echo "use flake" > .envrc
direnv allow
# Creates a dev shell from the project's flake.nix automatically on cd
```

---

## Phase 4 — Home Manager Standalone Flake
**Time: ~30 min | Risk: low**

### File layout (inside your existing dotfiles repo)
```
dotfiles/nix/
├── flake.nix       ← flake with HM input
├── home.nix        ← main HM config (imports modules)
└── modules/
    ├── packages.nix    ← home.packages list
    ├── shell.nix       ← fish + nushell + starship
    ├── tools.nix       ← git, direnv, nix-index-database
    └── editor.nix      ← neovim binary + mkOutOfStoreSymlink
```

### dotfiles/nix/flake.nix
```nix
{
  description = "prm home manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-index-database, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."prm" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-index-database.hmModules.nix-index-database
          ./home.nix
        ];
      };
    };
}
```

### dotfiles/nix/home.nix
```nix
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
```

### dotfiles/nix/modules/packages.nix
```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # CLI essentials
    ripgrep fd bat eza fzf jq yq
    htop btop
    wget curl
    unzip zip

    # Nix tooling
    nh
    nix-output-monitor
    nixfmt-rfc-style   # nix formatter

    # Dev
    git
    gh                 # github cli

    # Shell
    starship
    zoxide

    # Media / misc — add as needed
  ];
}
```

### dotfiles/nix/modules/shell.nix
```nix
{ config, pkgs, ... }:
{
  # Fish — binary managed by HM, config symlinked to live dotfiles
  programs.fish = {
    enable = true;
    # Do NOT set shellInit or interactiveShellInit here —
    # config lives in dotfiles/fish/.config/fish/config.fish (stow-managed, hot-reload)
  };

  # Symlink fish config → live dotfiles (hot-reload, no rebuild on config changes)
  xdg.configFile."fish".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/fish/.config/fish";

  # Starship prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # Zoxide (smarter cd)
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Nushell — just enable it, config can come later
  programs.nushell.enable = true;
}
```

> **Note:** `xdg.configFile."fish".source = mkOutOfStoreSymlink ...` replaces what stow
> was doing for fish. Run `stow -D fish` from dotfiles/ after HM switch to avoid conflict.

### dotfiles/nix/modules/tools.nix
```nix
{ config, pkgs, ... }:
{
  # Git
  programs.git = {
    enable = true;
    userName = "prm";
    userEmail = "you@example.com";   # ← fill in
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # direnv + nix-direnv (the core dev shell engine)
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  # nix-index-database (pre-built, weekly updated — "which package has foo?")
  # Module imported via flake.nix — this just enables it
  programs.nix-index-database.man.enable = false;  # optional: man page indexing
  programs.command-not-found.enable = false;        # disable the default, nix-index replaces it
}
```

### dotfiles/nix/modules/editor.nix
```nix
{ config, pkgs, ... }:
{
  # Neovim binary only — config lives in dotfiles, symlinked hot
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Symlink nvim config → live dotfiles (lazy.nvim writes lazy-lock.json freely)
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim/.config/nvim";
}
```

> **Note:** After HM switch, remove stow's nvim symlink: `stow -D nvim` from dotfiles/

### Install Home Manager and activate
```bash
# First: add ~/.config/home-manager pointing at your flake
mkdir -p ~/.config/home-manager
# Option A: symlink (cleanest)
ln -s ~/dotfiles/nix ~/.config/home-manager

# Install home-manager binary via nix profile
nix profile install nixpkgs#home-manager

# First switch
home-manager switch --flake ~/dotfiles/nix#prm

# After that, use nh for nicer output:
nh home switch ~/dotfiles/nix
```

### Stow cleanup after HM takes over
```bash
cd ~/dotfiles

# For each config HM now symlinks via mkOutOfStoreSymlink, unstow it:
stow -D nvim    # HM handles this now via editor.nix
stow -D fish    # HM handles this now via shell.nix

# Keep stowing everything HM doesn't touch:
# alacritty, kitty, kanata, tmux, wezterm, mpd, ncmpcpp
# niri is NOT stowed and NOT in HM — stays exactly as is
```

---

## Phase 5 — Per-project Dev Shells (ongoing)
**Time: per project | Risk: zero**

### Minimal flake.nix per project
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_22
          # add what the project needs
        ];
        shellHook = ''echo "🚀 dev shell ready"'';
      };
    };
}
```

```bash
# In project root:
echo "use flake" > .envrc
direnv allow
# nix-direnv auto-activates on cd, caches the env, no rebuild on repeat visits
```

### devenv alternative (richer — processes, services, language helpers)
```nix
# See research doc Part 4 for full devenv flake.nix example
# Use when you need: auto-start processes, postgres, redis, venvs, etc.
```

---

## PATH and Environment (Arch-specific fixes)

Add to `dotfiles/fish/.config/fish/config.fish` after nix install:
```fish
# Nix profile
fish_add_path $HOME/.nix-profile/bin

# Man pages from nix packages
set -x MANPATH $HOME/.nix-profile/share/man $MANPATH

# XDG data dirs (for .desktop files from nix packages)
set -x XDG_DATA_DIRS $HOME/.nix-profile/share $XDG_DATA_DIRS

# Locale (avoids warnings on Arch)
set -x LOCALE_ARCHIVE /usr/lib/locale/locale-archive
```

---

## nix.conf Reference (final state)
`/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
```

---

## Cheatsheet — Commands You'll Actually Use

| Task | Command |
|---|---|
| Apply HM config | `nh home switch ~/dotfiles/nix` |
| Update all flake inputs | `nix flake update ~/dotfiles/nix` |
| Search packages | `nix search nixpkgs <name>` |
| Run something without installing | `nix run nixpkgs#<name>` |
| Temp shell with package | `nix shell nixpkgs#<name>` |
| Check cache before rebuild | `nix run github:cafkafk/nix-weather` |
| Find which package has a binary | `nix-locate bin/<name>` |
| GC old generations | `nix-collect-garbage -d` |
| List HM generations | `home-manager generations` |
| Rollback HM | `home-manager generations` → pick one → activate |

---

## Validation Notes (from research cross-check)

| Claim | Status |
|---|---|
| snowfall-lib | ❌ Abandoned — author confirmed, skip entirely, use flake-utils |
| niri-flake declarative config | ⚠️ Works but SKIP — would replace your live KDL, DMS include system doesn't map cleanly |
| nix-index-database | ✅ Needs flake input + hmModules import — not just `programs.nix-index.enable` |
| direnv-instant (Mic92) | ✅ Active, has HM module (`programs.direnv-instant.enable`) — add later if shell load feels slow |
| Flakes "experimental" | ✅ De facto stable (78.9% usage), de jure still experimental in CppNix — use them, pin lockfile |
| nix-ld | ❌ NixOS only — use nix-alien on Arch if you need to run foreign ELF binaries |
| nixGL | ✅ Only needed for nix-installed GUI apps — your niri+NVIDIA is pacman, not affected |
| Dix (listed as fork) | ⚠️ "Dix" in research = diff tool bundled in `nh`, NOT a Nix implementation fork. Real forks: CppNix, Lix, Determinate Nix |

---

## What Is Explicitly Out of Scope

- `~/.config/niri/` — untouched forever unless you explicitly choose Zone C later
- `~/.config/niri/dms/` — untouched forever
- NVIDIA drivers — pacman owns these, nix never goes near them
- nixvim — you have lazy.nvim working via stow/symlink, keep it
- NixOS — Arch long-term
- Impermanence — not relevant to your setup
- niri-flake declarative config — revisit only when you want to experiment with a spare config and have TTY fallback ready

---

## Hand-off Checklist

- [ ] Phase 1: `pacman -S nix`, daemon, nix-users group, nix.conf
- [ ] Phase 2: `nix profile install` nh, nom; test `nix run`
- [ ] Phase 3: `pacman -S direnv`, nix-direnv, fish hook in config.fish, direnvrc
- [ ] Phase 4: write flake.nix + home.nix + modules into dotfiles/nix/, `nh home switch`
- [ ] Phase 4 cleanup: `stow -D nvim fish` after HM takes those over
- [ ] Phase 5: add `flake.nix` + `.envrc` to first real project
- [ ] Verify niri still works after every phase (it will — we never touch it)
