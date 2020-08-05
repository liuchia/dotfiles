local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
require("awful.autofocus")

local folder = os.getenv("HOME").."/.config/awesome"
local term = "kitty -1"
local browser = "qutebrowser"
local editor = os.getenv("EDITOR") or "nano"

-- THEME

local xresources = beautiful.xresources.get_current_theme()
beautiful.init {
	gap = 15;
	titlesize = 15;
	wallpaper = folder .. "/Images/PositronDreamFinespun.png";
	master_width_factor = 0.61;
	border_width = 0;
}

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
	if beautiful.wallpaper then
		gears.wallpaper.maximized(beautiful.wallpaper, s, true)
	end
end

screen.connect_signal("property::geometry", wallpaper)
awful.screen.connect_for_each_screen(wallpaper)

-- TAGS, BARS
local function updateWidgets(s)
	s.clock:setup {
		draw = function(self, context, cairo, w, h)
			if s.tags[1].selected then
				local offset = beautiful.titlesize / 2
				cairo:set_source(gears.color(xresources.foreground))
				cairo:rectangle(0, 0, w, beautiful.titlesize)
				cairo:fill()

				cairo:set_source(gears.color(xresources.background))
				cairo:rectangle(0, beautiful.titlesize, w, h - beautiful.titlesize)
				cairo:fill()

				cairo:set_line_width(1)
				for i = 1, 60 do
					local iangle = math.rad(6 * i)
					cairo:set_source(gears.color(xresources.foreground))
					local cosi = math.sin(iangle)
					local sini = math.cos(iangle)
					local dist1 = 80 / math.max(math.abs(cosi), math.abs(sini))
					local dist2 = (i%5 == 0 and 75 or 79) / math.max(math.abs(cosi), math.abs(sini))
					cairo:move_to(w/2 + math.sin(iangle)*dist1, offset + h/2 - math.cos(iangle)*dist1)
					cairo:line_to(w/2 + math.sin(iangle)*dist2, offset + h/2 - math.cos(iangle)*dist2)
					cairo:stroke()
				end

				local hour = tonumber(os.date("%H"))
				local minute = tonumber(os.date("%M"))
				local hangle = math.rad(30 * hour)
				local hsize = 50
				local msize = 90
				local mangle = math.rad(6 * minute)
				cairo:set_line_width(5)
				cairo:set_source(gears.color(xresources.foreground))
				cairo:move_to(w/2 + math.sin(mangle)*msize, offset + h/2 - math.cos(mangle)*msize)
				cairo:line_to(w/2, offset + h/2)
				cairo:stroke()
				cairo:set_source(gears.color(xresources.color1))
				cairo:move_to(w/2 + math.sin(hangle)*hsize, offset + h/2 - math.cos(hangle)*hsize)
				cairo:line_to(w/2, offset + h/2)
				cairo:stroke()
			end
		end;

		layout = wibox.widget.base.make_widget;
	}

	awful.spawn.easy_async_with_shell(
		"amixer sget Master | ruby -e 'puts STDIN.to_a.last.split(?[)[1].to_i'",
		function(out)
			local volume = tonumber(out)
			s.volume:setup {
				draw = function(self, context, cairo, w, h)
					if s.tags[1].selected then
						local offset = beautiful.titlesize / 2
						cairo:set_source(gears.color(xresources.foreground))
						cairo:rectangle(0, 0, w, beautiful.titlesize)
						cairo:fill()

						cairo:set_source(gears.color(xresources.background))
						cairo:rectangle(0, beautiful.titlesize, w, h - beautiful.titlesize)
						cairo:fill()

						local cx, cy = w/2, h/2 + offset/2
						local left = 85
						local speakw, speakh = 5, 10
						local jut = 10
						local gap = 5
						local barh = 2
						local barw = left*2 - speakw - jut - gap
						local notchw, notchh = 5, 20

						-- speaker icon
						cairo:set_source(gears.color(xresources.foreground))
						cairo:move_to(cx - left, cy - speakh/2)
						cairo:rel_line_to(speakw, 0)
						cairo:rel_line_to(jut, -jut)
						cairo:rel_line_to(0, jut*2 + speakh)
						cairo:rel_line_to(-jut, -jut)
						cairo:rel_line_to(-speakw, 0)
						cairo:fill()

						-- bar
						cairo:set_source(gears.color(xresources.color4))
						cairo:move_to(cx - left + gap + speakw + jut, cy - barh/2)
						cairo:rel_line_to(barw, 0)
						cairo:rel_line_to(0, barh)
						cairo:rel_line_to(-barw, 0)
						cairo:fill()

						-- indicators
						local n = 20
						local ih = 5
						local dist = (barw - notchw) / n
						cairo:move_to(cx-left+gap+speakw+jut+notchw/2-dist, cy+10)
						cairo:set_line_width(1)
						cairo:set_source(gears.color(xresources.foreground))
						for i = 0, n do
							local iih = i % 5 == 0 and ih or 1
							cairo:rel_move_to(dist, 0)
							cairo:rel_line_to(0, -iih)
							cairo:rel_move_to(0, iih)
						end
						cairo:stroke()

						-- notch position
						local x = (barw - notchw) * volume / 100
						cairo:set_source(gears.color(xresources.foreground))
						cairo:move_to(cx - left + gap + speakw + jut, cy - notchh/2)
						cairo:rel_move_to(x, 0)
						cairo:rel_line_to(notchw, 0)
						cairo:rel_line_to(0, notchh)
						cairo:rel_line_to(-notchw, 0)
						cairo:fill()
					end
				end;

				layout = wibox.widget.base.make_widget;
			}
		end
	)
end


awful.screen.connect_for_each_screen(function(s)
	local suit = awful.layout.suit
	for i = 1, 5 do
		awful.tag.add(tostring(i), {
			layout = suit.tile;
			screen = s;
			gap = 15;
			gap_single_client = true;
		})

	end
	s.tags[1]:view_only()

	s.bar = awful.wibar {
		position = "bottom";
		screen = s;
		bg = "#00000000";
		height = 30;
	}

	s.clock = wibox {
		bg = "#00000000";
		screen = s;
		x = 150;
		y = 50;
		width = 200;
		height = 200 + beautiful.titlesize;
		visible = true;
		widget = wibox.container.background;
	}

	s.volume = wibox {
		bg = "#00000000";
		screen = s;
		x = 150;
		y = 290;
		width = 200;
		height = 80 + beautiful.titlesize;
		visible = true;
		widget = wibox.container.background;
	}

	s:connect_signal("tag::history::update", function()
		updateWidgets(s)
		s.bar:setup {
			draw = function(self, context, cairo, w, h)
				local cx = w/2
				local cy = h/2
				local r = 12
				local d = r*2
				local g = 3

				local px = cx-d-d-g-g
				for i = 1, 5 do
					local t = s.tags[i]
					local pr = r * (t.selected and 1 or 0.39)
					local pd = pr + pr
					cairo:set_source(gears.color(t.selected and xresources.color2 or xresources.foreground))
					cairo:rectangle(px-pr, cy-pr, pd, pd)
					cairo:fill()
					px = px + d + g
				end
			end;

			layout = wibox.widget.base.make_widget;
		}
	end)

	gears.timer {
		timeout = 1;
		call_now = true;
		autostart = true;
		callback = function()
			awful.screen.connect_for_each_screen(updateWidgets)
		end
	}
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
	awful.key({"Mod4"}, "u", function()
		awful.spawn("sudo xbacklight -inc 10")
	end),
	awful.key({"Mod4"}, "i", function()
		awful.spawn("sudo xbacklight -dec 10")
	end),
	awful.key({"Mod4"}, "o", function()
		awful.spawn("amixer sset Master 5%-")
		awful.screen.connect_for_each_screen(updateWidgets)
	end),
	awful.key({"Mod4"}, "p", function()
		awful.spawn("amixer sset Master 5%+")
		awful.screen.connect_for_each_screen(updateWidgets)
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
		end, {})
	)
end

local ckeys = awful.util.table.join(
	awful.key({"Mod4"}, "q", function(c) c:kill() end, {}),
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
			border_width = 0;
			focus = awful.client.focus.filter;
			raise = true;
			maximized = false;
			keys = ckeys;
			buttons = buttons;
			screen = awful.screen.focused;
			placement = awful.placement.no_overlap + awful.placement.no_offscreen;
			titlebars_enabled = true;
			size_hints_honor = false;
		}
	};
}

-- SIGNALS

client.connect_signal("manage", function(c)
	awful.placement.no_overlap(c)
	awful.placement.no_offscreen(c)
	local t = c.first_tag
	if t and t == t.screen.tags[1] then
		local s = t.screen
		c:move_to_tag(s.tags[2])
		s.tags[2]:view_only()
	end
	c:raise()
	client.focus = c
end)

client.connect_signal("request::titlebars", function(c)
	awful.titlebar(c, {
		size = beautiful.titlesize;
		bg_focus = "#00000000";
		bg_normal = "#00000000";
	}):setup {
		fit = function(_, _, w, h)
			return width, height
		end;

		draw = function(self, context, cairo, w, h)
			cairo:set_source(gears.color(client.focus == c and xresources.color2 or xresources.foreground))
			cairo:rectangle(0, 0, w, h)
			cairo:fill()
		end;

		layout = wibox.widget.base.make_widget;
	}
end)
