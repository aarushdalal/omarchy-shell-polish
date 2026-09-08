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

<!-- Future image: assets/showcase/polish-hero.png -->
<!-- ![Main desktop experience](assets/showcase/polish-hero.png) -->

### Feature gallery

<!-- Future image: assets/showcase/polish-glass-blur.png -->
<!-- ![polish-glass-blur.png](assets/showcase/polish-glass-blur.png) -->

<!-- Future image: assets/showcase/polish-floating-bar.png -->
<!-- ![polish-floating-bar.png](assets/showcase/polish-floating-bar.png) -->

<!-- Future image: assets/showcase/polish-rounded-corners.png -->
<!-- ![polish-rounded-corners.png](assets/showcase/polish-rounded-corners.png) -->

<!-- Future image: assets/showcase/polish-window-gaps.png -->
<!-- ![polish-window-gaps.png](assets/showcase/polish-window-gaps.png) -->

<!-- Future image: assets/showcase/feature-05.png -->
<!-- ![Feature preview 5](assets/showcase/feature-05.png) -->

<!-- Future image: assets/showcase/feature-06.png -->
<!-- ![Feature preview 6](assets/showcase/feature-06.png) -->

<!-- Future image: assets/showcase/feature-07.png -->
<!-- ![Feature preview 7](assets/showcase/feature-07.png) -->

<!-- Future image: assets/showcase/feature-08.png -->
<!-- ![Feature preview 8](assets/showcase/feature-08.png) -->

<!-- Future image: assets/showcase/feature-09.png -->
<!-- ![Feature preview 9](assets/showcase/feature-09.png) -->

<!-- Future image: assets/showcase/feature-10.png -->
<!-- ![Feature preview 10](assets/showcase/feature-10.png) -->

### Motion and interaction

<!-- Future GIF: assets/showcase/interaction-01.gif -->
<!-- ![Interaction preview](assets/showcase/interaction-01.gif) -->

<!-- Future GIF: assets/showcase/interaction-02.gif -->
<!-- ![Transition preview](assets/showcase/interaction-02.gif) -->

### Video demonstrations

<!-- Future thumbnail: assets/showcase/video-01-thumbnail.png -->
<!-- [![Watch demo video](assets/showcase/video-01-thumbnail.png)](https://github.com/YOUR-USERNAME/PROJECT-NAME/releases) -->


---

## License

[MIT License](LICENSE).
