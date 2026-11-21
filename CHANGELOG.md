# Changelog

## [1.10.0] - 2026-11-21

- **Encrypted Disk Boot Unlock UI & Automated Background Sync (`reference/boot-unlock/`)**:
  - **Frosted Monolith Early-Boot Screen**: Centers a frosted glass container (`card.png`) with 26px rounded corners, specular highlight rim, and ambient Gaussian blur (`0x18`) over the active desktop wallpaper for early-boot Linux LUKS encrypted storage unlock.
  - **100% Automated Background Sync Engine**: Installs non-interactive sync script (`omarchy-plymouth-sync`) and Omarchy theme hook (`25-sddm-wallpaper-sync.sh`) that rebuilds the unified kernel image via `limine-mkinitcpio` silently in the background with zero terminal interruptions.
  - **Real-Time Desktop Notification Alerts**: Emits transient desktop notifications (`notify-send`) when wallpaper sync starts and updates in-place to "Sync Complete" upon initramfs rebuild.
  - **Zero Security or Encryption Changes**: Preserves existing LUKS keys, crypttab configurations, PAM stack, and desktop lock screen (`hyprlock`).
  - **Automated Test Coverage**: Added `tests/test_boot_unlock.py` validating asset integrity, Plymouth script syntax, and clean-room compliance.

## [1.9.0] - 2026-11-19

- **Virtualized 11-Delegate Arc Deck & Instant Gallery (`community.image-picker`)**:
  - Re-architected \`ImagePicker.qml\` arc deck repeater to use an 11-delegate ring buffer pool (\`Math.min(11, root.imageArray.length > 0 ? 11 : 0)\`), dropping active QML card allocations from 50,000+ items down to 11 live delegates.
  - Dropped opening and initialization time from 2–3s down to instantaneous sub-100ms with zero memory bloat or GC frame drops across large catalogs.
  - Preserved continuous card relativeIndex calculations and smooth Qt Quick physics across track navigation.
- **Space-in-Search & Multi-Term Token Filtering (`community.image-picker`)**:
  - Fixed Space key interception: typing a space while searching now smoothly appends to the search filter query instead of triggering peek mode.
  - Peek mode dynamically maps to \`Space\` when the search query is empty, and \`Ctrl+Space\` when actively typing a query.
  - Added multi-token whitespace-separated keyword matching in \`ImagePickerModel.js\`: searches like \"tokyo night\" or \"nord polar\" match all tokens across titles, labels, and slugs.
  - Bottom shortcuts dock dynamically adapts key badge between \`Space Peek\` and \`Ctrl+Space Peek\`.

## [1.8.1] - 2026-11-19

- **Lock Screen Visual Refinement (`reference/modern-lock/LockView.qml`)**:
  - **Transparent Backdrop**: Eliminated opaque black backdrop and scrim overlay under and around wallpaper surface, enabling transparent blur integration.
  - **12px Blur Precision**: Reduced MultiEffect blur from 48px to 12px (`blurMax: 12`, `blurMultiplier: 1`, `contrast: 0.0`), keeping the active wallpaper clearly visible with a clean frosted glass effect.
  - **View Revision**: Bumped `viewRevision` to `minimal-stats-live-20261119`.

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
