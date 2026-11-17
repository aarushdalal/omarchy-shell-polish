# Shell Polish 1.8.0 — Pixel Minimized Bubble & macOS Window Controls

Release 1.8.0 enhances the Floating Desktop experience with macOS traffic-light window controls, a Google Pixel / Material 3 floating minimized app bubble, native mouse edge and corner resizing, toggle-unsnap window snapping, and complete multi-workspace multitasking isolation.

### Key Highlights

- **macOS Traffic Light Window Controls (`hyprbars`)**:
  - Left-aligned traffic light dots: Red (`🔴 Close`), Yellow (`🟡 Minimize`), and Green (`🟢 Maximize/Restore`).
  - Circular rounding (`button_rounding = 12`) and glyphs displayed on mouse hover (`icon_on_hover = true`).
  - Double-clicking the titlebar toggles maximized state.
- **Google Pixel Minimized Bubble Plugin (`community.floating-bubble`)**:
  - Clean floating bubble anchored in the bottom-right corner adapting dynamically to system font scale and theme.
  - Strictly application icons only (zero text clutter).
  - Smooth horizontal expansion on hover with spring easing (`Easing.OutBack`).
  - Restores on single click, restores & maximizes on double/middle click, and restores all on right click.
  - **Collision Guard**: Never appears above a maximized or fullscreen window.
  - **Multi-Workspace Isolation**: Remembers which workspace each window was minimized from. Each workspace maintains its own isolated bubble, allowing smooth multitasking between floating and tiling desktops without losing minimized windows across workspace switches.
- **Native Border & Diagonal Corner Resizing**:
  - Border and corner grab areas enabled via `resize_on_border = true` and `extend_border_grab_area = 18`.
  - Comprehensive keyboard resizing shortcuts (<kbd>SUPER</kbd> + <kbd>CTRL</kbd> + Arrows for width/height, <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + `+`/`-` for diagonal whole size).
- **Smart Window Snapping & Unsnapping (`omarchy-hyprland-window-snap`)**:
  - Half-screen snap left/right, center, and maximize.
  - Geometry memory toggles back to previous floating size when repeating the same shortcut.
  - Strict layout isolation: snapping commands safely no-op in dwindle or scrolling workspaces.
- **Dedicated CLI Tools**:
  - `omarchy-hyprland-window-restore`: Restores individual, latest, or all minimized windows with per-workspace targeting.
  - `omarchy-hyprland-window-minimize`: Minimizes floating windows to `special:minimized` and tags them with originating workspace metadata.
  - `omarchy-hyprland-window-snap`: Snaps and unsnaps floating windows with geometry caching.

---

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
