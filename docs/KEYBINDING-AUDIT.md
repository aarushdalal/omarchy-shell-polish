# Keybinding Audit & Ergonomic Remapping

## Principle: Never Assume a Keybinding is Free

Before applying any keybinding customization, inspect all active bindings in your compositor:

```bash
hyprctl binds | grep -E 'bind: (SUPER|MOD4)'
```

## Potential Conflicts Checked

| Shortcut | Default Action | Ergonomic Remapping | Conflict Risk |
|---|---|---|---|
| `SUPER + T` | Terminal in some setups | Toggle floating (Omarchy default) | Check terminal hotkey |
| `SUPER + P` | Application runner | Pseudo tile (Omarchy default) | Check runner hotkey |
| `SUPER + D` | Runner / Launcher | `omarchy-menu toggle apps` | Safe override |
| `SUPER + ALT + H` | None | Config Time Machine panel | Safe |
