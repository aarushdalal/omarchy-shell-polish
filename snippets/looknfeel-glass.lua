-- Omarchy Shell Polish: Frosted Glass & Border Snippet
-- Append or merge into ~/.config/hypr/looknfeel.lua

hl.config({
  general = {
    border_size = 2,
    gaps_in = 5,
    gaps_out = 10,
  },
  decoration = {
    rounding = 12,
    dim_inactive = true,
    dim_strength = 0.10,

    blur = {
      enabled = true,
      size = 7,
      passes = 3,
      new_optimizations = true,
      xray = false,
      ignore_opacity = true,
      noise = 0.012,
      contrast = 0.92,
      brightness = 0.88,
      vibrancy = 0.30,
      popups = true,
    },

    shadow = {
      enabled = true,
      range = 20,
      render_power = 2,
      color = "rgba(00000038)",
    },
  },
})
