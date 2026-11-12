# Floating Bar, Dock & Panel Polish Guide

## Recommended Layout

Omarchy's Quickshell bar supports three zones: `left`, `center`, and `right`.
- **Left**: Stable anchors (Omarchy menu, Workspaces).
- **Center**: Prominent telemetry or center island (`daemon0.system-pulse`).
- **Right**: Action widgets, focus timer, cloud sync, audio controls, power.

## Floating Mode & Bottom Dock Integration

When a workspace is switched to **Floating Mode** (`SUPER + L`), the top bar works in tandem with the bottom interactive dock (`omarchy.dock`):
- **Top Bar**: Displays active workspace indicators, layout glyphs, system telemetry, and system tray.
- **Bottom Dock**: Automatically surfaces on floating workspaces to host pinned applications and provide a dedicated shelf for minimized windows, matching macOS and Windows desktop workflows.
- See the complete [Floating Mode Guide](FLOATING-MODE.md) for full configuration, titlebar setup, and keybindings.

## Safety & Backup Notice

Before modifying `~/.config/omarchy/shell.json`, always create a timestamped backup:
```bash
cp ~/.config/omarchy/shell.json ~/.config/omarchy/shell.json.backup.$(date +%Y%m%d_%H%M%S)
```
