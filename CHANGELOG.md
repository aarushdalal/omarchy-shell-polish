# Changelog

## [1.8.0] - 2026-11-17

- **Pixel Minimized Bubble Plugin (`community.floating-bubble`)**:
  - Adds a Google Pixel / Material 3 circular floating bubble in the bottom-right corner.
  - Strictly application icons only (zero text clutter), adapting dynamically to system scale and theme tokens.
  - Smooth horizontal expansion on hover with spring physics (`Easing.OutBack`).
  - Single-click restore, middle/double-click restore & maximize, right-click restore all.
  - **Maximized Window Guard**: Automatically hides when any window on the active workspace is maximized or fullscreen, ensuring zero overlap with active work.
  - **Multi-Workspace Isolation**: Remembers which workspace each window was minimized from. Each workspace maintains its own isolated bubble, allowing smooth multitasking between floating and tiling desktops without losing minimized windows across workspace switches.
- **macOS Traffic Light Titlebars (`hyprbars` / `snippets/floating-mode.lua`)**:
  - Left-aligned traffic light dots: Red (`🔴 Close`), Yellow (`🟡 Minimize`), and Green (`🟢 Maximize/Restore`).
  - Circular rounding (`button_rounding = 12`) and glyphs displayed on mouse hover (`icon_on_hover = true`).
  - Double-clicking the titlebar toggles maximized state.
- **Native Border & Diagonal Corner Resizing**:
  - Edge and corner grab areas enabled via `resize_on_border = true` and `extend_border_grab_area = 18`.
  - Comprehensive keyboard resizing shortcuts (<kbd>SUPER</kbd> + <kbd>CTRL</kbd> + Arrows for width/height, <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + `+`/`-` for diagonal whole size).
- **Smart Window Snapping & Unsnapping (`omarchy-hyprland-window-snap` & `snippets/bindings-ergonomic.lua`)**:
  - Half-screen snap left/right (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Left</kbd>/<kbd>Right</kbd>), center (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Down</kbd>), and maximize (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Up</kbd>).
  - Geometry memory toggles back to previous floating size when repeating the same shortcut.
  - Strict layout isolation: snapping commands safely no-op in dwindle or scrolling workspaces.
- **Dedicated CLI Tools (`bin/`)**:
  - `omarchy-hyprland-window-restore`: Restores individual, latest, or all minimized windows with per-workspace targeting.
  - `omarchy-hyprland-window-minimize`: Minimizes floating windows to `special:minimized` and tags them with originating workspace metadata.
  - `omarchy-hyprland-window-snap`: Snaps and unsnaps floating windows with geometry caching.

## [1.7.0] - 2026-11-12

- **Windows & macOS-style Floating Desktop Experience** (`snippets/floating-mode.lua` & `docs/FLOATING-MODE.md`):
  - **Freeform Floating Window Management**: Enables fluid, unconstrained floating window layouts on any workspace, offering an intuitive experience for multi-window triage, authoring, and casual browsing familiar from Windows 11 and macOS Sequoia.
  - **Native Window Titlebars (`hyprbars`)**: Adds theme-integrated titlebars with right-aligned window action buttons:
    - Close (`×` -> `hl.dsp.window.close`)
    - Maximize / Restore (`□` -> toggle maximized fullscreen), with titlebar double-click maximization support
    - Minimize (`−` -> `omarchy-hyprland-window-minimize`)
  - **Interactive Desktop Dock Integration (`omarchy.dock` / `snippets/shell-dock-layout.json`)**:
    - Automatically hosts minimized windows as a dedicated desktop shelf (macOS Dock / Windows Taskbar paradigm).
    - Supports pinned applications, position adjustment (`top|bottom|left|right`), and auto-hide toggling (`omarchy dock autohide on`).
  - **Drop Shadow & Visual Elevation**: Configures 16px soft drop shadows (`decoration.shadow`) to provide clear visual depth and natural layering between overlapping windows.
  - **Solid Opacity Overrides**: Enforces crisp, fully opaque (`1.0`) surface content on floating workspace windows so overlapping documents never suffer from bleed-through text or contrast loss.
  - **Ergonomic Layout Switching Shortcuts (`snippets/bindings-ergonomic.lua`)**:
    - `SUPER + L`: Cycles workspace layout forward (Dwindle -> Scrolling -> Floating) with on-screen HUD notification.
    - `SUPER + ALT + L`: Cycles workspace layout backward.
    - `SUPER + T`: Instant toggle for floating an individual window.
    - `SUPER + Left-Click Drag` / `SUPER + Right-Click Drag`: Freeform window movement and border resizing.
  - **Documentation & Verification**: Authored `docs/FLOATING-MODE.md`, updated `docs/BAR-POLISH.md` and `docs/KEYBINDING-AUDIT.md`, and added automated regression tests in `tests/test_floating_mode.py`.

## [1.6.1] - 2026-11-05

- Preserve an existing Files glass CSS recipe during automatic scans while still adding a missing import.
- Add a regression for custom Files tint/alpha preservation.

## [1.6.0] - 2026-11-05

- Add a capability-aware universal monitor for current/future apps, native recipe setup and once-per-app compatibility notifications.
- Add native background-only glass references, solid foreground content and shared gentle blur.
- Replace embedded Spotify wallpaper with native alpha; remove decorative gradients and fix cinema backdrop/navigation layering while preserving text masks.
- Include Files, ChatGPT, AntiGravity app and Foot settings, guarded runtime recipes and source-only licensed Spotify helper.
- Add private recovery-kit tools and portable setup documentation. AntiGravity IDE and pet changes are excluded.

## [1.5.0] - 2026-11-03

- **Project Daemon — Spotify Live Theme Synchronization Suite** (`reference/spotify-sync/`):
  - **Zero-Restart Live Synchronization**: Injects `daemon-spotify-sync.js` into Spotify via Spicetify, updating design tokens and CSS variables over Server-Sent Events (`http://127.0.0.1:8974/events`) in < 2ms without interrupting audio playback or restarting Spotify.
  - **Live Desktop Wallpaper Aura Integration**: Streams the active desktop wallpaper (`~/.local/state/omarchy/current/background`) via loopback HTTP (`/wallpaper`) into a hardware-accelerated fixed background canvas with reduced blur (`blur(2px)`) and OLED contrast optimization.
  - **Seamless Edge-to-Edge Layout**: Fully unifies the left navigation bar, right sidebar panel, bottom playback bar, and top bar to transparent backings, displaying an unbroken desktop wallpaper canvas across the entire application.
  - **Dynamic Gradient Purge & Plugin Precedence Enforcer**:
    - Automatically strips Spotify's dynamic color extraction gradients from recommendation rails and album shelves.
    - Neutralizes recommendation hero/billboard colored boxes, letting text and artwork float directly over the wallpaper.
    - Monitors `document.head` via `MutationObserver` to enforce stylesheet precedence over third-party Spicetify extensions and Marketplace snippets, guaranteeing unbroken visual consistency.
  - **Zero-Flash Local Caching**: Persists active palette in `localStorage` for instant correct styling on launch before the SSE handshake completes.
  - **Omarchy Theme Sync Adapter**: Adds `SpotifyAdapter` in `~/.local/lib/omarchy-theme-sync/adapters/spotify.py`, connecting desktop theme changes directly to the bridge.
  - **Systemd User Service & Management CLI**: Deploys `daemon-spotify-sync.service` and `daemon-spotify-sync` CLI for one-command status checks, live triggers, and logs.

## [1.4.0] - 2026-11-02
