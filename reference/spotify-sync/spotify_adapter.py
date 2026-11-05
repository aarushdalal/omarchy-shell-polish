"""Spotify Live Theme Synchronization Adapter for Omarchy & DaemonOS.

Translates the active system theme and semantic palette into Spotify's Spicetify
runtime variables and dispatches live updates to the local bridge.
"""

import json
import os
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

try:
    from .base import BaseAdapter
except (ImportError, ValueError):
    try:
        from base import BaseAdapter
    except ImportError:
        class BaseAdapter:  # type: ignore
            name = "base"
            def __init__(self, app_id=None, app_cfg=None):
                self.app_id = app_id
                self.app_cfg = app_cfg or {}
            def sync(self, theme) -> bool:
                return True

BRIDGE_URL = "http://127.0.0.1:8974"
STATE_DIR = Path.home() / ".local" / "state" / "omarchy"
CAELESTIA_STATE_DIR = Path.home() / ".local" / "state" / "caelestia"
THEME_JSON_PATH = STATE_DIR / "spotify-theme.json"
CAELESTIA_THEME_JSON_PATH = CAELESTIA_STATE_DIR / "spotify-theme.json"


def hex_to_rgb(hex_str: str) -> Tuple[int, int, int]:
    s = hex_str.lstrip("#")
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    if len(s) >= 6:
        return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)
    return (0, 0, 0)


def hex_to_rgb_str(hex_str: str) -> str:
    r, g, b = hex_to_rgb(hex_str)
    return f"{r}, {g}, {b}"


def detect_desktop() -> str:
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    if "DaemonOs" in desktop:
        return "DaemonOS"
    try:
        out = subprocess.check_output(["pgrep", "-x", "Hyprland"], text=True, stderr=subprocess.DEVNULL).strip().splitlines()
        if out:
            pid = out[0]
            cmd = Path(f"/proc/{pid}/cmdline").read_bytes().decode("utf-8", "ignore")
            if "daemon-os/hyprland.lua" in cmd:
                return "DaemonOS"
    except Exception:
        pass
    return "Omarchy"


class SpotifyAdapter(BaseAdapter):
    """Adapter for live Spotify theme synchronization."""

    def __init__(self, app_id: str, app_cfg: Dict[str, Any]):
        super().__init__(app_id, app_cfg)
        self.binary_path = Path(app_cfg.get("binaryPath", "/opt/spotify/spotify"))
        self.bridge_url = app_cfg.get("bridgeUrl", BRIDGE_URL)

    def is_available(self) -> bool:
        return self.binary_path.exists()

    def apply_theme(self, theme_data: Dict[str, Any], global_config: Dict[str, Any]) -> Tuple[bool, str]:
        desktop = detect_desktop()
        theme_name = theme_data.get("name", "Unknown")
        is_dark = theme_data.get("is_dark", True)
        semantic = theme_data.get("semantic", {})

        bg = semantic.get("background", "#000000")
        fg = semantic.get("foreground", "#d7d7d7")
        accent = semantic.get("accent", "#7d7d7d")

        # In DaemonOS, verify against Caelestia scheme if present
        if desktop == "DaemonOS":
            caelestia_scheme = CAELESTIA_STATE_DIR / "scheme.json"
            if caelestia_scheme.is_file():
                try:
                    cdata = json.loads(caelestia_scheme.read_text(encoding="utf-8"))
                    colours = cdata.get("colours", {})
                    if "background" in colours:
                        bg = f"#{colours['background']}"
                    if "onSurface" in colours:
                        fg = f"#{colours['onSurface']}"
                    if "primary" in colours:
                        accent = f"#{colours['primary']}"
                    if "name" in cdata:
                        theme_name = f"Caelestia {cdata['name'].capitalize()}"
                except Exception:
                    pass

        # Build normalized semantic palette conforming to Near-OLED-black specification
        bg_primary = bg if bg.startswith("#") else f"#{bg}"
        fg_primary = fg if fg.startswith("#") else f"#{fg}"
        acc_primary = accent if accent.startswith("#") else f"#{accent}"

        # Refined surfaces
        bg_secondary = "#0a0a0a" if bg_primary in ["#000000", "#090909", "#050505"] else bg_primary
        bg_elevated = "#141414"
        bg_hover = "#1c1c1c"
        bg_selected = "#222222"
        border_subtle = semantic.get("border", "#1a1a1a")
        if not border_subtle.startswith("#"):
            border_subtle = f"#{border_subtle}"
        card_bg = "#111111"
        player_bg = "#070707"
        sidebar_bg = "#000000"

        fg_subdued = semantic.get("foregroundDark", "#8f8f8f")
        fg_muted = semantic.get("foregroundMuted", "#666666")

        spice_vars = {
            "text": fg_primary,
            "subtext": fg_subdued,
            "main": bg_secondary,
            "main-elevated": bg_elevated,
            "highlight": bg_hover,
            "highlight-elevated": bg_selected,
            "sidebar": sidebar_bg,
            "player": player_bg,
            "card": card_bg,
            "shadow": "#000000",
            "selected-row": bg_selected,
            "button": acc_primary,
            "button-active": acc_primary,
            "button-disabled": "#333333",
            "tab-active": bg_elevated,
            "notification": acc_primary,
            "notification-error": "#e24c4b",
            "misc": bg_elevated,
        }

        spice_rgb = {k: hex_to_rgb_str(v) for k, v in spice_vars.items()}

        palette = {
            "name": theme_name,
            "is_dark": is_dark,
            "desktop": desktop,
            "timestamp": int(time.time()),
            "colors": {
                "backgroundPrimary": bg_primary,
                "backgroundSecondary": bg_secondary,
                "backgroundElevated": bg_elevated,
                "backgroundHover": bg_hover,
                "backgroundSelected": bg_selected,
                "foregroundPrimary": fg_primary,
                "foregroundSecondary": fg_subdued,
                "foregroundMuted": fg_muted,
                "accentPrimary": acc_primary,
                "accentHover": acc_primary,
                "borderSubtle": border_subtle,
                "controlsPrimary": acc_primary,
                "controlsDisabled": "#333333",
                "playerBackground": player_bg,
                "playerProgress": acc_primary,
                "playerVolume": acc_primary,
                "sidebarBackground": sidebar_bg,
                "cardBackground": card_bg,
            },
            "spicetify": {
                "vars": spice_vars,
                "rgb": spice_rgb,
            }
        }

        # 1. Save persistent state for cold starts
        try:
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            THEME_JSON_PATH.write_text(json.dumps(palette, indent=2), encoding="utf-8")
        except Exception:
            pass

        try:
            CAELESTIA_STATE_DIR.mkdir(parents=True, exist_ok=True)
            CAELESTIA_THEME_JSON_PATH.write_text(json.dumps(palette, indent=2), encoding="utf-8")
        except Exception:
            pass

        # 2. Update Spicetify color.ini for the active theme
        try:
            color_ini = Path.home() / ".config" / "spicetify" / "Themes" / "caelestia" / "color.ini"
            if color_ini.parent.is_dir():
                lines = ["[caelestia]"]
                for k, v in spice_vars.items():
                    clean_hex = v.lstrip("#")
                    lines.append(f"{k:<20}= {clean_hex}")
                color_ini.write_text("\n".join(lines) + "\n", encoding="utf-8")
        except Exception:
            pass

        # 3. Dispatch live update to the bridge
        bridge_notified = False
        notify_url = f"{self.bridge_url}/notify"
        try:
            req_data = json.dumps(palette).encode("utf-8")
            req = urllib.request.Request(
                notify_url,
                data=req_data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=1.2) as resp:
                if resp.status == 200:
                    bridge_notified = True
        except Exception:
            # If bridge service is not running, ensure user service is triggered
            try:
                subprocess.run(
                    ["systemctl", "--user", "start", "daemon-spotify-sync.service"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=2.0
                )
            except Exception:
                pass

        status_msg = f"Live Spotify palette updated: {theme_name} (bridge: {'connected' if bridge_notified else 'saved to disk'})"
        return True, status_msg
