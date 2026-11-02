# Optional balanced glass references

These are opt-in references and are not applied by the installer. Merge the TOML keys into existing sections in `~/.config/omarchy/shell.toml`; do not replace other settings. RGB, type, borders and per-theme roles continue to come from the current theme. The user override survives theme changes.

For Hyprland 0.56 Lua, place `visual-polish.lua` in `~/.config/hypr/shared/` and load it last from each desired desktop profile with `require("hypr.shared.visual-polish")`. Verify both complete configurations and check the active compositor's configuration errors before keeping it. The rules intentionally affect all normal app windows, including fullscreen windows; they change complete-window opacity rather than rewriting application content. Focused/inactive/fullscreen values are 75/70/82 percent. Existing per-app opacity exceptions are overridden. Keep an exact copy of your previous config to restore a different preference.

Blur is enabled with size 12 / three passes, optimization enabled and restrained contrast/noise. This is a material choice; no compositor FPS, power saving or universal performance improvement is claimed. Session-lock privacy and authentication remain separate. The optional lock view is in the adjacent modern-lock reference.

Syntax references: https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/ and https://wiki.hypr.land/configuring/core/config-options/

`picker-layout.ini` is a layout-only Fuzzel reference. Merge its keys with the current theme colors; use a near-opaque translucent background (for example alpha `ed`) and validate with `fuzzel --check-config`. The host power menu retains its existing actions and policy.
