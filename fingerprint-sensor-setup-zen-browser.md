# Bitwarden Browser Extension Fails to Connect in Zen Browser (Arch Linux)

> **Status 2026-08-22:** healthy. Manifest points at `.bitwarden_desktop_proxy`, proxy binary +
> `.app.bw.socket` present, Bitwarden desktop running. No action needed unless extension unlock
> breaks again — then recheck the manifest per "If It Breaks Again" below.

## Symptom

- Bitwarden desktop app is installed (AUR `bitwarden-bin`) and running.
- Bitwarden browser extension in [Zen Browser](https://zen-browser.app/) reports the desktop app is closed / unreachable, even though it's open and unlocked.
- Biometric/fingerprint unlock in the extension doesn't work as a result (it depends on the native messaging connection to the desktop app).

## Root Cause

Native messaging manifests are how Firefox-based browsers discover desktop apps like Bitwarden. There are two separate problems stacking here:

1. **`bitwarden-bin` never wrote a native messaging manifest at all** — nothing existed under any `NativeMessagingHosts` directory. This can happen even with "Allow browser integration" toggled on in the desktop app settings.
2. **Zen Browser has a known bug**: it only checks `~/.mozilla/native-messaging-hosts/`, not `~/.zen/native-messaging-hosts/`, even though `~/.zen` is where Zen actually stores its own profile data. Confirmed upstream: [zen-browser/desktop#10622](https://github.com/zen-browser/desktop/issues/10622).

So even if Bitwarden had written a manifest to a Zen-specific path, Zen wouldn't have found it.

## Diagnosis Commands

```bash
# Check if any manifest exists anywhere
find ~/.config -iname "com.8bit.bitwarden.json" -exec echo {} \; -exec cat {} \;

# Confirm Bitwarden desktop app is actually running
pgrep -af bitwarden

# Confirm not a Flatpak sandboxing issue (N/A if using AUR package)
flatpak list | grep -i bitwarden
```

## Fix

Manually create the native messaging manifest at the path Zen actually reads (`~/.mozilla/native-messaging-hosts/`), pointing at the AUR-installed Bitwarden binary:

```bash
mkdir -p ~/.mozilla/native-messaging-hosts

cat > ~/.mozilla/native-messaging-hosts/com.8bit.bitwarden.json << 'EOF'
{
  "name": "com.8bit.bitwarden",
  "description": "Bitwarden desktop <-> browser bridge",
  "path": "/home/prm/.mozilla/native-messaging-hosts/.bitwarden_desktop_proxy",
  "type": "stdio",
  "allowed_extensions": ["{446900e4-71c2-419f-a6a7-df9c091e268b}"]
}
EOF
```

Notes on the fields:
- `path` — newer Bitwarden desktop versions ship a dedicated native-messaging proxy binary
  (`.bitwarden_desktop_proxy`) that it drops into `~/.mozilla/native-messaging-hosts/` itself,
  next to its `.app.bw.socket` unix socket. Point the manifest at **the proxy**, not
  `/opt/Bitwarden/bitwarden-app`. Verify it exists and is executable:
  `ls -la ~/.mozilla/native-messaging-hosts/`
- Verified working 2026-08-22: manifest + proxy + socket all present, Bitwarden running.
- `allowed_extensions` — official Bitwarden Firefox extension ID (`{446900e4-71c2-419f-a6a7-df9c091e268b}`). Works for Zen since it's Gecko-based and uses the same extension ID.

Then fully restart both apps:

```bash
pkill -f bitwarden-app
pkill -f zen
```

Relaunch Bitwarden desktop first, unlock it, then launch Zen and retry the extension unlock.

## If It Breaks Again After a Zen or Bitwarden Update

This manifest is a manual file, not tracked/managed by either package. It can be silently wiped or ignored if:
- Bitwarden's own updater tries to "fix" browser integration and overwrites/removes it.
- Zen changes its native messaging lookup behavior (the underlying bug may get patched, which could mean `~/.zen/native-messaging-hosts/` becomes the correct path instead).

**Quick recheck:**
```bash
cat ~/.mozilla/native-messaging-hosts/com.8bit.bitwarden.json
```
If missing, just recreate it with the commands above.

## Dotfiles Automation Idea

Since this is a manual file outside package management, consider stowing/symlinking it from the dotfiles repo instead of leaving it as a one-off local file:

```bash
ln -sf ~/dotfiles/zen/com.8bit.bitwarden.json ~/.mozilla/native-messaging-hosts/com.8bit.bitwarden.json
```

That way a fresh Arch install / `stow` run restores this automatically instead of re-diagnosing it from scratch.

## References

- Zen native-messaging-hosts path bug: https://github.com/zen-browser/desktop/issues/10622
- Bitwarden extension native messaging errors (macOS variant of same class of bug): https://github.com/zen-browser/desktop/issues/13214
- Chrome/Firefox native messaging host spec (background reading): https://developer.chrome.com/docs/apps/nativeMessaging
