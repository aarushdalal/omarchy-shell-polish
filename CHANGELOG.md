# Changelog

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

- Unify user-owned popup materials at restrained dark glass and simplify menu presentation without removing routes or controls.
- Add Caelestia SearchBar material/focus refinement and hidden/reduced-motion ripple guards.
- Add an optional Modern Lock view with a compact date, read-only CPU/RAM/battery line, masked password input and finite motion. Authentication remains in the existing host.
- Include opt-in shared Hyprland and semantic shell material references; preserve existing configuration when merging. No installer changes to authentication or power policy.

## [1.3.1] - 2026-11-01

- Show per-item loading and unavailable states in the Theme Deck while retaining valid same-item thumbnails.
- Preserve existing card motion, sound, favorites, search, peek and explicit Apply; correct preview diagnostics.
- Add exact-source hidden Wayland compilation and isolated Qt image/selection/export regression checks. No real desktop theme is applied by these tests.

## 1.3.0 — 2026-10-31

- **Interactive 3D Motion, Harmony Swatches & Favoriting Suite** (`plugins/community.image-picker`):
  - **Dynamic 3D Parallax Tilt & Moving Sheen**: Hero card tracks cursor motion with real-time 3D $X$/$Y$ perspective tilt and a moving specular glass sheen reflecting across the active card surface.
  - **Dynamic Theme Color Harmony Swatches**: Displays live color palette dots (accent, background, foreground) extracted directly from theme metadata in a frosted pill on the hero card.
  - **Theme Favoriting & Star Pinning**: Clickable star icon (`★`/`☆`) and `Ctrl+S` shortcut with persistent storage in `~/.local/state/omarchy/favorite-themes.json`.
  - **Favorites-Only Deck Filter**: Top HUD toggle button (`★ Favorites (N)`) that filters the entire Arc Deck to show only starred themes with responsive count badges.
  - **Surprise Me / Roulette Shuffle**: Interactive shuffle button (`󰒝`) in top HUD and `Ctrl+R` shortcut to quickly discover and animate to a random theme.
  - **Clean Fullscreen Wallpaper Peeking**: Fullscreen button (`󰍹`) or `Space` key that cleanly fades all UI chrome and expands the master wallpaper into an immersive full-screen view.
  - **Acoustic Mechanical Audio Feedback**: Optional tactile tick on card flips, scrubbing, and toggles powered by `canberra-gtk-play`, toggleable with `Ctrl+M` or the top HUD sound button.
  - **Smooth Touchpad & Mouse Wheel Scrolling**: Integrated Qt 6 `WheelHandler` enabling smooth two-finger touchpad swipes and mouse wheel scrubbing across the deck.
  - **Ergonomic Shortcuts HUD**: Updated bottom dock with crystal-clear shortcut indicators (`◄ ► Deck`, `Enter Apply`, `Space Peek`, `Ctrl+R Shuffle`, `Ctrl+S Star`, `Ctrl+M Sound`, `Esc Close`).

## 1.2.0 — 2026-10-31

- **Prismatic 3D Arc Deck Theme & Wallpaper Selector** (`plugins/community.image-picker`):
  - **Prismatic 3D Amphitheater Arc Deck**: Replaced static carousel with an amphitheater card deck where flanking cards sweep outward and downward in an elegant crescent arc, keeping the hero card commanding and unblocked at the top.
  - **Hardware-Accelerated Anti-Aliased Masking**: Applied GPU `MultiEffect` alpha masks (`radius: 24`) to eliminate sharp image corner protrusion, guaranteeing silky-smooth curved borders on all cards without blank texture drops.
  - **Ultra-Fast Progressive 4K Rendering**: Dual-tier rendering decoupling instant fast-decode thumbnails (< 1ms per card) from crisp full-resolution 4K/1080p master wallpapers on the active hero card with smooth asynchronous fade-in.
  - **Ambient Atmospheric Horizon**: Dynamic wallpaper backdrop aura that blooms across the desktop matching the active artwork with obsidian vignette shading.
  - **Tactile Deck Scrubber & Glass HUDs**: Interactive timeline scrubber with click-to-seek, floating frosted header with group badges and instant search, and integrated hero controls with `Apply Theme` action button.
  - **Ergonomic Controls**: Arrow keys (`◄ ►`), `PgUp`/`PgDn` (jump ±5 cards), `Home`/`End`, mouse click-to-center on flanking cards, and `Escape` to clear search or close.
- **Installer Integration** (`tools/install_refinement.py`):
  - Automatically deploys and enables `community.image-picker` with executable permissions preserved.

## 1.1.1 — 2026-10-12

- Restore DaemonOS icon-only sizing; tracked session actions and visible failure handling on both desktops.
- Preserve running actions across drawer closure; explicit confirmation and force controls.
- Faster, transparent, local tech animation with theme tint and reduced-motion/visibility gating.


## [1.1.0] - 2026-10-11

- User-owned native Omarchy control/menu clones and Session widget; DaemonOS preset-aware drawers, readiness-aware loader and confirmed session actions; exact-file rollback installer.
- Clean current release files and retire workstation captures. Existing public history is preserved. Future commits use a GitHub noreply address; CI checks current release payloads.
- See docs/RELEASE-PRIVACY.md for scope and limitations. Sample artwork illustrates the design, rather than proving a live runtime result.

All notable changes to `omarchy-shell-polish` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-08

### Added
- Initial clean public release for Omarchy 4.0.2 / Arch Linux.
- Frosted glass blur and shadow settings (`snippets/looknfeel-glass.lua`).
- Floating bar and center anchor layout (`snippets/shell-bar-layout.json`).
- Ergonomic keybinding remappings and conflict audit (`snippets/bindings-ergonomic.lua`).
- Comprehensive safe user installer script (`install.sh`) supporting `--dry-run`.
- Full security exclusions, sanitized configurations, and complete documentation.
