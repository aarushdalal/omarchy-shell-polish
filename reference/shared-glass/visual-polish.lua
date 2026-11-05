-- Background-only glass in both profiles. Native content stays fully opaque.
-- Override avoids multiplying several older opacity rules together.
hl.config({
  decoration = {
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,
    blur = {
      enabled = true,
      size = 4,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
      noise = 0.008,
      contrast = 0.95,
      brightness = 1.0,
      vibrancy = 0.08,
      popups = true,
    },
  },
})
hl.window_rule({
  match = { class = ".*" },
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


-- GTK 4.24 otherwise advertises an empty blur region to Hyprland 0.56.
-- Keep the user-approved gentle compositor blur consistent for GTK apps too.
hl.env("GDK_WAYLAND_DISABLE", "ext_background_effect_manager_v1")
