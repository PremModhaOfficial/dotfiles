#!/usr/bin/env bash
# ── Action script (invoked by prefix+o) ─────────────────────────
# This runs when the user presses prefix+o.
# It opens the overlay pane that runs pane.sh.
#
# Keybinding in config.toml:
#   [[keys.command]]
#   key = "prefix+o"
#   type = "plugin_action"
#   command = "herdr-sesh.open"
#
# Why an action script? Because overlay panes can only be opened
# programmatically (herdr plugin pane open), not directly from a
# [[keys.command]] keybinding with type = "pane".
#
# Connected: herdr-plugin.toml → defines the "picker" pane entrypoint
#            pane.sh           → runs tv in the overlay pane
# ──────────────────────────────────────────────────────────────────
set -eo pipefail
exec herdr plugin pane open --plugin herdr-sesh --entrypoint picker
