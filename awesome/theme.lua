local theme = {};

--[[
	COLOURS:
		#dadaad
		#151515
	
		0) #ef473a
		1) #cb2d3e
		2) #870734
		3) #751f68
		4) #f9684a
		5) #ee9c4a
		6) #39aa38
		7) #ffd6bf
		-) #313131
--]]

theme.wallpaper = path.."Background.png";
theme.font = "/usr/share/fonts/TTF/RobotoMono-Thin 10";

theme.bg_normal = "#ffffff00";
theme.bg_focus = theme.bg_normal;
theme.bg_urgent = theme.bg_normal;
theme.bg_minimize = theme.bg_normal;
theme.bg_systray = theme.bg_normal;

theme.fg_normal = "#dadaad";
theme.fg_focus = theme.fg_normal;
theme.fg_urgent = theme.fg_normal;
theme.fg_minimize = theme.fg_normal;

theme.border_width = 0;
theme.master_width_factor = 0.6;

return theme;