# Shell Polish 1.7.0 — Windows & macOS Floating Desktop Experience

Release 1.7.0 brings a complete, refined Floating Desktop Experience to Omarchy and Hyprland, bridging the gap between keyboard-driven tiling and traditional Windows 11 / macOS Sequoia window management.

### Key Highlights

- **Freeform Floating Workspaces**: Enables fluid floating window management across workspaces, ideal for multi-window authoring, graphics tools, and casual multitasking.
- **Native Window Titlebars (`hyprbars`)**: Theme-integrated titlebars featuring standard window controls:
  - Close (`×` -> `hl.dsp.window.close`)
  - Maximize / Fullscreen toggle (`□` -> `hl.dsp.window.fullscreen`), plus titlebar double-click maximization
  - Minimize (`−` -> `omarchy-hyprland-window-minimize`)
- **Interactive Desktop Dock Integration (`omarchy.dock`)**:
  - Automatically activates on floating workspaces as an interactive minimization shelf and application launcher.
  - Clicking minimized windows restores them into focus immediately.
  - Supports quick customization via `omarchy dock` (position, auto-hide, application pinning).
- **Elevation & Visual Hierarchy**:
  - 16px soft drop shadows (`decoration.shadow`) to clearly delineate overlapping window layers.
  - Solid opacity override (`1.0`) ensuring overlapping documents stay crisp and readable without background text bleed-through.
- **Ergonomic Layout Switching**:
  - `SUPER + L`: Seamlessly cycles active workspace layout forward (Tiling → Scrolling → Floating).
  - `SUPER + ALT + L`: Cycles workspace layout backward.
  - `SUPER + T`: Instant toggle for floating an individual window.
- **Configuration & Documentation**:
  - New snippet: `snippets/floating-mode.lua`
  - New snippet: `snippets/shell-dock-layout.json`
  - Comprehensive guide: `docs/FLOATING-MODE.md`
  - Updated keybinding audit: `docs/KEYBINDING-AUDIT.md`
  - Bar & dock synergy: `docs/BAR-POLISH.md`

### Validation
- Validated with automated test suite in `tests/test_floating_mode.py`.
- Verified compatibility with Omarchy 4.0.2 / Hyprland 0.56.2 and Quickshell 0.3.1.
