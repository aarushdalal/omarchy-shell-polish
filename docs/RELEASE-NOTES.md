# omarchy-shell-polish 1.2.0

### Highlights

- **Prismatic 3D Arc Deck Theme & Wallpaper Gallery** (`community.image-picker`):
  - **Prismatic 3D Amphitheater Arc Deck**: Replaced the static carousel with a 3D fanned arc deck. Flanking cards sweep outward and downward in an amphitheater crescent, keeping the center hero card elevated, commanding, and completely unobstructed at the top.
  - **Hardware-Accelerated Anti-Aliased Masking**: Applied GPU `MultiEffect` alpha masks (`radius: 24`) across all cards, guaranteeing silky-smooth rounded corners and eliminating sharp image corner protrusion.
  - **Zero-Blur 4K Progressive Rendering**: Full-resolution master backgrounds decode asynchronously on the hero card while fast thumbnails provide instant (< 1ms) navigation across collections of 2,050+ wallpapers.
  - **Ambient Atmospheric Horizon**: Dynamic wallpaper backdrop aura that blooms across the desktop matching the active artwork with obsidian vignette shading.
  - **Tactile Deck Scrubber & Glass HUDs**: Live timeline scrub ribbon with click-to-seek, floating frosted header with group badges and instant search, and integrated hero controls with `Apply Theme` action button.
  - **Ergonomic Navigation**: Floating side chevron buttons (`‹` and `›`), mouse click-to-select on any side card, and extended keyboard controls (`◄ ►` for adjacent cards, `PageUp`/`PageDown` for jumping ±5 cards, `Home`/`End` for boundaries, `Escape` to clear search or close).
- **Installer Integration** (`tools/install_refinement.py`):
  - Seamlessly installs, manages, and rolls back `community.image-picker` alongside community panels with executable script permissions properly maintained.

### Privacy & Validation

Current payload privacy scan passed with 0 findings. All components validated on Qt 6 / Quickshell 0.3.1 / Hyprland 0.56.2.
