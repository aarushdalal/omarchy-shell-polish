# Changelog

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
