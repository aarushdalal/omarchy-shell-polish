# Universal glass monitor

A background-only automation service for the current and future desktop application inventory. It checks visible desktop entries (including Flatpak exports), plus Hyprland window classes, every 20 seconds. It never opens, focuses, closes or restarts an app and never fades a whole window.

Supported native recipes cover Foot, Ghostty, Kitty, Alacritty, Files/Nautilus and compatible Screensaver Studio builds. Existing alpha below 1.0 is retained, so custom transparency is preserved. Missing/opaque supported settings are updated with private recovery copies. A new Foot window loads its alpha. Other app recipes may need reopening at a convenient time.

Spotify, ChatGPT and AntiGravity use the separately installed, guarded native recipes. The monitor checks installed source layouts/build IDs and reports incompatible updates. It does not inject arbitrary new apps or bypass native package/security checks. All IDEs are included in the inventory; IDEs without a background-only recipe are notified like other unsupported apps. No pet integration is installed.

Apps without a known native background recipe are reported as needs-theme. The initial inventory uses one summary notification; each new unsupported identity is notified once, with status remembered privately. Unsupported apps may already implement some transparency; the status means this tool cannot configure/verify their backgrounds, not that it has measured opaque pixels. Ask for a theme patch for a named app when needed.

## Install (opt-in)

```sh
install -Dm644 daemon-glass.py "$HOME/.config/omarchy/glass-apps/universal-glass.py"
install -Dm644 recipes/nautilus-glass.css "$HOME/.config/omarchy/glass-apps/recipes/nautilus-glass.css"
if [ ! -e "$HOME/.config/omarchy/glass-apps/universal-glass.json" ]; then
  install -Dm644 universal-glass.example.json "$HOME/.config/omarchy/glass-apps/universal-glass.json"
fi
mkdir -p "$HOME/.local/bin"
printf '%s\n' '#!/bin/sh' 'exec /usr/bin/python3 "$HOME/.config/omarchy/glass-apps/universal-glass.py" "$@"' > "$HOME/.local/bin/daemon-glass"
chmod +x "$HOME/.local/bin/daemon-glass"
install -Dm644 daemon-glass.service "$HOME/.config/systemd/user/daemon-glass.service"
systemctl --user daemon-reload
systemctl --user enable --now daemon-glass.service
```

First merge the shared gentle compositor reference into the intended Hyprland profiles. Its blur and 100% content opacity apply to all app windows; native background recipes make that blur visible. Source recipes are version-specific, and opaque custom renderer surfaces still require their own theme support.

Use `daemon-glass scan` for a dry run, `daemon-glass scan --apply --notify` for a single applied scan, and `daemon-glass status` for the inventory. `--json` emits machine-readable status. State/notification history and recovery copies stay under `~/.local/state/omarchy/glass-monitor/` with private permissions; do not commit them. Local settings in `~/.config/omarchy/glass-apps/universal-glass.json` accept an `ignored_apps` list of shell-style application-ID patterns. Stop automatic changes/notifications with `systemctl --user disable --now daemon-glass.service`.

The unit starts/stops with the graphical session and uses low scheduling priority. Recipe status is configuration evidence, not visual acceptance of every application. Notification delivery requires the desktop notification service and retries if delivery fails. Offline tests cover settings preservation, dry runs, unsupported/excluded apps, backups, notification batching and duplicate suppression.
