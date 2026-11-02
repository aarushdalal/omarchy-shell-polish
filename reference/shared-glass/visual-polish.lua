-- User-requested balanced glass for application windows in both desktop profiles.
-- Override avoids multiplying several older opacity rules together.
hl.config({
  decoration = {
    active_opacity = 0.75,
    inactive_opacity = 0.70,
    fullscreen_opacity = 0.82,
    blur = {
      enabled = true,
      size = 12,
      passes = 3,
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
  opacity = "0.75 override 0.70 override 0.82 override",
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
