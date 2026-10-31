# omarchy-shell-polish 1.3.0

### Highlights

- **Interactive 3D Motion, Harmony Swatches & Favoriting Suite** (`community.image-picker`):
  - **Dynamic 3D Parallax Tilt & Moving Glass Sheen**: The hero card tracks cursor position in real-time with responsive 3D perspective tilt ($X$ and $Y$ rotation axes) and a moving specular glass reflection across the card face.
  - **Dynamic Theme Color Harmony Swatches**: Displays live color swatches (accent, background, foreground) parsed from theme metadata inside a frosted glass pill on the hero card.
  - **Theme Favoriting & Star Pinning**: Dedicated star button (`★`/`☆`) on the hero card and `Ctrl+S` shortcut, persisted directly in `~/.local/state/omarchy/favorite-themes.json`.
  - **Favorites Filter Mode**: Instant toggle in the top floating island (`★ Favorites`) to filter the entire Arc Deck down to only starred themes with updated item counts.
  - **Surprise Me / Roulette Shuffle**: Interactive button (`󰒝`) and `Ctrl+R` shortcut that smoothly animates the deck to a random theme.
  - **Immersive Fullscreen Wallpaper Peeking**: `Space` key or `󰍹` button that fades out all UI chrome and scales the master wallpaper to fullscreen, with a floating exit pill.
  - **Acoustic Mechanical Tick Feedback**: Mechanical audio tick on card flips and scrubbing using `canberra-gtk-play`, toggleable with `Ctrl+M` or the audio button (`󰕾`/`󰖁`).
  - **Touchpad & Mouse Wheel Navigation**: Native `WheelHandler` support for smooth two-finger touchpad swiping and mouse wheel navigation across the entire deck.
  - **Refined Bottom HUD**: Polished shortcuts dock with clear badges for all deck interactions (`◄ ► Deck`, `Enter Apply`, `Space Peek`, `Ctrl+R Shuffle`, `Ctrl+S Star`, `Ctrl+M Sound`, `Esc Close`).

### Included Features & Enhancements

- **Prismatic 3D Amphitheater Arc Deck**: Flanking cards fan outward and curve downward in a crescent arc to keep the central hero card commanding and unblocked at the top.
- **Hardware-Accelerated Anti-Aliased Clipping**: GPU `MultiEffect` alpha masks prevent rectangular image corners from bleeding past the rounded card borders.
- **Progressive 4K Master Wallpaper Pipeline**: Instant low-latency preview thumbnails decoupled from crystal-clear master full-resolution wallpapers on the active card.
- **Dynamic Horizon Ambient Backdrop**: Full-screen wallpaper aura blooming beneath the gallery with subtle obsidian vignette shading.
- **Tactile Deck Scrubber**: Timeline ribbon supporting instant drag and seek across 2,050+ wallpapers.

### Validation

- Privacy and payload validation: `python3 tools/release_privacy_check.py` (0 findings).
- Zero corner-clipping bleed and verified 60 FPS fluid rendering.
