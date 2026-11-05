#!/usr/bin/env python3
"""Daemon Spotify Sync Bridge Daemon.

Provides a lightweight, zero-dependency localhost event bridge between
Omarchy / DaemonOS theme synchronizers and Spotify's Spicetify runtime extension.
Supports real-time SSE theme distribution and high-performance wallpaper streaming.
"""

import asyncio
import json
import os
import signal
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional, Set

DEFAULT_PORT = 8974
HOST = "127.0.0.1"

STATE_DIR = Path.home() / ".local" / "state" / "omarchy"
CAELESTIA_STATE_DIR = Path.home() / ".local" / "state" / "caelestia"
THEME_JSON_PATH = STATE_DIR / "spotify-theme.json"
CAELESTIA_THEME_JSON_PATH = CAELESTIA_STATE_DIR / "spotify-theme.json"


def hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
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
        import subprocess
        out = subprocess.check_output(["pgrep", "-x", "Hyprland"], text=True, stderr=subprocess.DEVNULL).strip().splitlines()
        if out:
            pid = out[0]
            cmd = Path(f"/proc/{pid}/cmdline").read_bytes().decode("utf-8", "ignore")
            if "daemon-os/hyprland.lua" in cmd:
                return "DaemonOS"
    except Exception:
        pass
    return "Omarchy"


def get_current_wallpaper_path(desktop: str = "Omarchy") -> Optional[Path]:
    """Retrieve absolute path to current desktop wallpaper."""
    if desktop == "DaemonOS":
        p = CAELESTIA_STATE_DIR / "wallpaper" / "current"
        if p.exists():
            return p.resolve()
        p_txt = CAELESTIA_STATE_DIR / "wallpaper" / "path.txt"
        if p_txt.is_file():
            target = Path(p_txt.read_text(encoding="utf-8").strip())
            if target.is_file():
                return target

    p = STATE_DIR / "current" / "background"
    if p.exists():
        return p.resolve()
    return None


def get_default_palette() -> Dict[str, Any]:
    """Derive palette from current Omarchy or DaemonOS state."""
    desktop = detect_desktop()
    name = "Default Dark"
    is_dark = True
    bg = "#000000"
    fg = "#d7d7d7"
    accent = "#7d7d7d"

    omarchy_colors = STATE_DIR / "current" / "theme" / "colors.toml"
    omarchy_name_file = STATE_DIR / "current" / "theme.name"

    if omarchy_name_file.is_file():
        slug = omarchy_name_file.read_text(encoding="utf-8").strip()
        if slug:
            name = " ".join(word.capitalize() for word in slug.replace("_", "-").split("-"))

    if omarchy_colors.is_file():
        try:
            for line in omarchy_colors.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip().strip("\"'").strip()
                    if k == "background":
                        bg = v
                    elif k == "foreground":
                        fg = v
                    elif k == "accent":
                        accent = v
                    elif k == "mode":
                        is_dark = v.lower() != "light"
        except Exception:
            pass

    caelestia_scheme = CAELESTIA_STATE_DIR / "scheme.json"
    if desktop == "DaemonOS" and caelestia_scheme.is_file():
        try:
            data = json.loads(caelestia_scheme.read_text(encoding="utf-8"))
            colours = data.get("colours", {})
            if "background" in colours:
                bg = f"#{colours['background']}"
            if "onSurface" in colours:
                fg = f"#{colours['onSurface']}"
            if "primary" in colours:
                accent = f"#{colours['primary']}"
            if "name" in data:
                name = f"Caelestia {data['name'].capitalize()}"
        except Exception:
            pass

    return build_semantic_palette(name, is_dark, bg, fg, accent, desktop)


def build_semantic_palette(name: str, is_dark: bool, bg: str, fg: str, accent: str, desktop: str) -> Dict[str, Any]:
    bg_primary = bg if bg.startswith("#") else f"#{bg}"
    fg_primary = fg if fg.startswith("#") else f"#{fg}"
    acc_primary = accent if accent.startswith("#") else f"#{accent}"

    bg_secondary = "#0a0a0a" if bg_primary in ["#000000", "#090909", "#050505"] else bg_primary
    bg_elevated = "#141414"
    bg_hover = "#1c1c1c"
    bg_selected = "#222222"
    border_subtle = "#1a1a1a"
    card_bg = "#111111"
    player_bg = "#070707"
    sidebar_bg = "#000000"

    fg_subdued = "#8f8f8f"
    fg_muted = "#666666"

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

    wall_path = get_current_wallpaper_path(desktop)
    wall_mtime = int(wall_path.stat().st_mtime) if (wall_path and wall_path.is_file()) else int(time.time())
    wallpaper_url = f"http://127.0.0.1:8974/wallpaper?t={wall_mtime}" if wall_path else None

    return {
        "name": name,
        "is_dark": is_dark,
        "desktop": desktop,
        "timestamp": int(time.time()),
        "wallpaperUrl": wallpaper_url,
        "hasWallpaper": bool(wall_path and wall_path.is_file()),
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


class BridgeServer:
    def __init__(self, host: str = HOST, port: int = DEFAULT_PORT):
        self.host = host
        self.port = port
        self.subscribers: Set[asyncio.StreamWriter] = set()
        self.current_palette: Dict[str, Any] = {}
        self.last_theme_mtime: float = 0
        self.last_wall_mtime: float = 0
        self.start_time = time.time()
        self.server: Optional[asyncio.Server] = None

    def load_cached_palette(self) -> Dict[str, Any]:
        if THEME_JSON_PATH.is_file():
            try:
                data = json.loads(THEME_JSON_PATH.read_text(encoding="utf-8"))
                if "spicetify" in data and "colors" in data:
                    self.last_theme_mtime = THEME_JSON_PATH.stat().st_mtime
                    desktop = detect_desktop()
                    wall = get_current_wallpaper_path(desktop)
                    if wall and wall.is_file():
                        self.last_wall_mtime = wall.stat().st_mtime
                        data["wallpaperUrl"] = f"http://127.0.0.1:8974/wallpaper?t={int(self.last_wall_mtime)}"
                        data["hasWallpaper"] = True
                    return data
            except Exception:
                pass
        palette = get_default_palette()
        self.save_palette(palette)
        return palette

    def save_palette(self, palette: Dict[str, Any]):
        try:
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            THEME_JSON_PATH.write_text(json.dumps(palette, indent=2), encoding="utf-8")
            self.last_theme_mtime = THEME_JSON_PATH.stat().st_mtime
        except Exception:
            pass
        try:
            CAELESTIA_STATE_DIR.mkdir(parents=True, exist_ok=True)
            CAELESTIA_THEME_JSON_PATH.write_text(json.dumps(palette, indent=2), encoding="utf-8")
        except Exception:
            pass

    async def broadcast_theme(self, palette: Dict[str, Any]):
        self.current_palette = palette
        self.save_palette(palette)
        payload = json.dumps(palette)
        msg = f"event: theme\ndata: {payload}\n\n".encode("utf-8")
        dead = []
        for writer in self.subscribers:
            try:
                writer.write(msg)
                await writer.drain()
            except Exception:
                dead.append(writer)
        for d in dead:
            self.subscribers.discard(d)

    async def file_watcher_loop(self):
        while True:
            await asyncio.sleep(0.5)
            try:
                desktop = detect_desktop()
                # 1. Check wallpaper change
                wall = get_current_wallpaper_path(desktop)
                if wall and wall.is_file():
                    wmtime = wall.stat().st_mtime
                    if wmtime > self.last_wall_mtime:
                        self.last_wall_mtime = wmtime
                        new_pal = get_default_palette()
                        await self.broadcast_theme(new_pal)
                        continue

                # 2. Check theme state change
                if THEME_JSON_PATH.is_file():
                    mtime = THEME_JSON_PATH.stat().st_mtime
                    if mtime > self.last_theme_mtime:
                        self.last_theme_mtime = mtime
                        data = json.loads(THEME_JSON_PATH.read_text(encoding="utf-8"))
                        if data.get("name") != self.current_palette.get("name") or data.get("timestamp") != self.current_palette.get("timestamp"):
                            self.current_palette = data
                            await self.broadcast_theme(data)
            except Exception:
                pass

    async def heartbeat_loop(self):
        while True:
            await asyncio.sleep(25)
            if not self.subscribers:
                continue
            ping = b": ping\n\n"
            dead = []
            for writer in self.subscribers:
                try:
                    writer.write(ping)
                    await writer.drain()
                except Exception:
                    dead.append(writer)
            for d in dead:
                self.subscribers.discard(d)

    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        try:
            line = await reader.readline()
            if not line:
                writer.close()
                await writer.wait_closed()
                return

            request_line = line.decode("utf-8", "ignore").strip()
            parts = request_line.split()
            if len(parts) < 2:
                writer.close()
                await writer.wait_closed()
                return

            method, path = parts[0].upper(), parts[1]

            headers = {}
            content_length = 0
            while True:
                hline = await reader.readline()
                if not hline or hline == b"\r\n" or hline == b"\n":
                    break
                hstr = hline.decode("utf-8", "ignore").strip()
                if ":" in hstr:
                    k, v = hstr.split(":", 1)
                    headers[k.strip().lower()] = v.strip()
                    if k.strip().lower() == "content-length":
                        try:
                            content_length = int(v.strip())
                        except ValueError:
                            content_length = 0

            cors_headers = (
                "Access-Control-Allow-Origin: *\r\n"
                "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
                "Access-Control-Allow-Headers: Content-Type, Authorization, *\r\n"
                "Access-Control-Allow-Private-Network: true\r\n"
            )

            if method == "OPTIONS":
                response = f"HTTP/1.1 204 No Content\r\n{cors_headers}Content-Length: 0\r\n\r\n"
                writer.write(response.encode("utf-8"))
                await writer.drain()
                writer.close()
                await writer.wait_closed()
                return

            # Serve current wallpaper
            if method in ["GET", "HEAD"] and path.startswith("/wallpaper"):
                desktop = detect_desktop()
                wall_path = get_current_wallpaper_path(desktop)
                if not wall_path or not wall_path.is_file():
                    writer.write(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
                    await writer.drain()
                    writer.close()
                    await writer.wait_closed()
                    return

                stat = wall_path.stat()
                etag = f'"{stat.st_mtime_ns}-{stat.st_size}"'
                if headers.get("if-none-match") == etag:
                    writer.write(b"HTTP/1.1 304 Not Modified\r\n\r\n")
                    await writer.drain()
                    writer.close()
                    await writer.wait_closed()
                    return

                suffix = wall_path.suffix.lower()
                mime = "image/png"
                if suffix in [".jpg", ".jpeg"]:
                    mime = "image/jpeg"
                elif suffix == ".webp":
                    mime = "image/webp"

                try:
                    content = wall_path.read_bytes()
                    headers_out = (
                        "HTTP/1.1 200 OK\r\n"
                        f"Content-Type: {mime}\r\n"
                        f"Content-Length: {len(content)}\r\n"
                        f"ETag: {etag}\r\n"
                        "Cache-Control: public, max-age=3600\r\n"
                        f"{cors_headers}\r\n"
                    )
                    writer.write(headers_out.encode("utf-8") + content)
                    await writer.drain()
                except Exception:
                    pass
                writer.close()
                await writer.wait_closed()
                return

            if method == "GET" and path.startswith("/events"):
                headers_out = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: text/event-stream\r\n"
                    "Cache-Control: no-cache, no-transform\r\n"
                    "Connection: keep-alive\r\n"
                    f"{cors_headers}\r\n"
                )
                writer.write(headers_out.encode("utf-8"))
                await writer.drain()

                init_payload = json.dumps(self.current_palette)
                init_msg = f"event: theme\ndata: {init_payload}\n\n".encode("utf-8")
                writer.write(init_msg)
                await writer.drain()

                self.subscribers.add(writer)

                try:
                    while True:
                        data = await reader.read(1024)
                        if not data:
                            break
                except Exception:
                    pass
                finally:
                    self.subscribers.discard(writer)
                    writer.close()
                    await writer.wait_closed()
                return

            if method == "GET" and (path == "/theme" or path == "/"):
                body = json.dumps(self.current_palette, indent=2).encode("utf-8")
                headers_out = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: application/json; charset=utf-8\r\n"
                    f"Content-Length: {len(body)}\r\n"
                    f"{cors_headers}\r\n"
                )
                writer.write(headers_out.encode("utf-8") + body)
                await writer.drain()
                writer.close()
                await writer.wait_closed()
                return

            if method == "GET" and (path == "/status" or path == "/health"):
                status_data = {
                    "status": "ok",
                    "uptime_seconds": int(time.time() - self.start_time),
                    "subscribers": len(self.subscribers),
                    "active_theme": self.current_palette.get("name", "Unknown"),
                    "desktop": self.current_palette.get("desktop", "Unknown"),
                    "has_wallpaper": self.current_palette.get("hasWallpaper", False),
                    "timestamp": self.current_palette.get("timestamp", 0)
                }
                body = json.dumps(status_data, indent=2).encode("utf-8")
                headers_out = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: application/json; charset=utf-8\r\n"
                    f"Content-Length: {len(body)}\r\n"
                    f"{cors_headers}\r\n"
                )
                writer.write(headers_out.encode("utf-8") + body)
                await writer.drain()
                writer.close()
                await writer.wait_closed()
                return

            if method == "POST" and path == "/log":
                body_bytes = b""
                if content_length > 0 and content_length < 1048576:
                    body_bytes = await reader.readexactly(content_length)
                try:
                    Path("/tmp/spotify_dom_debug.json").write_bytes(body_bytes)
                except Exception:
                    pass
                res_body = b'{"status":"ok"}'
                headers_out = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: application/json\r\n"
                    f"Content-Length: {len(res_body)}\r\n"
                    f"{cors_headers}\r\n"
                )
                writer.write(headers_out.encode("utf-8") + res_body)
                await writer.drain()
                writer.close()
                await writer.wait_closed()
                return

            if method == "POST" and (path == "/notify" or path == "/theme"):
                body_bytes = b""
                if content_length > 0 and content_length < 65536:
                    body_bytes = await reader.readexactly(content_length)

                if body_bytes:
                    try:
                        req_data = json.loads(body_bytes.decode("utf-8"))
                        if "colors" in req_data or "spicetify" in req_data:
                            new_pal = req_data
                        else:
                            new_pal = get_default_palette()
                            if "name" in req_data:
                                new_pal["name"] = req_data["name"]
                    except Exception:
                        new_pal = get_default_palette()
                else:
                    new_pal = get_default_palette()

                await self.broadcast_theme(new_pal)

                res_body = json.dumps({"status": "ok", "subscribers": len(self.subscribers)}).encode("utf-8")
                headers_out = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: application/json\r\n"
                    f"Content-Length: {len(res_body)}\r\n"
                    f"{cors_headers}\r\n"
                )
                writer.write(headers_out.encode("utf-8") + res_body)
                await writer.drain()
                writer.close()
                await writer.wait_closed()
                return

            writer.write(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
            await writer.drain()
            writer.close()
            await writer.wait_closed()

        except Exception:
            try:
                writer.close()
                await writer.wait_closed()
            except Exception:
                pass

    async def start(self):
        self.current_palette = self.load_cached_palette()
        self.server = await asyncio.start_server(self.handle_client, self.host, self.port)
        asyncio.create_task(self.file_watcher_loop())
        asyncio.create_task(self.heartbeat_loop())
        async with self.server:
            await self.server.serve_forever()


def run_server():
    server = BridgeServer()
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, loop.stop)
        except NotImplementedError:
            pass
    try:
        loop.run_until_complete(server.start())
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        loop.close()


if __name__ == "__main__":
    run_server()
