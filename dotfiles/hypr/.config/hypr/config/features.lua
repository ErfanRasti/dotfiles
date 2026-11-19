-----------------------------
---- HYPRLAND 0.57 EXTRAS ----
-----------------------------
-- New in the Lua-config era: glow, wobbly windows, motion blur, shader blur
-- variants, event hooks and Lua gesture callbacks.
-- Comment out require("config.features") in hyprland.lua to drop all of it.

local mainMod = "SUPER"

---------------------
---- DECORATION  ----
---------------------
hl.config({
	decoration = {
		-- Soft colored halo around the focused window (matugen colors)
		glow = {
			enabled = true,
			range = 12,
			render_power = 3,
			color = primary,
			color_inactive = "0x00000000",
		},

		-- Jelly windows while dragging/resizing. Cheap; tune stiffness/damping to taste.
		wobble = {
			enabled = true,
			mesh = 8,
			stiffness = 220,
			damping = 22,
			mass = 1,
			intensity = 0.8,
		},

		-- Off by default: samples every frame of an animation, costs GPU on the iGPU.
		motion_blur = {
			enabled = false,
			samples = 6,
		},

		-- Parameters for the shader blur variants. Variant 0 is the classic kawase blur
		-- from appearance.lua; SUPER+F9 cycles through the rest live.
		blur = {
			acrylic = { tint = surface },
			aurora = { color1 = primary, color2 = tertiary },
		},
	},
})

---------------------
----   TOGGLES   ----
---------------------
local BLUR_VARIANTS = 10 -- decoration.blur.variant accepts 0..10

local function cycle_blur(step)
	return function()
		local v = ((tonumber(hl.get_config("decoration.blur.variant")) or 0) + step) % (BLUR_VARIANTS + 1)
		hl.config({ decoration = { blur = { variant = v } } })
		NOTIFY("Blur variant " .. v .. (v == 0 and " (classic)" or ""))
	end
end

hl.bind(mainMod .. " + F8", function()
	TOGGLE("Wobbly windows", "decoration.wobble.enabled")
end, { description = "Toggle wobbly windows" })
hl.bind(mainMod .. " + F9", cycle_blur(1), { description = "Next blur variant" })
hl.bind(mainMod .. " + SHIFT + F9", cycle_blur(-1), { description = "Previous blur variant" })
hl.bind(mainMod .. " + F10", function()
	TOGGLE("Motion blur", "decoration.motion_blur.enabled")
end, { description = "Toggle motion blur" })
hl.bind(mainMod .. " + F11", function()
	TOGGLE("Glow", "decoration.glow.enabled")
end, { description = "Toggle window glow" })

-- (A custom hl.layout.register() grid layout used to live here. Removed: Hyprland 0.57.2
-- crashes while unregistering Lua layouts when the config manager is torn down at exit.)

---------------------
----   GESTURES  ----
---------------------
-- Like umbriel (workspaces stacked vertically, columns side by side):
--   3 fingers up/down     switch workspace
--   3 fingers left/right  scroll the column strip (scrolling layout)
--   4 fingers up/down     open / close the overview
hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({ fingers = 4, direction = "vertical", action = function()
	OVERVIEW_TOGGLE()
end })

---------------------
----    EVENTS   ----
---------------------
-- Privacy indicator: tell me whenever something starts/stops capturing the screen.
hl.on("screenshare.state", function(state)
	if type(state) == "boolean" then
		NOTIFY(state and "Screen sharing started" or "Screen sharing stopped", state and red or primary)
	else
		NOTIFY("Screen sharing state changed")
	end
end)
