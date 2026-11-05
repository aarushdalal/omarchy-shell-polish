#!/usr/bin/env python3
"""Daemon Spotify Sync CLI.

Management and diagnostics utility for Daemon Spotify Live Theme Synchronization.
"""

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

BRIDGE_URL = "http://127.0.0.1:8974"


def print_status():
    print("=== Daemon Spotify Sync Status ===")
    # 1. Spotify Process
    try:
        sp_out = subprocess.check_output(["pgrep", "-a", "spotify"], text=True).strip().splitlines()
        sp_pids = [line for line in sp_out if "--type=" not in line]
        if sp_pids:
            print(f"Spotify Client: RUNNING (PID {sp_pids[0].split()[0]})")
        else:
            print("Spotify Client: NOT RUNNING")
    except Exception:
        print("Spotify Client: NOT RUNNING")

    # 2. Bridge Service
    bridge_ok = False
    try:
        req = urllib.request.Request(f"{BRIDGE_URL}/status", headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            print(f"Bridge Daemon: RUNNING on {BRIDGE_URL}")
            print(f"  - Active Theme: {data.get('active_theme')}")
            print(f"  - Desktop: {data.get('desktop')}")
            print(f"  - Connected Spotify Clients: {data.get('subscribers')}")
            print(f"  - Uptime: {data.get('uptime_seconds')}s")
            bridge_ok = True
    except Exception as e:
        print(f"Bridge Daemon: NOT RESPONDING ({e})")

    # 3. Systemd Unit
    try:
        unit_state = subprocess.check_output(
            ["systemctl", "--user", "is-active", "daemon-spotify-sync.service"],
            text=True, stderr=subprocess.DEVNULL
        ).strip()
        print(f"Systemd Unit: daemon-spotify-sync.service ({unit_state})")
    except Exception:
        print("Systemd Unit: daemon-spotify-sync.service (inactive or not loaded)")

    # 4. Spicetify Extension Check
    ext_file = Path.home() / ".config" / "spicetify" / "Extensions" / "daemon-spotify-sync.js"
    cfg_file = Path.home() / ".config" / "spicetify" / "config-xpui.ini"
    ext_active = False
    if cfg_file.is_file():
        text = cfg_file.read_text(encoding="utf-8")
        if "daemon-spotify-sync.js" in text:
            ext_active = True
    print(f"Spicetify Extension: {'INSTALLED & CONFIGURED' if (ext_file.is_file() and ext_active) else 'NEEDS SETUP'}")


def trigger_sync():
    print("Triggering desktop theme sync to Spotify...")
    # Invoke omarchy-theme-sync
    try:
        res = subprocess.run(["omarchy-theme-sync", "sync"], capture_output=True, text=True)
        print(res.stdout.strip())
        if res.returncode == 0:
            print("✓ Theme sync successfully completed.")
        else:
            print(f"✗ Sync exited with status {res.returncode}")
    except Exception as e:
        print(f"Error executing omarchy-theme-sync: {e}")


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["status", "-s", "--status"]:
        print_status()
    elif sys.argv[1] in ["sync", "-r", "--sync"]:
        trigger_sync()
    elif sys.argv[1] == "bridge":
        os.execv(sys.executable, [sys.executable, str(Path.home() / ".local" / "bin" / "daemon-spotify-sync-bridge")])
    elif sys.argv[1] == "restart":
        subprocess.run(["systemctl", "--user", "restart", "daemon-spotify-sync.service"])
        print_status()
    elif sys.argv[1] == "theme" and len(sys.argv) > 2:
        name = " ".join(sys.argv[2:])
        try:
            req_data = json.dumps({"name": name}).encode("utf-8")
            req = urllib.request.Request(f"{BRIDGE_URL}/notify", data=req_data, headers={"Content-Type": "application/json"}, method="POST")
            with urllib.request.urlopen(req, timeout=2.0) as resp:
                print(f"Pushed theme '{name}' to bridge: {resp.read().decode('utf-8')}")
        except Exception as e:
            print(f"Failed to push theme to bridge: {e}")
    else:
        print("Usage: daemon-spotify-sync [status|sync|restart|theme <name>|bridge]")


if __name__ == "__main__":
    main()
