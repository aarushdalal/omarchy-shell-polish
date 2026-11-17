# Floating Desktop Mode (Windows & macOS Experience on Omarchy)

> **Community Refinement**: A complete guide and drop-in configuration for enabling the traditional floating desktop window management experience on Omarchy and Hyprland, featuring macOS traffic light controls, Google Pixel / Material 3 minimized floating bubbles, native mouse/keyboard window resizing, smart snapping with unsnap memory, and multi-workspace multitasking isolation.

---

## Overview

While Omarchy defaults to auto-tiling (Dwindle) and horizontal panning (Scrolling), many workflows—especially multi-window authoring, design tools, file triage, and casual browsing—feel significantly more natural with a freeform floating layout reminiscent of **Microsoft Windows** and **Apple macOS**.

In Floating Mode:
- **Freeform Windows**: Windows float freely, overlap naturally, and can be moved and resized with familiar mouse or keyboard gestures.
- **macOS Traffic Light Titlebars (`hyprbars`)**: Every window gains native circular traffic light controls on the top-left: **Close (`🔴 ×`)**, **Minimize (`🟡 −`)**, and **Maximize/Restore (`🟢 ＋`)**.
- **Pixel / Material 3 Minimized Bubble (`community.floating-bubble`)**: Minimized windows tuck into an adaptive floating bubble in the bottom-right corner. It displays strictly application icons (no text), expands horizontally on hover, and **never obscures a maximized or fullscreen window**.
- **Multi-Workspace Isolation**: Each workspace remembers its own minimized windows with its own bubble. Switching workspaces keeps minimized windows cleanly isolated per desktop, allowing seamless multitasking between floating and tiling workspaces.
- **Native Border & Corner Resizing**: Smooth mouse resizing from any window edge or corner, plus fine-grained keyboard resizing shortcuts.
- **Smart Window Snapping & Unsnapping**: Snap windows to the left or right half, center, or toggle-unsnap back to previous floating coordinates.
- **Elevation & Shadows**: Balanced drop shadows provide depth perception between overlapping windows.
- **Solid Opacity**: Floating windows enforce opaque surface content so background text never creates distracting bleed-through.

---

## Layout Comparison Matrix

| Feature | Tiling (Dwindle) | Scrolling (PaperWM) | Floating Mode (Windows/macOS) |
|---|---|---|---|
| **Window Arrangement** | Automatic grid partition | Infinite horizontal strip | Freeform floating canvas & natural overlap |
| **Window Controls** | Keyboard shortcuts | Keyboard / column swipe | macOS Traffic Light dots: 🔴 Close, 🟡 Minimize, 🟢 Maximize |
| **Minimization Shelf** | Scratchpad (`SUPER + S`) | Column collapse | Google Pixel / Material 3 Floating Bubble |
| **Multi-Workspace Memory** | Single workspace scratchpad | Single workspace stack | **Per-workspace isolated bubbles & state** |
| **Window Resizing** | Partition splits | Column width adjustments | Edge/corner mouse dragging & keyboard resize |
| **Window Snapping** | Automatic | Automatic | Edge snap with **toggle-unsnap memory** |
| **Layout Isolation** | Tiled | Strip | Clean transitions without stranded windows |
| **Best For** | Code editing, CLI splits | Linear reading, wide sheets | Office apps, media, multi-window triage, casual use |

---

## Core Components

### 1. macOS Traffic Light Titlebars (`hyprbars`)

When a workspace enters floating mode, Hyprland dynamically enables the `hyprbars` plugin with macOS aesthetic styling:
- **Left-Aligned Controls**: Three circular traffic-light control dots positioned on the top-left:
  - **🔴 Red (`×`)**: Closes the window (`hl.dsp.window.close()`).
  - **🟡 Yellow (`−`)**: Minimizes the window to the Pixel floating bubble (`omarchy-hyprland-window-minimize %WINDOW%`).
  - **🟢 Green (`＋`)**: Toggles window maximization (`hl.dsp.window.fullscreen(mode="maximized")`).
- **Interactive Hover Dots**: The control dots display symbol glyphs on mouse hover (`icon_on_hover = true`) and remain clean solid circles at rest.
- **Double-Click Titlebar**: Double-clicking the titlebar maximizes the window to fill the workspace, or restores it to its previous floating geometry.

### 2. Google Pixel Minimized Bubble (`community.floating-bubble`)

A Material 3 / Pixel-inspired floating bubble located in the bottom-right corner:
- **Strictly Icons Only**: No text labels or titles—clean, modern, unobtrusive application icons.
- **Horizontal Hover Expansion**: Expands smoothly from a single circular badge into an interactive horizontal tray on hover using spring physics (`Easing.OutBack`).
- **System Adaptive**: Scales its dimensions (`bubbleSize`, `iconSize`, `radius`, `margin`) dynamically using the active Omarchy `Style.fontScale` and color scheme.
- **Maximized Window Guard**: Automatically hides whenever any window on the active workspace is maximized or fullscreen, ensuring zero overlap with your active content.
- **Per-Workspace Isolation**: Remembers which workspace each window was minimized from. Switching to another workspace only shows windows minimized from that specific workspace, keeping multiple workspaces organized and conflict-free.
- **Interactive Gestures**:
  - **Left-Click Slot**: Restores the window to the current workspace and focuses it.
  - **Middle-Click / Double-Click Slot**: Restores and immediately maximizes the window.
  - **Right-Click Bubble**: Restores all minimized windows belonging to the current workspace.

### 3. Mouse Edge & Corner Resizing

Native window edge and corner grab areas eliminate clumsy resizing:
- **`resize_on_border = true`**: Hovering near any border or corner switches the cursor to the appropriate resize arrow.
- **`extend_border_grab_area = 18`**: Generous 18px grab zone makes grabbing edges and diagonal corners effortless on high-resolution displays.
- **Corner Resizing**: Dragging any corner resizes width and height simultaneously.

### 4. Smart Window Snapping & Unsnapping

CLI and keybinding engine (`omarchy-hyprland-window-snap`):
- **Half-Screen Snap**: Snap left (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Left</kbd>) or right (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Right</kbd>).
- **Toggle Unsnap Memory**: Snapping a window remembers its pre-snap geometry in `/tmp/omarchy-snap-<address>.json`. Pressing the same snap shortcut again or centering (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Down</kbd>) restores the exact pre-snap dimensions and position.
- **Layout Isolation**: Snapping commands verify that the current workspace is in floating mode; if in tiling or scrolling mode, snapping safely exits to avoid corrupting layout trees.

---

## Keybindings & Shortcuts

| Shortcut | Category | Description | Action |
|---|---|---|---|
| <kbd>SUPER</kbd> + <kbd>L</kbd> | Layout | **Cycle Layout Forward** | Dwindle → Scrolling → **Floating** |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>L</kbd> | Layout | **Cycle Layout Backward** | Floating → Scrolling → Dwindle |
| <kbd>SUPER</kbd> + <kbd>T</kbd> | Window | **Toggle Window Float** | Float or tile current window only |
| <kbd>SUPER</kbd> + <kbd>Left-Click Drag</kbd> | Mouse | **Move Window** | Drag floating window freely |
| <kbd>SUPER</kbd> + <kbd>Right-Click Drag</kbd> | Mouse | **Resize Window** | Freeform resize from any window edge |
| <kbd>Border / Corner Drag</kbd> | Mouse | **Native Edge Resize** | Resize width, height, or diagonal corner |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Left</kbd> / <kbd>Right</kbd> | Resize | **Adjust Width** | Decrease / increase window width |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Up</kbd> / <kbd>Down</kbd> | Resize | **Adjust Height** | Decrease / increase window height |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>=</kbd> / <kbd>-</kbd> | Resize | **Diagonal Whole Size** | Scale window proportionally up / down |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Left</kbd> | Snapping | **Snap Left / Unsnap** | Snap to left half; toggle restores original size |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Right</kbd> | Snapping | **Snap Right / Unsnap** | Snap to right half; toggle restores original size |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Down</kbd> | Snapping | **Center / Unsnap** | Center window or restore pre-snap geometry |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>Up</kbd> | Snapping | **Maximize Window** | Toggle maximized state |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>M</kbd> | Minimization | **Restore Latest Window** | Unminimize latest window onto current workspace |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>SHIFT</kbd> + <kbd>M</kbd> | Minimization | **Restore All Windows** | Unminimize all windows for current workspace |

---

## Installation & Setup

### Step 1: Install Plugin & Binaries
Copy the floating bubble plugin and helper scripts into your configuration:
```bash
# Register floating bubble plugin in ~/.config/omarchy/plugins
mkdir -p ~/.config/omarchy/plugins/daemon0.floating-bubble
cp plugins/community.floating-bubble/* ~/.config/omarchy/plugins/daemon0.floating-bubble/

# Install helper binaries to ~/.local/bin
mkdir -p ~/.local/bin
cp bin/* ~/.local/bin/
chmod +x ~/.local/bin/omarchy-hyprland-window-*
```

### Step 2: Register in `shell.json`
Add the plugin ID to your `~/.config/omarchy/shell.json` plugins list:
```json
{
  "plugins": [
    "daemon0.floating-bubble"
  ]
}
```

### Step 3: Add Ergonomic Keybindings & Look'n'Feel
Merge [`snippets/bindings-ergonomic.lua`](../snippets/bindings-ergonomic.lua) into `~/.config/hypr/bindings.lua` and [`snippets/floating-mode.lua`](../snippets/floating-mode.lua) into `~/.config/hypr/looknfeel.lua`.

Reload Hyprland and Quickshell:
```bash
hyprctl reload
omarchy-restart-shell
```

### Step 4: Toggle & Multitask
Press **`SUPER + L`** to cycle into **Floating Layout**. Minimize any window using the yellow traffic light dot or shortcut; the Pixel bubble will appear in the bottom-right corner. Switch workspaces (<kbd>SUPER</kbd> + <kbd>1</kbd>, <kbd>2</kbd>, etc.) to experience clean, isolated multitasking across floating and tiling desktops!
