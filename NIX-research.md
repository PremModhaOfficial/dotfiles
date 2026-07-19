# Nix Research — All Agent Findings (2026-07-19)
## Arch Linux + niri + Home Manager + Flakes

---

# PART 1: Nix Helper Tools & CLI Utilities

## 🔧 Core CLI Helpers

### **nh** (Nix Helper)
- **What:** Rust reimplementation of nixos-rebuild, home-manager CLI, and darwin-rebuild — unified into one pretty tool
- **Commands:** `nh os switch`, `nh home switch`, `nh darwin switch`, `nh search`, `nh clean`
- **Why:** Faster builds with nix-output-monitor integration, pretty diffs via `dix`, nicer garbage collection with gcroot cleanup, offline SPAM database search, GitHub PR/issue search. Written in Rust, no Python/shell wrappers
- **Install:** `nix shell nixpkgs#nh`

### **nix-output-monitor (nom)**
- **What:** Pipes nix-build output through a live dependency tree visualization with progress bars, build times, and download stats
- **Why:** Turns opaque build logs into a readable tree. Shows what's building, what's done, what failed, and estimated times. Drop-in replacement: `nom build` instead of `nix build`
- **Install:** `nix shell nixpkgs#nix-output-monitor`

### **nix-search-cli**
- **What:** CLI client for search.nixos.org packages — search by name, description, installed status
- **Why:** Fast terminal search without opening a browser. Pipe-friendly JSON output
- **Install:** `nix run github:peterldowns/nix-search-cli`

### **nix-weather**
- **What:** Rust tool that checks binary cache availability for your entire NixOS system before you rebuild. "Checks the weather" before switching
- **Why:** Avoid surprise rebuilds. Runs `nix-store` requisites, then checks cache headers in parallel (~45ms typical). Inspired by Guix's `guix weather`
- **Install:** `nix run github:cafkafk/nix-weather -- --name myhost --config ~/my-nixos-config`

---

## 📦 Package & Profile Management

### **nix profile** (vs nix-env)
- **What:** Modern replacement for `nix-env` — manages Nix profiles with rollback, per-profile installs, and generational tracking
- **nix-env problems:** Mutates a single profile, hard to track what you installed, slow dependency resolution
- **nix profile advantages:** Versioned generations, independent package management, works with flakes (`nix profile install nixpkgs#hello`), proper rollback support
- **Use:** `nix profile install`, `nix profile remove`, `nix profile list`, `nix profile rollback`

### **nix-index**
- **What:** Indexes built derivations in nixpkgs binary caches so you can search "which package provides this file"
- **Why:** Run `nix-locate 'bin/hello'` to find the exact package. Also provides a `command-not-found` hook — type a missing command and it tells you how to install it
- **Install:** `nix run github:nix-community/nix-index#nix-index` (builds the DB, ~5 min)

### **nix-index-database**
- **What:** Pre-generated nix-index databases (so you don't wait 5 min to build your own)
- **Why:** Comes with NixOS and Home Manager modules. Just enable and get instant `command-not-found` and `nix-locate` with no local build step
- **Use:** `programs.nix-index.enable = true` in NixOS/HM config

### **nix-prefetch-url / nix-prefetch-git / nix-prefetch-github**
- **What:** Download a source archive/git repo and print its hash — for pinning dependencies in derivations
- **Why:** Essential for writing packages: get the hash, paste into `fetchurl`/`fetchFromGitHub`. `nix-prefetch-github` handles GitHub API pagination automatically
- **Install:** Built-in (`nix-prefetch-url`), others via nixpkgs

---

## 🏠 Development Environment

### **nix-direnv**
- **What:** Faster, persistent implementation of direnv's `use_nix` and `use_flake` — caches the nix-shell environment so it loads nearly instantly on repeat visits
- **Why:** Standard direnv rebuilds the env every time you `cd`. nix-direnv caches it, prevents garbage collection of build deps (won't lose your environment mid-flight with no internet). Simpler than lorri — no daemon
- **Install:** Via home-manager (`programs.direnv.nix-direnv.enable = true`) or NixOS (`programs.direnv.enable = true`)
- **Use:** Add `use nix` or `use flake` to `.envrc`

### **direnv-instant**
- **What:** Non-blocking daemon that runs direnv async in the background — your shell loads immediately while env builds in background
- **Why:** Pairs with nix-direnv for truly instant shell entry. Auto-notifies when environment is ready
- **Install:** `nix run github:Mic92/direnv-instant`

---

## 🧩 Flake Infrastructure

### **flake-utils**
- **What:** Pure Nix utility functions for writing flake outputs — `eachDefaultSystem`, `mkApp`, `flattenTree`, `simpleFlake`
- **Why:** Eliminates boilerplate in every flake. `eachDefaultSystem` auto-generates packages for x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin. Used by thousands of flakes
- **Use:** `inputs.flake-utils.url = "github:numtide/flake-utils"` then `flake-utils.lib.eachDefaultSystem (system: { ... })`

### **snowfall-lib**
- **What:** Higher-level flake library built on flake-utils-plus — unified configuration for systems, packages, modules, shells, templates with automatic directory conventions
- **Why:** Convention over configuration: put files in `systems/`, `packages/`, `modules/` and they're auto-discovered. Eliminates explicit per-system wiring. Good for larger multi-system flake repos
- **Note:** Currently unmaintained (call for maintainers active as of 2025). Consider flake-utils or manual wiring for new projects

---

## 🎨 Configuration-as-Code

### **nixvim**
- **What:** Configure Neovim entirely in Nix — plugins, keybindings, options, LSP, everything declarative
- **Why:** Reproducible editor config across machines. Integrates with your NixOS/HM config. Can generate standalone Neovim packages or embed in your system config. ~2.7k stars, actively maintained
- **Install:** `programs.nixvim.enable = true` in Home Manager, or use as standalone flake
- **Docs:** nix-community.github.io/nixvim

---

# PART 2: Nix Home Manager Problems, Gotchas, and Workarounds

## 1. The Rebuild Problem

### Root Cause
No incremental eval cache + GC root proliferation + nixvim rebuilds. Every `home-manager switch` evaluates your entire config from scratch.

### Workarounds

**mkOutOfStoreSymlink (PR #1211 by rycee)**
- Symlinks direct from your repo, zero rebuilds for config changes
- Creates a symlink directly to a live path outside the Nix store
- Config stays mutable, not read-only

**Faster iteration without home-manager switch:**
```bash
nix build .#homeConfigurations."user@host".activationPackage
./result/activate
```
Skips the full `home-manager switch` overhead.

**Profile GC workaround:**
```bash
nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager
```
Systemd timer for NixOS-module users.

**nix.conf tuning:**
```
max-jobs = auto
cores = 0
```

**Split HM as standalone** (not NixOS module) for independent activation.

---

## 2. Config Reloading

### Neovim
- **`wrapRc = false`** is critical — allows `:source $MYVIMRC`, lazy loading, plugin managers
- **NVIM_APPNAME trick** — launch separate nvim configs without rebuild: `NVIM_APPNAME=nvim-dev nvim`
- **Symlink approach** — use `mkOutOfStoreSymlink` for zero-rebuild config

### Other apps
- Fish, tmux, kitty: Use `mkOutOfStoreSymlink` in `home.file` for zero-rebuild configs
- Apps that support live reload (like niri with its KDL config) work great with symlinks

---

## 3. Arch Gotchas

### PATH conflicts
- Nix vs pacman versions of git, nvim, node, python
- **Don't add common Arch packages to home.packages** — let pacman manage them

### Man pages
- Add `~/.nix-profile/share/man` to MANPATH manually

### allowed-users
- ALL HM users must be listed in nix.conf — otherwise daemon refuses connection
- Issue #5704, still open as of 2026

### Double nix daemon
- Don't install `pkgs.nix` in `home.packages` on Arch — let pacman manage the daemon

### nixos-init + HM
- Dotfiles vanish on reboot (issue #8599)
- Workaround: systemd unit `After=home.mount`

### Desktop integration
- Add `~/.nix-profile/share` to `$XDG_DATA_DIRS` for .desktop files

### Locale warnings
- `export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive`

### Sandbox issues
- May need `sandbox = false` in `/etc/nix/nix.conf` on some Arch setups

---

## 4. Flakes Stability

- **Still experimental** in CppNix as of mid-2026
- RFC 136 merged but SC vote 0003 failed
- **78.9% of users use flakes** (2025 survey) — de facto stable, de jure not
- Three forks diverging: CppNix, Lix (moving flakes to plugin), Dix
- **Practical advice:** Use flakes, pin lockfile, don't depend on flake schemas, have channel fallback

---

## 5. Alternatives to Home Manager

| Tool | Best For | Complexity | What You Have |
|------|----------|------------|---------------|
| **chezmoi** | Cross-machine configs with native encryption, instant apply | Medium | Dotfiles + secrets in one tool |
| **GNU Stow** | Simplest symlink manager, pure POSIX | Low | Just symlinks, nothing else |
| **YADM** | Git bare repo with templating, very low maintenance | Low | Git-powered dotfiles |
| **Bare git repo** | Zero dependencies, full git power | Low | Just git |
| **Hybrid (Nix packages + Stow dotfiles)** | Best of both worlds for non-NixOS | Low-Med | Nix for packages, Stow for configs |

---

# PART 3: Nix + niri + Flake Research

## 1. Home-Manager Niri Module & Declarative Niri Config

### The niri-flake (sodiboo/niri-flake) — THE way to use niri + Nix
- **NixOS module** (`niri.nixosModules.niri`)
- **Home Manager module** (`niri.homeModules.niri`)
- **Config module** (`niri.homeModules.config`) — build-time validated config
- **Overlay** (`niri.overlays.niri` / `niri.overlays.niri-unstable`)
- **Stylix integration** (`niri.homeModules.stylix`)
- **Binary cache** at `niri.cachix.org`

### Declarative config example:
```nix
{
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
}
```

- `programs.niri.settings` = Nix attrset, validated at build time against niri schema
- NixOS module auto-installs xdg-desktop-portal-gnome, enables polkit, swaylock PAM, dconf, opengl
- `programs.niri.package` defaults to `niri-stable`; use `pkgs.niri-unstable` for bleeding edge

### Niri itself (niri-wm/niri)
- Scrollable-tiling Wayland compositor, written in Rust
- Dynamic workspaces (like GNOME), floating support since 25.01, tabs, gradient borders, background blur, custom shaders
- Integrated Xwayland via xwayland-satellite since 25.08
- Config is KDL format, live-reloading
- Matrix: #niri:matrix.org

---

## 2. Fun Flake Examples

### A) devenv + Flakes
```nix
{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
  };
  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [({ pkgs, config, ... }: {
          packages = [ pkgs.hello ];
          enterShell = '' hello '';
          processes.run.exec = "hello";
        })];
      };
    };
}
```

### B) flake-parts
Core framework for writing distributed Nix flakes with module system:
- Splits `flake.nix` into focused units in their own files
- Handles `system` cleanly
- Home-manager itself now has a flake-parts module option
- Docs: https://flake.parts

### C) flake-utils pattern (most common)
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.nixfmt-tree;
        devShells.default = pkgs.mkShell { packages = with pkgs; [ ... ]; };
      }
    );
}
```

---

## 3. Dotfile Repo Structures for Arch + Nix + Wayland

### gvolpe/nix-config (⭐1.1k) — The gold standard
```
├── nixosConfigurations (per-machine)
├── homeConfigurations (per-WM per-monitor: niri-edp, niri-hdmi, etc.)
├── packages (custom: neovim, slack, metals, bazecor)
└── out (overlays + pkgs for consumers)
```
- Separate NixOS and Home Manager generations
- Neovim config as its own flake: github:gvolpe/neovim-flake

### XiaoXioe/nixos-config — Modern modular niri setup
```
├── flake.nix
├── dotfiles/
├── lib/
├── hosts/nixos/
├── modules/
│   ├── ai/ (Ollama, llama.cpp, MCP servers)
│   ├── apps/
│   ├── core/
│   ├── desktop/ (KDE, GNOME, Niri, Hyprland)
│   ├── hardware/ (Impermanence)
│   ├── scripts/
│   ├── security/ (sops, hardening)
│   ├── services/
│   ├── settings/
│   ├── specialization/ (Gaming modes)
│   └── virtualisation/
└── secrets/ (sops-nix)
```
Key: Per-user feature mapping — `userFeatures.desktop.niri = true` auto-enables all options.

---

## 4. Nixvim vs Regular Neovim Config Debate

### Nixvim pros
- Everything is a module — `plugins.X.enable = true` does everything
- Build-time validation of config
- Reproducible across machines
- Standalone mode works too: `nix run github:nix-community/nixvim`

### Nixvim cons
- Not all plugins have modules — you'll still use `extraPlugins` sometimes
- Lags behind nixpkgs
- Debugging can be harder (generated lua vs hand-written)
- Some people find it more complex than just writing lua

### Regular neovim + Nix
- Neovim config as its own flake (`neovim-flake`)
- Plugins managed via nix derivation
- Config in lua, just wrapped in a nix derivation
- More control, more boilerplate

### **VERDICT for your case:** Just symlink your existing config. Use `mkOutOfStoreSymlink`. Keep your lazy.nvim, your Lua config, everything. Nix just installs the binary.

---

## 5. Cool Nix Things on Non-NixOS

### A) Impermanence (nix-community/impermanence)
Root filesystem wiped on boot, with declarative persistence:

**tmpfs as root** (simplest):
```nix
fileSystems."/" = {
  device = "none";
  fsType = "tmpfs";
  options = [ "defaults" "size=25%" "mode=755" ];
};
```

**Declarative persistence:**
```nix
environment.persistence."/persistent" = {
  hideMounts = true;
  directories = [
    "/var/log" "/var/lib/bluetooth" "/var/lib/nixos"
    { directory = ".gnupg"; mode = "0700"; }
    { directory = ".ssh"; mode = "0700"; }
  ];
};
```

### B) nix-alien (thiagokokada/nix-alien)
Run non-nix ELF binaries:
```bash
nix-alien ~/myapp              # Run in FHS shell with all deps
nix-alien-ld ~/myapp           # Set NIX_LD_LIBRARY_PATH for nix-ld
nix-alien-find-libs ~/myapp    # Interactive library finder (fzf-based)
```

### C) nixGL
For running OpenGL/Vulkan apps on non-NixOS:
```bash
nix run --impure github:nix-community/nixGL -- blender
nix run --impure github:guibou/nixGL -- nix run github:thiagokokada/nix-alien -- blender
```

### D) nix-ld
System-wide dynamic linker compatibility (NixOS only — doesn't work on Arch):
```nix
programs.nix-ld.enable = true;
```

### E) Fun combos people do
- Nix on Arch + niri + impermanence (tmpfs root) + sops-nix for secrets
- Per-app bubblewrap sandboxing via NixPak
- Devenv for project-specific dev shells on non-NixOS
- nix profile install for user-level package management alongside pacman

---

# PART 4: Nix-Direnv + Devenv + Home-Manager on Arch

## Installing Nix on Arch
```bash
sudo pacman -S nix
sudo systemctl enable nix-daemon
sudo systemctl start nix-daemon
sudo gpasswd -a $USER nix-users
# Log out and back in
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## Installing direnv + nix-direnv on Arch
```bash
sudo pacman -S direnv
nix profile install nixpkgs#nix-direnv
```

### Shell Hook Setup

**Zsh** — add to `~/.zshrc`:
```bash
eval "$(direnv hook zsh)"
```

**Fish** — add to `~/.config/fish/config.fish`:
```fish
direnv hook fish | source
```

### Configure nix-direnv in direnvrc
Create/edit `~/.config/direnv/direnvrc`:
```bash
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

## .envrc File Examples

### Minimal — use flake
```bash
use flake
```

### Full nix-direnv bootstrap (recommended)
```bash
if ! has nix_direnv_version || ! nix_direnv_version 3.1.2; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.1.2/direnvrc" "sha256-Di03ad3a0ueGi6CGrfhrQzyGdQIg9APXIPCAMNQgWYM="
fi
use flake
```

### Manual reload mode
```bash
nix_direnv_manual_reload
use flake
```

### Pass --impure to flake evaluation
```bash
use flake . --impure
```

## flake.nix for Dev Shells

### Plain Nix
```nix
{
  description = "My project dev shell";
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
  outputs = { self, nixpkgs }:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_22 python3 rustc cargo git jq ripgrep fd
          nil nixfmt-rfc-style
        ];
        shellHook = '' echo "🚀 Dev shell loaded" '';
      };
    };
}
```

### devenv
```nix
{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
  };
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [({ pkgs, config, ... }: {
          languages.python = { enable = true; version = "3.12"; venv.enable = true; };
          languages.javascript = { enable = true; npm.enable = true; };
          languages.rust = { enable = true; channel = "stable"; };
          packages = [ pkgs.git pkgs.jq pkgs.ripgrep ];
          enterShell = '' echo "devenv shell loaded" '';
          processes.dev.exec = "npm run dev";
        })];
      };
    };
}
```

## Home-Manager on Arch (Not NixOS)

### Install
```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

### Minimal flake.nix
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

### Minimal home.nix
```nix
{ config, pkgs, ... }:
{
  home.username = "prm";
  home.homeDirectory = "/home/prm";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [ htop ripgrep fd jq git direnv ];

  programs.git = { enable = true; userName = "Your Name"; userEmail = "you@example.com"; };

  programs.starship = { enable = true; enableZshIntegration = true; };

  programs.zsh = {
    enable = true; enableCompletion = true;
    shellAliases = { ll = "ls -la"; gs = "git status"; };
    initExtra = '' source ~/.nix-profile/etc/profile.d/hm-session-vars.sh '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
```

### Switching / Updating
```bash
home-manager switch
home-manager switch --flake ~/.config/home-manager#prm
nix flake update ~/.config/home-manager
```

---

# PART 5: Symlink Neovim Config (No nixvim)

## The Lazy Solution
```nix
{ config, ... }:
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink /path/to/your/nvim/config;
}
```

## What is mkOutOfStoreSymlink?
Normal `xdg.configFile` copies your config into the Nix store (`/nix/store/...`) and symlinks from there — making it read-only. `mkOutOfStoreSymlink` creates a symlink directly to a live path **outside** the store, so your config stays mutable.

## Can You Just Point HM at a Folder?
Yes. The `source` attribute accepts an absolute path string or a `mkOutOfStoreSymlink` call.

**For a local directory:**
```nix
xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
```

**Must use absolute paths** with `mkOutOfStoreSymlink`.

## Pros
- Zero-latency iteration: edit config, nvim sees it immediately
- `lazy-lock.json` stays writable (lazy.nvim works normally)
- Git versions your config without Nix store intermediaries
- Bidirectional: change via nvim GUI, commit later in git

## Cons
- Config is NOT in the Nix store → can't rollback via generations
- Remote deployment breaks: you need the dotfiles repo physically on the target machine
- New machines need manual clone before HM switch works
- Lose Nix-level co-location of settings across programs

## The lazy-lock.json issue
This is THE reason people use mkOutOfStoreSymlink for neovim. Standard `xdg.configFile` (without mkOutOfStoreSymlink) copies to the Nix store → lazy.nvim can't write lazy-lock.json → error. mkOutOfStoreSymlink fixes this because the symlink points to a writable directory.

## Recommended Config
```nix
{ config, pkgs, ... }:
{
  programs.neovim = { enable = true; };
  xdg.configFile."nvim".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/path/to/your/nvim-config";
}
```

---

# PART 6: Nix on Arch Daily Driver Tips

## nix profile alongside pacman — No PATH Conflicts
Pacman installs to `/usr/bin`, `/usr/lib`, etc. Nix installs to `/nix/store/...` with symlinks in `~/.nix-profile/bin`. Completely separate filesystem trees. No collision.

## Modern nix commands vs nix-env

| Old (nix-env) | New (modern nix) |
|---|---|
| `nix-env -iA nixpkgs.hello` | `nix profile install nixpkgs#hello` |
| `nix-env -e hello` | `nix profile remove hello` |
| `nix-env -q` | `nix profile list` |
| `nix-env --rollback` | `nix profile rollback` |
| `nix-shell -p pkg` | `nix shell nixpkgs#pkg` |
| `nix-build -E ...` | `nix build nixpkgs#pkg` |
| `nix-shell --run "cmd"` | `nix run nixpkgs#pkg` |
| (nothing) | `nix develop` (flake dev shells) |

## nix-ld vs nix-alien
- **nix-ld:** Doesn't work on Arch (designed for NixOS where it can replace `/lib64`)
- **nix-alien:** Works everywhere — auto-detects binary deps, wraps with nix libs

```bash
nix-alien ~/myapp                    # FHS shell with all deps
nix-alien-ld ~/myapp                 # NIX_LD_LIBRARY_PATH wrapper
nix-alien-find-libs ~/myapp          # Interactive library finder (fzf)
```

## nixGL for GUI Apps
```bash
nix run --impure github:nix-community/nixGL -- blender
nix run --impure github:nix-community/nixGL -- vscode
```

## Fun Nix One-Liners
```bash
# Run anything without installing
nix run nixpkgs#cowsay -- "Hello!"
nix shell nixpkgs#git

# Nix shebangs — make scripts self-contained
#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.pillow python3Packages.requests
import requests
from PIL import Image

# Flake-based shebangs (Nix 2.19+)
#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#hello nixpkgs#cowsay --command bash

# Search packages
nix search nixpkgs python | grep numpy

# Show what's in a flake
nix flake show github:user/repo

# Garbage collection
nix-collect-garbage
nix store gc
nix store optimise

# Check store size
nix path-info -S /nix/store

# Fun commands
nix run nixpkgs#cmatrix          # Matrix rain
nix run nixpkgs#fastfetch        # Neofetch alternative
nix run nixpkgs#figlet -- "NIX"  # ASCII art
```

---

# QUICK REFERENCE

## Arch + Nix setup checklist
1. `pacman -S nix` → `systemctl enable --now nix-daemon`
2. Add `~/.nix-profile/bin` to PATH
3. Enable flakes: `experimental-features = nix-command flakes` in nix.conf
4. Set `max-jobs = auto` in nix.conf
5. Install nixGL for GUI apps
6. Use `nix profile` for persistent installs, `nix run` for one-offs
7. Use direnv for project dev shells
8. Never touch nix-env again

## Essential tools
| Tool | What |
|------|------|
| **nh** | Pretty nixos-rebuild/home-manager in Rust |
| **nom** | Live build dependency tree visualization |
| **nix-weather** | Check cache hit rate before rebuilding |
| **nix-index** | "Which package has this file?" |
| **nix-direnv** | Fast cached per-project dev shells |
| **nix-alien** | Run random non-nix ELF binaries |
| **nixGL** | OpenGL wrapper for GUI apps on non-NixOS |
| **flake-utils** | Flake boilerplate elimination |

## Sources
- https://wiki.archlinux.org/title/Nix
- https://github.com/nix-community/home-manager
- https://github.com/sodiboo/niri-flake
- https://github.com/nix-community/nixvim
- https://github.com/nix-community/impermanence
- https://github.com/thiagokokada/nix-alien
- https://github.com/nix-community/nixGL
- https://github.com/gvolpe/nix-config
- https://flake.parts
- https://devenv.sh
