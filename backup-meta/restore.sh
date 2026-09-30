#!/usr/bin/env bash
# restore configs saved by ryoku-shell-install. undo lines are appended as
# the installer changes things; run the whole script to roll back.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
rm -rf "$HOME/.config/quickshell" && mkdir -p "$HOME/.config" && cp -a "$DIR/.config/quickshell" "$HOME/.config/quickshell"
rm -rf "$HOME/.config/niri" && mkdir -p "$HOME/.config" && cp -a "$DIR/.config/niri" "$HOME/.config/niri"
rm -rf "$HOME/.config/kitty" && mkdir -p "$HOME/.config" && cp -a "$DIR/.config/kitty" "$HOME/.config/kitty"
rm -rf "$HOME/.config/fish" && mkdir -p "$HOME/.config" && cp -a "$DIR/.config/fish" "$HOME/.config/fish"
rm -rf "$HOME/.config/nvim" && mkdir -p "$HOME/.config" && cp -a "$DIR/.config/nvim" "$HOME/.config/nvim"
rm -rf "$HOME/.config/mimeapps.list" && mkdir -p "$HOME/.config" && cp -a "$DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list"
rm -rf "$HOME/.config/systemd/user" && mkdir -p "$HOME/.config/systemd" && cp -a "$DIR/.config/systemd/user" "$HOME/.config/systemd/user"
systemctl --user enable dms.service || true
sudo systemctl disable sddm.service && sudo systemctl enable greetd.service
sudo rm -f /etc/sddm.conf.d/99-ryoku.conf
sudo usermod -s /bin/bash prm
