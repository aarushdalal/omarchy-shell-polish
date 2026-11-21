-- Omarchy Shell Polish: Frosted Glass Opacity & Blur Preset
-- Merge into ~/.config/hypr/looknfeel.lua or load via ~/.config/hypr/hyprland.lua

hl.config({
  decoration = {
    active_opacity = 0.80,
    inactive_opacity = 0.70,
    fullscreen_opacity = 0.80,
    blur = {
      enabled = true,
      size = 7,
      passes = 3,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
      noise = 0.012,
      contrast = 0.92,
      brightness = 0.90,
      vibrancy = 0.30,
      popups = true,
    },
  },
})

-- Terminals: crisp translucent frosted glass with wallpaper visibility
hl.window_rule({
  match = { class = "^(kitty|org\\.omarchy\\.agent|foot|org\\.codeberg\\.dnkl\\.foot|Alacritty|com\\.mitchellh\\.ghostty)$" },
  opacity = "0.75 override 0.65 override 0.75 override",
  no_blur = false,
})

-- File Managers: Nautilus, Thunar, and file pickers
hl.window_rule({
  match = { class = "^(org\\.gnome\\.Nautilus|nautilus|thunar|Thunar|org\\.gnome\\.NautilusPreviewer)$" },
  opacity = "0.75 override 0.65 override 0.75 override",
  no_blur = false,
})

hl.window_rule({
  match = { class = "xdg-desktop-portal-gtk" },
  opacity = "0.80 override 0.70 override 0.80 override",
  no_blur = false,
})

-- Code Editors & IDEs
hl.window_rule({
  match = { class = "^(Antigravity|antigravity|antigravity-ide|code|Code|com\\.microsoft\\.VSCode)$" },
  opacity = "0.80 override 0.70 override 0.80 override",
  no_blur = false,
})

-- Notes & Markdown
hl.window_rule({
  match = { class = "^(obsidian|Obsidian)$" },
  opacity = "0.78 override 0.68 override 0.78 override",
  no_blur = false,
})

-- Chat & AI Tools
hl.window_rule({
  match = { class = "^(chatgpt|ChatGPT)$" },
  opacity = "0.78 override 0.68 override 0.78 override",
  no_blur = false,
})

hl.window_rule({
  match = { class = "^(discord|vesktop|WhatsApp)$" },
  opacity = "0.80 override 0.70 override 0.80 override",
  no_blur = false,
})

-- Music & Audio
hl.window_rule({
  match = { class = "^(Spotify|spotify)$" },
  opacity = "0.78 override 0.68 override 0.78 override",
  no_blur = false,
})

-- System Monitors & Floating Utilities
hl.window_rule({
  match = { class = "^(btop|org\\.omarchy\\.btop|omacalc|org\\.omarchy\\.about)$" },
  opacity = "0.78 override 0.68 override 0.78 override",
  no_blur = false,
})

-- Web browsers, media players, and games stay strictly opaque
hl.window_rule({
  match = { class = "^(mpv|vlc|losslesscut-bin|imv|steam|RetroArch)$" },
  opacity = "1.0 override 1.0 override 1.0 override",
  no_blur = false,
})

hl.layer_rule({
  match = { namespace = "^(omarchy-.*|caelestia-.*|quickshell|fuzzel)$" },
  blur = true,
  ignore_alpha = 0.20,
})

hl.layer_rule({
  match = { namespace = "fuzzel" },
  no_anim = false,
  animation = "popin 96%",
})

-- GTK 4.24 workaround: disable empty background-effect region advertisement
hl.env("GDK_WAYLAND_DISABLE", "ext_background_effect_manager_v1")
