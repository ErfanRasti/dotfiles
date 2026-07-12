---------------------
---- KEYBINDINGS ----
---------------------
local function toggle_or_launch(app_class, app_cmd)
	local active = hl.get_active_window()
	if active and active.class == app_class then
		hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
	else
		local target = nil
		for _, w in ipairs(hl.get_windows()) do
			if w.class == app_class then
				target = w
				break
			end
		end
		if target then
			hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace(), follow = true, window = target }))
			hl.dispatch(hl.dsp.focus({ window = target }))
		else
			hl.exec_cmd(app_cmd)
		end
	end
end
-- See https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(TERMINAL), { description = "Open the terminal" })
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(TERMINAL), { description = "Open the terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Kill the active window" })
hl.bind(
	mainMod .. " + SHIFT + Q",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
	{ description = "Exit Hyprland" }
)
hl.bind(mainMod .. " + E", function()
	toggle_or_launch(nautilus_class, "nautilus")
end, { description = "Toggle the file manager" })

hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating window" })
hl.bind(
	mainMod .. " + D",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofi_launcher.sh"),
	{ description = "Open search menu" }
)
hl.bind(
	mainMod .. " + SHIFT + D",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofi_launcher.sh -a"),
	{ description = "Open alternative search menu" }
)
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("vicinae toggle"), { description = "Open search menu" })

-- `pseudo` makes the window behave like a floating window
-- but stays tiled (a hybrid state). # dwindle
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Toggle pseudo window" })

-- `pin` Pins the window so it stays visible on all workspaces
-- (like "sticky" windows in other WMs).
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin(), { description = "Pin the window to all workspaces" })

-- `togglesplit` Switches between horizontal and vertical splits forcce
-- the focused container (useful for rearranging tiled windows). # dwindle
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.layout("togglesplit"), { description = "Toggle split arangement" })

-- Reload hypland
hl.bind(
	mainMod .. " + SHIFT + R",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/reload_config.sh"),
	{ description = "Reload Hyprland" }
)

-- Fullscreen keybinding
hl.bind(
	mainMod .. " + SHIFT + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Toggle fullscreen window" }
)

-- Maximize keybinding
-- 0 - fullscreen (takes your entire screen)
-- 1 - maximize (keeps gaps and bar(s))
hl.bind(
	mainMod .. " + M",
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "Toggle maximize window" }
)

-- Settings shortcut
hl.bind(mainMod .. " + I", function()
	toggle_or_launch(gnome_settings_class, SETTINGS)
end, { description = "Open settings app" })
hl.bind(
	mainMod .. " + SHIFT + I",
	hl.dsp.exec_cmd('~/.config/hypr/scripts/toggle_app.sh "$better_control_class" "better-control"'),
	{ description = "Toggle better-control" }
)

-- Screenshot keybindings
hl.bind(
	"PRINT",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprshot_notify.sh region"),
	{ description = "Take screenshot of the region" }
)
hl.bind(
	"SHIFT + PRINT",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprshot_notify.sh output"),
	{ description = "Take screenshot of an entire monitor" }
)
hl.bind(
	mainMod .. " + PRINT",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprshot_notify.sh window"),
	{ description = "Take screenshot of an open window" }
)
hl.bind(
	"CTRL + PRINT",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/screenshot.sh"),
	{ description = "Open screehshot panel" }
)

-- Hyprpicker keybinding
hl.bind(
	mainMod .. " + CTRL + SHIFT + P",
	hl.dsp.exec_cmd("hyprpicker -al"),
	{ description = "Launch hyprpicker and copy the lowercase color hex" }
)

-- Lockscreen keybinding
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("hyprlock"), { description = "Lock the screen" })
-- bindl makes the binding work even when inputs are locked
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "Suspend the system" })

-- btop keybinding
-- `btop` opens in `kitty` class; So we need dispatcher to
-- forcce the custom windowrules.
-- For more infor: https://wiki.hypr.land/Configuring/Dispatchers/
-- bind = CTRL SHIFT, ESCAPE, exec, kitty --title btop -e btop # Launch btop++
hl.bind("CTRL + SHIFT + ESCAPE", function()
	toggle_or_launch(btop_class, "btop")
end, { description = "Toggle btop" })
hl.bind("CTRL + SHIFT + F1", function()
	toggle_or_launch("nvtop", "nvtop")
end, { description = "Toggle nvtop" })
hl.bind("CTRL + SHIFT + F2", function()
	toggle_or_launch("htop", "htop")
end, { description = "Toggle htop" })
hl.bind("CTRL + SHIFT + F3", function()
	toggle_or_launch(system_monitor_class, "gnome-system-monitor")
end, { description = "Toggle system-monitor" })
hl.bind(
	"CTRL + SHIFT + F4",
	hl.dsp.exec_cmd(
		'~/.config/hypr/scripts/toggle_app.sh "$mission_center_class" "flatpak run io.missioncenter.MissionCenter"'
	),
	{ description = "Toggle mission-center" }
)

-- Yazi keybinding
hl.bind(mainMod .. " + ALT + E", function()
	toggle_or_launch(yazi_class, "yazi")
end, { description = "Toggle yazi file manager scratchpad visibility" })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Move focus to right" })
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Move focus to left" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Move focus to up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Move focus to down" })

hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Move focus to up" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Move focus to down" })

-- Cycle at the workspace level
-- See https://wiki.hypr.land/Configuring/Dispatchers/#list-of-dispatchers
hl.bind(mainMod .. " + L", hl.dsp.window.cycle_next({ next = true }), { description = "Go to the next window" })
hl.bind(mainMod .. " + H", hl.dsp.window.cycle_next({ prev = true }), { description = "Go to the previous window" })

-- Move floating window position
hl.bind(
	mainMod .. " + CTRL + SHIFT + right",
	hl.dsp.window.move({ x = 50, y = 0, relative = true }),
	{ repeating = true, description = "Move active window 50px to right" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + left",
	hl.dsp.window.move({ x = -50, y = 0, relative = true }),
	{ repeating = true, description = "Move active window 50px to left" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + up",
	hl.dsp.window.move({ x = 0, y = -50, relative = true }),
	{ repeating = true, description = "Move active window 50px to up" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + down",
	hl.dsp.window.move({ x = 0, y = 50, relative = true }),
	{ repeating = true, description = "Move active window 50px to down" }
)

hl.bind(
	mainMod .. " + CTRL + SHIFT + L",
	hl.dsp.window.move({ x = 50, y = 0, relative = true }),
	{ repeating = true, description = "Move active window 50px to right" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + H",
	hl.dsp.window.move({ x = -50, y = 0, relative = true }),
	{ repeating = true, description = "Move active window 50px to left" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + K",
	hl.dsp.window.move({ x = 0, y = -50, relative = true }),
	{ repeating = true, description = "Move active window 50px to up" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + J",
	hl.dsp.window.move({ x = 0, y = 50, relative = true }),
	{ repeating = true, description = "Move active window 50px to down" }
)

-- Move active window
hl.bind(
	mainMod .. " + CTRL + right",
	hl.dsp.window.move({ direction = "r" }),
	{ description = "Move active window to right" }
)
hl.bind(
	mainMod .. " + CTRL + left",
	hl.dsp.window.move({ direction = "l" }),
	{ description = "Move active window to left" }
)
hl.bind(
	mainMod .. " + CTRL + up",
	hl.dsp.window.move({ direction = "u" }),
	{ description = "Move active window to up" }
)
hl.bind(
	mainMod .. " + CTRL + down",
	hl.dsp.window.move({ direction = "d" }),
	{ description = "Move active window to down" }
)

hl.bind(
	mainMod .. " + CTRL + L",
	hl.dsp.window.move({ direction = "r" }),
	{ description = "Move active window to right" }
)
hl.bind(
	mainMod .. " + CTRL + H",
	hl.dsp.window.move({ direction = "l" }),
	{ description = "Move active window to left" }
)
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "u" }), { description = "Move active window to up" })
hl.bind(
	mainMod .. " + CTRL + J",
	hl.dsp.window.move({ direction = "d" }),
	{ description = "Move active window to down" }
)

-- Switch workspaces with mainMod + [0-9]
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }), { description = "Switch to workspace 1" })
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }), { description = "Switch to workspace 2" })
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }), { description = "Switch to workspace 3" })
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }), { description = "Switch to workspace 4" })
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }), { description = "Switch to workspace 5" })
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }), { description = "Switch to workspace 6" })
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }), { description = "Switch to workspace 7" })
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }), { description = "Switch to workspace 8" })
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }), { description = "Switch to workspace 9" })
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }), { description = "Switch to workspace 10" })

-- Switch workspaces using $mainMod+Alt+Arrow keys
hl.bind(mainMod .. " + ALT + H", hl.dsp.focus({ workspace = -1 }), { description = "Switch to previous workspace" })
hl.bind(mainMod .. " + ALT + L", hl.dsp.focus({ workspace = "+1" }), { description = "Switch to next workspace" })

hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ workspace = -1 }), { description = "Switch to previous workspace" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ workspace = "+1" }), { description = "Switch to next workspace" })

-- bind = $mainMod ALT, left, workspace, e-1 # Switch to the previous existing workspace
-- bind = $mainMod ALT, right, workspace, e+1 # Switch to the next existing workspace

-- Move window forward or backward
hl.bind(
	mainMod .. " + SHIFT + ALT + right",
	hl.dsp.window.move({ workspace = "r+1" }),
	{ description = "Move window to the next workspace" }
)
hl.bind(
	mainMod .. " + SHIFT + ALT + left",
	hl.dsp.window.move({ workspace = "r-1" }),
	{ description = "Move window to the previous workspace" }
)

hl.bind(
	mainMod .. " + SHIFT + ALT + H",
	hl.dsp.window.move({ workspace = "r-1" }),
	{ description = "Move window to the previous workspace" }
)
hl.bind(
	mainMod .. " + SHIFT + ALT + L",
	hl.dsp.window.move({ workspace = "r+1" }),
	{ description = "Move window to the next workspace" }
)

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
hl.bind(
	mainMod .. " + SHIFT + 1",
	hl.dsp.window.move({ workspace = 1 }),
	{ description = "Move active window to workspace 1" }
)
hl.bind(
	mainMod .. " + SHIFT + 2",
	hl.dsp.window.move({ workspace = 2 }),
	{ description = "Move active window to workspace 2" }
)
hl.bind(
	mainMod .. " + SHIFT + 3",
	hl.dsp.window.move({ workspace = 3 }),
	{ description = "Move active window to workspace 3" }
)
hl.bind(
	mainMod .. " + SHIFT + 4",
	hl.dsp.window.move({ workspace = 4 }),
	{ description = "Move active window to workspace 4" }
)
hl.bind(
	mainMod .. " + SHIFT + 5",
	hl.dsp.window.move({ workspace = 5 }),
	{ description = "Move active window to workspace 5" }
)
hl.bind(
	mainMod .. " + SHIFT + 6",
	hl.dsp.window.move({ workspace = 6 }),
	{ description = "Move active window to workspace 6" }
)
hl.bind(
	mainMod .. " + SHIFT + 7",
	hl.dsp.window.move({ workspace = 7 }),
	{ description = "Move active window to workspace 7" }
)
hl.bind(
	mainMod .. " + SHIFT + 8",
	hl.dsp.window.move({ workspace = 8 }),
	{ description = "Move active window to workspace 8" }
)
hl.bind(
	mainMod .. " + SHIFT + 9",
	hl.dsp.window.move({ workspace = 9 }),
	{ description = "Move active window to workspace 9" }
)
hl.bind(
	mainMod .. " + SHIFT + 0",
	hl.dsp.window.move({ workspace = 10 }),
	{ description = "Move active window to workspace 10" }
)

-- For grouping (tabbed windows)
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle group" })
hl.bind(
	mainMod .. " + SHIFT + G",
	hl.dsp.window.move({ out_of_group = true }),
	{ description = "Move the current window out of the group" }
)

hl.bind(mainMod .. " + TAB", hl.dsp.group.next(), { description = "Navigate to the next window of the group" })
hl.bind(
	mainMod .. " + SHIFT + TAB",
	hl.dsp.group.prev(),
	{ description = "Navigate to the previous window of the group" }
)

hl.bind(
	mainMod .. " + SHIFT + RIGHT",
	hl.dsp.window.move({ into_group = "r" }),
	{ description = "Move the window to the right group" }
)
hl.bind(
	mainMod .. " + SHIFT + LEFT",
	hl.dsp.window.move({ into_group = "l" }),
	{ description = "Move the window to the left group" }
)
hl.bind(
	mainMod .. " + SHIFT + UP",
	hl.dsp.window.move({ into_group = "u" }),
	{ description = "Move the window to the up group" }
)
hl.bind(
	mainMod .. " + SHIFT + DOWN",
	hl.dsp.window.move({ into_group = "d" }),
	{ description = "Move the window to the down group" }
)
hl.bind(
	mainMod .. " + SHIFT + L",
	hl.dsp.window.move({ into_group = "r" }),
	{ description = "Move the window to the right group" }
)
hl.bind(
	mainMod .. " + SHIFT + H",
	hl.dsp.window.move({ into_group = "l" }),
	{ description = "Move the window to the left group" }
)
hl.bind(
	mainMod .. " + SHIFT + K",
	hl.dsp.window.move({ into_group = "u" }),
	{ description = "Move the window to the up group" }
)
hl.bind(
	mainMod .. " + SHIFT + J",
	hl.dsp.window.move({ into_group = "d" }),
	{ description = "Move the window to the down group" }
)

-- Example special workspace (scratchpad)
-- This bindings will all happen when pressing mainMod+S.
hl.bind("SUPER + S", function()
	hl.dispatch(hl.dsp.workspace.toggle_special("minimize"))
	hl.dispatch(hl.dsp.window.move({ workspace = "+0" }))
	hl.dispatch(hl.dsp.workspace.toggle_special("minimize"))
	hl.dispatch(hl.dsp.window.move({ workspace = "special:minimize" }))
	hl.dispatch(hl.dsp.workspace.toggle_special("minimize"))
end, { description = "Move the current window to/from minimize" })

-- Toggle special:minimize
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.workspace.toggle_special("minimize"),
	{ description = "Toggle minimize workspace" }
)

hl.bind(
	mainMod .. " + W",
	hl.dsp.window.move({ workspace = "special:scratchpad" }),
	{ description = "Move the current window to scratchpad" }
)
hl.bind(
	mainMod .. " + W",
	hl.dsp.workspace.toggle_special("scratchpad"),
	{ description = "Move the current window to scratchpad" }
)

-- Toggle special:scratchpad
hl.bind(
	mainMod .. " + SHIFT + W",
	hl.dsp.workspace.toggle_special("scratchpad"),
	{ description = "Toggle scratchpad workspace" }
)

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(
	mainMod .. " + CTRL + mouse_down",
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Move to next workspace" }
)
hl.bind(
	mainMod .. " + CTRL + mouse_up",
	hl.dsp.focus({ workspace = "e-1" }),
	{ description = "Move to previous workspace" }
)

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { description = "Move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { description = "Resize Window" })

-- SUPER + PERIOD to open emoji panel
hl.bind(
	mainMod .. " + PERIOD",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofimoji.sh"),
	{ description = "Open emoji panel" }
)

-- Rofi Cliphist
hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofi_cliphist.sh"),
	{ description = "Open cliphist panel" }
)
-- bind = SUPER, V, exec, kitty --class clipse -e clipse # Open clipse menu
-- bind = SUPER, V, exec, clipse-gui # Open clipse gui menu

-- Rofi menues
hl.bind(
	mainMod .. " + CTRL + P",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/powermenu.sh"),
	{ description = "Open rofi powermenu" }
)
hl.bind(
	mainMod .. " + ALT + A",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/apps.sh"),
	{ description = "Open rofi favourite apps" }
)
hl.bind(
	mainMod .. " + ALT + Q",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/quicklinks.sh"),
	{ description = "Open rofi quicklinks" }
)
hl.bind(
	mainMod .. " + CTRL + B",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/battery.sh"),
	{ description = "Open rofi battery menu" }
)
hl.bind(
	mainMod .. " + ALT + V",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/volume.sh"),
	{ description = "Open rofi volume control" }
)
hl.bind(
	mainMod .. " + ALT + B",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/brightness.sh"),
	{ description = "Open rofi brightness control" }
)
hl.bind(
	mainMod .. " + ALT + P",
	hl.dsp.exec_cmd("~/.config/rofi/applets/scripts/player.sh"),
	{ description = "Open rofi player control" }
)
hl.bind(
	mainMod .. " + SHIFT + ESCAPE",
	hl.dsp.exec_cmd("~/.config/rofi/powermenu/run.sh"),
	{ description = "Open rofi powermenu" }
)
hl.bind("ALT + F4", hl.dsp.exec_cmd("~/.config/rofi/powermenu/run.sh"), { description = "Open rofi powermenu" })

-- Rofi window menu
hl.bind(
	"ALT + TAB",
	hl.dsp.exec_cmd("~/.config/rofi/windows/run.sh"),
	{ description = "Open rofi list of windows menu" }
)

-- Waypaper
hl.bind(
	mainMod .. " + ALT + W",
	hl.dsp.exec_cmd('~/.config/hypr/scripts/toggle_app.sh "$waypaper_class" "waypaper"'),
	{ description = "Open waypaper" }
)

-- Restore waypaper (reload hyprland, spicetify, and ... as the matugen post_command)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("waypaper --restore"), { description = "Restore waypaper and matugen" })
-- bind = $mainMod, R, exec, hyprpanel -q;hyprpanel

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "Open swaync notification" })

-- Hyprpanel
-- See https://hyprpanel.com/configuration/cli.html#toggling-hiding-the-bars
-- To list all commands: hyprpanel explain
-- bind = $mainMod, A, exec, hyprpanel t dashboardmenu
-- bind = $mainMod, N, exec, hyprpanel t notificationsmenu
-- bind = $mainMod SHIFT, I, exec, hyprpanel t settings-dialor
-- bind = $mainMod SHIFT, C, exec, hyprpanel t calendarmenu
-- bind = $mainMod SHIFT, T, exec, hyprpanel useTheme "/usr/share/hyprpanel/themes/nord.json"

-- Laptop multimedia keys for volume and LCD brightness
-- e at the end: allows the binding to repeat while you hold the key down
-- l at the end: makes the binding work even when inputs are locked
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(
		"pactl set-sink-mute @DEFAULT_SINK@ 0;swayosd-client --output-volume raise;paplay ~/.nix-profile/share/sounds/ocean/stereo/audio-volume-change.oga"
	),
	{ locked = true, repeating = true, description = "Raise the volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(
		"swayosd-client --output-volume lower;paplay ~/.nix-profile/share/sounds/ocean/stereo/audio-volume-change.oga"
	),
	{ locked = true, repeating = true, description = "Lower the volume" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
	{ locked = true, repeating = true, description = "Toggle mute audio" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle;pactl set-source-volume @DEFAULT_SOURCE@ 25%"),
	{ locked = true, repeating = true, description = "Toggle mute microphone" }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("swayosd-client --device intel_backlight --brightness raise"),
	{ locked = true, repeating = true, description = "Turn the brightness up" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("swayosd-client --device intel_backlight --brightness lower"),
	{ locked = true, repeating = true, description = "Turn the brightness down" }
)

-- Capslock key
hl.bind(
	"CAPS + Caps_Lock",
	hl.dsp.exec_cmd("swayosd-client --caps-lock;paplay ~/.nix-profile/share/sounds/freedesktop/stereo/dialog-warning.oga"),
	{ description = "Caps-Lock" }
)
hl.bind("MOD2 + Num_Lock", hl.dsp.exec_cmd("swayosd-client --num-lock"), { description = "Num-Lock" })

-- Requires playerctl
-- o at the end: triggers on long press
hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd("swayosd-client --playerctl next"),
	{ locked = true, long_press = true, description = "hold the key to go to the next song" }
)
hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd("playerctl position 5+"),
	{ locked = true, description = "Move the position of audio +5s" }
)
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"),
	{ locked = true, description = "Pause the audio" }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"),
	{ locked = true, description = "Play the audio" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("swayosd-client --playerctl prev"),
	{ locked = true, long_press = true, description = "Hold the key to go to the previous song" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("playerctl position 5-"),
	{ locked = true, description = "Move the position of audio -5s" }
)

-- Calculator
hl.bind("XF86Calculator", hl.dsp.exec_cmd("gnome-calculator"), { description = "Launch calculator" })

-- Resize window submaps
-- See https://wiki.hypr.land/Configuring/Binds/#submaps
--
-- will switch to a submap called resize
hl.bind("ALT + R", hl.dsp.submap("resize"), { description = "Activate resize submap" })

-- will start a submap called "resize"
hl.define_submap("resize", function()
	-- sets repeatable binds for resizing the active window
	hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

	hl.bind("l", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("h", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

	-- use reset to go back to the global submap
	hl.bind("escape", hl.dsp.submap("reset"))

	-- will reset the submap, which will return to the global submap
end)

-- keybinds further down will be global again...

-- Resize window
hl.bind(
	mainMod .. " + equal",
	hl.dsp.window.resize({ x = 10, y = 0, relative = true }),
	{ repeating = true, description = "Increase window size 10 pixels horizontally" }
)
hl.bind(
	mainMod .. " + minus",
	hl.dsp.window.resize({ x = -10, y = 0, relative = true }),
	{ repeating = true, description = "Decrease window size 10 pixels horizontally" }
)
hl.bind(
	mainMod .. " + ALT + equal",
	hl.dsp.window.resize({ x = 0, y = 10, relative = true }),
	{ repeating = true, description = "Increase window size 10 pixels vertically" }
)
hl.bind(
	mainMod .. " + ALT + minus",
	hl.dsp.window.resize({ x = 0, y = -10, relative = true }),
	{ repeating = true, description = "Decrease window size 10 pixels vertically" }
)

-- Show desktop
hl.bind(
	mainMod .. " + D",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/show_desktop.sh"),
	{ description = "Toggle show desktop" }
)

-- Toggle special:desktop
hl.bind(
	mainMod .. " + SHIFT + D",
	hl.dsp.workspace.toggle_special("desktop"),
	{ description = "Toggle desktop workspace" }
)

-- Add zoom keybidings
hl.bind(
	mainMod .. " + mouse_down",
	hl.dsp.exec_cmd(
		"hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
	),
	{ description = "Zoom into the position of the cursor" }
)
hl.bind(
	mainMod .. " + mouse_up",
	hl.dsp.exec_cmd(
		"hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')"
	),
	{ description = "Zoom out of the position of the cursor" }
)

hl.bind(
	mainMod .. " + SHIFT + equal",
	hl.dsp.exec_cmd(
		"hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
	),
	{ repeating = true, description = "Zoom into the position of the cursor" }
)
hl.bind(
	mainMod .. " + SHIFT + minus",
	hl.dsp.exec_cmd(
		"hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')"
	),
	{ repeating = true, description = "Zoom out of the position of the cursor" }
)
hl.bind(
	mainMod .. " + KP_ADD",
	hl.dsp.exec_cmd(
		"hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
	),
	{ repeating = true, description = "Zoom into the position of the cursor" }
)
hl.bind(
	mainMod .. " + KP_SUBTRACT",
	hl.dsp.exec_cmd(
		"hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')"
	),
	{ repeating = true, description = "Zoom out of the position of the cursor" }
)

hl.bind(
	mainMod .. " + SHIFT + mouse_up",
	hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor 1"),
	{ description = "Go back to normal zoom factor" }
)
hl.bind(
	mainMod .. " + SHIFT + mouse_down",
	hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor 1"),
	{ description = "Go back to normal zoom factor" }
)
hl.bind(
	mainMod .. " + SHIFT + minus",
	hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor 1"),
	{ description = "Go back to normal zoom factor" }
)
hl.bind(
	mainMod .. " + SHIFT + KP_SUBTRACT",
	hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor 1"),
	{ description = "Go back to normal zoom factor" }
)
hl.bind(
	mainMod .. " + SHIFT + 0",
	hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor 1"),
	{ description = "Go back to normal zoom factor" }
)

-- Toggle animations/blur/etc for game modehl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("~/.config/hypr/scripts/activate_layout.sh gamemode"), { description = "Toggle game mode" })

-- Toggle smart gaps mode
hl.bind(
	mainMod .. " + F2",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/activate_layout.sh smartgaps"),
	{ description = "Toggle smart gaps mode" }
)

-- Switch to different layouts
-- dwindle: binary tree windows
-- master: a main and sub windows
-- See:
-- https://wiki.hypr.land/Configuring/Master-Layout/
-- https://wiki.hypr.land/Configuring/Dwindle-Layout/
hl.bind(
	mainMod .. " + F3",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/activate_layout.sh dwindle"),
	{ description = "Switch to dwindle layout" }
)
hl.bind(
	mainMod .. " + F4",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/activate_layout.sh master"),
	{ description = "Switch to master layout" }
)
hl.bind(
	mainMod .. " + F5",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/activate_layout.sh scrolling"),
	{ description = "Switch to scrolling layout" }
)
hl.bind(
	mainMod .. " + F6",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/activate_layout.sh hy3"),
	{ description = "Switch to hy3 layout" }
)

-- Hyprspace keybinding
-- hl.bind(mainMod .. " + O", hl.dispatch("scrolloverview:overview toggle"), { description = "Toggle hymission overview" })

-- Open rofi keybindings
hl.bind(
	mainMod .. " + SLASH",
	hl.dsp.exec_cmd("~/.config/rofi/keybindings/run.sh"),
	{ description = "Open rofi keybindings menu" }
)
hl.bind(
	mainMod .. " + SHIFT + SLASH",
	hl.dsp.exec_cmd("~/.config/rofi/keybindings/run.sh -o"),
	{ description = "Open rofi keybindings overview" }
)

-- pyprland
hl.bind(mainMod .. " + GRAVE", hl.dsp.exec_cmd("pypr toggle terminal"), { description = "Toggle popup terminal" })
hl.bind(
	mainMod .. " + SHIFT + B",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/pypr_expose.sh"),
	{ description = "Expose every window temporarily or 'jump' to the fucused one" }
)
hl.bind(
	mainMod .. " + SHIFT + A",
	hl.dsp.exec_cmd("pypr fetch_client_menu"),
	{ description = "Fetch window to the current workspace" }
)
hl.bind(
	mainMod .. " + U",
	hl.dsp.exec_cmd("pypr toggle_special minimized"),
	{ description = "Toggle a window from/to the 'minimized' special workspace" }
)
hl.bind(
	mainMod .. " + SHIFT + U",
	hl.dsp.workspace.toggle_special("minimized"),
	{ description = "Toggle the 'minimized' special workspace" }
)
hl.bind(
	mainMod .. " + SHIFT + O",
	hl.dsp.exec_cmd("pypr shift_monitors +1"),
	{ description = "Swap workspaces between monitors" }
)

-- Wordbook
hl.bind(
	mainMod .. " + SHIFT + mouse:272",
	hl.dsp.exec_cmd(
		'ydotool key 29:1 46:1 46:0 29:0;~/.config/hypr/scripts/toggle_app.sh "$wordbook_class" "flatpak run dev.mufeed.Wordbook"'
	),
	{ description = "Copy text and open wordbook" }
)
hl.bind(
	mainMod .. " + SHIFT + RETURN",
	hl.dsp.exec_cmd(
		'ydotool key 29:1 46:1 46:0 29:0;~/.config/hypr/scripts/toggle_app.sh "$wordbook_class" "flatpak run dev.mufeed.Wordbook"'
	),
	{ description = "Copy text and open wordbook" }
)

hl.bind(mainMod .. " + CTRL + ALT + P", hl.dsp.exec_cmd("pypr toggle fum"), { description = "Toggle fum player" })

hl.bind(
	mainMod .. " + B",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_hyprbars.sh"),
	{ description = "Toggle hyprbars" }
)
hl.bind(
	mainMod .. " + SHIFT + C",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_dynamic_cursors.sh"),
	{ description = "Toggle hypr-dynamic-cursors" }
)

-- bind = $mainMod, Z, easymotion, action:hyprctl dispatch focuswindow address:{} # Select window using easymotion
-- bind = $mainMod, BACKSPACE, easymotion, textcolor:$red_value, bordercolor:$red_container, action:hyprctl dispatch closewindow address:{} # Close window using easymotion

-- TODO: manual review on line 360 — no mapping for dispatcher "plugin:xtd:throwunfocused"
-- hl.bind(mainMod .. " + X", hl.dsp.plugin_xtd_throwunfocused("special:scratchpad"), { description = "Throw all unfocused windows to special:scratchpad" })
--
-- TODO: manual review on line 361 — no mapping for dispatcher "plugin:xtd:bringallfrom"
-- hl.bind(mainMod .. " + SHIFT + X", hl.dsp.plugin_xtd_bringallfrom("special:scratchpad"), { description = "Bring all windows from specail:scratchpad" })
-- TODO: manual review on line 362 — no mapping for dispatcher "plugin:xtd:closeunfocused"
-- hl.bind(mainMod .. " + CTRL + X", hl.dsp.plugin_xtd_closeunfocused(), { description = "Close all unfocused windows on the current workspace." })

hl.bind(mainMod .. " + SHIFT + BACKSPACE", hl.dsp.submap("clean"), { description = "Disable all keybindings" })
-- The submap name clean is arbitrary
hl.define_submap("clean", function()
	hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind("F8", hl.dsp.exec_cmd("~/.config/hypr/scripts/switch_monitors.sh"), { description = "Switch monitors" })
