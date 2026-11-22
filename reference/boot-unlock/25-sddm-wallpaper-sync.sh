#!/usr/bin/env bash
# ==============================================================================
# 25-sddm-wallpaper-sync.sh: Automated Zero-Prompt Sync for SDDM & Plymouth
# Synchronizes wallpaper, pre-blurred bokeh cache, and colors.toml palette
# ==============================================================================
set -euo pipefail

DEST_DIR="/var/cache/multienv"
DEST_FILE="$DEST_DIR/background.png"
DEST_BLURRED="$DEST_DIR/background_blurred.png"
DEST_COLORS_JS="$DEST_DIR/ThemeColors.js"
DEST_COLORS_JSON="$DEST_DIR/colors.json"
REPO_THEME_DIR="$HOME/Work/arch-multienv/sddm/themes/multienv-selector"
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

# Resolve colors.toml path:
COLORS_TOML=""
if [[ -f "$HOME/.local/state/omarchy/current/theme/colors.toml" ]]; then
  COLORS_TOML="$HOME/.local/state/omarchy/current/theme/colors.toml"
elif [[ -n "${1:-}" && -f "$HOME/.config/omarchy/themes/$1/colors.toml" ]]; then
  COLORS_TOML="$HOME/.config/omarchy/themes/$1/colors.toml"
fi

# 1. Update MultiEnv SDDM Wallpaper & Pre-blurred Cache (Instant, Zero Sudo)
if [[ -n "$CURRENT_BG" && -f "$CURRENT_BG" && -d "$DEST_DIR" ]]; then
  REAL_SRC="$(readlink -f "$CURRENT_BG" 2>/dev/null || echo "$CURRENT_BG")"
  REAL_DST="$(readlink -f "$DEST_FILE" 2>/dev/null || echo "$DEST_FILE")"
  if [[ "$REAL_SRC" != "$REAL_DST" ]]; then
    cp -L "$CURRENT_BG" "$DEST_FILE"
    chmod 644 "$DEST_FILE"
  fi

  if command -v magick >/dev/null 2>&1; then
    magick "$DEST_FILE" -resize 1920x1080^ -gravity center -extent 1920x1080 -blur 0x20 "$DEST_BLURRED"
    chmod 644 "$DEST_BLURRED"
  fi
fi

# 2. Synchronize Color Palette from colors.toml to ThemeColors.js & colors.json
if [[ -n "$COLORS_TOML" && -f "$COLORS_TOML" ]]; then
  python3 -c "
import tomllib, json, os

with open('$COLORS_TOML', 'rb') as f:
    c = tomllib.load(f)

palette = {
    'mode': c.get('mode', 'dark'),
    'accent': c.get('accent', '#38bdf8'),
    'accentHover': c.get('bright_blue', c.get('bright_cyan', '#60a5fa')),
    'foreground': c.get('foreground', c.get('fg', '#f1f5f9')),
    'secondary': c.get('dark_fg', '#94a3b8'),
    'muted': c.get('muted', '#64748b'),
    'background': c.get('background', c.get('bg', '#08090d')),
    'lighterBg': c.get('lighter_bg', '#141824'),
    'cyan': c.get('cyan', '#38bdf8'),
    'blue': c.get('blue', '#60a5fa'),
    'red': c.get('red', '#f87171'),
    'green': c.get('green', '#4ade80'),
    'yellow': c.get('yellow', '#facc15')
}

js_content = f'''// Generated from active Omarchy theme colors.toml
.pragma library

var palette = {json.dumps(palette, indent=4)};
'''

for p in ['$DEST_COLORS_JS', '$REPO_THEME_DIR/ThemeColors.js']:
    try:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w') as f:
            f.write(js_content)
        os.chmod(p, 0o644)
    except Exception:
        pass

try:
    with open('$DEST_COLORS_JSON', 'w') as f:
        json.dump(palette, f, indent=2)
    os.chmod('$DEST_COLORS_JSON', 0o644)
except Exception:
    pass
" 2>/dev/null || true
fi

# 3. Trigger Plymouth Background Rebuild with Pure Vector Desktop Notifications
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
