------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "auto",
	scale = "1.25",
	vrr = 1,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "preferred",
	position = "auto",
	scale = "auto",
	vrr = 1,
})

-- Unscale XWayland
hl.config({ xwayland = { force_zero_scaling = true } })
