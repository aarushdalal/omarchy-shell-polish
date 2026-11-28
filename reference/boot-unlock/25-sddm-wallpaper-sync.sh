#!/usr/bin/env bash
# ==============================================================================
# 25-sddm-wallpaper-sync.sh: Automated Zero-Prompt Sync for SDDM & Plymouth
# Synchronizes wallpaper, pre-blurred bokeh cache, colors.toml palette, and SVG logo
# ==============================================================================
set -euo pipefail

DEST_DIR="/var/cache/multienv"
DEST_FILE="$DEST_DIR/background.png"
DEST_BLURRED="$DEST_DIR/background_blurred.png"
DEST_COLORS_JS="$DEST_DIR/ThemeColors.js"
DEST_COLORS_JSON="$DEST_DIR/colors.json"
DEST_LOGO_SVG="$DEST_DIR/brand-logo.svg"
LOGO_TPL="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/boot-unlock/brand-logo.svg.tpl"
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

# 2. Synchronize Color Palette & SVG Brand Logo from colors.toml
if [[ -n "$COLORS_TOML" && -f "$COLORS_TOML" ]]; then
  python3 - "$COLORS_TOML" "$DEST_COLORS_JS" "$DEST_COLORS_JSON" "$LOGO_TPL" "$DEST_LOGO_SVG" <<'PY' 2>/dev/null || true
import json, os, sys, tomllib

toml_path, js_out, json_out, logo_tpl, logo_out = sys.argv[1:6]
with open(toml_path, "rb") as f:
    c = tomllib.load(f)

palette = {
    "mode": c.get("mode", "dark"),
    "accent": c.get("accent", "#38bdf8"),
    "accentHover": c.get("bright_blue", c.get("bright_cyan", "#60a5fa")),
    "foreground": c.get("foreground", c.get("fg", "#f1f5f9")),
    "secondary": c.get("dark_fg", "#94a3b8"),
    "muted": c.get("muted", "#64748b"),
    "background": c.get("background", c.get("bg", "#08090d")),
    "lighterBg": c.get("lighter_bg", "#141824"),
    "cyan": c.get("cyan", "#38bdf8"),
    "blue": c.get("blue", "#60a5fa"),
    "red": c.get("red", "#f87171"),
    "green": c.get("green", "#4ade80"),
    "yellow": c.get("yellow", "#facc15"),
}

js_content = f"// Generated from active Omarchy theme colors.toml\n.pragma library\n\nvar palette = {json.dumps(palette, indent=4)};\n"
os.makedirs(os.path.dirname(js_out), exist_ok=True)
with open(js_out, "w", encoding="utf-8") as f:
    f.write(js_content)
os.chmod(js_out, 0o644)

with open(json_out, "w", encoding="utf-8") as f:
    json.dump(palette, f, indent=2)
os.chmod(json_out, 0o644)

if os.path.isfile(logo_tpl):
    with open(logo_tpl, "r", encoding="utf-8") as f:
        svg = f.read().format(FG=palette["foreground"], ACCENT=palette["accent"])
    with open(logo_out, "w", encoding="utf-8") as f:
        f.write(svg)
    os.chmod(logo_out, 0o644)
PY
fi

# 3. Trigger Plymouth Background & Frosted Asset Rebuild with Desktop Notifications
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
