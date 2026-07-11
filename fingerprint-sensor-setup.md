# Fingerprint Sensor Setup — ASUS Vivobook K6500ZC

## System Info
- **Machine:** ASUS Vivobook K6500ZC (`Vivobook_ASUSLaptop K6500ZC_K6500ZC`)
- **OS:** Arch Linux (rolling)
- **Kernel:** 6.14-zen
- **Display:** Wayland (niri 26.04)

## Fingerprint Hardware
- **Sensor:** FocalTech FT9366 (Realtek USB2.0 Finger Print Bridge)
- **USB ID:** `2808:a658`
- **Bus:** USB 3-8 (no driver bound — shows `DRIVER=usb` only, no functional driver)
- **Status:** Detected by kernel, no driver loaded

## Driver Options

### Option A: github.com/leopalladium/focaltech-ft9366-arch-shim (recommended)
A proxy-shim that makes the proprietary driver work on modern libgusb.
Repo: https://github.com/leopalladium/focaltech-ft9366-arch-shim

**Steps:**
1. Install deps: `sudo pacman -S fprintd libfprint gcc pkgconf libgusb patchelf`
2. Clone repo, compile shim (`gcc -shared -fPIC -Wl,--version-script=shim.map -o focaltech-shim.so shim.c $(pkg-config --cflags --libs glib-2.0) -ldl`)
3. Copy driver + shim to `/usr/lib/`
4. `patchelf --add-needed focaltech-shim.so /usr/lib/libfprint-2.so.2.0.0`
5. Install udev rules for USB access
6. Create udev rule to disable USB autosuspend for the sensor
7. `sudo systemctl restart fprintd`
8. Enroll: `fprintd-enroll`
9. Add `auth sufficient pam_fprintd.so` to `/etc/pam.d/system-auth`

### Option B: AUR package `libfprint-ft9366`
- Was available on AUR but DMCA'd (sources removed Oct 2025).
- Do not rely on this.

### Option C: github.com/bro2020/fprint-focaltech
- Alternative repo with similar approach (Debian/Ubuntu focused).
- https://github.com/bro2020/fprint-focaltech

## Key Caveats
- **Proprietary driver** — no open-source alternative exists for this sensor.
- **USB Autosuspend** is the #1 gotcha — sensor appears dead if kernel suspends it. Fix: udev rule setting `power/control=on`.
- **fprintd must be restarted** after driver install.
- First `fprintd-enroll` may fail — keep finger pressed before and during command to wake sensor.

## PAM Integration (fingerprint-first with timeout)
Place before `pam_unix.so` in `/etc/pam.d/system-auth`:
```
auth       sufficient                    pam_fprintd.so      timeout=5
```
- `timeout=5` prevents 30s hang when sensor is unresponsive
- Placed after `#%PAM-1.0` header, BEFORE `pam_faillock.so preauth`
- If sensor flakes, falls through to password after 5s
- `sudo sed -i '/^#%PAM-1.0$/a auth       sufficient                    pam_fprintd.so      timeout=5' /etc/pam.d/system-auth`

## Post-Suspend Fix (sensor dies after resume)
Kill fprintd before sleep so systemd socket-activates a fresh instance after resume.

**`/etc/systemd/system/kill-fprintd.service`:**
```ini
[Unit]
Description=Kill fprintd before sleep
Before=sleep.target

[Service]
Type=oneshot
ExecStart=/usr/bin/killall -q fprintd

[Install]
WantedBy=sleep.target
```
Enable: `sudo systemctl enable --now kill-fprintd.service`

Also applied USB autosuspend udev rule at `/etc/udev/rules.d/80-focaltech-fix.rules`:
```
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2808", ATTR{idProduct}=="a658", ATTR{power/control}="on", ATTR{power/autosuspend}="-1"
```

## References
- https://github.com/leopalladium/focaltech-ft9366-arch-shim
- https://github.com/bro2020/fprint-focaltech
- https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/413
- https://linux-hardware.org/?id=usb%3A2808-a658
