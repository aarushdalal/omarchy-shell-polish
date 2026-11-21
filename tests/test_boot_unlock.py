#!/usr/bin/env python3
"""Unit tests for the Encrypted Disk Boot Unlock & Wallpaper Sync module."""
import os
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BOOT_UNLOCK_DIR = ROOT / "reference" / "boot-unlock"

class TestBootUnlockModule(unittest.TestCase):
    def test_required_assets_exist(self):
        required_files = [
            "omarchy.script",
            "card.png",
            "omarchy-plymouth-sync",
            "25-sddm-wallpaper-sync.sh",
            "boot-unlock-preview.png",
            "README.md",
        ]
        for fname in required_files:
            file_path = BOOT_UNLOCK_DIR / fname
            self.assertTrue(file_path.is_file(), f"Missing required file: {fname}")
            self.assertGreater(file_path.stat().st_size, 0, f"File {fname} is empty")

    def test_plymouth_script_structure(self):
        script_path = BOOT_UNLOCK_DIR / "omarchy.script"
        content = script_path.read_text(encoding="utf-8")
        self.assertIn("Window.SetBackgroundTopColor", content)
        self.assertIn("card.png", content)
        self.assertIn("background.png", content)
        self.assertIn("Encrypted Storage", content)

    def test_sync_script_clean_syntax(self):
        sync_script = BOOT_UNLOCK_DIR / "omarchy-plymouth-sync"
        content = sync_script.read_text(encoding="utf-8")
        self.assertIn("limine-mkinitcpio", content)
        self.assertNotIn("home" + "/daemon", content)

    def test_hook_notifications(self):
        hook_path = BOOT_UNLOCK_DIR / "25-sddm-wallpaper-sync.sh"
        content = hook_path.read_text(encoding="utf-8")
        self.assertIn("notify-send", content)
        self.assertIn("Syncing Boot and Login Screens", content)
        self.assertIn("Sync Complete", content)

if __name__ == "__main__":
    unittest.main()
