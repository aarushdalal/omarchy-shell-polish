# Omarchy Shell Polish (`omarchy-shell-polish`)

> **Unofficial / Community Guide**: Curated configuration snippets for UI polish and ergonomics on Omarchy.

A collection of tested configuration snippets, frosted glass shaders, floating bar layouts, and conflict-free keybinding mappings for Omarchy and Hyprland.

---

## Status / Experimental Warning

**This repository does NOT automatically modify `shell.json`, `bindings.lua`, or `looknfeel.lua`.** All settings are provided as modular snippets with clear instructions and conflict analysis so you can audit them before applying.

---

## Snippets Included

1. **Frosted Glass & Decorations** (`snippets/looknfeel-glass.lua`):
   - Dual-pass Gaussian blur with subtle noise, high contrast, and vibrancy.
   - Rounded corners (12px) and soft drop shadows.
2. **Floating Top Bar Layout** (`snippets/shell-bar-layout.json`):
   - Center island telemetry placement with balanced left and right widget clusters.
3. **Ergonomic Keybindings** (`snippets/bindings-ergonomic.lua`):
   - Restores core Omarchy defaults (`SUPER + T`, `SUPER + P`, `SUPER + S`).
   - Maps universal media and productivity shortcuts (`SUPER + \`, `SUPER + D`, `SUPER + ALT + H`).

---

## Requirements

- Omarchy `dev (13f18b2c) / 4.0.2`
- Hyprland `0.56.2`

---

## Installation & Usage

1. Inspect snippets:
   ```bash
   ./install.sh check
   ```
2. Back up your existing files:
   ```bash
   cp ~/.config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua.bak
   cp ~/.config/omarchy/shell.json ~/.config/omarchy/shell.json.bak
   ```
3. Copy desired snippets into your configuration files and run `hyprctl reload`.

---

## Showcase

> Visual previews, UI screenshots, and recordings for documentation and release verification.

### Main experience

**Omarchy Desktop Showcase** (click to view)

<video src="https://github.com/aarushdalal/omarchy-shell-polish/raw/main/assets/showcase/omarchy_intro_showcase.mp4" controls width="100%"></video>

### Feature gallery

### Motion and interaction

<!-- Future GIF: assets/showcase/interaction-01.gif -->
<!-- Future GIF: assets/showcase/interaction-02.gif -->
### Video demonstrations

<!-- Future thumbnail: assets/showcase/video-01-thumbnail.png -->
<!-- [![Watch demo video](assets/showcase/video-01-thumbnail.png)](https://github.com/YOUR-USERNAME/PROJECT-NAME/releases) -->


---

## License

[MIT License](LICENSE).
