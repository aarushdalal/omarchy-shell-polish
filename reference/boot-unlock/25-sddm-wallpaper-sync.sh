#!/usr/bin/env bash
# ==============================================================================
# 25-sddm-wallpaper-sync.sh: 100% Automated Zero-Prompt Sync for SDDM & Plymouth
# ==============================================================================
set -euo pipefail

CURRENT_BG="${1:-${OMARCHY_CURRENT_BACKGROUND:-$HOME/.local/state/omarchy/current/background}}"
DEST_DIR="/var/cache/multienv"
DEST_FILE="$DEST_DIR/background.png"

# 1. Update MultiEnv SDDM Wallpaper (Instant, Zero Sudo)
if [[ -f "$CURRENT_BG" && -d "$DEST_DIR" ]]; then
  cp -L "$CURRENT_BG" "$DEST_FILE"
  chmod 644 "$DEST_FILE"
fi

# 2. Trigger Plymouth Background Rebuild with Desktop Notifications
if [[ -x "/usr/local/bin/omarchy-plymouth-sync" ]]; then
  (
    if command -v notify-send >/dev/null 2>&1; then
      notify-send -a "Omarchy Sync" -i preferences-desktop-wallpaper \
        -h string:x-canonical-private-synchronous:boot-sync \
        -u low "Syncing Boot & Login Screens" "Updating SDDM greeter & Encrypted Disk unlock backgrounds..."
    fi

    if sudo -n /usr/local/bin/omarchy-plymouth-sync >/dev/null 2>&1; then
      if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Omarchy Sync" -i preferences-desktop-wallpaper \
          -h string:x-canonical-private-synchronous:boot-sync \
          -u low "Sync Complete" "Encrypted disk unlock & login greeter updated with active theme."
      fi
    fi
  ) >/dev/null 2>&1 &
fi
