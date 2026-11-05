# Optional shared glass references

Version 1.6 keeps normal app content at 100% opacity and uses application-native background transparency, superseding the earlier whole-window fading preset. Merge visual-polish.lua last into the desired Hyprland 0.56 Lua profiles; retain a before copy and validate both profiles plus hyprctl configerrors. The general installer does not apply this reference.

Shared blur uses size 4 / two passes, optimization enabled and restrained contrast/noise. The GTK 4.24 workaround disables its empty background-effect region advertisement, allowing the compositor to supply blur. Native background settings are in [background-glass](../background-glass/README.md). Applications without native alpha remain opaque. No pet window rule is included.

shell-materials.toml remains an optional semantic material reference. Merge its keys into existing sections and retain theme RGB, type, borders and per-theme roles. picker-layout.ini is a layout-only Fuzzel reference: retain current colors and a readable translucent backing; validate with fuzzel --check-config.

No compositor FPS, power saving or universal performance improvement is claimed. Session-lock privacy and authentication remain separate; the adjacent modern-lock reference does not change the authentication host.

Syntax: https://wiki.hypr.land/configuring/core/rules/window-rules/ and https://wiki.hypr.land/configuring/core/config-options/
