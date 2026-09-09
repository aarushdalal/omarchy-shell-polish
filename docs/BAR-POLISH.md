# Floating Bar & Panel Polish Guide

## Recommended Layout

Omarchy's Quickshell bar supports three zones: `left`, `center`, and `right`.
- **Left**: Stable anchors (Omarchy menu, Workspaces).
- **Center**: Prominent telemetry or center island (`daemon0.system-pulse`).
- **Right**: Action widgets, focus timer, cloud sync, audio controls, power.

## Safety & Backup Notice

Before modifying `~/.config/omarchy/shell.json`, always create a timestamped backup:
```bash
cp ~/.config/omarchy/shell.json ~/.config/omarchy/shell.json.backup.$(date +%Y%m%d_%H%M%S)
```
