local theme = {}

theme.wallpaper = path.."Background.png"
theme.font = "/usr/share/fonts/TTF/iosevka-regular.ttf"

local white = "#efe6eb"
local black = "#141311"
local orange = "#da8e6a"

theme.fg_normal 	= white
theme.fg_focus 		= white
theme.fg_urgent 	= white
theme.fg_minimize 	= white
theme.fg_systray 	= white

theme.bg_normal 	= black
theme.bg_focus	 	= black
theme.bg_urgent 	= black
theme.bg_minimize 	= black

theme.titlebar_fg   = orange
theme.titlebar_bg   = black

theme.border_normal = black
theme.border_focus 	= black
theme.border_width  = 0
theme.border_fwidth = 0
theme.master_width_factor = 0.61

return theme