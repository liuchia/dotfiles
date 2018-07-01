path = os.getenv("HOME").."/.config/awesome/Orbit_Trap/";

gears = require("gears");
awful = require("awful");
	awful.rules = require("awful.rules");
	require("awful.autofocus");
watch = require("awful.widget.watch");
wibox = require("wibox");
beautiful = require("beautiful");
naughty = require("naughty");
shape = require("gears.shape");
lain = require("lain");
markup = lain.util.markup;

-- LOAD THEME
beautiful.init(path.."theme.lua");
lain.layout.cascade.offset_x = 48;
lain.layout.cascade.offset_y = 32;
lain.layout.cascade.nmaster = 1;

-- ERROR HANDLING
local ErrorHandling do
	if awesome.startup_errors then
		naughty.notify {
			preset = naughty.config.presets.critical;
			title = "Oh no! A startup error!";
			text = awesome.startup_errors;
		}
	end

	local in_error = false;
	awesome.connect_signal("debug::error", function(err)
		if in_error then return end
		in_error = true;
		naughty.notify {
			preset = naughty.config.presets.critical;
			title = "Oh no! A runtime error!";
			text = err;
		}
	end);
end

-- TAG SETUP
local mod = "Mod4";
local alt = "Mod1";
local ctrl = "Control";
local term = "termite";

local tag_order = {"Tiling 1", "Tiling 2", "Cascading", "Floating"};
local tag_properties = {
	["Tiling 1"] = {
		layout = awful.layout.suit.tile.right;
		gap_single_client = true;
		gap = 5;
	};

	["Tiling 2"] = {
		layout = awful.layout.suit.tile.right;
		gap_single_client = true;
		gap = 5;
	};

	Cascading = {
		layout = lain.layout.cascade;
		gap_single_client = true;
		gap = 10;
	};

	Floating = {
		layout = awful.layout.suit.floating;
	}
};

-- CREATE TAGS
local volumeImage = wibox.widget {
	image = path.."icons/AudioHigh.png";
	resize = false;
	widget = wibox.widget.imagebox;		
};

local alsaCommand = 'amixer get Master | grep -P -o "\\[(on|off)\\]|[0-9]+(%=?)"';
alsaCommand = "bash -c '"..alsaCommand.."'";
local alsaStatus = true;
local alsa alsa = wibox.widget {
	text = "100%";
	widget = wibox.widget.textbox;
	align = "left";
	update = function()
		awful.spawn.with_line_callback(alsaCommand, {
			stdout = function(line)
				if line:find("off") then
					volumeImage:set_image(path.."icons/AudioMute.png");
					alsa:set_markup("off");
					alsaStatus = false;
				elseif line:find("on") then
					alsaStatus = true;											
				else
					if alsaStatus == true then
						local pc = tonumber(line:match("%d+"));
						alsa:set_text(pc.."%");
						if pc > 75 then
							volumeImage:set_image(path.."icons/AudioHigh.png");
						elseif pc > 35 then
							volumeImage:set_image(path.."icons/AudioMid.png");
						elseif pc > 0 then
							volumeImage:set_image(path.."icons/AudioLow.png");
						else
							volumeImage:set_image(path.."icons/AudioMute.png");
						end
					end
				end			
			end;

			stderr = function() end;
		})
	end;
};

local volume = {
	volumeImage;
	alsa;
	spacing = 3;
	layout = wibox.layout.fixed.horizontal;
};

local batteryImage = wibox.widget {
	image = path.."icons/BatteryCharge.png";
	resize = false;
	widget = wibox.widget.imagebox;
};

local battery = {
	batteryImage;
	awful.widget.watch(
		'bash -c "acpi -b | grep -P -o \'Full|Discharging|Charging|[0-9]+(%=?)\'"', 
		2, function(widget, stdout)
			local status;
			for line in stdout:gmatch("[^\r\n]+") do
				if not status then
					status = line;
					if status ~= "Discharging" then
						batteryImage:set_image(path.."icons/BatteryCharge.png");
					end
				else
					widget:set_text(line);
					if status == "Discharging" then
						local pc = tonumber(line:sub(1, -2));
						if pc > 80 then
							batteryImage:set_image(path.."icons/BatteryFull.png");
						elseif pc > 35 then
							batteryImage:set_image(path.."icons/BatteryMid.png");
						elseif pc > 10 then
							batteryImage:set_image(path.."icons/BatteryLow.png");
						else
							batteryImage:set_image(path.."icons/BatteryEmpty.png");
						end
					end
				end
			end
	end);
	spacing = 3;
	layout = wibox.layout.fixed.horizontal;
};

local wifiImage = wibox.widget {
	image = path.."icons/WifiOn.png";
	resize = false;
	widget = wibox.widget.imagebox;
};

local workspace = {};
local workspaceText = {};
local workspaceImage = wibox.widget {
	image = path.."icons/Workspace.png";
	resize = false;
	widget = wibox.widget.imagebox;
};

local wifi = {
	wifiImage;
	awful.widget.watch(
		'bash -c "nmcli dev | grep connected"',
		1, function(widget, stdout)
			local connected = false;
			local connection = nil;
			for line in stdout:gmatch("[^\r\n]+") do
				local _, j = line:find("connected");
				local conn = ""; local started = false;
				for i = j+1, line:len() do
					if started or line:sub(i, i) ~= " " then
						started = true;
						conn = conn..line:sub(i, i);
					end
				end
				connection = conn;
				if line:find("ethernet") then
					connected = "ethernet";
					break;
				else
					connected = "wifi";
				end
			end

			if connected then
				--TODO : add some indicator for etherne
				wifiImage:set_image(path.."icons/WifiOn.png");	
				widget:set_text(connection);
			else
				wifiImage:set_image(path.."icons/WifiOff.png");
				widget:set_text("off");
			end

			workspace.update();
	end);
	spacing = 3;
	layout = wibox.layout.fixed.horizontal;
};

local tagicons = {};
for i = 1, 4 do
	tagicons[i] = wibox.widget {
		image = path.."icons/InactiveEmptyTab.png";
		resize = false;
		widget = wibox.widget.imagebox;
	}
end

local taglistview = {
	tagicons[1]; tagicons[2]; tagicons[3]; tagicons[4];
	spacing = 1;
	layout = wibox.layout.fixed.horizontal;
};

workspace.update = function()
	for s, w in pairs(workspaceText) do
		if #s.selected_tags > 0 then
			w.text = s.selected_tags[1].name;
		else
			w.text = "none";
		end

		for i = 1, 4 do
			local imagepath = path.."icons/";
			if s.tags[i].selected then
				imagepath = imagepath.."Active";
			else
				imagepath = imagepath.."Inactive";
			end
			local clients = s.tags[i]:clients();
			if not clients or #clients == 0  then
				imagepath = imagepath.."Empty";
			end
			imagepath = imagepath.."Tab.png";
			tagicons[i].image = imagepath;
		end
	end
end;

awful.screen.connect_for_each_screen(function(s)
	for i = 1, #tag_order do
		local v = tag_order[i];
		local tag = awful.tag.add(v, tag_properties[v]);
	end
end);

-- INFOBAR
awful.screen.connect_for_each_screen(function(s)
	workspaceText[s] = wibox.widget {
		text = "???";
		align = "left";
		widget = wibox.widget.textbox;
	};

	workspace[s] = {
		workspaceImage;
		workspaceText[s];
		spacing = 6;
		layout = wibox.layout.fixed.horizontal;		
	};

	local w1 = wibox {
		screen = s;
		visible = true;
		x = 900;
		y = 700;
		width = 450;
		height = 50;
		widget = wibox.container.background;
	};

	local clocks = {
		date = wibox.widget.textclock("<span color='#ee9c4a' font='28' font_weight='light' stretch='ultracondensed'>%d</span>", 60);
		month = wibox.widget.textclock("<span color='#ee9c4a'>%b</span>", 60);
		time = wibox.widget.textclock("%H:%M", 60);
	};
	clocks.date.align = "center";
	clocks.month.align = "center";
	clocks.time.align = "center";
	clocks.date.point = function(geo, args)
		return {x = args.parent.width-100; y=0; width=50; height=args.parent.height};
	end;
	w1:setup {
		{
			{
				workspace[s];
				taglistview;
				layout = wibox.layout.flex.horizontal;	
				spacing = 135;
			},
			{
				battery;
				volume;
				wifi;
				layout = wibox.layout.flex.horizontal;
			},
			point = function(geo, args)
				return {x = 5; y = 2; width = args.parent.width - 90; height = args.parent.height-4};
			end;
			layout = wibox.layout.flex.vertical;
		},
		clocks.date,
		{
			clocks.month;
			clocks.time;
			point = function(geo, args)
				return {x = args.parent.width-50; y = 5; width = 50; height = args.parent.height-10};
			end;
			layout = wibox.layout.flex.vertical;
		},
		layout = wibox.layout.manual;
	};
end);

-- MOUSE EVENTS FOR TAGS
local tagbuttons = awful.util.table.join(
	awful.button({}, 1, function(t) t:view_only() end), -- left click to only view one tag
	awful.button({}, 3, awful.tag.viewtoggle) -- right click to toggle view of tag
);

-- KEY BINDINGS
local clientkeys = awful.util.table.join(
	awful.key({ctrl}, "q", function(c) c:kill() end), -- close a client
	awful.key({alt}, "Tab", function() -- alt tabbing
		awful.client.cycle(true);
		awful.client.focus.byidx(-1);
		if client.focus then client.focus:raise() end
	end),
	awful.key({}, "F11", function(c) c.fullscreen = not c.fullscreen end), -- toggle fullscreen
	awful.key({ctrl}, "space", function(c) c:swap(awful.client.getmaster()) end) -- set as master client in tag
);

local clientbuttons = awful.util.table.join(
	awful.button({}, 1, function(c) client.focus = c; c:raise() end), -- focus on left click
	awful.button({mod}, 1, awful.mouse.client.move), -- mod + LMB drag to move
	awful.button({mod}, 3, awful.mouse.client.resize) -- mod + RMB drag to resize
);

local globalkeys = awful.util.table.join(
	awful.key({mod}, "Left", function() awful.tag.viewprev(); workspace.update() end),
	awful.key({mod}, "Right", function() awful.tag.viewnext(); workspace.update() end),
	awful.key({mod}, "Tab", function() awful.tag.viewnext(); workspace.update() end),
	awful.key({mod}, "Escape", function() awful.tag.history.restore(); workspace.update() end),

	awful.key({mod}, "Return", function() awful.spawn(term) end),
	awful.key({mod}, "F5", function() awesome.restart() end),
	awful.key({alt, ctrl}, "Delete", function() awesome.quit() end),

	awful.key({}, "XF86MonBrightnessUp", function() os.execute("xbacklight -inc 10") end),
	awful.key({}, "XF86MonBrightnessDown", function() os.execute("xbacklight -dec 10") end),
	awful.key({mod}, "=", function() os.execute("amixer -q sset Master 3%+") alsa.update(); end),
	awful.key({mod}, "-", function() os.execute("amixer -q sset Master 3%-") alsa.update(); end),
	awful.key({}, "XF86AudioRaiseVolume", function() os.execute("amixer -q sset Master 10%+") alsa.update(); end),
	awful.key({}, "XF86AudioLowerVolume", function() os.execute("amixer -q sset Master 10%-") alsa.update(); end),
	awful.key({}, "XF86AudioMute", function() os.execute("amixer -q sset Master toggle") alsa.update(); end)
);

for i = 1, #tag_order do -- Mod + Number n to view nth tag
	globalkeys = awful.util.table.join(globalkeys,
		awful.key({mod}, "#"..(i+9), function()
			local tag = mouse.screen.tags[i];
			if tag then
				tag:view_only();
				workspace.update();
			end
		end)
	);
end

-- RULES
awful.rules.rules = {
	{	-- BASE CASE
		rule = {};
		properties = {
			border_width = beautiful.border_width;
			focus = awful.client.focus.filter;
			raise = true;
			keys = clientkeys;
			maximized_horizontal = false;
			maximized_vertical = false;
			maximized = false;
			buttons = clientbuttons;		
		};
	};
}

-- WIRING
alsa.update();
root.keys(globalkeys);

client.connect_signal("manage", function(c, startup) -- event on new client added
	if not startup and not c.size_hints.user_position and not c.size_hints.program_position then
		awful.placement.no_overlap(c);
		awful.placement.no_offscreen(c);
		c:raise();
		client.focus = c;
	end
end);

awful.screen.connect_for_each_screen(function(s) -- view first tag on startup
	gears.wallpaper.maximized(beautiful.wallpaper, s, true); -- set wallpaper

	local tag = s.tags[1];
	if tag then
		tag:view_only();
	end
	
	workspace.update();
end);