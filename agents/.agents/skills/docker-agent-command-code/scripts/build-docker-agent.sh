#!/usr/bin/env bash
# Build a docker-agent binary from upstream main, which carries the
# `command-code` harness. Use this when the installed docker-agent predates the
# wiring (anything released before 2026-10-13) or no such release exists yet.
#
# Safe to re-run; it refreshes the checkout in place.
#
# Usage: build-docker-agent.sh [dest-dir]   (default: /tmp/docker-agent-cc)
set -euo pipefail

REPO="https://github.com/docker/docker-agent.git"
DEST="${1:-/tmp/docker-agent-cc}"

command -v git >/dev/null || { echo "git not found" >&2; exit 1; }
command -v go  >/dev/null || { echo "go not found" >&2; exit 1; }

if [ -d "$DEST/.git" ]; then
  echo "==> refreshing $DEST"
  git -C "$DEST" fetch --depth 1 origin main
  git -C "$DEST" checkout -q FETCH_HEAD
else
  echo "==> cloning $REPO (main) into $DEST"
  rm -rf "$DEST"
  git clone --depth 1 --branch main "$REPO" "$DEST"
fi

cd "$DEST"
echo "==> building"
go build -o bin/docker-agent .

BIN="$DEST/bin/docker-agent"
# grep -a reads the binary directly: piping `strings` into `grep -q` would trip
# pipefail, because grep exits early on the first match and SIGPIPEs strings.
if grep -qa 'command-code' "$BIN"; then
  echo "==> OK: $BIN knows the command-code harness"
else
  echo "==> WARNING: command-code not found in the binary" >&2
  exit 1
fi
