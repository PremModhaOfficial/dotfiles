#!/bin/sh
# herdr <-> jcode lifecycle bridge.
#
# Reports jcode session/turn state to herdr over its local socket API so herdr
# can show a "jcode" agent in the sidebar with working/idle state, even though
# herdr has no native jcode integration yet.
#
# Managed via the dotfiles repo (stow package "jcode"). When herdr ships native
# jcode support (`herdr integration install jcode`), that installer can adopt
# this same path.
#
# HERDR_INTEGRATION_ID=jcode
# HERDR_INTEGRATION_VERSION=1

set -eu

event="${JCODE_HOOK_EVENT:-}"

# Only act when running inside a herdr pane.
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_SOCKET_PATH:-}" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

case "$event" in
  session_start | turn_start | turn_end | session_end) ;;
  *) exit 0 ;;
esac

export JCODE_HOOK_EVENT JCODE_HOOK_SESSION_ID JCODE_HOOK_SOURCE JCODE_HOOK_STATUS
export HERDR_SOCKET_PATH HERDR_PANE_ID

python3 - <<'PY'
import json
import os
import random
import socket
import time

# Custom source: herdr accepts arbitrary agent labels/sources over the socket
# API (see `herdr pane report-agent`), so "jcode" works without a native
# integration. The `custom:` prefix matches herdr's documented convention for
# third-party sources.
source = "custom:jcode"
agent = "jcode"

pane_id = os.environ.get("HERDR_PANE_ID")
socket_path = os.environ.get("HERDR_SOCKET_PATH")
if not pane_id or not socket_path:
    raise SystemExit(0)

event = os.environ.get("JCODE_HOOK_EVENT", "")
session_id = os.environ.get("JCODE_HOOK_SESSION_ID") or None


def send(method, **params):
    request = {
        "id": f"{source}:{int(time.time() * 1000)}:{random.randrange(1_000_000):06d}",
        "method": method,
        "params": {
            "pane_id": pane_id,
            "source": source,
            "agent": agent,
            "seq": time.time_ns(),
            **params,
        },
    }
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(0.5)
        client.connect(socket_path)
        client.sendall((json.dumps(request) + "\n").encode())
        try:
            client.recv(4096)
        except Exception:
            pass
        client.close()
    except Exception:
        pass


if event == "session_start":
    # Give herdr the jcode session identity so the pane is resumable/labeled.
    params = {}
    if session_id:
        params["agent_session_id"] = session_id
    start_source = os.environ.get("JCODE_HOOK_SOURCE") or None
    if start_source:
        params["session_start_source"] = start_source
    if params:
        send("pane.report_agent_session", **params)
    # jcode is sitting at the prompt, waiting for input.
    send("pane.report_agent", state="idle")
elif event == "turn_start":
    send("pane.report_agent", state="working")
elif event == "turn_end":
    send("pane.report_agent", state="idle")
elif event == "session_end":
    send("pane.report_agent", state="idle")
    # Hand the pane back to shell/screen detection.
    send("pane.release_agent")
PY
exit 0
