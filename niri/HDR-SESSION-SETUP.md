# niri + HDR setup (niri-HDR fork session)

Hybrid laptop: Intel Alder Lake iGPU (drives panel) + NVIDIA RTX 3050 Mobile (idle).
Panel: Samsung ATNA56YX03-0 (SDC4161), 15.6" FHD 1920x1080@60 OLED, 10-bit, DCI-P3,
~390 nits SDR / 617 nits HDR peak, no VRR. EDID honest — ignore any old configs
claiming 2560x1600@240.

## What this is

Community niri HDR fork (dividebysandwich/niri + paired smithay ds-hdr-master,
cloned at ../smithay relative to the fork repo) as a **separate login session**.
Stock niri 26.04 (no HDR support) stays untouched as the default session.

Fork repo here: ~/project/niri-hdr (singular "project").

## Files (mirrored here under niri/)

| Live path | Purpose |
|---|---|
| .config/niri/config-hdr.kdl | fork config: eDP-1, max-bpc 10, hdr mode="on" |
| .config/niri/config.kdl | stock niri config (no hdr/max-bpc nodes — must stay clean) |
| .config/niri/dms/*.kdl | shared DMS includes |
| .config/systemd/user/niri-hdr.service | user unit, Type=notify, --session + config-hdr.kdl |
| .local/bin/niri-hdr-session | wrapper: import env, start unit, wait, shutdown target |
| .local/bin/toggle-hdr | flips hdr block via `/-` comment, notify-send with state |
| .local/share/wayland-sessions/niri-hdr.desktop | greeter session entry |

System-wide copy required (greeter runs as `greeter` user, cannot see $HOME):
`sudo cp .local/share/wayland-sessions/niri-hdr.desktop /usr/share/wayland-sessions/`

## Session flow

greetd → dms-greeter (session picker: Niri-HDR) → niri-hdr-session →
systemd user unit → fork niri --session → graphical-session.target →
dms.service (DankMaterialShell) auto-starts. Same shell UX as stock session.

## Toggle

Mod+Alt+B in config-hdr.kdl. Each flip = one brief screen blank (panel
re-negotiates PQ signalling — normal). Notification shows resulting state.
In HDR mode the panel ignores intel_backlight writes (by design, PQ hands
brightness to content); brightness keys work again once HDR toggled off.

## Verify HDR active

modetest -M i915 -c | check eDP-1 section:
- Colorspace: value 9 (BT2020_RGB)
- HDR_OUTPUT_METADATA blob populated (eotf 02 = PQ/ST2084)

Or journal: `updated HDR signalling to match content connector="eDP-1" hdr=true`

## Gotchas learned

- Config keys kebab-case (`max-bpc`), validate with fork's own
  `niri validate -c <file>` — use the FORK binary for config-hdr.kdl
- Fork never runs nested inside another compositor (parent owns the display);
  launch from greeter session or TTY
- dms-greeter reads /usr/share/wayland-sessions AND $HOME/.local/share/... of
  the GREETER user (not yours) — hence the sudo copy
- Cargo [patch] uses ../smithay relative path — fork and smithay-hdr clones
  must stay siblings; both moved together to ~/project/ on 2026-09-02
