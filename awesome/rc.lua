path = os.getenv("HOME").."/.config/awesome/Atheme/"

gears = require("gears")
	shape = require("gears.shape")
awful = require("awful")
	awful.rules = require("awful.rules")
	require("awful.autofocus")
beautiful = require("beautiful")
naughty = require("naughty")
wibox = require("wibox")
beautiful.init(path.."theme.lua")

do -- error handling
	if awesome_startup_errors then
		naughty.notify {
			preset = naughty.config.presets.critical;
			title = "startup_error";
			text = awesome.startup_errors;
		}
	end

	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		if in_error then return end
		in_error = true
		naughty.notify {
			preset = naughty.config.presets.critical;
			title = "runtime_error";
			text = err;
		}
	end)
end

local mod = "Mod4"
local alt = "Mod1"
local ctl = "Control"
local trm = "urxvt"

function setwallpaper(s)
	gears.wallpaper.set("#141311")
end

screen.connect_signal("property::geometry", setwallpaper)

local tag_order = {"Tiler Mk01", "Tiler Mk02", "Floater"}
local tag_props = {
	[tag_order[1]] = {
		layout = awful.layout.suit.tile.right;
		gap_single_client = true;
		gap = 5;
	};

	[tag_order[2]] = {
		layout = awful.layout.suit.tile.left;
		gap_single_client = true;
		gap = 5;
	};

	[tag_order[3]] = {
		layout = awful.layout.suit.floating;
	};
}

awful.screen.connect_for_each_screen(function(s)
	setwallpaper(s)
	s.prompt = awful.widget.prompt()

	for i = 1, #tag_order do
		local v = tag_order[i]
		local tag = awful.tag.add(v, tag_props[v])
		if i == 1 then
			tag:view_only()
		end
	end
end)

-- key bindings
local client_keys = awful.util.table.join(
	awful.key({mod}, "q", function(c) c:kill() end),
	awful.key({alt}, "Tab", function()
		awful.client.focus.byidx(1)
		if client.focus then
			client.focus:raise()
		end
	end),
	awful.key({}, "F11", function(c) c.fullscreen = not c.fullscreen end),
	awful.key({alt}, "space", function(c) c:swap(awful.client.getmaster()) end)
)

local client_buton = awful.util.table.join(
	awful.button({}, 1, function(c) client.focus = c; c:raise() end),
	awful.button({mod}, 1, awful.mouse.client.move),
	awful.button({mod}, 3, awful.mouse.client.resize)
)

local global_buton = awful.util.table.join(
	awful.key({mod}, "r", function() awful.screen.focused().prompt:run() end),

	awful.key({mod}, "Left", function() awful.tag.viewprev() end),
	awful.key({mod}, "Right", function() awful.tag.viewnext() end),
	awful.key({mod}, "Tab", function() awful.tag.viewnext() end),
	
	awful.key({mod}, "Return", function() awful.spawn(trm) end),
	awful.key({mod}, "F5", function() awesome.restart() end),
	awful.key({alt, ctl}, "Delete", function() awesome.quit() end),
	
	awful.key({}, "XF86MonBrightnessUp", function() os.execute("light -A 10") end),
	awful.key({}, "XF86MonBrightnessDown", function() os.execute("light -U 10") end),
	awful.key({mod}, "=", function() os.execute("amixer -q sset Master 3%+") end),
	awful.key({mod}, "-", function() os.execute("amixer -q sset Master 3%-") end),
	awful.key({}, "XF86AudioRaiseVolume", function() os.execute("amixer -q sset Master 10%+") end),
	awful.key({}, "XF86AudioLowerVolume", function() os.execute("amixer -q sset Master 10%-") end),
	awful.key({}, "XF86AudioMute", function() os.execute("amixer -q sset Master toggle") end)
)

for i = 1, #tag_order do
	global_buton = awful.util.table.join(global_buton,
		awful.key({mod}, "#"..(i+9), function()
			local tag = awful.screen.focused().tags[i]
			if tag then
				tag:view_only()
			end
		end)
	)
end

root.keys(global_buton)

awful.rules.rules = {
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width;
			border_color = beautiful.border_normal;
			raise = true;
			keys = client_keys;
			buttons = client_buton;
			maximized = false;
			size_hints_honor = false;
			placement = awful.placement.no_overlap + awful.placement.no_offscreen;
			screen = awful.screen.focused();
		}
	},

	{
		rule_any = {type = {"normal", "dialog"}},
		properties = {
			titlebars_enabled = true;
		}
	}
}

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
	c.border_width = beautiful.border_fwidth
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
	c.border_width = beautiful.border_width
end)

client.connect_signal("manage", function(c, startup) -- event on new client added
	if not startup and not c.size_hints.user_position and not c.size_hints.program_position then
		awful.placement.no_overlap(c);
		awful.placement.no_offscreen(c);
		c:raise();
		client.focus = c;
	end
end);

client.connect_signal("request::titlebars", function(c)
	awful.titlebar(c, {
		size = 10;
		bg_focus = "#00000000";--beautiful.titlebar_fg;
		bg_normal = "#00000000";--beautiful.titlebar_bg;
	}):setup {
		fit = function(self, context, width, height)
			return width, height;
		end;
		draw = function(self, context, cr, width, height)
			cr:set_source_rgb(20/255, 19/255, 17/255)
			cr:rectangle(0, 0, width, height/2)
			cr:fill()
			if client.focus == c then
				cr:set_source_rgb(218/255, 142/255, 106/255)
				cr:rectangle(10, 1, 50, height/2)
				cr:fill()
			end
		end;
		layout = wibox.widget.base.make_widget
	}
end)

do
	local bheight = 7
	local brad = 40
	local grad = 45
	local ggap = grad * 2
	local fontsize = 16

	local kb = {"1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"}
	local gapx = {0, 0, grad, grad*2}
	local gapy = {0, 3+ggap, 3+ggap*2, 3+ggap*3}
	local test = awful.wibar {
		position = "bottom";
		height = 400;
		bg = "#00000000";
	}

	test:setup {
	    draw   = function(self, context, cr, w, h)
			cr:set_line_width(1)
			cr:set_source_rgb(218/255, 142/255, 106/255)
			cr:set_font_size(fontsize)
			for i = 1, #kb do
				local num_keys = kb[i]:len()
				for j = 1, num_keys do
					local cx, cy = -grad + ggap*j + gapx[i], grad + gapy[i]
			        cr:arc(cx, cy, brad, 0, math.pi*2)
			        cr:stroke()

					cr:move_to(cx+brad, cy)
					cr:line_to(cx+brad, cy+bheight)
			        cr:stroke()

					cr:move_to(cx-brad, cy)
					cr:line_to(cx-brad, cy+bheight)
			        cr:stroke()

			        cr:arc(cx, cy+bheight, brad, 0, math.pi)
			        cr:stroke()

					local letter = kb[i]:sub(j, j)
					local ext = cr:text_extents(letter)
					cr:move_to(cx-ext.x_bearing-ext.width/2, cy+fontsize/4)
					cr:show_text(letter)
					cr:stroke()
				end
			end
	    end,
	    layout = wibox.widget.base.make_widget,
	}


end