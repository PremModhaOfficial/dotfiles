#!/usr/bin/env bash
# Mesh peer helpers. Everything resolves from KV - never hardcode a subject.
# Chat words (same thing, plain names):
#   chat <to> <message>  private message to one agent (same as send)
#   group <message>      message to everyone (work.<W>.all.<sender>)
#   inbox [me]           read your messages (same as drain)
#   contacts             who is here (same as peers)
# Technical names:
#   peers                the registry, with each pane's live/dead status
#   send <to> <message>  publish to <to>'s inbox, resolved from KV (not guessed)
#   drain [me]           replay work.<W>.<me>.> from the WORK stream
# Env: NATS (binary), MESH_WORK (default leya), MESH_ME (sender, default $USER)
set -euo pipefail
NATS="${NATS:-$(ls -1 "$HOME"/.cache/agent-mesh/nats-*/nats 2>/dev/null | head -1)}"
BUCKET="${MESH_BUCKET:-AGENT_STATE}"
W="${MESH_WORK:-leya}"
cmd="${1:-}"; shift 2>/dev/null || true

live_panes() {
  # `herdr pane list` with no --workspace is scoped unpredictably; walk every workspace.
  for ws in $(herdr workspace list 2>/dev/null | python3 -c 'import sys,json;print(" ".join(w["workspace_id"] for w in json.load(sys.stdin)["result"]["workspaces"]))' 2>/dev/null); do
    herdr pane list --workspace "$ws" 2>/dev/null | python3 -c 'import sys,json;print("\n".join(p["pane_id"] for p in json.load(sys.stdin)["result"]["panes"]))' 2>/dev/null || true
  done
}

case "$cmd" in
  contacts|peers)
    live=$(live_panes)
    for k in $("$NATS" kv ls "$BUCKET" | grep '^mesh\.members\.'); do
      name=${k#mesh.members.}; rec=$("$NATS" kv get "$BUCKET" "$k" --raw)
      pane=$(printf '%s' "$rec" | sed -n 's/.*"pane":"\([^"]*\)".*/\1/p')
      state=dead; [ -n "$pane" ] && printf '%s\n' "$live" | grep -qx "$pane" && state=live
      printf '%-24s pane=%-9s %s\n' "$name" "${pane:--}" "$state"
    done
    ;;
  chat|send)
    to="${1:?usage: mesh-peer.sh send <to> <message>}"; msg="${2:?}"
    rec=$("$NATS" kv get "$BUCKET" "mesh.members.$to" --raw)
    inbox=$(printf '%s' "$rec" | sed -n 's/.*"subject":"\([^"]*\)".*/\1/p')
    [ -n "$inbox" ] || inbox=$(printf '%s' "$rec" | sed -n 's/.*"inbox":"\([^"]*\)".*/\1/p')
    [ -n "$inbox" ] || { echo "no inbox for '$to' in KV" >&2; exit 1; }
    "$NATS" pub "work.$W.$to.${MESH_ME:-$USER}" "$msg"
    ;;
  drain|inbox) me="${1:-${MESH_ME:-$USER}}"; "$NATS" sub "work.$W.$me.>" --all --stream WORK ;;
  group) msg="${1:?usage: mesh-peer.sh group <message>}"; "$NATS" pub "work.$W.all.${MESH_ME:-$USER}" "$msg" ;;
  *) echo "usage: mesh-peer.sh {chat <to> <msg>|group <msg>|inbox [me]|contacts}" >&2; exit 2;;
esac
