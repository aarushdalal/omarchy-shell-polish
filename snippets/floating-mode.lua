-- Omarchy Shell Polish: Floating Mode (Windows & macOS-style Desktop UX)
-- Merge into ~/.config/hypr/hyprland.lua or ~/.config/hypr/looknfeel.lua
-- This configures the floating workspace mode, native hyprbars titlebars,
-- drop-shadow depth, and solid opacity for clean overlapping windows.

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

-- 2. Keep floating window contents crisp & fully opaque so overlapping text
-- never bleeds through or creates visual noise.
hl.window_rule({
  match = { tag = "workspace-floated" },
  opacity = "1.0 override 1.0 override",
  no_shadow = false,
})

-- 3. Hyprbars native window titlebars (Close, Maximize/Restore, Minimize to Dock)
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
        bar_text_weight = "normal",
        bar_text_align = "left",
        bar_buttons_alignment = "right",
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        bar_padding = 10,
        bar_button_padding = 8,
        button_rounding = 0,
        icon_on_hover = false,
        on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. window .. " })'",
      },
    },
  })

  -- Native Window Control Buttons (Close, Maximize/Restore, Minimize to Dock)
  local buttons = {
    { icon = "×", action = "hyprctl dispatch 'hl.dsp.window.close({ " .. window .. " })'" },
    { icon = "□", action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. window .. " })'" },
    { icon = "−", action = "omarchy-hyprland-window-minimize %WINDOW%" },
  }

  for _, button in ipairs(buttons) do
    hl.plugin.hyprbars.add_button({
      size = 20,
      icon = button.icon,
      action = button.action,
    })
  end
end

pcall(setup_titlebars)
