local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local cairo = require("lgi").cairo
require("awful.autofocus")

local folder = os.getenv("HOME").."/.config/awesome"
local term = "kitty -1"
local browser = "firefox"
local editor = os.getenv("EDITOR") or "nano"

-- THEME

local xresources = beautiful.xresources.get_current_theme()
beautiful.init {
	gap = 8;
	master_width_factor = 0.5;
}

client.connect_signal("focus", function(c) c.border_color = "#ff1166" end)
client.connect_signal("unfocus", function(c) c.border_color = "#d2c9a5" end)

-- ERROR HANDLING
if awesome.startup_errors then
	naughty.notify {
		preset = naughty.config.presets.critical;
		title = "startup error";
		text = awesome.startup_errors;
	}
end

do
	local errored = false
	awesome.connect_signal("debug::error", function(msg)
		if errored then return end
		errored = true
		naughty.notify {
			preset = naughty.config.presets.critical;
			title = "debug error";
			text = tostring(msg);
		}
		errored = false
	end)
end

-- WALLPAPER
function wallpaper(s)
	gears.wallpaper.set(xresources.background)
end

screen.connect_signal("property::geometry", wallpaper)
awful.screen.connect_for_each_screen(wallpaper)

-- TAGS
awful.screen.connect_for_each_screen(function(s)
	local suit = awful.layout.suit
	for i = 1, 5 do
		awful.tag.add(tostring(i), {
			layout = suit.tile;
			screen = s;
			gap = beautiful.gap;
			gap_single_client = true;
		})
	end
	s.tags[1]:view_only()

	s.bar = awful.wibar {
		position = "bottom";
		screen = s;
		bg = xresources.background;
		height = 8;
	}

	s:connect_signal("tag::history::update", function()
		s.bar:setup {
			draw = function(self, context, cairo, w, h)
				local cx = w/2
				local px = cx-100
				for i = 1, 5 do
					local t = s.tags[i]
					if not t.selected then
						cairo:set_source(gears.color("#d2c9a5"))
						cairo:rectangle(px, 1, 40, 1)
						cairo:fill()
					else
						cairo:set_source(gears.color("#ff1166"))
						cairo:rectangle(px, 1, 40, 1)
						cairo:fill()
					end
					px = px + 40
				end
			end;

			layout = wibox.widget.base.make_widget;
		}
	end)
end)

-- KEYBINDINGS
local keys = awful.util.table.join(
	awful.key({"Mod4"}, "Left", awful.tag.viewprev, {}),
	awful.key({"Mod4"}, "Right", awful.tag.viewnext, {}),
	awful.key({"Mod4"}, "Tab", awful.tag.viewnext, {}),
	awful.key({"Mod4", "Shift"}, "q", awesome.quit, {}),
	awful.key({"Mod4", "Control"}, "q", awesome.quit, {}),
	awful.key({"Mod4", "Shift"}, "r", awesome.restart, {}),
	awful.key({"Mod4", "Control"}, "r", awesome.restart, {}),
	awful.key({"Mod4"}, "Return", function() awful.spawn(term) end, {}),
	awful.key({"Mod4"}, "b", function() awful.spawn(browser) end, {}),
	awful.key({"Mod1"}, "Tab", function()
		awful.client.focus.byidx(1)
		if client.focus then client.focus:raise() end
	end, {}),
	awful.key({"Mod4"}, "i", function()
		awful.spawn("sudo xbacklight -inc 10")
	end),
	awful.key({"Mod4"}, "u", function()
		awful.spawn("sudo xbacklight -dec 10")
	end),
	awful.key({"Mod4"}, "o", function()
		awful.spawn("amixer sset Master 1%-")
	end),
	awful.key({"Mod4"}, "p", function()
		awful.spawn("amixer sset Master 1%+")
	end)
)

for i = 1, 5 do
	keys = awful.util.table.join(keys,
		awful.key({"Mod4"}, "#"..(i+9), function()
			local s = awful.screen.focused()
			local t = s.tags[i]
			if t then
				t:view_only()
			end
		end, {}),
		awful.key({"Mod4", "Shift"}, "#"..(i+9), function()
			if client.focus then
				local s = awful.screen.focused()
				local t = s.tags[i]
				if t then
					client.focus:move_to_tag(t)
				end
			end
		end, {})
	)
end

local ckeys = awful.util.table.join(
	awful.key({"Mod4"}, "q", function(c) c:kill() end, {}),
	awful.key({"Mod4"}, "f", function(c) c.fullscreen = not c.fullscreen end, {}),
	awful.key({"Mod4"}, "space", function(c) c:swap(awful.client.getmaster()) end, {})
)

local buttons = awful.util.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {raise = true})
	end),
	awful.button({"Mod4"}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {raise = true})
		awful.mouse.client.move(c)
	end),
	awful.button({"Mod4"}, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", {raise = true})
		awful.mouse.client.resize(c)
	end)
)

root.keys(keys)

-- RULES

awful.rules.rules = {
	{
		rule = {};
		properties = {
			border_width = 1;
            border_color = "#d2c9a5";
			maximized = false;
			keys = ckeys;
			buttons = buttons;
			screen = awful.screen.focused;
			placement = awful.placement.no_overlap + awful.placement.no_offscreen;
			size_hints_honor = false;
		}
	};
}

-- SIGNALS
client.connect_signal("manage", function(c)
	awful.placement.no_overlap(c)
	awful.placement.no_offscreen(c)
	c:raise()
end)
