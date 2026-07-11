#!/usr/bin/env bash
# ── Overlay pane script ──────────────────────────────────────────
# Runs inside the floating overlay pane.
# tv takes over the pane (exec). When user picks, the channel action
# creates/focuses the workspace, herdr closes the overlay, tv dies.
#
# tv channel: ~/.config/television/cable/herdr-sesh.toml
#   Source + preview + workspace action (one-liner).
#   Channel action is the ONLY way — tv doesn't exit after execute,
#   so capturing $(tv ...) in a subshell would hang forever.
# ──────────────────────────────────────────────────────────────────
exec tv herdr-sesh
