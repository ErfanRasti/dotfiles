---------------------
---- KEYBINDINGS ----
---------------------
-- The same shortcuts as umbriel (~/.config/umbriel/config/binds.toml), mapped onto Hyprland,
-- in the same order. Shell keys (launcher, volume, panels, screenshots...) are overridden by
-- config/noctalia.lua or config/dms.lua, like umbriel's config/noctalia.toml.
-- Hyprland-only extras (zoom, effects, rofi, plugins) sit on keys umbriel leaves free.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"
local M = mainMod .. " + "

---------------------
----   HELPERS   ----
---------------------

-- Window-rule classes are regexes like "^(btop)$"; window.class is the plain string.
local function plain_class(class)
	return (class:gsub("[%^%$%(%)]", ""))
end

-- Toggle an app between the current workspace and special:scratchpad, launching it if needed
-- (umbriel's scripts/toggle_app.py).
local function toggle_or_launch(app_class, app_cmd)
	local class = plain_class(app_class)
	local active = hl.get_active_window()
	if active and active.class == class then
		hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
		return
	end
	for _, w in ipairs(hl.get_windows()) do
		if w.class == class then
			local ws = hl.get_active_workspace()
			hl.dispatch(hl.dsp.window.move({ workspace = ws and ws.name or "e+0", follow = true, window = w }))
			hl.dispatch(hl.dsp.focus({ window = w }))
			return
		end
	end
	hl.exec_cmd(app_cmd)
end
TOGGLE_APP = toggle_or_launch -- shared with config/dms.lua

local function toggle(app_class, app_cmd)
	return function()
		toggle_or_launch(app_class, app_cmd)
	end
end

-- Run a TUI in kitty with a class the window rules can match.
local function tui(class, cmd)
	return "kitty --override confirm_os_window_close=0 --class " .. class .. " -e " .. (cmd or class)
end

-- One key, two behaviours: `scrolling` for tiled windows on a scrolling workspace,
-- `default` for every other layout and for floating windows.
function per_layout(scrolling, default)
	return function()
		local ws = hl.get_active_workspace()
		local layout = ws and ws.tiled_layout ~= "" and ws.tiled_layout or hl.get_config("general.layout")
		local win = hl.get_active_window()
		local d = default
		if scrolling and tostring(layout):lower() == "scrolling" and not (win and win.floating) then
			d = scrolling
		end
		if d then
			hl.dispatch(d)
		end
	end
end

-- Logical (scaled) box of the focused monitor
local function monitor_box()
	local m = hl.get_active_monitor()
	if not m then
		return nil
	end
	local s = (m.scale and m.scale > 0) and m.scale or 1
	return { x = m.x, y = m.y, w = m.width / s, h = m.height / s }
end

-- Move the window: floating ones by 5% of the screen per press, tiled ones by layout
-- (umbriel's scripts/move_window.sh)
local function move_window(dir)
	local short = dir:sub(1, 1)
	-- scrolling: left/right move the whole column, up/down move the window inside its column
	-- (the plain window move; Hyprland 0.57's scrolling layout has no "movewindowto" message)
	local plain = hl.dsp.window.move({ direction = short })
	local scrolling = (short == "l" or short == "r") and hl.dsp.layout("swapcol " .. short) or plain
	local tiled = per_layout(scrolling, plain)
	return function()
		local w = hl.get_active_window()
		local mb = monitor_box()
		if w and w.floating and mb then
			local dx = ({ l = -1, r = 1 })[short] or 0
			local dy = ({ u = -1, d = 1 })[short] or 0
			hl.dispatch(hl.dsp.window.move({ x = dx * mb.w * 0.05, y = dy * mb.h * 0.05, relative = true }))
		else
			tiled()
		end
	end
end

-- Snap the focused window into a screen half (umbriel's stacking regions)
local function set_region(region)
	return function()
		local mb = monitor_box()
		if not mb then
			return
		end
		local x, y, w, h = mb.x, mb.y, mb.w, mb.h
		if region == "left" then
			w = w / 2
		elseif region == "right" then
			x, w = x + w / 2, w / 2
		elseif region == "top" then
			h = h / 2
		elseif region == "bottom" then
			y, h = y + h / 2, h / 2
		end
		hl.dispatch(hl.dsp.window.float({ action = "enable" }))
		hl.dispatch(hl.dsp.window.resize({ x = math.floor(w), y = math.floor(h) }))
		hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y) }))
	end
end

-- Focus between floating and tiled windows of the workspace, or cycle the shown scratchpad
local function scratchpad_or_float_cycle()
	local special = hl.get_active_special_workspace()
	if special then
		hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
		return
	end
	local active = hl.get_active_window()
	local ws = hl.get_active_workspace()
	local best
	for _, w in ipairs(hl.get_windows()) do
		if ws and w.workspace and w.workspace.id == ws.id and w ~= active and w.mapped then
			if not active or w.floating ~= active.floating then
				if not best or w.focus_history_id < best.focus_history_id then
					best = w
				end
			end
		end
	end
	if best then
		hl.dispatch(hl.dsp.focus({ window = best }))
	elseif active then
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	end
end

-- Store the window in the scratchpad, or take it back out when it is in there
-- (umbriel's scripts/scratchpad_window.sh)
local function scratchpad_window(follow)
	return function()
		local w = hl.get_active_window()
		if not w then
			return
		end
		local in_pad = w.workspace and w.workspace.special
		if in_pad then
			local ws = hl.get_active_workspace()
			hl.dispatch(hl.dsp.window.move({ workspace = ws and ws.name or "e+0", follow = follow }))
			if follow then
				hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
			end
		else
			hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
		end
	end
end

-- Bring the most recently minimized window back
local function restore_minimized()
	local best
	for _, w in ipairs(hl.get_windows()) do
		if w.workspace and w.workspace.name == "special:minimize" then
			if not best or w.focus_history_id < best.focus_history_id then
				best = w
			end
		end
	end
	if best then
		local ws = hl.get_active_workspace()
		hl.dispatch(hl.dsp.window.move({ workspace = ws and ws.name or "e+0", follow = true, window = best }))
		hl.dispatch(hl.dsp.focus({ window = best }))
	end
end

-- Repeat a step until the window stops moving (first/last column, like niri)
local function to_edge(step)
	return function()
		local last
		for _ = 1, 50 do
			local w = hl.get_active_window()
			local pos = w and (tostring(w.address) .. ":" .. tostring(w.at and (w.at.x or w.at[1])) .. ":" .. tostring(w.at and (w.at.y or w.at[2])))
			if not w or pos == last then
				break
			end
			last = pos
			step()
		end
	end
end

-- Move the whole workspace up/down the list: swap its windows with the neighbour's and follow
-- (umbriel's workspace-move-down/up)
local function move_workspace(delta)
	return function()
		local ws = hl.get_active_workspace()
		if not ws or not ws.id or ws.id < 1 or ws.id + delta < 1 then
			return
		end
		local a, b = ws.id, ws.id + delta
		local mine, theirs = {}, {}
		for _, w in ipairs(hl.get_windows()) do
			local id = w.workspace and w.workspace.id
			if id == a then
				mine[#mine + 1] = w
			elseif id == b then
				theirs[#theirs + 1] = w
			end
		end
		for _, w in ipairs(mine) do
			hl.dispatch(hl.dsp.window.move({ workspace = b, follow = false, window = w }))
		end
		for _, w in ipairs(theirs) do
			hl.dispatch(hl.dsp.window.move({ workspace = a, follow = false, window = w }))
		end
		hl.dispatch(hl.dsp.focus({ workspace = b }))
	end
end

local function overview()
	local ov = hl.plugin.overview or hl.plugin.hyprspace
	if not (ov and ov.toggle) then
		NOTIFY("Hyprspace (overview) plugin is not loaded")
		return
	end
	local r = ov.toggle()
	if r ~= nil and type(r) ~= "boolean" then
		hl.dispatch(r)
	end
end

OVERVIEW_TOGGLE = overview -- shared with the 4-finger gesture (config/features.lua)

-- Shared with features.lua / workspace_layouts.lua
function NOTIFY(text, color)
	hl.notification.create({ text = text, timeout = 2000, color = color or primary })
end

-- Flip a boolean option by dotted key ("decoration.glow.enabled") and say so
function TOGGLE(label, key)
	local on = not hl.get_config(key)
	local cfg = on
	for part in key:reverse():gmatch("[^.]+") do
		cfg = { [part:reverse()] = cfg }
	end
	hl.config(cfg)
	NOTIFY(label .. (on and " on" or " off"))
end

-- Cursor zoom without spawning hyprctl + jq on every scroll tick
local function zoom(mult)
	return function()
		local z = 1
		if mult then
			z = math.max(1, (tonumber(hl.get_config("cursor.zoom_factor")) or 1) * mult)
		end
		hl.config({ cursor = { zoom_factor = z } })
	end
end

local rofi = "~/.config/rofi/applets/scripts/"
local layouts = { "scrolling", "floating", "dwindle", "master", "toggle" }

-- ============================================================== Layouts
-- umbriel: Mod+F1..F5 = scrolling, stacking, dwindle, master, toggle (Shift: all workspaces).
-- Hyprland has no stacking layout; "floating" floats every window of the workspace.
for i, layout in ipairs(layouts) do
	hl.bind(M .. "F" .. i, function()
		SET_LAYOUT(layout, false)
	end, { description = "Workspace layout: " .. layout })
	hl.bind(M .. "SHIFT + F" .. i, function()
		SET_LAYOUT(layout, true)
	end, { description = "All workspaces layout: " .. layout })
end
-- Game mode / smart gaps (Hyprland-only, were SUPER+F1/F2)
-- Game mode: every effect off; pressing again reloads the config, which restores them
hl.bind(M .. "CTRL + F1", function()
	if not hl.get_config("animations.enabled") then
		NOTIFY("Game mode off")
		return hl.dispatch(hl.dsp.reload_config())
	end
	local off = { enabled = false }
	hl.config({
		animations = off,
		general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
		decoration = {
			rounding = 0,
			active_opacity = 1,
			inactive_opacity = 1,
			shadow = off,
			blur = off,
			glow = off,
			wobble = off,
			motion_blur = off,
		},
	})
	if hl.plugin.hyprglass then
		hl.config({ plugin = { hyprglass = off } })
	end
	NOTIFY("Game mode on")
end, { description = "Toggle game mode" })
-- Smart gaps: the "no gaps when only one window" rules from appearance.lua
hl.bind(M .. "CTRL + F2", function()
	local on = not SMART_GAPS[1]:is_enabled()
	for _, r in ipairs(SMART_GAPS) do
		r:set_enabled(on)
	end
	hl.exec_scheduled_prop_refresh_immediately()
	NOTIFY("Smart gaps " .. (on and "on" or "off"))
end, { description = "Toggle smart gaps" })

-- Layout-specific helpers
hl.bind(M .. "ALT + T", hl.dsp.layout("togglesplit"), { description = "dwindle: flip split direction" })
hl.bind(M .. "CTRL + equal", hl.dsp.layout("addmaster"), { description = "master: one more master window" })
hl.bind(M .. "CTRL + minus", hl.dsp.layout("removemaster"), { description = "master: one less master window" })
hl.bind(M .. "ALT + RETURN", hl.dsp.window.swap({ next = true }), { description = "Swap with the next window" })
for _, d in ipairs({ { "left", "l" }, { "right", "r" }, { "up", "u" }, { "down", "d" } }) do
	hl.bind(M .. "CTRL + ALT + " .. d[1], hl.dsp.window.swap({ direction = d[2] }), { description = "Swap with the window " .. d[1] })
end
hl.bind(M .. "CTRL + ALT + K", hl.dsp.window.swap({ direction = "u" }), { description = "Swap with the window above" })
hl.bind(M .. "CTRL + ALT + J", hl.dsp.window.swap({ direction = "d" }), { description = "Swap with the window below" })
-- Snap the focused window into halves (floats it)
for _, r in ipairs({ { "left", "left" }, { "right", "right" }, { "up", "top" }, { "down", "bottom" } }) do
	hl.bind(M .. "CTRL + ALT + SHIFT + " .. r[1], set_region(r[2]), { description = "Snap the window to the " .. r[2] .. " half" })
end
hl.bind(M .. "ALT + SHIFT + C", hl.dsp.window.float({ action = "disable" }), { description = "Back to tiling (clear snap)" })

-- ============================================================== Apps & session
hl.bind(M .. "SHIFT + SLASH", hl.dsp.exec_cmd("~/.config/rofi/keybindings/run.sh -o"), { description = "Keybindings cheatsheet" })
-- SUPER+SLASH: rofi menu without a desktop shell; dms.lua / noctalia.lua rebind it to the shell's
-- keybind cheatsheet (as on niri/umbriel).
hl.bind(M .. "SLASH", hl.dsp.exec_cmd("~/.config/rofi/keybindings/run.sh"), { description = "Keybindings menu" })
-- Same rofi keys as niri/umbriel, never taken by the shell configs.
hl.bind(M .. "CTRL + SHIFT + SLASH", hl.dsp.exec_cmd("~/.config/rofi/keybindings/run.sh -o"), { description = "Keybindings cheatsheet" })
hl.bind(M .. "CTRL + SLASH", hl.dsp.exec_cmd("~/.config/rofi/keybindings/run.sh"), { description = "Keybindings menu" })
hl.bind(M .. "T", hl.dsp.exec_cmd("kitty --class kitty-main"), { description = "Open the terminal" })
hl.bind(M .. "RETURN", hl.dsp.exec_cmd(TERMINAL), { description = "Open the terminal" })
hl.bind(M .. "D", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofi_launcher.sh"), { description = "Open search menu" })
hl.bind(
	M .. "SHIFT + D",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofi_launcher.sh -a"),
	{ description = "Open alternative search menu" }
)
hl.bind(M .. "I", toggle(gnome_settings_class, SETTINGS), { description = "Toggle settings" })
hl.bind(M .. "E", toggle(nautilus_class, FILEMANAGER .. " --new-window"), { description = "Toggle the file manager" })
hl.bind(M .. "SHIFT + E", hl.dsp.exec_cmd(FILEMANAGER .. " --new-window"), { description = "New file manager window" })
hl.bind(M .. "ALT + E", toggle("yazi", tui("yazi", "bash -c yazi")), { description = "Toggle yazi" })
hl.bind(
	M .. "GRAVE",
	toggle("kitty-dropterm", "kitty --class kitty-dropterm --title kitty-dropterm"),
	{ description = "Toggle drop-down terminal" }
)
-- (umbriel's Mod+Shift+I moves the workspace up, see Workspaces)
hl.bind(M .. "CTRL + I", toggle("better_control.py", "better-control"), { description = "Toggle better-control" })

-- System monitors (open as a normal window; same key again -> scratchpad)
hl.bind("CTRL + SHIFT + ESCAPE", toggle("btop", tui("btop")), { description = "Toggle btop" })
hl.bind("CTRL + SHIFT + F1", toggle("nvtop", tui("nvtop")), { description = "Toggle nvtop" })
hl.bind("CTRL + SHIFT + F2", toggle("org.gnome.SystemMonitor", "gnome-system-monitor"), { description = "Toggle system monitor" })
hl.bind("CTRL + SHIFT + F3", toggle("io.missioncenter.MissionCenter", "missioncenter"), { description = "Toggle mission center" })
hl.bind("CTRL + SHIFT + F4", toggle("htop", tui("htop")), { description = "Toggle htop" })

-- Rofi applets
hl.bind(M .. "ALT + A", hl.dsp.exec_cmd(rofi .. "apps.sh"), { description = "Favourite apps" })
hl.bind(M .. "ALT + SHIFT + A", hl.dsp.exec_cmd(rofi .. "appsasroot.sh"), { description = "Apps as root" })
hl.bind(M .. "ALT + Q", hl.dsp.exec_cmd(rofi .. "quicklinks.sh"), { description = "Quicklinks" })
hl.bind(M .. "CTRL + B", hl.dsp.exec_cmd(rofi .. "battery.sh"), { description = "Battery menu" })
hl.bind(M .. "ALT + V", hl.dsp.exec_cmd(rofi .. "volume.sh"), { description = "Volume control" })
hl.bind(M .. "ALT + B", hl.dsp.exec_cmd(rofi .. "brightness.sh"), { description = "Brightness control" })
hl.bind(M .. "ALT + P", hl.dsp.exec_cmd(rofi .. "player.sh"), { description = "Player control" })
hl.bind(M .. "SHIFT + ESCAPE", hl.dsp.exec_cmd("~/.config/rofi/powermenu/run.sh"), { description = "Power menu" })
hl.bind(M .. "CTRL + P", hl.dsp.exec_cmd(rofi .. "powermenu.sh"), { description = "Power menu (applet)" })

-- Music / visualizer
hl.bind(M .. "ALT + CTRL + P", hl.dsp.exec_cmd("kitty --title fum fum"), { description = "Open fum" })
hl.bind(M .. "ALT + CTRL + C", hl.dsp.exec_cmd("kitty --title cava cava"), { description = "Open cava" })

hl.bind(M .. "R", hl.dsp.exec_cmd("~/.config/hypr/scripts/reload_config.sh"), { description = "Reload Hyprland and the shell" })
-- Asks first (like umbriel's session-quit), then closes apps gracefully with hyprshutdown
hl.bind(M .. "SHIFT + Q", hl.dsp.exec_cmd("~/.config/hypr/scripts/confirm_quit.sh"), { description = "Quit Hyprland (asks first)" })
hl.bind(M .. "SHIFT + P", hl.dsp.dpms({ action = "off" }), { description = "Turn the screens off" })
-- Escape hatch: pass every key to the app until pressed again (umbriel: shortcuts-inhibit-toggle)
hl.bind(M .. "CTRL + ESCAPE", hl.dsp.submap("passthrough"), { description = "Pass all keys to the app (toggle)" })
hl.define_submap("passthrough", function()
	hl.bind(M .. "CTRL + ESCAPE", hl.dsp.submap("reset"))
end)

-- ============================================================== Windows
hl.bind(M .. "O", overview, { description = "Toggle workspace overview" })
-- Tap Super alone (release without another key) for the overview, like umbriel's "Mod"
hl.bind("SUPER + SUPER_L", overview, { release = true, description = "Toggle workspace overview" })
hl.bind(M .. "Q", hl.dsp.window.close(), { description = "Close the window" })
hl.bind(M .. "F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(M .. "TAB", scratchpad_or_float_cycle, { description = "Next scratchpad window, else floating <-> tiled focus" })
hl.bind(M .. "G", hl.dsp.group.toggle(), { description = "Toggle tabbed group" })
hl.bind(M .. "CTRL + ALT + H", hl.dsp.group.prev(), { description = "Previous tab" })
hl.bind(M .. "CTRL + ALT + L", hl.dsp.group.next(), { description = "Next tab" })
hl.bind(M .. "ALT + G", function()
	TOGGLE("Tab bar", "group.groupbar.enabled")
end, { description = "Toggle the tab bar" })
hl.bind(M .. "ALT + SHIFT + G", function()
	if hl.plugin.hyprglass then
		TOGGLE("Liquid glass", "plugin.hyprglass.enabled")
	else
		NOTIFY("hyprglass is not loaded")
	end
end, { description = "Toggle liquid glass" })
hl.bind(M .. "ALT + SHIFT + P", hl.dsp.window.pin(), { description = "Pin the window to all workspaces" })

hl.bind(
	M .. "M",
	per_layout(hl.dsp.layout("fit active"), hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })),
	{ description = "Maximize (scrolling: fit the column)" }
)
hl.bind(M .. "SHIFT + M", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Maximize to edges" })
hl.bind(M .. "CTRL + M", hl.dsp.window.move({ workspace = "special:minimize", follow = false }), { description = "Minimize" })
hl.bind(M .. "ALT + M", restore_minimized, { description = "Restore the last minimized window" })
hl.bind(M .. "SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Toggle fullscreen" })

hl.bind(
	M .. "C",
	per_layout(hl.dsp.layout("center"), hl.dsp.window.center()),
	{ description = "Center the column (floating: center the window)" }
)
hl.bind(M .. "SHIFT + C", hl.dsp.window.center(), { description = "Center the window" })

-- Width / height presets and fine adjustments
hl.bind(M .. "ALT + R", per_layout(hl.dsp.layout("colresize +conf"), nil), { description = "Next column width preset" })
hl.bind(M .. "CTRL + R", per_layout(hl.dsp.layout("colresize -conf"), nil), { description = "Previous column width preset" })
-- umbriel: Mod+Shift+R cycles window heights; here it enters the resize mode (arrows/hjkl, Esc)
hl.bind(M .. "SHIFT + R", hl.dsp.submap("resize"), { description = "Resize mode" })
hl.define_submap("resize", function()
	for _, s in ipairs({
		{ keys = { "right", "l" }, x = 20, y = 0, col = "+0.05" },
		{ keys = { "left", "h" }, x = -20, y = 0, col = "-0.05" },
		{ keys = { "down", "j" }, x = 0, y = 20 },
		{ keys = { "up", "k" }, x = 0, y = -20 },
	}) do
		local plain = hl.dsp.window.resize({ x = s.x, y = s.y, relative = true })
		local action = s.col and per_layout(hl.dsp.layout("colresize " .. s.col), plain) or plain
		for _, key in ipairs(s.keys) do
			hl.bind(key, action, { repeating = true })
		end
	end
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("return", hl.dsp.submap("reset"))
end)
hl.bind(
	M .. "minus",
	per_layout(hl.dsp.layout("colresize -0.1"), hl.dsp.window.resize({ x = -50, y = 0, relative = true })),
	{ repeating = true, description = "Narrower" }
)
hl.bind(
	M .. "equal",
	per_layout(hl.dsp.layout("colresize +0.1"), hl.dsp.window.resize({ x = 50, y = 0, relative = true })),
	{ repeating = true, description = "Wider" }
)
hl.bind(M .. "SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "Shorter" })
hl.bind(M .. "SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "Taller" })

-- Consume / expel (scrolling: into / out of the neighbouring column)
local consume_l = per_layout(hl.dsp.layout("consume_or_expel prev"), hl.dsp.window.move({ direction = "l" }))
local consume_r = per_layout(hl.dsp.layout("consume_or_expel next"), hl.dsp.window.move({ direction = "r" }))
for _, k in ipairs({ "ALT + H", "BRACKETLEFT", "ALT + left" }) do
	hl.bind(M .. k, consume_l, { description = "Consume or expel left" })
end
for _, k in ipairs({ "ALT + L", "BRACKETRIGHT", "ALT + right" }) do
	hl.bind(M .. k, consume_r, { description = "Consume or expel right" })
end

-- Recent windows: Alt+Tab is the shell's switcher (noctalia.lua) or rofi
hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.config/rofi/windows/run.sh"), { description = "Window switcher" })
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("~/.config/rofi/windows/run.sh"), { description = "Window switcher" })
hl.bind("ALT + GRAVE", hl.dsp.focus({ last = true }), { description = "Back to the previous window" })
hl.bind("ALT + SHIFT + GRAVE", hl.dsp.window.cycle_next({ prev = true }), { description = "Previous window in order" })

-- ============================================================== Focus
-- Scrolling: the layout's own "focus" moves by column order (and scrolls the strip), so windows
-- off-screen or behind the overview panel are reachable; the geometric focus only finds windows
-- whose edges touch. Other layouts / floating windows keep the geometric focus.
local function focus_raw(name)
	return per_layout(hl.dsp.layout("focus " .. name:sub(1, 1)), hl.dsp.focus({ direction = name }))
end

-- Like umbriel's focus.sh: up/down = "window-focus-or-workspace" (at the top/bottom of a column,
-- or on an empty workspace, go to the workspace above/below, the empty one after the last too);
-- left/right = "window-focus-or-output" (at the edge, try the next monitor).
local function focus_dir(name)
	local move, short = focus_raw(name), name:sub(1, 1)
	local to_monitor = hl.dsp.focus({ monitor = short })
	return function()
		local before = hl.get_active_window()
		local addr = before and before.address
		if addr then
			move()
			local after = hl.get_active_window()
			if after and after.address ~= addr then
				return
			end
		end
		if short == "l" or short == "r" then
			return hl.dispatch(to_monitor)
		end
		local ws = hl.get_active_workspace()
		local id = ws and ws.id or 0
		if short == "u" then
			if id > 1 then
				hl.dispatch(hl.dsp.focus({ workspace = id - 1 }))
			end
			return
		end
		if id < 1 then
			return
		end
		-- down from an empty workspace only if something below has windows (niri keeps one empty)
		if not addr then
			local below = false
			for _, w in ipairs(hl.get_workspaces()) do
				if w.id and w.id > id and (w.windows or 0) > 0 then
					below = true
					break
				end
			end
			if not below then
				return
			end
		end
		hl.dispatch(hl.dsp.focus({ workspace = id + 1 }))
	end
end
for _, d in ipairs({ { "left", "H" }, { "right", "L" }, { "up", "K" }, { "down", "J" } }) do
	local focus, desc = focus_dir(d[1]), { description = "Focus " .. d[1] }
	hl.bind(M .. d[1], focus, desc)
	hl.bind(M .. d[2], focus, desc)
end

local focus_l, focus_r = focus_raw("left"), focus_raw("right")
hl.bind(M .. "Home", to_edge(function() focus_l() end), { description = "Focus the first column" })
hl.bind(M .. "End", to_edge(function() focus_r() end), { description = "Focus the last column" })

-- ============================================================== Move
-- Floating windows move 5% of the screen per press; tiled ones move with the layout
for _, d in ipairs({ { "left", "H" }, { "right", "L" }, { "up", "K" }, { "down", "J" } }) do
	local move = move_window(d[1])
	hl.bind(M .. "CTRL + " .. d[1], move, { repeating = true, description = "Move the window " .. d[1] })
	hl.bind(M .. "CTRL + " .. d[2], move, { repeating = true, description = "Move the window " .. d[1] })
end

local move_l, move_r = move_window("left"), move_window("right")
hl.bind(M .. "CTRL + Home", to_edge(move_l), { description = "Move the column to the start" })
hl.bind(M .. "CTRL + End", to_edge(move_r), { description = "Move the column to the end" })

-- ============================================================== Monitors
for _, d in ipairs({ { "left", "H", "l" }, { "right", "L", "r" }, { "up", "K", "u" }, { "down", "J", "d" } }) do
	for _, key in ipairs({ d[1], d[2] }) do
		hl.bind(M .. "SHIFT + " .. key, hl.dsp.focus({ monitor = d[3] }), { description = "Focus the monitor " .. d[1] })
		hl.bind(
			M .. "SHIFT + CTRL + " .. key,
			hl.dsp.window.move({ monitor = d[3] }),
			{ description = "Move the window to the monitor " .. d[1] }
		)
		hl.bind(
			M .. "SHIFT + ALT + " .. key,
			hl.dsp.workspace.move({ monitor = d[3] }),
			{ description = "Move the workspace to the monitor " .. d[1] }
		)
	end
end

-- ============================================================== Workspaces
hl.bind(M .. "Page_Down", hl.dsp.focus({ workspace = "+1" }), { description = "Next workspace" })
hl.bind(M .. "Page_Up", hl.dsp.focus({ workspace = "-1" }), { description = "Previous workspace" })
hl.bind(
	M .. "CTRL + Page_Down",
	hl.dsp.window.move({ workspace = "r+1" }),
	{ description = "Move the window to the next workspace" }
)
hl.bind(
	M .. "CTRL + Page_Up",
	hl.dsp.window.move({ workspace = "r-1" }),
	{ description = "Move the window to the previous workspace" }
)
hl.bind(M .. "SHIFT + Page_Down", move_workspace(1), { description = "Move the workspace down" })
hl.bind(M .. "SHIFT + Page_Up", move_workspace(-1), { description = "Move the workspace up" })
hl.bind(M .. "SHIFT + U", move_workspace(1), { description = "Move the workspace down" })
hl.bind(M .. "SHIFT + I", move_workspace(-1), { description = "Move the workspace up" })

-- Move the focused window to the next / previous workspace (you follow it)
for _, k in ipairs({ { "J", "r+1", "next" }, { "down", "r+1", "next" }, { "K", "r-1", "previous" }, { "up", "r-1", "previous" } }) do
	hl.bind(M .. "ALT + " .. k[1], hl.dsp.window.move({ workspace = k[2] }), { description = "Move the window to the " .. k[3] .. " workspace" })
end
hl.bind(M .. "P", hl.dsp.focus({ workspace = "previous" }), { description = "Back to the previous workspace" })

for i = 1, 10 do
	local key = tostring(i % 10)
	hl.bind(M .. key, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(M .. "CTRL + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move the window to workspace " .. i })
	hl.bind(M .. "SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move the window to workspace " .. i })
end

-- ============================================================== Scratchpad
hl.bind(M .. "W", scratchpad_window(true), { description = "Store in / take out of the scratchpad" })
hl.bind(M .. "SHIFT + W", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Show / hide the scratchpad" })
hl.bind(M .. "CTRL + W", scratchpad_window(false), { description = "Take out of the scratchpad (stay open)" })
hl.bind(M .. "SHIFT + TAB", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Show the scratchpad" })
hl.bind(M .. "SHIFT + S", hl.dsp.workspace.toggle_special("minimize"), { description = "Show / hide minimized windows" })

-- ============================================================== Mouse wheel
hl.bind(M .. "mouse_down", hl.dsp.focus({ workspace = "+1" }), { description = "Next workspace" })
hl.bind(M .. "mouse_up", hl.dsp.focus({ workspace = "-1" }), { description = "Previous workspace" })
hl.bind(M .. "CTRL + mouse_down", hl.dsp.window.move({ workspace = "r+1" }), { description = "Move the window to the next workspace" })
hl.bind(M .. "CTRL + mouse_up", hl.dsp.window.move({ workspace = "r-1" }), { description = "Move the window to the previous workspace" })
hl.bind(M .. "SHIFT + mouse_down", focus_dir("right"), { description = "Focus right" })
hl.bind(M .. "SHIFT + mouse_up", focus_dir("left"), { description = "Focus left" })
hl.bind(M .. "CTRL + SHIFT + mouse_down", move_window("right"), { description = "Move the column right" })
hl.bind(M .. "CTRL + SHIFT + mouse_up", move_window("left"), { description = "Move the column left" })
hl.bind(M .. "mouse_right", focus_dir("right"), { description = "Focus right" })
hl.bind(M .. "mouse_left", focus_dir("left"), { description = "Focus left" })
hl.bind(M .. "CTRL + mouse_right", move_window("right"), { description = "Move the column right" })
hl.bind(M .. "CTRL + mouse_left", move_window("left"), { description = "Move the column left" })

-- Move/resize windows with the mouse
hl.bind(M .. "mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind(M .. "mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

---------------------------------------------------------------------------
---- Hyprland-only extras (keys umbriel leaves free)
---------------------------------------------------------------------------
-- Cursor zoom: SUPER+ALT + wheel / = / - / 0, keypad +/-
hl.bind(M .. "ALT + mouse_down", zoom(1.1), { description = "Zoom in" })
hl.bind(M .. "ALT + mouse_up", zoom(0.9), { description = "Zoom out" })
hl.bind(M .. "ALT + equal", zoom(1.1), { repeating = true, description = "Zoom in" })
hl.bind(M .. "ALT + minus", zoom(0.9), { repeating = true, description = "Zoom out" })
hl.bind(M .. "ALT + 0", zoom(nil), { description = "Reset zoom" })
hl.bind(M .. "KP_ADD", zoom(1.1), { repeating = true, description = "Zoom in" })
hl.bind(M .. "KP_SUBTRACT", zoom(0.9), { repeating = true, description = "Zoom out" })

-- Show desktop
hl.bind(M .. "CTRL + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/show_desktop.sh"), { description = "Toggle show desktop" })
hl.bind(M .. "CTRL + SHIFT + D", hl.dsp.workspace.toggle_special("desktop"), { description = "Toggle desktop workspace" })

-- Plugins (SUPER+F8..F11 effects live in config/features.lua)
hl.bind(M .. "CTRL + ALT + B", function()
	if hl.plugin.hyprbars then
		TOGGLE("Title bars", "plugin.hyprbars.enabled")
	else
		NOTIFY("hyprbars is not loaded")
	end
end, { description = "Toggle title bars" })
hl.bind("F8", hl.dsp.exec_cmd("~/.config/hypr/scripts/switch_monitors.sh"), { description = "Switch monitors" })
hl.bind(M .. "CTRL + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -al"), { description = "Pick a color" })
hl.bind(M .. "SHIFT + BACKSPACE", hl.dsp.submap("passthrough"), { description = "Pass all keys to the app (toggle)" })

-- Wordbook: copy the selection, then toggle the dictionary
local function wordbook()
	hl.exec_cmd("ydotool key 29:1 46:1 46:0 29:0")
	toggle_or_launch("dev.mufeed.Wordbook", "flatpak run dev.mufeed.Wordbook")
end
hl.bind(M .. "SHIFT + mouse:272", wordbook, { description = "Copy text and open Wordbook" })
hl.bind(M .. "SHIFT + RETURN", wordbook, { description = "Copy text and open Wordbook" })

---------------------------------------------------------------------------
---- Standalone shell keys (replaced by config/noctalia.lua / config/dms.lua)
---------------------------------------------------------------------------
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("vicinae toggle"), { description = "Launcher" })
hl.bind(M .. "V", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofi_cliphist.sh"), { description = "Clipboard history" })
hl.bind(M .. "PERIOD", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_rofimoji.sh"), { description = "Emoji picker" })
hl.bind(M .. "N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "Notifications" })
hl.bind(M .. "ALT + W", toggle("waypaper", "waypaper"), { description = "Wallpaper picker" })
hl.bind(M .. "ESCAPE", hl.dsp.exec_cmd("hyprlock"), { description = "Lock the screen" })
hl.bind("ALT + F4", hl.dsp.exec_cmd("~/.config/rofi/powermenu/run.sh"), { description = "Power menu" })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "Suspend" })
hl.bind("XF86Calculator", hl.dsp.exec_cmd("gnome-calculator"), { description = "Calculator" })

-- Screenshots
local shot = "~/.config/hypr/scripts/hyprshot_notify.sh "
hl.bind("PRINT", hl.dsp.exec_cmd(shot .. "region"), { description = "Screenshot a region" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd(shot .. "output"), { description = "Screenshot the monitor" })
hl.bind(M .. "PRINT", hl.dsp.exec_cmd(shot .. "window"), { description = "Screenshot the window" })
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd(rofi .. "screenshot.sh"), { description = "Screenshot menu" })

-- Media keys (work while locked)
local vol_sound = ";paplay ~/.nix-profile/share/sounds/ocean/stereo/audio-volume-change.oga"
local function media_opts(desc, repeating)
	return { locked = true, repeating = repeating ~= false, description = desc }
end
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0;swayosd-client --output-volume raise" .. vol_sound),
	media_opts("Raise the volume")
)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower" .. vol_sound), media_opts("Lower the volume"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), media_opts("Toggle mute", false))
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle;pactl set-source-volume @DEFAULT_SOURCE@ 25%"),
	media_opts("Toggle microphone mute", false)
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("swayosd-client --device intel_backlight --brightness raise"),
	media_opts("Brightness up")
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("swayosd-client --device intel_backlight --brightness lower"),
	media_opts("Brightness down")
)
hl.bind(
	"CAPS + Caps_Lock",
	hl.dsp.exec_cmd("swayosd-client --caps-lock;paplay ~/.nix-profile/share/sounds/freedesktop/stereo/dialog-warning.oga"),
	{ description = "Caps-Lock" }
)
hl.bind("MOD2 + Num_Lock", hl.dsp.exec_cmd("swayosd-client --num-lock"), { description = "Num-Lock" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), media_opts("Next track"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"), media_opts("Previous track"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), media_opts("Play/pause", false))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), media_opts("Play/pause", false))
