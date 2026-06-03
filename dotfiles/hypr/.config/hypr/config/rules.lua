--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from apps. You'll probably like this.

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
	tag = "+hyprglass_enabled",
})
suppressMaximizeRule:set_enabled(true)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- To figure out the title or calls of a window to these:
-- Run this command while the window is open:
-- hyprctl clients

-- GNOME System Monitor - Floating
 system_monitor_class = "^(org.gnome.SystemMonitor)$"
hl.window_rule({
	name = "system-monitor",
	match = {
		class = system_monitor_class,
	},
	float = true,
	size = "900 600",
})

-- Mission Center - Floating
local mission_center_class = "^(io.missioncenter.MissionCenter)$"
hl.window_rule({
	name = "mission-center",
	match = {
		class = mission_center_class,
	},
	size = "1200 700",
	animation = "slide down",
})

-- Windowrules for Sticky Notes
local sticky_class = "^(com.vixalien.sticky)$"
hl.window_rule({
	name = "sticky",
	match = {
		class = sticky_class,
	},
	float = true,
	size = { "monitor_w * 0.1", "monitor_h * 0.1" },
	move = { "monitor_w * 0.8", "monitor_h * 0.15" },
})

-- Windowrules for btop
btop_class = "^(btop)$"
hl.window_rule({
	name = "btop",
	match = {
		class = btop_class,
	},
	float = true,
	size = { "monitor_w * 0.6", "monitor_h * 0.7" },
})

-- Windowrules for yazi
 yazi_class = "^(yazi)$"
hl.window_rule({
	name = "yazi",
	match = {
		class = yazi_class,
	},
	float = true,
	size = { "monitor_w * 0.6", "monitor_h * 0.7" },
})

-- kitty-dropterm
local kitty_dropterm_class = "^(kitty-dropterm)$"
hl.window_rule({
	name = "kitty-dropterm",
	match = {
		class = kitty_dropterm_class,
	},
	float = true,
	size = { "monitor_w * 0.6", "monitor_h * 0.7" },
})

-- Zen browser save as windowrule
hl.window_rule({
	name = "zen-save-as",
	match = {
		class = "zen",
		title = "Save As",
	},
	float = true,
	size = { "monitor_w * 0.3", "monitor_h * 0.5" },
})

-- showmethekey windowrules
-- windowrule = float, class:^(one.alynx.showmethekey)$ # float the settings panel
-- windowrule = size 500 400, class:^(one.alynx.showmethekey)$ # resize settings panel
hl.window_rule({
	name = "showmethekey-gtk",
	match = {
		class = "one.alynx.showmethekey",
		title = "Floating Window - Show Me The Key",
	},
	float = true,
	pin = true,
	no_focus = true,
	size = { "monitor_w * 0.1", "monitor_h * 0.1" },
	move = { "monitor_w * 0.895", "monitor_h * 0.89" },
	opacity = "1.0 override",
	no_dim = true,
})

-- Nautilus
nautilus_class = "org.gnome.Nautilus"
hl.window_rule({
	name = "nautilus",
	match = {
		class = nautilus_class,
	},
	float = true,
	center = true,
	size = "(monitor_w*0.6) (monitor_h*0.7)",
	animation = "slide top",
})

-- nemo
local nemo_class = "nemo"
hl.window_rule({
	name = "nemo",
	match = {
		class = nemo_class,
	},
	float = true,
	size = "900 600",
	animation = "slide top",
})

-- Clipse
local clipse_float = "(clipse)"
hl.window_rule({
	name = "clipse",
	match = {
		class = clipse_float,
	},
	size = "622 652",
	stay_focused = true,
})

-- Clipse GUI
local clipse_gui_class = "(clipse-gui)"
hl.window_rule({
	name = "clipse-gui",
	match = {
		class = clipse_gui_class,
	},
	float = true,
	size = "400 650",
	stay_focused = true,
	animation = "slide right",
	move = "100%-410 30",
})

-- Gnome Settings
gnome_settings_class = "(org.gnome.Settings)"
hl.window_rule({
	name = "gnome-settings",
	match = {
		class = gnome_settings_class,
	},
	float = true,
	size = "900 600",
	animation = "slide top",
})

-- Overskride
local overskride_class = "(io.github.kaii_lb.Overskride)"
hl.window_rule({
	name = "overskride",
	match = {
		class = overskride_class,
	},
	float = true,
	size = "900 600",
	animation = "slide top",
})

-- Better Control
local better_control_class = "(better_control.py)"
hl.window_rule({
	name = "better-control",
	match = {
		class = better_control_class,
	},
	float = true,
	size = "1000 600",
	animation = "slide top",
})

-- GNOME Calendar
local gnome_calendar_class = "(org.gnome.Calendar)"
hl.window_rule({
	name = "gnome-calendar",
	match = {
		class = gnome_calendar_class,
	},
	float = true,
	size = "900 600",
	animation = "slide top",
})

-- Wordbook dictionary
local wordbook_class = "dev.mufeed.Wordbook"
hl.window_rule({
	name = "wordbook-dictionary",
	match = {
		class = wordbook_class,
	},
	float = true,
	size = "900 600",
	animation = "slide top",
})

-- uGet
local uget_class = "(uget-gtk)"
hl.window_rule({
	name = "uget-gtk",
	match = {
		class = uget_class,
	},
	float = true,
	size = "900 600",
	animation = "slide top",
})

-- hyprland-share-picker
local share_picker_class = "hyprland-share-picker"
hl.window_rule({
	name = "hyprland-share-picker",
	match = {
		class = share_picker_class,
	},
	float = true,
	size = "600 600",
	animation = "slide top",
})

-- Waypaper windowrules
local waypaper_class = "^(waypaper)$"
hl.window_rule({
	name = "waypaper",
	match = {
		class = waypaper_class,
	},
	float = true,
	size = "900 700",
})

-- Layer-rules
-- See https://wiki.hypr.land/Configuring/Window-Rules/#layer-rules

-- blur popups
-- TODO: manual review — malformed layerrule on line 265: blur_popups on

-- rofi
hl.layer_rule({
	name = "rofi",
	match = {
		namespace = "rofi",
	},
	blur = true,
	ignore_alpha = 0.5,
	animation = "slide down",
})

-- Vicinae
hl.layer_rule({
	name = "vicinae",
	match = {
		namespace = "vicinae",
	},
	blur = true,
	ignore_alpha = 0.5,
	animation = "slide down",
	-- noanim = on
})

-- Hyprpanel blur
--# bar
hl.layer_rule({
	name = "hyprpanel-bar",
	match = {
		namespace = "bar-0",
	},
	blur = true,
	ignore_alpha = 0.3,
})

--# notifications-wondow
hl.layer_rule({
	name = "hyprpanel-notifications",
	match = {
		namespace = "notifications-window",
	},
	blur = true,
	ignore_alpha = 0.4,
})

--# OSD
hl.layer_rule({
	name = "hyprpanel-osd",
	match = {
		namespace = "indicator",
	},
	blur = true,
	ignore_alpha = 0.8,
})

-- Don't allow idle on fullscreen windows
hl.window_rule({
	name = "no-idle-fullscreen",
	match = {
		class = ".*",
	},
	idle_inhibit = "fullscreen",
})

-- waybar blur
hl.layer_rule({
	name = "waybar",
	match = {
		namespace = "waybar",
	},
	blur = true,
	ignore_alpha = 0.2,
})

-- ashell blur
hl.layer_rule({
	name = "ashell",
	match = {
		namespace = "ashell-main-layer",
	},
	blur = true,
	ignore_alpha = 0.4,
})

-- hypr-dock
hl.layer_rule({
	name = "hypr-dock",
	match = {
		namespace = "hypr-dock",
	},
	blur = true,
	ignore_alpha = 0.2,
})

-- swaync blur
--# panel
hl.layer_rule({
	name = "swaync-control-center",
	match = {
		namespace = "swaync-control-center",
	},
	blur = true,
	animation = "slide right",
	ignore_alpha = 0.4,
})

--# notification popup
hl.layer_rule({
	name = "swaync-notification-window",
	match = {
		namespace = "swaync-notification-window",
	},
	blur = true,
	animation = "slide right",
	ignore_alpha = 0.4,
})

-- swayosd blur
hl.layer_rule({
	name = "swayosd",
	match = {
		namespace = "swayosd",
	},
	blur = true,
	animation = "slide up",
	ignore_alpha = 0.39,
})

-- Pyprland expose special workspace
hl.workspace_rule({
	workspace = "special:exposed",
	gaps_out = 10,
	gaps_in = 10,
	border_size = 5,
	no_border = true,
	no_shadow = true,
})
