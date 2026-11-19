-------------------
---- SCROLLING ----
----  LAYOUT   ----
-------------------

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/

hl.config({
	general = {
		layout = "scrolling",
	},
})

-- Animations
-- Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 1.94,
	bezier = "almostLinear",
	style = "slidevert",
})
hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = 1.21,
	bezier = "almostLinear",
	style = "slidevert",
})
hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = 1.94,
	bezier = "almostLinear",
	style = "slidevert",
})

-- Scrolling keybindings live in binds.lua: every layout-sensitive key goes through
-- per_layout(), so the same key does the scrolling action here and the normal
-- action on dwindle/master/floating windows. No unbind/rebind needed.
