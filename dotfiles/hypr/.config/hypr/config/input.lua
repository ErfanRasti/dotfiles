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
		-- Click-to-focus like umbriel (follows_mouse = false): hovering never moves keyboard focus,
		-- clicking does; scrolling still goes to the window under the cursor.
		follow_mouse = 2,
		sensitivity = 0, -- mouse: no change (umbriel leaves it at default); touchpad below
		touchpad = {
			natural_scroll = true, -- also sets the direction of the swipe gestures
			tap_to_click = true,
			disable_while_typing = true,
		},
	},

	-- https://wiki.hyprland.org/Configuring/Basics/Variables/#gestures
	gestures = {
		-- How much the swipe has to proceed in order to commence it.
		workspace_swipe_cancel_ratio = 0.15,
	},
})

-- Touchpad, same as umbriel's [input.touchpad] (`hyprctl devices` lists the names)
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
	name = "touchpad",
	sensitivity = 0.4,
	tap_to_click = true,
	disable_while_typing = true,
	natural_scroll = true,
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
		hl.exec_cmd("~/.config/hypr/scripts/show_desktop.sh")
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
