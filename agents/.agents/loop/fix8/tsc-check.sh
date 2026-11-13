#!/bin/sh
# FIX-8: the committed form of the `tsc --strict` claim. The extension imports
# `@earendil-works/pi-coding-agent`, which is installed globally, so the type
# entry is resolved through `paths` in tsconfig.check.json instead of node_modules.
# Rerun: sh ~/.agents/loop/fix8/tsc-check.sh
set -e
cd "$(dirname "$0")"
exec tsc -p tsconfig.check.json
