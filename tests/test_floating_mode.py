import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class TestFloatingMode(unittest.TestCase):
    def test_floating_mode_snippet_structure(self):
        snippet_path = ROOT / 'snippets' / 'floating-mode.lua'
        self.assertTrue(snippet_path.is_file(), "snippets/floating-mode.lua must exist")
        content = snippet_path.read_text()

        # Check shadow configuration
        self.assertIn("shadow", content)
        self.assertIn("range = 16", content)

        # Check opacity override for floated workspace
        self.assertIn("workspace-floated", content)
        self.assertIn("1.0 override", content)

        # Check native mouse edge resizing
        self.assertIn("resize_on_border = true", content)
        self.assertIn("extend_border_grab_area = 18", content)

        # Check hyprbars and macOS traffic light titlebar buttons
        self.assertIn("hyprbars", content)
        self.assertIn("bar_buttons_alignment = \"left\"", content)
        self.assertIn("button_rounding = 12", content)
        self.assertIn("icon_on_hover = true", content)
        self.assertIn("×", content)  # close button
        self.assertIn("＋", content)  # maximize button
        self.assertIn("−", content)  # minimize button
        self.assertIn("omarchy-hyprland-window-minimize", content)
        self.assertIn("on_double_click", content)

    def test_bindings_ergonomic_has_floating_and_layout_toggles(self):
        bindings_path = ROOT / 'snippets' / 'bindings-ergonomic.lua'
        self.assertTrue(bindings_path.is_file(), "snippets/bindings-ergonomic.lua must exist")
        content = bindings_path.read_text()

        self.assertIn("omarchy-hyprland-workspace-layout-toggle", content)
        self.assertIn('"SUPER", "L"', content)
        self.assertIn('"SUPER ALT", "L"', content)
        self.assertIn('"SUPER", "T"', content)
        self.assertIn("togglefloating", content)

        # Snapping shortcuts
        self.assertIn("omarchy-hyprland-window-snap left", content)
        self.assertIn("omarchy-hyprland-window-snap right", content)
        self.assertIn("omarchy-hyprland-window-snap center", content)
        self.assertIn("omarchy-hyprland-window-snap maximize", content)

        # Keyboard resizing
        self.assertIn("resizeactive", content)

        # Restore engine shortcuts
        self.assertIn("omarchy-hyprland-window-restore --latest", content)
        self.assertIn("omarchy-hyprland-window-restore --all", content)

    def test_dock_layout_snippet_valid_json(self):
        dock_snippet = ROOT / 'snippets' / 'shell-dock-layout.json'
        self.assertTrue(dock_snippet.is_file(), "snippets/shell-dock-layout.json must exist")
        raw = dock_snippet.read_text()
        lines = [line for line in raw.splitlines() if not line.strip().startswith("//")]
        data = json.loads("\n".join(lines))
        self.assertIn("dock", data)
        self.assertIn("position", data["dock"])
        self.assertIn("autohide", data["dock"])
        self.assertIn("pinned", data["dock"])
        self.assertIsInstance(data["dock"]["pinned"], list)

    def test_floating_bubble_plugin_structure(self):
        plugin_dir = ROOT / 'plugins' / 'community.floating-bubble'
        self.assertTrue(plugin_dir.is_dir(), "community.floating-bubble plugin must exist")

        manifest_file = plugin_dir / 'manifest.json'
        self.assertTrue(manifest_file.is_file(), "manifest.json must exist")
        manifest = json.loads(manifest_file.read_text())
        self.assertEqual(manifest["id"], "community.floating-bubble")
        self.assertEqual(manifest["version"], "1.8.0")

        service_file = plugin_dir / 'Service.qml'
        self.assertTrue(service_file.is_file(), "Service.qml must exist")

        bubble_qml = plugin_dir / 'FloatingBubbleWindow.qml'
        self.assertTrue(bubble_qml.is_file(), "FloatingBubbleWindow.qml must exist")
        bubble_content = bubble_qml.read_text()
        self.assertIn("WlrLayershell.namespace: \"omarchy-floating-bubble\"", bubble_content)
        self.assertIn("hasMaximizedWindow", bubble_content)
        self.assertIn("minimizedWindows", bubble_content)
        self.assertIn("fromWs === workspaceId", bubble_content)

    def test_cli_tools_exist_and_executable(self):
        bin_dir = ROOT / 'bin'
        self.assertTrue(bin_dir.is_dir(), "bin/ directory must exist")

        restore_bin = bin_dir / 'omarchy-hyprland-window-restore'
        self.assertTrue(restore_bin.is_file(), "omarchy-hyprland-window-restore must exist")
        self.assertTrue(restore_bin.stat().st_mode & 0o111, "restore script must be executable")

        minimize_bin = bin_dir / 'omarchy-hyprland-window-minimize'
        self.assertTrue(minimize_bin.is_file(), "omarchy-hyprland-window-minimize must exist")
        self.assertTrue(minimize_bin.stat().st_mode & 0o111, "minimize script must be executable")

        snap_bin = bin_dir / 'omarchy-hyprland-window-snap'
        self.assertTrue(snap_bin.is_file(), "omarchy-hyprland-window-snap must exist")
        self.assertTrue(snap_bin.stat().st_mode & 0o111, "snap script must be executable")

    def test_documentation_and_version(self):
        doc_path = ROOT / 'docs' / 'FLOATING-MODE.md'
        self.assertTrue(doc_path.is_file(), "docs/FLOATING-MODE.md must exist")
        doc_content = doc_path.read_text()
        self.assertIn("hyprbars", doc_content)
        self.assertIn("community.floating-bubble", doc_content)
        self.assertIn("SUPER + L", doc_content)
        self.assertIn("Windows", doc_content)
        self.assertIn("macOS", doc_content)

        version_path = ROOT / 'VERSION'
        self.assertEqual(version_path.read_text().strip(), "1.8.0")

        changelog_path = ROOT / 'CHANGELOG.md'
        self.assertIn("## [1.8.0]", changelog_path.read_text())

if __name__ == '__main__':
    unittest.main()
