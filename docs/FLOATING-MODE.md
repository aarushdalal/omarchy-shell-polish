# Floating Desktop Mode (Windows & macOS Experience on Omarchy)

> **Unofficial / Community Refinement**: A complete guide and drop-in configuration for enabling the traditional floating desktop window management experience on Omarchy and Hyprland.

---

## Overview

While Omarchy defaults to auto-tiling (Dwindle) and horizontal panning (Scrolling), many workflows—especially multi-window authoring, design tools, file triage, and casual browsing—feel significantly more natural with a freeform floating layout reminiscent of **Microsoft Windows** and **Apple macOS**.

In Floating Mode:
- **Freeform Windows**: Windows float freely, overlap naturally, and can be moved and resized with familiar mouse or keyboard gestures.
- **Native Titlebars (`hyprbars`)**: Every window gains a native titlebar with theme-matched accents and standard window controls: **Close (`×`)**, **Maximize/Restore (`□`)**, and **Minimize (`−`)**.
- **Interactive Desktop Dock (`omarchy.dock`)**: Minimized windows tuck into the bottom dock (macOS Dock / Windows Taskbar style), restoring instantly when clicked.
- **Elevation & Shadows**: Balanced drop shadows provide depth perception between overlapping windows.
- **Solid Opacity**: Floating windows enforce opaque surface content so background text never creates distracting bleed-through.

---

## Layout Comparison Matrix

| Feature | Tiling (Dwindle) | Scrolling (PaperWM) | Floating Mode (Windows/macOS) |
|---|---|---|---|
| **Window Arrangement** | Automatic grid partition | Infinite horizontal strip | Freeform floating canvas & overlap |
| **Window Controls** | Keyboard shortcuts | Keyboard / column swipe | Titlebar buttons: Close, Maximize, Minimize |
| **Double-Click Titlebar** | N/A | Focus column | Toggle maximized fullscreen |
| **Minimization Shelf** | Scratchpad (`SUPER + S`) | Column collapse | Bottom interactive Dock (`omarchy.dock`) |
| **Window Snapping** | Automatic | Automatic | Manual drag & drop / edge snap |
| **Best For** | Code editing, CLI splits | Linear reader, wide sheets | Office apps, media, multi-window triage |

---

## Core Components

### 1. Native Titlebars (`hyprbars`)

When a workspace enters floating mode, Hyprland dynamically enables the `hyprbars` plugin:
- **Titlebar Height**: 30px with theme-adaptive background (`colors.lighter_background` / `selection`) and foreground text.
- **Controls Alignment**: Top-right corner matching standard desktop conventions:
  - **`×` (Close)**: Dispatches `hl.dsp.window.close()`.
  - **`□` (Maximize / Restore)**: Dispatches `hl.dsp.window.fullscreen(mode="maximized")`.
  - **`−` (Minimize to Dock)**: Dispatches `omarchy-hyprland-window-minimize %WINDOW%`.
- **Double-Click**: Double-clicking the titlebar maximizes the window to fill the workspace, or restores it to its previous floating geometry.

### 2. Desktop Dock (`omarchy.dock`)

The interactive dock automatically appears on floating workspaces:
- Serves as the **minimization shelf**: Clicking any minimized window thumbnail or icon brings it back into focus.
- Hosts **pinned applications** for one-click launching.
- Configurable via the `omarchy dock` CLI:
  ```bash
  # Check or change dock position
  omarchy dock position bottom    # options: top | bottom | left | right

  # Toggle or enable auto-hide
  omarchy dock autohide on        # options: on | off | toggle

  # Pin or unpin applications
  omarchy dock pin org.gnome.Nautilus
  omarchy dock unpin org.gnome.Nautilus

  # List pinned applications
  omarchy dock pinned
  ```

### 3. Visual Depth & Opacity Rules

Overlapping floating windows require visual separation to avoid cognitive fatigue:
- **Drop Shadows**: Configured with a 16px soft spread (`render_power = 3`, `rgba(0,0,0,0.21)`).
- **Opaque Surface Override**: Unlike tiled windows which may use subtle frosted transparency, floating workspace windows are forced to `1.0` active opacity so overlapping documents remain completely legible.

---

## Keybindings & Shortcuts

| Shortcut | Description | Action |
|---|---|---|
| `SUPER + L` | **Cycle Layout Forward** | Dwindle → Scrolling → **Floating** |
| `SUPER + ALT + L` | **Cycle Layout Backward** | Floating → Scrolling → Dwindle |
| `SUPER + T` | **Toggle Window Float** | Float/tile current window only |
| `SUPER + Left-Click Drag` | **Move Window** | Drag floating window freely |
| `SUPER + Right-Click Drag` | **Resize Window** | Resize floating window from any edge |
| `Double-Click Titlebar` | **Maximize / Restore** | Toggle window maximized state |

---

## Manual Installation & Usage

### Step 1: Add Ergonomic Keybindings
Merge the bindings from [`snippets/bindings-ergonomic.lua`](../snippets/bindings-ergonomic.lua) into `~/.config/hypr/bindings.lua`:
```lua
hl.bind("SUPER", "L", "exec", "omarchy-hyprland-workspace-layout-toggle")
hl.bind("SUPER ALT", "L", "exec", "omarchy-hyprland-workspace-layout-toggle back")
hl.bind("SUPER", "T", "togglefloating")
```
Reload Hyprland:
```bash
hyprctl reload
```

### Step 2: Configure Floating Snippet
Merge [`snippets/floating-mode.lua`](../snippets/floating-mode.lua) into `~/.config/hypr/looknfeel.lua` or `~/.config/hypr/hyprland.lua`.

### Step 3: Configure Dock in Quickshell
Optionally configure your dock preferences in `~/.config/omarchy/shell.json` using [`snippets/shell-dock-layout.json`](../snippets/shell-dock-layout.json):
```json
{
  "dock": {
    "position": "bottom",
    "autohide": false,
    "pinned": [
      "org.gnome.Nautilus",
      "google-chrome",
      "foot",
      "spotify",
      "antigravity"
    ]
  }
}
```
Restart the shell to apply:
```bash
omarchy-restart-shell
```

### Step 4: Toggle & Enjoy
Press **`SUPER + L`** on any workspace until the on-screen HUD displays **Floating Layout**. Your windows now feature draggable titlebars, close/maximize/minimize buttons, and an interactive dock at the bottom!
