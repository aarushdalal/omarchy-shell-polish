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

        # Check hyprbars and titlebar buttons
        self.assertIn("hyprbars", content)
        self.assertIn("×", content)  # close button
        self.assertIn("□", content)  # maximize button
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

    def test_dock_layout_snippet_valid_json(self):
        dock_snippet = ROOT / 'snippets' / 'shell-dock-layout.json'
        self.assertTrue(dock_snippet.is_file(), "snippets/shell-dock-layout.json must exist")
        raw = dock_snippet.read_text()
        # strip // comments for json parse
        lines = [line for line in raw.splitlines() if not line.strip().startswith("//")]
        data = json.loads("\n".join(lines))
        self.assertIn("dock", data)
        self.assertIn("position", data["dock"])
        self.assertIn("autohide", data["dock"])
        self.assertIn("pinned", data["dock"])
        self.assertIsInstance(data["dock"]["pinned"], list)

    def test_documentation_and_version(self):
        doc_path = ROOT / 'docs' / 'FLOATING-MODE.md'
        self.assertTrue(doc_path.is_file(), "docs/FLOATING-MODE.md must exist")
        doc_content = doc_path.read_text()
        self.assertIn("hyprbars", doc_content)
        self.assertIn("omarchy.dock", doc_content)
        self.assertIn("SUPER + L", doc_content)
        self.assertIn("Windows", doc_content)
        self.assertIn("macOS", doc_content)

        version_path = ROOT / 'VERSION'
        self.assertEqual(version_path.read_text().strip(), "1.7.0")

        changelog_path = ROOT / 'CHANGELOG.md'
        self.assertIn("## [1.7.0]", changelog_path.read_text())

if __name__ == '__main__':
    unittest.main()
