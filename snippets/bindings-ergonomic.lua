-- Omarchy Shell Polish: Ergonomic Keybinding Overrides
-- Merge into ~/.config/hypr/bindings.lua
-- Inspect existing bindings first with `hyprctl binds` to verify no conflicts.

-- Window Management
hl.bind("SUPER", "T", "togglefloating")
hl.bind("SUPER", "P", "pseudo")
hl.bind("SUPER", "S", "togglespecialworkspace")
hl.bind("SUPER SHIFT", "SPACE", "exec", "omarchy-shell shell toggle omarchy.bar")

-- Media & System Controls
hl.bind("SUPER", "backslash", "exec", "playerctl play-pause")
hl.bind("SUPER", "M", "exec", "playerctl play-pause")
hl.bind("SUPER ALT", "A", "exec", "switch-audio-profile toggle")

-- Fast Productivity
hl.bind("SUPER", "D", "exec", "omarchy-menu toggle apps")
hl.bind("SUPER", "B", "exec", "omarchy-launch-browser")
hl.bind("SUPER ALT", "H", "exec", "omarchy-shell shell toggle daemon0.config-timemachine")
