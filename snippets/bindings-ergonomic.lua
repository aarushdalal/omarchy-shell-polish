-- Omarchy Shell Polish: Ergonomic Keybinding Overrides
-- Merge into ~/.config/hypr/bindings.lua
-- Inspect existing bindings first with `hyprctl binds` to verify no conflicts.

-- Workspace Layout & Floating Desktop UX (Windows & macOS-style)
hl.bind("SUPER", "L", "exec", "omarchy-hyprland-workspace-layout-toggle")
hl.bind("SUPER ALT", "L", "exec", "omarchy-hyprland-workspace-layout-toggle back")

-- Window Management
hl.bind("SUPER", "T", "togglefloating")
hl.bind("SUPER", "P", "pseudo")
hl.bind("SUPER", "S", "togglespecialworkspace")
hl.bind("SUPER SHIFT", "SPACE", "exec", "omarchy-shell shell toggle omarchy.bar")

-- Floating Window Snapping (Left, Right, Center/Unsnap, Maximize)
hl.bind("SUPER ALT", "Left", "exec", "omarchy-hyprland-window-snap left")
hl.bind("SUPER ALT", "Right", "exec", "omarchy-hyprland-window-snap right")
hl.bind("SUPER ALT", "Down", "exec", "omarchy-hyprland-window-snap center")
hl.bind("SUPER ALT", "Up", "exec", "omarchy-hyprland-window-snap maximize")

-- Floating Window Resizing (Width, Height, and Diagonal Whole Size)
hl.binde("SUPER CTRL", "Left", "resizeactive", "-40 0")
hl.binde("SUPER CTRL", "Right", "resizeactive", "40 0")
hl.binde("SUPER CTRL", "Up", "resizeactive", "0 -40")
hl.binde("SUPER CTRL", "Down", "resizeactive", "0 40")
hl.binde("SUPER CTRL", "equal", "resizeactive", "40 40")
hl.binde("SUPER CTRL", "minus", "resizeactive", "-40 -40")

-- Minimized Window Restore Engine
hl.bind("SUPER CTRL", "M", "exec", "omarchy-hyprland-window-restore --latest")
hl.bind("SUPER CTRL SHIFT", "M", "exec", "omarchy-hyprland-window-restore --all")

-- Media & System Controls
hl.bind("SUPER", "backslash", "exec", "playerctl play-pause")
hl.bind("SUPER", "M", "exec", "playerctl play-pause")
hl.bind("SUPER ALT", "A", "exec", "switch-audio-profile toggle")

-- Fast Productivity
hl.bind("SUPER", "D", "exec", "omarchy-menu toggle apps")
hl.bind("SUPER", "B", "exec", "omarchy-launch-browser")
hl.bind("SUPER ALT", "H", "exec", "omarchy-shell shell toggle daemon0.config-timemachine")
