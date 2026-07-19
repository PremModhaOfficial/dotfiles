# Nix Home Manager: Problems, Gotchas & Workarounds (2026)

Research conducted July 2026 across discourse.nixos.org, GitHub issues, blog posts, and community discussions.

---

## 1. The Rebuild Problem

Home manager is famously slow. The bottleneck is rarely the build step — it's the **eval phase** (Nix expression evaluation) that dominates. A typical `home-manager switch` does a full evaluation of every config module even when nothing changed. On a flake-heavy config with nixvim, this can take 30–60 seconds for a one-line git config change.

### Why it's slow

- **No incremental eval cache.** Nix evaluates the entire expression graph every time. `nix flake show` on a large config can take 10+ seconds.
- **GC root proliferation.** Every `home-manager switch` creates a new generation profile link under `~/.local/state/nix/profiles/home-manager`. If you never clean them, the profile resolution itself becomes slow. Worse: when home-manager is used as a NixOS module, the GC roots it creates are **never cleaned** by `--delete-generations`. See [issue #4014](https://github.com/nix-community/home-manager/issues/4014).
- **nixvim in particular.** A nixvim config rebuilds the entire Neovim wrapper binary every time. This is a ~30-second penalty on even trivial out-of-scope changes.

### Workarounds

**a) `mkOutOfStoreSymlink` for dotfiles**

If you're just managing plain config files (not packages), use `mkOutOfStoreSymlink` to symlink directly from your repo instead of copying into the store:

```nix
home.file.".config/git/config" = {
  source = mkOutOfStoreSymlink ./config/git/config;
};
```

This skips the Nix store entirely — no hash, no copy, just a direct symlink. Changes to the source file take effect immediately without a rebuild. Introduced in [PR #1211](https://github.com/nix-community/home-manager/pull/1211) (rycee, 2020).

**b) `text` instead of `source` for small files**

For small inline configs, use `text = ''...''` instead of a `source` file — avoids a store copy and a separate derivation.

**c) Manual profile GC**

```bash
# Clean generations, keeping only the last N
nix-env --profile ~/.local/state/nix/profiles/home-manager --delete-generations +5
home-manager switch  # rebuilds a clean profile
```

For NixOS-module users, the workaround is a `boot.postBootCommands` hook or a periodic systemd timer that prunes stale HM GC roots:

```nix
systemd.timers."hm-gc-cleanup" = {
  wantedBy = [ "timers.target" ];
  timerConfig.OnCalendar = "weekly";
};
systemd.services."hm-gc-cleanup" = {
  script = ''
    nix-collect-garbage --delete-older-than 30d
    # Home-manager GC roots hang around as dead profile links.
    # The only reliable cleanup is to garbage-collect the home-manager
    # profile explicitly:
    ${pkgs.nix}/bin/nix-env --profile /home/*/.local/state/nix/profiles/home-manager \
      --delete-generations +3 2>/dev/null || true
  '';
};
```

**d) `nix build` the activation package separately**

Skip `home-manager switch` entirely for iterative work. Build the activation script once, then re-run it:

```bash
# In your flake
home-manager switch --dry-run  # see what would change
# Build just the activation:
nix build .#homeConfigurations."user@hostname".activationPackage
# Run the activation directly:
./result/activate
```

Much faster loop when tweaking dotfiles.

**e) `--impure` for eval speed**

On flakes, `--impure` skips the pure-eval sandbox check. This avoids some eval overhead and allows reading environment variables during eval (e.g. `builtins.getEnv`). Not a huge win, but measurable on large configs.

**f) `nixConfig` tuning in the flake**

```nix
{
  nixConfig = {
    extra-substituters = [ "https://cache.example.com" ];
    extra-trusted-public-keys = [ "..." ];
    cores = 0;  # use all cores
    max-jobs = 4;
  };
}
```

**g) Split home-manager usage into standalone (NOT as NixOS module)**

When home-manager is a NixOS module, every `nixos-rebuild switch` evaluates the entire HM config. Running standalone gives you independent activation profiles and faster iteration loops. The tradeoff: more manual work to keep system and user configs in sync.

---

## 2. Config Reloading for Specific Apps

### Neovim: `wrapRc = false`

Home manager wraps the Neovim init script by default (sets `-u` to a store path). This breaks lazy loading, luarocks, and any plugin that expects to read `init.lua` from the filesystem.

**The fix:**

```nix
programs.neovim = {
  enable = true;
  wrapRc = false;  # critical: don't wrap init, use runtime dir
};
```

Then put your actual init in `~/.config/nvim/init.lua` (managed by home.file or mkOutOfStoreSymlink). This gives you:
- Real-time `:source $MYVIMRC` working
- Lazy.nvim / lazy loading functional
- No rebuild required for VimL/Lua changes
- Normal plugin manager works (lazy.nvim, packer)

**The `NVIM_APPNAME` trick** — not unique to HM but pairs well:

```bash
# Launch a totally separate Neovim config without a rebuild
NVIM_APPNAME="nvim-test" nvim
```

This reads `~/.config/nvim-test/` instead of `~/.config/nvim/`. Useful for testing config changes side-by-side with your HM-managed production config. The non-wrapped config (wrapRc=false) allows this to work seamlessly because there's no hardcoded `-u` path in the wrapper binary.

**Live reload without rebuilding:**

- Use mkOutOfStoreSymlink for `init.lua` — edit, save, `:source $MYVIMRC`. Zero rebuilds.
- For Lua plugin files: `home.file."${xdg.configHome}/nvim/..."` with mkOutOfStoreSymlink.
- Never rebuild Neovim unless you change the package version or a `programs.neovim` option.

### Fish shell

Fish config changes via `programs.fish.shellInit` or `programs.fish.functions` require a `home-manager switch`. To avoid this for rapid iteration, manage fish config files via `home.file` with mkOutOfStoreSymlink:

```nix
home.file."${config.xdg.configHome}/fish/config.fish" = {
  source = mkOutOfStoreSymlink ./dotfiles/fish/config.fish;
};
```

Edit `config.fish` and source it: `. $__fish_config_dir/config.fish`.

### tmux

`programs.tmux.extraConfig` requires a rebuild. Workaround:

```nix
home.file."${config.xdg.configHome}/tmux/tmux.conf" = {
  source = mkOutOfStoreSymlink ./dotfiles/tmux/tmux.conf;
};
```

Then `tmux source-file ~/.config/tmux/tmux.conf` applies changes immediately.

### Kitty / Alacritty / WezTerm

Same pattern — use mkOutOfStoreSymlink in `home.file` instead of the `programs.kitty` module (unless you need the derivation-level features). Terminal emulators mostly don't need rebuilds for config changes.

### nix-darwin

If you use `nix-darwin` + HM as a module, the same pattern applies. Use `mkOutOfStoreSymlink` for anything that changes frequently.

---

## 3. Common Gotchas on Arch / Non-NixOS Linux

### a) PATH conflicts

On Arch, `pacman` installs its own versions of tools in `/usr/bin`. Nix adds `~/.nix-profile/bin` to PATH. The result: **which binary runs depends on ordering**. This is worse on Arch because `pacman` doesn't know about Nix-managed packages.

**Solution — explicit profile priority:**

```nix
home.sessionPath = [ "$HOME/.nix-profile/bin" ];
# Or use programs.bash.initExtra, programs.fish.shellInit to set PATH explicitly:
programs.bash.initExtra = ''
  export PATH="$HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:$PATH"
'';
```

The HM module already prepends `~/.nix-profile/bin` to PATH, but the system `/etc/profile` or your shell rc might reorder it. Best practice: put Nix paths first and use `type`/`which` to verify.

**Key binaries that often collide on Arch:**

| Binary | Nix version | Arch pacman version | Conflict |
|--------|-------------|---------------------|----------|
| `git` | Yes | Yes | HM installs git, pacman installs git |
| `vim`/`nvim` | Yes | Yes | Both available |
| `node` | Yes | Yes | LTS mismatch |
| `python` | Yes | Yes | Major version difference |
| `tmux` | Yes | Yes | Feature mismatch |
| `gcc` | Yes | Yes | Avoid Nix gcc on Arch! |

**Rule:** If Arch already has a solid, recent package that you don't need to pin for reproducibility, just don't add it to `home.packages`. Only let Nix manage things where you need version pinning or where the Arch package is broken/outdated.

### b) man pages

When packages are installed via HM, their man pages go into `~/.nix-profile/share/man`. If the system `man` doesn't know about this path, you get no man pages for Nix-installed software.

**Fix:**

```nix
manual.manpages.enable = true;  # installs HM man pages
programs.man.enable = true;     # configures MANPATH
```

Or manually:

```bash
# In shell init:
export MANPATH="$HOME/.nix-profile/share/man:$MANPATH"
```

Arch's `man-db` also searches `/etc/man_db.conf`. You could add the Nix path there, but it gets overwritten on updates — shell init is more reliable.

### c) XDG base directory spec

Home-manager's XDG support is good but has edge cases:

- `xdg.configHome` defaults to `~/.config`, spec-compliant.
- `xdg.dataHome` defaults to `~/.local/share`.
- `xdg.stateHome` defaults to `~/.local/state` (non-standard, but widely adopted).

**Gotcha:** Some HM modules (e.g., `programs.git`, `programs.ssh`) write to `~/.config/git` / `~/.ssh` even with XDG enabled. Double-check the module documentation.

**Gotcha on Arch:** The Nix daemon must run as a multi-user install. Arch's `nix` package in pacman installs it as multi-user, but you need manual systemd enable:

```bash
sudo systemctl enable nix-daemon.service --now
```

Without the daemon running, Nix commands fail with "cannot connect to daemon" or "connection reset by peer."

### d) `nix-daemon` service and `allowed-users`

**The single biggest Arch gotcha:** Every user managed by home-manager must be in `nix.settings.allowed-users` (typically `nix.allowedUsers` in NixOS, or `/etc/nix/nix.conf` on Arch). If the user isn't listed, the daemon refuses connections:

```
error: cannot open connection to remote store 'daemon': connection reset by peer
```

This is a known bug/limitation: [issue #5704](https://github.com/nix-community/home-manager/issues/5704), still open as of mid-2026. The workaround:

```bash
# /etc/nix/nix.conf
allowed-users = *
# Or list specific users:
allowed-users = prem alice bob
```

Restart the daemon: `sudo systemctl restart nix-daemon`.

**Why this happens:** The daemon verification and the HM activation both run during the switch. If the user isn't `allowed-users`, the HM activation script can't read from the store to create the symlinks. It fails silently-ish (connection reset), leaving a broken home-manager generation.

### e) `nixos-init` (impermanence) + HM

If you use `nixos-init` (impermanence module) on a non-NixOS system, **all HM-managed dotfiles disappear after reboot**. This is [issue #8599](https://github.com/nix-community/home-manager/issues/8599), still open.

The problem: impermanence creates a tmpfs for `/home`, and HM writes its config links there. On reboot, the tmpfs is wiped. The HM systemd service (`home-manager-$user.service`) needs to run at boot to recreate them, but sometimes fires before the tmpfs is mounted, failing silently.

**Workaround:** Ensure the HM systemd service has a proper dependency:

```bash
systemctl edit home-manager-prem.service
```

```ini
[Unit]
After=home.mount
Wants=home.mount
```

Or add a `RequiresMountsFor=/home` in the service override.

### f) `nix-daemon` double installation

On Arch, `sudo pacman -S nix` installs nix via pacman. If you also install nix via home-manager's `home.packages`, you get two nix binaries. They can conflict on `nix.conf` location (XDG vs `/etc/nix`). Best practice: let pacman manage the nix daemon, don't add `pkgs.nix` to `home.packages`.

### g) No systemd user service support (standalone)

Standalone home-manager on non-NixOS Linux cannot automatically enable systemd user services in the same way the NixOS module can. The HM module `systemd.user.services` exists but the activation script may not enable/start them properly outside NixOS.

```nix
# Works on NixOS. On Arch, you might need to run manually:
systemctl --user enable --now my-service
```

As of 2025/2026, there's been work on controlling user services on non-NixOS ([related PRs](https://github.com/nix-community/home-manager/pull/5780)), but it's still not fully seamless.

---

## 4. Flakes Stability in 2026

### Status: Still "experimental" in CppNix

As of mid-2026, **flakes remain an experimental feature** in CppNix (the "official" Nix implementation). RFC 136 ("A plan to stabilize the new CLI and Flakes incrementally") was merged but has not resulted in flakes being declared stable. The Nix Steering Committee voted on stabilization (motion 0003) and it **did not pass**.

### The debate (from 2025 community survey)

The 2025 NixOS Community Survey reported **78.9% of users use flakes**. The discourse thread shows a deep split:

- **Pro-stabilization camp** (cafkafk, many commercial users): "Flakes are ossified — they're de facto stable. Keeping them experimental is reputational harm."
- **Anti-premature-stabilization camp** (roberth, xokdvium, Nix team): "Flakes have significant defects that can only be fixed with breaking changes. Stabilizing now locks in those defects."
- **Lix fork** strips flakes out of core and moves them to a plugin. Lix's FAQ says they consider flakes part of their compatibility guarantee despite this.

### Practical reality

- **Flakes work fine** for home-manager today. The vast majority of HM users use flakes, and HM's flake integration is mature.
- **No breaking changes** have occurred in years. The syntax and semantics are effectively ossified.
- **Three Nix forks** (CppNix, Lix, Dix) now exist, and they handle flakes differently. This is the biggest risk: divergence means a `flake.nix` that works on CppNix might not on Lix, and vice versa.
- **The experimental label matters if you care about:** long-term format stability guarantees, enterprise procurement (some orgs ban "experimental" features), or using features that depend on flake schemas (which stalled [PR #8892](https://github.com/NixOS/nix/pull/8892), abandoned for 3+ years).

### Recommendation

Use flakes. They work. But:
- Pin your flake inputs explicitly (`flake.lock`), always.
- Test on CppNix (most common), be aware of Lix divergence.
- Don't depend on flake schemas for anything critical.
- Have a migration path to non-flake HM (channels) if you need absolute stability guarantees.

---

## 5. Alternatives to Home Manager

### a) Chezmoi

| Aspect | Chezmoi | HM |
|--------|---------|----|
| Language | Go binary, config in YAML/JSON/toml | Nix expressions |
| Dependencies | No runtime deps beyond chezmoi binary | Full Nix installation |
| Built-in encryption | Yes (age/gpg) via `.chezmoiage` templates | External (sops-nix, agenix, ragenix) |
| Package management | No | Yes (install packages declaratively) |
| Template system | Powerful (go templates) | Nix language (templates are Nix exprs) |
| Learning curve | Low | High |
| Speed | Instant (symlink/copy) | Slow (eval + build) |
| App config reloading | Native (run scripts after apply) | Via activation scripts |

**Best for:** Users who want dotfile management without committing to the Nix ecosystem. Chezmoi works standalone, handles encryption natively, and has zero rebuild time.

**Worst for:** Users who want declarative package installation, complex cross-machine configs, or tight integration with NixOS.

### b) GNU Stow

| Aspect | Stow | HM |
|--------|------|----|
| Complexity | Dead simple | Complex |
| Language | Perl | Nix |
| State | Filesystem symlinks | Store symlinks + profile |
| Determinism | Not guaranteed | Fully deterministic |
| Cross-platform | Any POSIX | Nix-supported systems |
| Packages | No | Yes |

**Best for:** Minimalists who just want symlinks. Stow is the simplest possible solution: organize files as `~/dotfiles/stow/bash/.bashrc`, run `stow bash`, done.

**Worst for:** Anyone who needs conditional configs, package management, templating, or secret management. Stow does exactly one thing.

### c) YADM

| Aspect | YADM | HM |
|--------|------|----|
| Approach | Git bare repo with extensions | Nix declarative config |
| Encryption | GPG via `.yadm/encrypt` | Via external tools |
| Bootstrap | `yadm bootstrap` scripts | HM activation scripts |
| Templates | Jinja2-like (via `yadm alt`) | Nix |
| Diff | git-native | No built-in |
| Maintenance | Very low (just git) | High (rebuild loop) |

**Best for:** People who just want to version-control dotfiles with git, maybe with some templating. YADM is "git with extras."

**Worst for:** Anyone who wants declarative system management, multi-machine divergence, or package management.

### d) Nix + Stow hybrid

A common compromise: use Nix+HM for **packages** only, and Stow or mkOutOfStoreSymlink for **dotfiles**. This avoids the rebuild bottleneck for config changes while keeping declarative package management:

```nix
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    git
    fish
    tmux
    htop
    btop
  ];

  # Dotfiles: mkOutOfStoreSymlink = zero rebuilds
  home.file."${config.xdg.configHome}/nvim" = {
    source = mkOutOfStoreSymlink ../dotfiles/nvim;
    recursive = true;
  };
  home.file."${config.xdg.configHome}/fish" = {
    source = mkOutOfStoreSymlink ../dotfiles/fish;
    recursive = true;
  };
}
```

### e) Bare git repo

The simplest alternative and surprisingly effective:

```bash
git init --bare ~/.dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dotfiles config status.showUntrackedFiles no
dotfiles add .config/nvim/init.lua
dotfiles commit -m "add nvim config"
```

**Pros:** No tools to install. Full git power. Zero overhead.
**Cons:** No templating, no encryption, no conditional logic, no package management.

---

## Summary Cheatsheet: When to Use What

| Situation | Best tool |
|-----------|-----------|
| Already on NixOS, want everything declarative | Home Manager (as NixOS module) |
| Non-NixOS, want packages + dotfiles declaratively | Home Manager (standalone) |
| Dotfiles only, don't care about Nix | Chezmoi (best balance of features/simplicity) |
| Dotfiles only, want pure simplicity | Stow or bare git repo |
| Dotfiles with encryption needs | Chezmoi (native) or YADM+git-crypt |
| Rapid iteration on app configs | mkOutOfStoreSymlink + HM for packages only |
| Minimal overhead, single machine | Bare git repo |

---

## Key GitHub Issues to Watch

| Issue | Description | Status |
|-------|-------------|--------|
| [#8815](https://github.com/nix-community/home-manager/issues/8815) | HM + Lix compatibility issues | Open |
| [#8868](https://github.com/nix-community/home-manager/issues/8868) | allowed-users must include all HM users (daemon connection reset) | Open (dup of #5704) |
| [#8599](https://github.com/nix-community/home-manager/issues/8599) | nixos-init (impermanence) + HM: dotfiles lost on reboot | Open |
| [#4014](https://github.com/nix-community/home-manager/issues/4014) | GC roots never cleaned when HM is NixOS module | Open |
| [#8786](https://github.com/nix-community/home-manager/issues/8786) | mkOutOfStoreSymlink interactions with nix develop | Open |
| [#9432](https://github.com/nix-community/home-manager/issues/9432) | Activation script timeout for slow machines | Open |
| [#4204](https://github.com/nix-community/home-manager/issues/4204) | NixOS GC doesn't clean HM generations | Open |
| [#4672](https://github.com/nix-community/home-manager/issues/4672) | generations nixos gc prune not enough | Open |

---

*Research conducted July 2026. Sources: discourse.nixos.org, GitHub (nix-community/home-manager), NixOS 2025 Community Survey, RFC 136, and blog posts. Key participants cited: cafkafk, roberth, xokdvium, RaitoBezarius, rycee.*
