---------------
---- INPUT ----
---------------
hl.config({
	-- https://wiki.hyprland.org/Configuring/Basics/Variables/#input
	input = {
		kb_layout = "us,ir",
		kb_variant = ",winkeys",
		kb_model = "",
		kb_options = "grp:win_space_toggle",
		-- kb_options = "grp:win_space_toggle,grp:alt_shift_toggle",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0.25, -- -1.0 - 1.0, 0 means no modification.
		touchpad = {
			natural_scroll = true,
		},
	},

	-- https://wiki.hyprland.org/Configuring/Basics/Variables/#gestures
	gestures = {
		-- How much the swipe has to proceed in order to commence it.
		workspace_swipe_cancel_ratio = 0.15,
	},
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/

-- Zoom gestures
-- hl.gesture({
-- 	fingers = 2,
-- 	direction = "pinchout",
-- 	mods = "SUPER",
-- 	action = "cursorZoom",
-- 	zoom_level = 0.6,
-- })
--
-- hl.gesture({
-- 	fingers = 2,
-- 	direction = "pinchin",
-- 	mods = "SUPER",
-- 	action = "cursorZoom",
-- 	zoom_level = 1.5,
-- })
hl.gesture({
	fingers = 2,
	direction = "pinch",
	mods = "SUPER",
	action = "cursorZoom",
	zoom_level = 1,
	mode = "live",
})

-- Workspace gestures

-- Native alternative:
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })

-- Window gestures

hl.gesture({
	fingers = 3,
	direction = "pinch",
	action = function()
		hl.dsp.exec_cmd("~/.config/hypr/scripts/show_desktop.sh")
	end,
})

-- hl.gesture({
-- 	fingers = 4,
-- 	direction = "up",
-- 	mods = "SUPER",
-- 	action = "resize",
-- })
--
-- hl.gesture({
-- 	fingers = 4,
-- 	direction = "down",
-- 	mods = "SUPER",
-- 	action = "move",
-- })
--
-- hl.gesture({
--     fingers = 4,
--     direction = "vertical",
--     action = "fullscreen"
-- })
