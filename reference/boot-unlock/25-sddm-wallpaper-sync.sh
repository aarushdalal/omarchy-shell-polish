#!/usr/bin/env bash
# ==============================================================================
# 25-sddm-wallpaper-sync.sh: Automated Zero-Prompt Sync for SDDM & Plymouth
# ==============================================================================
set -euo pipefail

DEST_DIR="/var/cache/multienv"
DEST_FILE="$DEST_DIR/background.png"
SYNC_ICON="$HOME/.local/share/icons/omarchy-sync.svg"

# Resolve the actual current background image path:
CURRENT_BG=""
if [[ -n "${1:-}" && -f "$1" ]]; then
  CURRENT_BG="$1"
elif [[ -n "${OMARCHY_CURRENT_BACKGROUND:-}" && -f "$OMARCHY_CURRENT_BACKGROUND" ]]; then
  CURRENT_BG="$OMARCHY_CURRENT_BACKGROUND"
elif [[ -f "$HOME/.local/state/omarchy/current/background" ]]; then
  CURRENT_BG="$HOME/.local/state/omarchy/current/background"
fi

# 1. Update MultiEnv SDDM Wallpaper (Instant, Zero Sudo)
if [[ -n "$CURRENT_BG" && -f "$CURRENT_BG" && -d "$DEST_DIR" ]]; then
  REAL_SRC="$(readlink -f "$CURRENT_BG" 2>/dev/null || echo "$CURRENT_BG")"
  REAL_DST="$(readlink -f "$DEST_FILE" 2>/dev/null || echo "$DEST_FILE")"
  if [[ "$REAL_SRC" != "$REAL_DST" ]]; then
    cp -L "$CURRENT_BG" "$DEST_FILE"
    chmod 644 "$DEST_FILE"
  fi
fi

# 2. Trigger Plymouth Background Rebuild with Pure Vector Desktop Notifications
if [[ -x "/usr/local/bin/omarchy-plymouth-sync" ]]; then
  (
    ICON_ARG=()
    if [[ -f "$SYNC_ICON" ]]; then
      ICON_ARG=(-i "$SYNC_ICON")
    fi

    if command -v notify-send >/dev/null 2>&1; then
      notify-send -a "Omarchy Sync" "${ICON_ARG[@]}" \
        -h string:x-canonical-private-synchronous:boot-sync \
        -u low "Syncing Boot and Login Screens" "Updating SDDM greeter and Encrypted Disk unlock backgrounds..."
    fi

    if sudo -n /usr/local/bin/omarchy-plymouth-sync >/dev/null 2>&1; then
      if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Omarchy Sync" "${ICON_ARG[@]}" \
          -h string:x-canonical-private-synchronous:boot-sync \
          -u low "Sync Complete" "Encrypted disk unlock and login greeter updated with active theme."
      fi
    fi
  ) >/dev/null 2>&1 &
fi
