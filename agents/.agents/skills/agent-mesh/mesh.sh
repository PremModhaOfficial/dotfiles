#!/usr/bin/env bash
# agent-mesh bootstrap: one nats-server, one nats CLI, one registry.
# Idempotent. Safe to re-run.
#
# After the reboot-proof mod (2026-09-28), this script is the MANUAL path only.
# The mod itself ensures the server on every session start (dial-first, boot if
# absent), so a rebooted PC needs nothing but `cmd --yolo --mod .../mesh.ts`.
# Use this script to pre-warm a machine, inspect state, or stop the server.
set -euo pipefail

DIR="${0%/*}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/agent-mesh"
URL="${NATS_URL:-nats://127.0.0.1:4222}"
HOSTPORT="${URL#nats://}"; HOSTPORT="${HOSTPORT%%/*}"
[ -z "$HOSTPORT" ] && HOSTPORT="127.0.0.1:4222"
VER_CLI="0.5.0"

die() { echo "error: $*" >&2; exit 1; }

have_server() {
  # A real publish is the only trustworthy probe. `nats server list` exits 0
  # even when it errors, and /varz needs the monitoring port (off by default).
  "$NATSCLI" pub -q _mesh.probe ping >/dev/null 2>&1
}

install_cli() {
  mkdir -p "$CACHE"
  local os arch
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  [ "$os" = "darwin" ] && os="darwin"
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64) arch=amd64 ;;
    arm64|aarch64) arch=arm64 ;;
    *) die "unsupported arch $arch — install nats CLI manually" ;;
  esac
  local zip="$CACHE/nats-$VER_CLI-$os-$arch.zip"
  if [ ! -x "$CACHE/nats-$VER_CLI-$os-$arch/nats" ]; then
    echo "fetching nats CLI $VER_CLI ($os/$arch)..."
    curl -fsSL -o "$zip" \
      "https://github.com/nats-io/natscli/releases/download/v$VER_CLI/nats-$VER_CLI-$os-$arch.zip" \
      || die "download failed"
    unzip -oq "$zip" -d "$CACHE" || die "unzip failed"
  fi
  echo "$CACHE/nats-$VER_CLI-$os-$arch/nats"
}

# Stream limits (DeepWiki-sourced, verified 2026-09-27): 10k msgs, 100MB,
# 72h age, 1MB per message, discard-old. Recreate path because `stream edit`
# needs a TTY for confirmation; `stream add --defaults` is headless-safe.
# Defined before the case block: bash runs top-down, calling it earlier fails.
ensure_streams() {
  local NCLI="$1"
  for spec in "AGENTS:agents.>" "WORK:work.>"; do
    local S="${spec%%:*}" SUBJ="${spec##*:}"
    if ! "$NCLI" stream info "$S" >/dev/null 2>&1; then
      "$NCLI" stream add "$S" --subjects "$SUBJ" --storage file \
        --retention limits --discard old \
        --max-msgs 10000 --max-bytes 104857600 --max-age 72h \
        --max-msg-size 1048576 --defaults >/dev/null 2>&1
    fi
  done
}

case "${1:-up}" in
  up)
    NATSCLI="$(install_cli)"           # the probe needs the CLI, so install first
    export PATH="$(dirname "$NATSCLI"):$PATH"
    if have_server; then
      echo "server already up at $URL"
    else
      BIN="$DIR/nats-server"
      if [ ! -x "$BIN" ]; then
        die "no nats-server at $BIN — download from github.com/nats-io/nats-server/releases"
      fi
      mkdir -p "$DIR/jsdata"
      nohup "$BIN" -js -sd "$DIR/jsdata" >"$DIR/server.log" 2>&1 &
      echo $! >"$DIR/server.pid"
      for _ in $(seq 1 20); do have_server && break; sleep 0.25; done
      have_server || die "server failed to start, see $DIR/server.log"
      echo "server started (JetStream on), pid $!"
    fi
    "$NATSCLI" kv add AGENT_STATE >/dev/null 2>&1 || true   # idempotent
    ensure_streams "$NATSCLI"
    echo "nats CLI: $NATSCLI"
    echo "registry: AGENT_STATE ready"
    echo "URL: $URL"
    ;;
  down)
    NATSCLI="$(install_cli)"
    # Kill by pid file, then by matching our own binary — a stale pid file or a
    # server started outside this script must not leave the port held.
    [ -f "$DIR/server.pid" ] && kill "$(cat "$DIR/server.pid")" 2>/dev/null
    for p in $(ps -eo pid,args | awk -v d="$DIR/nats-server" '$0 ~ d && !/awk/ {print $1}'); do
      kill "$p" 2>/dev/null
    done
    rm -f "$DIR/server.pid"
    for _ in $(seq 1 20); do have_server || break; sleep 0.25; done
    have_server && die "server still running on $HOSTPORT"
    echo "stopped"
    ;;
  status)
    NATSCLI="$(install_cli 2>/dev/null || true)"
    NATSCLI="${NATSCLI:-}"
    have_server && echo "server: up ($URL)" || echo "server: down"
    ;;
  *)
    echo "usage: mesh.sh [up|down|status]" >&2
    exit 1
    ;;
esac
