local wezterm = require 'wezterm'
local c = {}
local config = c

-- To see if there are issues with font rendering
front_end = "WebGpu"

c.enable_scroll_bar = true
c.enable_tab_bar = false
c.font = wezterm.font'DejaVu Sans Mono'
c.font_size = 12
c.enable_wayland = false

local colors = wezterm.color.get_default_colors()
colors.background = 'black'
colors.foreground = 'white'
c.colors = colors

return c
