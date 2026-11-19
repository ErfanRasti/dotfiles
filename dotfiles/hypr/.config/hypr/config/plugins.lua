-----------------
---- PLUGINS ----
-----------------
-- Plugins are built by NixOS against the running Hyprland and linked into /etc/hypr/plugins
-- (nixos-config/host/modules/hyprland-plugins.nix). No hyprpm: add/remove a plugin there and
-- `rebuild`; every .so listed below that exists gets loaded.
--
-- Hyprland loads config plugins *after* the config pass and then reloads the config, so a
-- plugin's options/Lua API only exist on that second pass; settings are applied there.
-- Loading is also gated by ecosystem.enforce_permissions; see config/permissions.lua.
local PLUGIN_DIR = "/etc/hypr/plugins/"
local PLUGINS = { "hyprglass", "hyprbars", "hyprspace" }

-- True when a plugin is loaded (names as reported by the plugin, compared case-insensitively)
function HAS_PLUGIN(name)
	name = name:lower()
	for _, p in ipairs(hl.get_loaded_plugins()) do
		local n = tostring(p.name or ""):lower()
		if n == name or n:find(name, 1, true) then
			return true
		end
	end
	return false
end

-- Which plugins NixOS installed (checked once per config pass)
local installed = {}
for _, name in ipairs(PLUGINS) do
	local f = io.open(PLUGIN_DIR .. name .. ".so", "r")
	installed[name] = f ~= nil
	if f then
		f:close()
	end
end

-- Per-plugin settings, run once the plugin is loaded
local SETTINGS = {}

-- hyprglass: macOS-like liquid glass on windows and the shell's bar/panels
-- (built by NixOS from hyprnux/hyprglass). Check with `hyprctl configerrors`.
-- Kept cheap on purpose:
--   xray = true        the glass shows the wallpaper, never the apps underneath, so it is not
--                      re-rendered whenever another window changes (same as umbriel's cached blur)
--   frost/self_sample  off: both re-blur busy content
--   skip_opaque_windows / blur_fold: no glass under windows that hide it, fewer blur passes
--   live_resample      off for layers: bar/panels don't re-render behind a playing video
-- Glass replaces Hyprland's blur on glassed windows (manage_window_blur), so it is not paid twice.
-- SUPER+ALT+SHIFT+G toggles it (binds.lua), like umbriel.
SETTINGS.hyprglass = function()
	local hg = hl.plugin.hyprglass

	hg.config({
		default_theme = "dark",
		default_preset = "pomme", -- built-in Apple Liquid Glass look: thin edge lensing, soft top light, faint bevel
		xray = true,
		frost = 0,
		self_sample = 0,
		skip_opaque_windows = true,
		blur_fold = true,
		layers = { enabled = true, live_resample = false },
	})

	-- Layer surfaces: listing a namespace whitelists it (only listed layers get glass)
	if DESKTOP_SHELL == "noctalia" then
		for _, ns in ipairs({
			"noctalia-bar-default",
			"noctalia-panel",
			"noctalia-attached-panel",
			"noctalia-dock",
			"noctalia-notification",
			"noctalia-osd",
		}) do
			hg.layer(ns, { preset = "pomme", mask_threshold = 0.05 })
		end
	elseif DESKTOP_SHELL == "dms" then
		-- Dock, notifications and every desktop widget (layer "dms:desktop-widget:<type>:<id>",
		-- read from DMS's settings so new widgets get glass too); never the wallpaper layers
		hg.layer("dms:dock", { preset = "pomme", mask_threshold = 0.05 })
		hg.layer("dms:notification-popup", { preset = "pomme" })
		local f = io.open(os.getenv("HOME") .. "/.config/DankMaterialShell/settings.json", "r")
		if f then
			local json = f:read("a")
			f:close()
			local block = json:match('"desktopWidgetInstances"%s*:%s*(%b[])') or ""
			for obj in block:gmatch("%b{}") do
				local id, wtype = obj:match('"id"%s*:%s*"([^"]+)"'), obj:match('"widgetType"%s*:%s*"([^"]+)"')
				if id and wtype then
					hg.layer("dms:desktop-widget:" .. wtype .. ":" .. id, { preset = "pomme", mask_threshold = 0.05 })
				end
			end
		end
	else
		hg.layer("waybar", { preset = "pomme", mask_threshold = 0.05 })
		hg.layer("swaync", { preset = "pomme" })
	end
	hg.layer("debug-panel", { exclude = true })

	-- Extra presets, per window via the tag hyprglass_preset_<name>
	hg.preset("clear", {
		glass_opacity = 0.8,
		blur_strength = 1.5,
		dark = { brightness = 0.7 },
		light = { brightness = 1.2 },
	})
	hg.preset("contrasted", {
		inherits = "high_contrast",
		contrast = 1.2,
		adaptive_dim = 1.5,
		dark = { tint_color = 0x02142aa9 },
	})
end

-- hyprbars: off by default, SUPER+CTRL+ALT+B toggles (binds.lua)
SETTINGS.hyprbars = function()
	hl.config({
		plugin = {
			hyprbars = {
				enabled = false,
				bar_height = 15,
				bar_blur = true,
				bar_title_enabled = true,
				col = { text = primary },
				bar_buttons_alignment = "left",
				bar_text_size = 10,
				bar_text_font = "CaskaydiaCove Nerd Font Propo",
				icon_on_hover = true,
				bar_part_of_window = true, -- shadow around the bar too
				bar_precedence_over_border = false, -- bar outside the border
				bar_padding = 5,
				bar_button_padding = 2,
				inactive_button_color = secondary,
				on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'",
			},
		},
	})
	local hb = hl.plugin.hyprbars
	hb.add_button({
		bg_color = red_value,
		fg_color = white_value,
		size = 10,
		icon = "",
		action = "hyprctl dispatch 'hl.dsp.window.close()'",
	})
	hb.add_button({
		bg_color = green_value,
		fg_color = white_value,
		size = 10,
		icon = "",
		action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'",
	})
	hb.add_button({
		bg_color = yellow_value,
		fg_color = white_value,
		size = 10,
		icon = "",
		action = "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:scratchpad\", follow = false })'",
	})
end

-- hyprspace: workspace overview, SUPER+O (binds.lua)
-- Vertical like niri/umbriel: workspaces stacked top to bottom in a column on the left
-- (`vertical` comes from nixos-config/host/modules/hyprspace-vertical.patch; set it to false
-- for Hyprspace's original strip along the top, where panelHeight is the strip height).
SETTINGS.hyprspace = function()
	hl.config({
		plugin = {
			overview = {
				vertical = true,
				fitWorkspaces = true, -- show every window, incl. off-screen scrolling columns
				overrideGaps = false, -- keep the normal gaps under the overview (like umbriel)
				disableGestures = true, -- the 4-finger swipe toggles it (features.lua), 3 fingers switch workspace
				panelHeight = 380, -- column width (scaled px) in vertical mode
				workspaceMargin = 16,
				centerAligned = true, -- center the column of workspaces vertically
				showSpecialWorkspace = true,
				showEmptyWorkspace = true,
				showNewWorkspace = true, -- an empty workspace at the end, like niri
			},
		},
	})
end

-- Declare every installed plugin on EVERY config pass. Hyprland treats the hl.plugin.load()
-- calls of the latest pass as the wanted set: a plugin left out of a pass is unloaded, and each
-- new load triggers another config reload. Skipping already-loaded plugins therefore caused an
-- endless load -> reload -> unload loop (25k cycles in two minutes, then a crash).
for _, name in ipairs(PLUGINS) do
	if installed[name] then
		hl.plugin.load(PLUGIN_DIR .. name .. ".so")
	end
end

-- At startup the plugins are not loaded yet during this pass; Hyprland loads them right after
-- and reloads the config. On that pass they are present, so their settings apply here.
local errors = {}
for _, name in ipairs(PLUGINS) do
	if installed[name] and HAS_PLUGIN(name) and SETTINGS[name] then
		local ok, err = pcall(SETTINGS[name])
		if not ok then
			errors[#errors + 1] = name .. ": " .. tostring(err)
		end
	end
end
-- Shown in Hyprland's error overlay; everything above has already been applied.
-- (assert, not error(): colors.lua defines a color named `error`.)
assert(#errors == 0, "plugin settings failed: " .. table.concat(errors, "; "))
