# paru-fish-debug final report (2026-09-02)

## Root cause
NOT paru. Carapace's yay completer misparses `yay -Ss` output when a package
description contains slashes. Package `wob` (extra) description:
"A lightweight overlay volume/backlight/progress/anything bar for Wayland"
produces bogus candidate `backlight/progress/anything` with desc
`extra/python-pyaml 26.7.0-1 ...`. For query "ba" it is the single returned
candidate, so fish auto-inserts it on TAB. Carapace bridge (config.fish
`carapace _carapace | source`) erases vendor yay.fish completions first.

## Evidence
- pacman -Ql paru: only /usr/share/fish/vendor_completions.d/paru.fish + bin
- diff baseline/yay-completions-before.txt yay-completions-after.txt: EMPTY
- shim log: carapace calls `yay -Ss ba`; weird string exists only in wob desc
- vendor yay.fish standalone: correct AUR results
- "maximum recursion depth" error: NOT reproduced (ruled out)
- function collision yay.fish/paru.fish: NONE (no function defs in either)

## Fix
~/.config/fish/config.fish after carapace line:
  complete -e -c yay
  source /usr/share/fish/vendor_completions.d/yay.fish

## Verification
- yay -S ba<TAB>: proper AUR menu, 2 fresh fish sessions (herdr panes)
- paru -S ba<TAB>: still works (carapace spec)

## Rollback anchor
Snapper snapshot 28 (pre-paru): sudo snapper -c root rollback 28
Post-fix snapshot: sudo snapper -c root create --description "post-paru-fish-fixed-$(date +%Y%m%d-%H%M)"

## How to recreate the bug (lab reproduction)
1. Fresh state WITHOUT the config.fish override (stash the fix).
2. In fish, run: `yay -Ss ba` — note wob entry and its slash-heavy description.
3. Run: `carapace yay fish yay -S ba` — outputs single bogus candidate
   `backlight/progress/anything<TAB>extra/python-pyaml 26.7.0-1 (...)`.
4. In real fish TAB `yay -S ba`: garbage auto-inserted (single candidate).
   Any query where "ba" matches wob's description word "bar" reproduces.
   Upstream suspected package: github.com/carapace-sh/carapace-bin
   (yay_completer, `-Ss` output parser).

## How to refix
In ~/.config/fish/config.fish, directly after `carapace _carapace | source`:
```fish
complete -e -c yay
source /usr/share/fish/vendor_completions.d/yay.fish
```
This drops carapace's broken yay completer and restores the upstream
pacman-style vendor file. paru keeps carapace completions (its spec is fine).

## Debug one-liners
- What carapace actually runs: shim trick —
  `mkdir -p /tmp/shim; printf '#!/bin/sh\necho "CALL %s $*" >> /tmp/shim/calls.log\nexec /usr/bin/yay "$@"\n' > /tmp/shim/yay; chmod +x /tmp/shim/yay; PATH=/tmp/shim:$PATH carapace yay fish yay -S ba; cat /tmp/shim/calls.log`
- Vendor completions sanity: `fish -c 'complete -e -c yay; source /usr/share/fish/vendor_completions.d/yay.fish; complete -C "yay -S ba" | head'`
- Pre/Post diff: `fish -c "complete -c yay" > before; <after change> fish -c "complete -c yay" > after; diff before after`

## Snapshot trail
- 28: pre-paru-fish-debug-20260902-1405 (rollback anchor)
- 29/30: snapper pre/post for paru install
- post-fix snapshot created 2026-09-02
