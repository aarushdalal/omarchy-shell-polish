# Omarchy Shell Polish (`omarchy-shell-polish`)

> **Unofficial / Community Refinement**: A curated collection of Hyprland and Omarchy shell configuration snippets for frosted glass aesthetics, floating bar layout, Pixel floating bubble, macOS traffic-light window controls, and ergonomic keybinding polish.

Version 1.9 adds the **Virtualized 11-Delegate Arc Deck & Space-in-Search Filtering** (`plugins/community.image-picker/`):
- **Virtualized Ring Buffer Pool**: Re-architects `ImagePicker.qml` to instantiate an 11-delegate ring buffer pool (`Math.min(11, count)`), reducing GUI thread QML allocations by 99.6% across large libraries (from 50,000+ objects down to 11 live delegates) and eliminating opening freeze (<100ms instant presentation).
- **Space-in-Search & Multi-Term Matching**: Solves space key interception by allowing space character entry during active search without triggering peek mode. Dynamically routes Peek to `Space` when idle and `Ctrl+Space` when typing, with an adaptive bottom shortcut dock. Adds multi-token keyword searching in `ImagePickerModel.js`.

Version 1.8 adds the **Pixel Minimized Bubble & macOS Window Controls**: a Google Pixel / Material 3 floating minimized app bubble with horizontal hover expansion and multi-workspace isolation, macOS traffic-light window buttons (🔴 Close, 🟡 Minimize, 🟢 Maximize), native border and diagonal corner mouse resizing, keyboard resize shortcuts, smart snapping with toggle-unsnap memory, and clean layout isolation. See [Floating Mode Guide](docs/FLOATING-MODE.md).

Version 1.7 adds the **Windows & macOS-style Floating Desktop Experience**: freeform floating window management, native `hyprbars` titlebars with Close (`×`), Maximize (`□`), and Minimize (`−`) buttons, titlebar double-click maximization, an interactive bottom desktop dock (`omarchy.dock`) acting as the minimization shelf and pinned app launcher, drop shadows for depth, solid opacity overrides, and seamless layout cycling (`SUPER + L` / `SUPER + ALT + L`).

Version 1.6 adds native background-only glass for Spotify, Files, ChatGPT, the AntiGravity app and Foot, with solid foreground content and gentle compositor blur. Spotify fullscreen color backdrops and decorative gradients are removed. See [background glass setup](reference/background-glass/README.md) and [Spotify live sync](reference/spotify-sync/README.md). The optional [universal monitor](reference/background-glass/universal/README.md) covers current/future installed desktop apps and notifies when a native theme recipe is missing. Pet changes are excluded.

Version 1.4 adds a quieter shared glass material, compact menu motion, a Caelestia SearchBar refinement and an optional minimal live-status lock view. See [balanced glass references](reference/shared-glass/README.md) and [lock integration boundaries](reference/modern-lock/README.md).

Version 1.1 adds preset-aware native controls for Omarchy and a Caelestia overlay for DaemonOS. It preserves both desktop identities and retains the original optional snippets. See [Refinement and rollback](docs/REFINEMENT.md) and [component licensing](docs/COMPONENT-PROVENANCE.md).

This project was developed through an AI-assisted workflow. The concept, customization, configuration, testing, integration, and final iteration were directed and carried out by me.

---

## My Contribution

I did not write Omarchy, Quickshell, or Hyprland from scratch. What I contributed:

- **Pixel Minimized Bubble Plugin** (`plugins/community.floating-bubble/` & `docs/FLOATING-MODE.md`): Designed and built the Material 3 / Pixel floating bubble in Quickshell QML. Features icons-only display, smooth horizontal hover expansion, strict collision avoidance against maximized windows, and complete multi-workspace isolation so each workspace remembers only its own minimized apps.
- **Virtualized Community Arc Deck Plugin** (`plugins/community.image-picker/`): Engineered the 11-delegate ring buffer pool algorithm and space-in-search multi-term filtering, dropping QML items by 99.6% across large catalogs and enabling instant deck presentation without compositor freeze.
- **macOS Traffic Light Titlebars** (`snippets/floating-mode.lua`): Integrated circular traffic-light window controls (🔴 Close, 🟡 Minimize, 🟢 Maximize) with hover icons and titlebar double-click maximization.
- **Native Window Resizing Polish**: Configured `resize_on_border = true` and `extend_border_grab_area = 18` for effortless mouse edge and corner dragging, plus directional keyboard resize bindings (<kbd>SUPER</kbd> + <kbd>CTRL</kbd> + Arrows/`+`/`-`).
- **Smart Snapping & Unsnapping Engine** (`bin/omarchy-hyprland-window-snap`): Built snapping with toggle geometry memory, returning windows to their exact pre-snap floating position when re-triggered.
- **Minimization & Restore Tools** (`bin/omarchy-hyprland-window-minimize` & `bin/omarchy-hyprland-window-restore`): Implemented reliable workspace tagging and restore dispatching across special workspaces.
- **Ergonomic Keybindings Snippet** (`snippets/bindings-ergonomic.lua`): Audited and wired workspace layout cycling (`SUPER + L` / `SUPER + ALT + L` for Tiling -> Scrolling -> Floating), snapping, resizing, and window restore.
- **Frosted Glass Snippet** (`snippets/looknfeel-glass.lua`): Tuned Hyprland `decoration` parameters — blur radius, passes, layerrule blur targets, window opacity, and shadow settings — to produce a frosted glass aesthetic on Wayland.
- **Floating Bar Layout Snippet** (`snippets/shell-bar-layout.json`): Designed a `shell.json` layout configuration placing a center island telemetry widget (`daemon0.system-pulse`) with balanced left and right widget clusters for the Omarchy Quickshell bar.
- **Interactive Dock Layout Snippet** (`snippets/shell-dock-layout.json`): Configured the Quickshell desktop dock for pinned apps and minimization shelf.
- **Testing & Verification**: Automated unit tests and test suites covering all snippets, plugins, and helper scripts.

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
├── bin/
│   ├── omarchy-hyprland-window-minimize    # Tag and minimize floating windows
│   ├── omarchy-hyprland-window-restore     # Restore latest, all, or specific windows
│   └── omarchy-hyprland-window-snap        # Snap left/right/center with unsnap memory
├── plugins/
│   └── community.floating-bubble/          # Pixel / Material 3 floating minimized bubble
│       ├── manifest.json
│       ├── Service.qml
│       └── FloatingBubbleWindow.qml
├── snippets/
│   ├── floating-mode.lua                   # macOS traffic lights, edge resizing, shadows
│   ├── shell-dock-layout.json              # Interactive dock configuration & pinned apps
│   ├── looknfeel-glass.lua                 # Frosted glass blur + opacity parameters
│   ├── shell-bar-layout.json               # Center island floating bar layout
│   └── bindings-ergonomic.lua              # Ergonomic keybindings (Super+L, resize, snap)
├── docs/
│   ├── FLOATING-MODE.md                    # Comprehensive Floating Desktop UX guide
│   ├── RELEASE-NOTES.md                    # Version release highlights
│   ├── BAR-POLISH.md                       # Top bar and bottom dock layout guide
│   └── KEYBINDING-AUDIT.md                 # Conflict-free keybinding audit table
├── tests/                                  # Automated regression test suites
├── install.sh
├── VERSION
└── CHANGELOG.md
```

---

## Snippets Overview

### 1. Floating Desktop Mode (`snippets/floating-mode.lua`)

Transforms any workspace into a freeform floating desktop experience:

- Native `hyprbars` window titlebars with macOS traffic light controls: Close (`🔴 ×`), Minimize (`🟡 −`), and Maximize (`🟢 ＋`).
- Double-clicking titlebars toggles maximized state.
- Native border and corner grab areas for smooth mouse resizing (`resize_on_border = true`).
- Drop shadows (`range: 16`, `render_power: 3`) for natural visual depth across overlapping windows.
- Solid opacity override (`1.0`) ensuring background documents never bleed through.
- Detailed guide: [docs/FLOATING-MODE.md](docs/FLOATING-MODE.md).

### 2. Ergonomic Keybindings (`snippets/bindings-ergonomic.lua`)

A conflict-free, fully-audited Hyprland keybinding set:

- **Workspace Layout Cycling**: `SUPER + L` (Cycle forward: Tiling → Scrolling → **Floating**), `SUPER + ALT + L` (Cycle backward).
- **Window Snapping**: `SUPER + ALT + Left/Right/Down/Up` (Snap left/right, center/unsnap, maximize).
- **Keyboard Resizing**: `SUPER + CTRL + Arrows` (width/height), `SUPER + CTRL + =/-` (diagonal whole size).
- **Window Restore Engine**: `SUPER + CTRL + M` (restore latest), `SUPER + CTRL + SHIFT + M` (restore all on workspace).
- **Window Management**: `SUPER + T` (float single window), `SUPER + P` (pseudo), `SUPER + S` (scratchpad), `SUPER + SHIFT + SPACE` (top bar toggle).

### 3. Frosted Glass (`snippets/looknfeel-glass.lua`)

Hyprland `decoration` parameters for frosted glass window and layer blur:

- Blur radius, passes, and `layerrule blur` targets for the Omarchy top bar and pop-ups.
- Window opacity tuned for terminals and editors.
- Shadow spread and color matched to active Omarchy theme accent.

Apply by merging into `~/.config/hypr/looknfeel.lua` and running `hyprctl reload`.

### 4. Floating Bar Layout (`snippets/shell-bar-layout.json`)

A `shell.json` layout snippet for the Omarchy Quickshell bar:

- Places `daemon0.system-pulse` as the center anchor.
- Balances left cluster (workspaces, active window) and right cluster (cloud sync, config time machine, tray, clock).

Merge into `~/.config/omarchy/shell.json` and run `omarchy-restart-shell`.

### 5. Interactive Desktop Dock (`snippets/shell-dock-layout.json`)

A `shell.json` dock snippet for floating workspaces:

- Surfaces on floating workspaces as the dedicated shelf for minimized windows and pinned quick-launch applications.
- Supports bottom, top, left, or right positioning and auto-hide mode.

Merge into `~/.config/omarchy/shell.json` under `"dock"` and run `omarchy-restart-shell`.

---

## Requirements

- **Omarchy** `4.5.0` / Hyprland `0.56.2` / Quickshell `0.3.1`
- Arch Linux rolling base
