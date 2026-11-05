"""Unit and integration test suite for Daemon Spotify Live Theme Synchronization."""

import json
import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPOTIFY_DIR = ROOT / "reference" / "spotify-sync"


class TestSpotifySyncManifest(unittest.TestCase):
    """Verify presence and integrity of all Spotify sync suite assets."""

    def test_required_files_exist(self):
        expected_files = [
            "daemon-spotify-sync.js",
            "daemon-spotify-sync-bridge.py",
            "spotify_adapter.py",
            "daemon-spotify-sync.service",
            "daemon-spotify-sync.sh",
            "README.md",
        ]
        for fname in expected_files:
            target = SPOTIFY_DIR / fname
            self.assertTrue(target.is_file(), f"Missing required file: {fname}")
            self.assertGreater(target.stat().st_size, 50, f"File {fname} is unexpectedly small")

    def test_extension_javascript_syntax(self):
        """Ensure the Spicetify runtime extension has 100% valid JavaScript syntax."""
        js_path = SPOTIFY_DIR / "daemon-spotify-sync.js"
        res = subprocess.run(
            ["node", "-c", str(js_path)],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, f"Syntax error in extension: {res.stderr}")

    def test_extension_architecture_rules(self):
        """Validate key architectural requirements inside the Spicetify extension."""
        content = (SPOTIFY_DIR / "daemon-spotify-sync.js").read_text(encoding="utf-8")

        # 1. Server-Sent Events listener
        self.assertIn("new EventSource", content, "Missing SSE connection")
        self.assertIn("daemon-spotify-sync:palette", content, "Missing localStorage cache key")

        # 2. Remove the legacy wallpaper canvas and keep native fullscreen alpha.
        self.assertIn('document.getElementById("daemon-spotify-wallpaper")?.remove()', content)
        self.assertNotIn("blur(2px)", content)
        self.assertIn(":fullscreen::backdrop", content)
        self.assertIn("data-daemon-cinema-fullscreen", content)

        # 3. Transparent unified background layout
        self.assertIn("Root__right-sidebar", content, "Missing right-sidebar override")
        self.assertIn(".Root__nav-bar", content, "Missing nav-bar override")
        self.assertIn(".Root__now-playing-bar", content, "Missing now-playing-bar override")

        # 4. Gradient purge and style enforcer
        self.assertIn("ensureStylesheetPrecedence", content, "Missing stylesheet precedence enforcer")
        self.assertIn("setupStyleEnforcer", content, "Missing active style enforcer")
        self.assertIn("MutationObserver", content, "Missing DOM MutationObserver")


class TestSpotifySyncBridge(unittest.TestCase):
    """Verify bridge daemon helpers and palette transformation logic."""

    def test_hex_conversion_helpers(self):
        bridge_path = SPOTIFY_DIR / "daemon-spotify-sync-bridge.py"
        self.assertTrue(bridge_path.is_file())

        # Test hex conversions using Python directly
        import importlib.util
        spec = importlib.util.spec_from_file_location("bridge", str(bridge_path))
        bridge = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(bridge)

        self.assertEqual(bridge.hex_to_rgb("#000000"), (0, 0, 0))
        self.assertEqual(bridge.hex_to_rgb("#ffffff"), (255, 255, 255))
        self.assertEqual(bridge.hex_to_rgb("#ff007f"), (255, 0, 127))
        self.assertEqual(bridge.hex_to_rgb_str("#123456"), "18, 52, 86")

    def test_default_palette_structure(self):
        bridge_path = SPOTIFY_DIR / "daemon-spotify-sync-bridge.py"
        import importlib.util
        spec = importlib.util.spec_from_file_location("bridge", str(bridge_path))
        bridge = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(bridge)

        pal = bridge.get_default_palette()
        self.assertIsInstance(pal, dict)
        self.assertIn("name", pal)
        self.assertIn("colors", pal)
        self.assertIn("spicetify", pal)
        self.assertIn("wallpaperUrl", pal)
        self.assertIn("/wallpaper", pal["wallpaperUrl"])

        colors = pal["colors"]
        for key in ["backgroundPrimary", "foregroundPrimary", "accentPrimary", "borderSubtle"]:
            self.assertIn(key, colors, f"Missing key in semantic palette: {key}")

        spice = pal["spicetify"]
        self.assertIn("vars", spice)
        self.assertIn("rgb", spice)
        self.assertIn("main", spice["vars"])
        self.assertIn("button-active", spice["vars"])


class TestSpotifyThemeAdapter(unittest.TestCase):
    """Verify omarchy-theme-sync adapter contract."""

    def test_adapter_class_structure(self):
        adapter_path = SPOTIFY_DIR / "spotify_adapter.py"
        self.assertTrue(adapter_path.is_file())

        import importlib.util
        spec = importlib.util.spec_from_file_location("spotify_adapter", str(adapter_path))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)

        self.assertTrue(hasattr(mod, "SpotifyAdapter"))
        adapter = mod.SpotifyAdapter("spotify", {"enabled": True})
        self.assertEqual(adapter.app_id, "spotify")
        self.assertTrue(hasattr(adapter, "sync"))

        # Verify safe degradation if bridge is down
        class DummyTheme:
            name = "Test Theme"
            is_dark = True
            colors = {"background": "#0b0c0f", "foreground": "#dddddf", "accent": "#336699"}
            def get_color(self, k, default=""):
                return self.colors.get(k, default)

        # sync should return safely (True or False) without raising uncaught exceptions
        res = adapter.sync(DummyTheme())
        self.assertIsInstance(res, bool)


if __name__ == "__main__":
    unittest.main()
