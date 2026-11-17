-- Omarchy Shell Polish: Floating Mode (Windows & macOS-style Desktop UX)
-- Merge into ~/.config/hypr/hyprland.lua or ~/.config/hypr/looknfeel.lua
-- This configures the floating workspace mode, macOS-style traffic light titlebars,
-- native mouse edge/corner resizing, drop-shadow depth, and solid opacity.

-- 1. Window elevation & drop shadow for floating window depth
hl.config({
  decoration = {
    shadow = {
      enabled = true,
      range = 16,
      render_power = 3,
      color = "rgba(00000035)",
    },
  },
})

-- 2. Native edge & corner mouse resizing (macOS & Windows style)
hl.config({
  general = {
    resize_on_border = true,
    extend_border_grab_area = 18,
    hover_icon_on_border = true,
  },
})

-- 3. Keep floating window contents crisp & fully opaque so overlapping text
-- never bleeds through or creates visual noise.
hl.window_rule({
  match = { tag = "workspace-floated" },
  opacity = "1.0 override 1.0 override",
  no_shadow = false,
})

-- 4. Hyprbars native window titlebars (macOS Traffic Light controls)
-- Loaded dynamically when floating workspaces are active.
local function setup_titlebars()
  if not hl.plugin or not hl.plugin.hyprbars then
    return
  end

  local window = [[window = "address:%WINDOW%"]]

  hl.config({
    plugin = {
      hyprbars = {
        enabled = true,
        workspace_tag = "workspace-floated",
        bar_height = 30,
        bar_text_font = "sans-serif",
        bar_text_size = 11,
        bar_text_weight = "bold",
        bar_text_align = "center",
        bar_buttons_alignment = "left",
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        bar_padding = 12,
        bar_button_padding = 8,
        button_rounding = 12,
        icon_on_hover = true,
        on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. window .. " })'",
      },
    },
  })

  -- macOS Traffic Light Buttons: Red (Close), Yellow (Minimize), Green (Maximize)
  local buttons = {
    { icon = "×", bg = "rgba(ff5f57ee)", fg = "rgba(4a0002ee)", action = "hyprctl dispatch 'hl.dsp.window.close({ " .. window .. " })'" },
    { icon = "−", bg = "rgba(febc2eee)", fg = "rgba(4a3900ee)", action = "omarchy-hyprland-window-minimize %WINDOW%" },
    { icon = "＋", bg = "rgba(28c840ee)", fg = "rgba(02380dee)", action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. window .. " })'" },
  }

  for _, button in ipairs(buttons) do
    hl.plugin.hyprbars.add_button({
      bg_color = button.bg,
      fg_color = button.fg,
      size = 13,
      icon = button.icon,
      action = button.action,
    })
  end
end

pcall(setup_titlebars)
