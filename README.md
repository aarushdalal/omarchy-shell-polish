# Omarchy Shell Polish (`omarchy-shell-polish`)

> **Unofficial / Community Snippets**: A curated collection of Hyprland and Omarchy shell configuration snippets for frosted glass aesthetics, floating bar layout, and ergonomic keybinding polish.

Three focused configuration snippets that apply visual refinements, a center-island bar layout, and a conflict-free ergonomic keybinding set to Omarchy Hyprland — without modifying any Omarchy core files.

This project was developed through an AI-assisted workflow. The concept, customization, configuration, testing, integration, and final iteration were directed and carried out by me.

---

## My Contribution

I did not write Omarchy, Quickshell, or Hyprland from scratch. What I contributed:

- **Frosted Glass Snippet** (`snippets/looknfeel-glass.lua`): Tuned Hyprland `decoration` parameters — blur radius, passes, layerrule blur targets, window opacity, and shadow settings — to produce a frosted glass aesthetic on Wayland with AMD Radeon Vega integrated graphics. Values were iterated to balance visual quality with performance on a 60 Hz 1080p panel.
- **Floating Bar Layout Snippet** (`snippets/shell-bar-layout.json`): Designed a `shell.json` layout configuration placing a center island telemetry widget (`daemon0.system-pulse`) with balanced left and right widget clusters for the Omarchy Quickshell bar.
- **Ergonomic Keybindings Snippet** (`snippets/bindings-ergonomic.lua`): Fully audited all live Hyprland keybindings against the Omarchy distribution defaults. Restored missing core Omarchy window management bindings (`SUPER + T`, `SUPER + P`, `SUPER + S`, `SUPER + SHIFT + SPACE`). Mapped universal productivity shortcuts — media playback cluster (`SUPER + \`), app launcher (`SUPER + D`), LazyGit (`SUPER + CTRL + G`), Config Time Machine (`SUPER + ALT + H`), screenshot (`SUPER + SHIFT + S`), Study Focus (`SUPER + CTRL + ALT + S`) — eliminating all duplicate dispatches.
- **Installer**: Authored `./install.sh check` for dependency validation.
- **Documentation**: Wrote all snippet descriptions, usage instructions, and manual application guides.
- **Testing**: Tested all snippets on Omarchy 4.0.2 / Hyprland 0.56.2 with a AMD Ryzen 7 PRO 5850U system.

---

## Based On / Credits

- **[Omarchy](https://github.com/basecamp/omarchy)** — The open-source Arch Linux desktop environment by Basecamp. All snippets are designed as drop-in complements to Omarchy's configuration files (`looknfeel.lua`, `shell.json`, `bindings.lua`). No Omarchy core files are replaced.
- **[Hyprland](https://hyprland.org)** — The Wayland tiling compositor whose configuration system (`decoration`, `animations`, `binds`) these snippets target.
- **[Quickshell](https://quickshell.outfoxxed.me)** — The Qt6 QML desktop shell. The bar layout snippet targets Quickshell's `shell.json` widget configuration.

**Related Repos**:
- [omarchy-motion-presets](https://github.com/aarushdalal/omarchy-motion-presets) — 19 Hyprland animation preset Lua files
- [omarchy-theme-transitions](https://github.com/aarushdalal/omarchy-theme-transitions) — GPU GLSL theme transition shaders
- [omarchy-system-pulse](https://github.com/aarushdalal/omarchy-system-pulse) — System telemetry center-island widget
- [omarchy-aesthetic-themes](https://github.com/aarushdalal/omarchy-aesthetic-themes) — Anime color themes and live wallpapers

---

## Repository Structure

```
omarchy-shell-polish/
├── snippets/
│   ├── looknfeel-glass.lua       # Frosted glass blur + opacity parameters
│   ├── shell-bar-layout.json     # Center island floating bar layout
│   └── bindings-ergonomic.lua    # Ergonomic keybinding set
├── assets/showcase/
├── docs/
├── install.sh
└── CHANGELOG.md
```

---

## Snippets Overview

### 1. Frosted Glass (`snippets/looknfeel-glass.lua`)

Hyprland `decoration` parameters for frosted glass window and layer blur:

- Blur radius, passes, and `layerrule blur` targets for the Omarchy top bar and pop-ups.
- Window opacity tuned for terminals and editors.
- Shadow spread and color matched to active Omarchy theme accent.

Apply by merging into `~/.config/hypr/looknfeel.lua` and running `hyprctl reload`.

### 2. Floating Bar Layout (`snippets/shell-bar-layout.json`)

A `shell.json` layout snippet for the Omarchy Quickshell bar:

- Places `daemon0.system-pulse` as the center anchor.
- Balances left cluster (workspaces, active window) and right cluster (cloud sync, config time machine, tray, clock).

Merge into `~/.config/omarchy/shell.json` and run `omarchy-restart-shell`.

### 3. Ergonomic Keybindings (`snippets/bindings-ergonomic.lua`)

A conflict-free, fully-audited Hyprland keybinding set:

- Restores core Omarchy defaults: `SUPER + T` (float toggle), `SUPER + P` (pseudo), `SUPER + S` (scratchpad), `SUPER + SHIFT + SPACE` (top bar toggle).
- Maps universal shortcuts: media playback (`SUPER + \`), app launcher (`SUPER + D`), LazyGit (`SUPER + CTRL + G`), Config Time Machine (`SUPER + ALT + H`), screenshot (`SUPER + SHIFT + S`), Study Focus (`SUPER + CTRL + ALT + S`).
- Eliminates duplicate volume key dispatches and conflicting application hotkeys.

Apply by merging into `~/.config/hypr/bindings.lua` and running `hyprctl reload`.

---

## Requirements

- **Omarchy** `dev (13f18b2c) / 4.0.2`
- **Hyprland** `0.56.2`
- **Quickshell** `0.3.1`

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
   cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak
   ```
3. Copy desired snippets into your configuration files:
   ```bash
   # Example — merge glass snippet
   cat snippets/looknfeel-glass.lua >> ~/.config/hypr/looknfeel.lua
   hyprctl reload
   ```

---

## Showcase

**Omarchy Desktop Showcase** (click to view)

<video src="./assets/showcase/omarchy_intro_showcase.webm" autoplay loop muted width="100%"></video>

---

## License

[MIT License](LICENSE).
omarchy-shell-polish/assets/showcase/omarchy_intro_showcase.webm