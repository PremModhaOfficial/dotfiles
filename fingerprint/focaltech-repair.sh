#!/bin/bash
# Re-install FocalTech FT9366 proprietary libfprint driver after a libfprint package upgrade.
# Run as root:  sudo ~/dotfiles/fingerprint/focaltech-repair.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$DIR/libfprint-2.so.2.0.0" "$DIR/focaltech-shim.so" /usr/lib/
patchelf --add-needed focaltech-shim.so /usr/lib/libfprint-2.so.2.0.0
systemctl restart fprintd
echo "done - verify with: fprintd-list $SUDO_USER"
