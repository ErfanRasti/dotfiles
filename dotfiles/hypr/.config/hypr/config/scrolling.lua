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

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
hl.unbind(mainMod .. " + L")
hl.unbind(mainMod .. " + H")
hl.unbind(mainMod .. " + K")
hl.unbind(mainMod .. " + J")
hl.bind(mainMod .. " + L", hl.dsp.layout("move +col"), { description = "[LAYOUT:scrolling] Move layout to right" })
hl.bind(mainMod .. " + H", hl.dsp.layout("move -col"), { description = "[LAYOUT:scrolling] Move layout to left" })
hl.bind(
	mainMod .. " + K",
	hl.dsp.focus({ workspace = -1 }),
	{ description = "[LAYOUT:scrolling] Move to previous workspace" }
)
hl.bind(
	mainMod .. " + J",
	hl.dsp.focus({ workspace = "+1" }),
	{ description = "[LAYOUT:scrolling] Move to next workspace" }
)

hl.unbind("ALT + R")
hl.bind("ALT + R", hl.dsp.submap("resize"), { description = "[LAYOUT:scrolling] Activate column resize" })

hl.define_submap("resize", function()
	-- If you don't unbind them you get both functionality
	-- Normal resize for floating windows
	-- Column resize for scrolling windows
	-- Don't unbind these to get the `binds.lua` functionality on flatoing windows
	-- hl.unbind("right")
	-- hl.unbind("left")
	-- hl.unbind("up")
	-- hl.unbind("down")
	-- hl.unbind("l")
	-- hl.unbind("h")
	-- hl.unbind("k")
	-- hl.unbind("j")

	hl.bind("right", hl.dsp.layout("colresize +0.05"), { repeating = true })
	hl.bind("left", hl.dsp.layout("colresize -0.05"), { repeating = true })
	hl.bind("up", hl.dsp.layout("colresize all 0.5"), { repeating = true })
	hl.bind("down", hl.dsp.layout("colresize all 0.2"), { repeating = true })
	hl.bind("l", hl.dsp.layout("colresize +0.05"), { repeating = true })
	hl.bind("h", hl.dsp.layout("colresize -0.05"), { repeating = true })
	hl.bind("k", hl.dsp.layout("colresize all 0.5"), { repeating = true })
	hl.bind("j", hl.dsp.layout("colresize all 0.2"), { repeating = true })
	-- e at the end: allows the binding to repeat while you hold the key down

	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Resize column
hl.bind(
	mainMod .. " + equal",
	hl.dsp.layout("colresize +0.05"),
	{ repeating = true, description = "[LAYOUT:scrolling] Increase window size 10px" }
)
hl.bind(
	mainMod .. " + minus",
	hl.dsp.layout("colresize -0.05"),
	{ repeating = true, description = "[LAYOUT:scrolling] Decrease window size 10px" }
)
hl.bind(
	mainMod .. " + ALT + equal",
	hl.dsp.layout("colresize all 0.5"),
	{ repeating = true, description = "[LAYOUT:scrolling] Set size of all widnows 0.5" }
)
hl.bind(
	mainMod .. " + ALT + minus",
	hl.dsp.layout("colresize all 0.2"),
	{ repeating = true, description = "[LAYOUT:scrolling] Set size of all widnows 0.2" }
)

-- Move window
hl.unbind(mainMod .. " CTRL + L")
hl.unbind(mainMod .. " CTRL + H")
hl.unbind(mainMod .. " CTRL + K")
hl.unbind(mainMod .. " CTRL + J")
hl.bind(
	mainMod .. " + CTRL + L",
	hl.dsp.layout("movewindowto r"),
	{ description = "[LAYOUT:scrolling] Move window to right" }
)
hl.bind(
	mainMod .. " + CTRL + H",
	hl.dsp.layout("movewindowto l"),
	{ description = "[LAYOUT:scrolling] Move window to left" }
)
hl.bind(
	mainMod .. " + CTRL + K",
	hl.dsp.layout("movewindowto u"),
	{ description = "[LAYOUT:scrolling] Move window to up" }
)
hl.bind(
	mainMod .. " + CTRL + J",
	hl.dsp.layout("movewindowto d"),
	{ description = "[LAYOUT:scrolling] Move window to down" }
)

hl.unbind(mainMod .. " + M")
hl.unbind(mainMod .. " + SHIFT + M")
hl.unbind(mainMod .. " + CTRL + A")
hl.unbind(mainMod .. " + SHIFT + HOME")
hl.unbind(mainMod .. " + SHIFT + HOME")

hl.bind(
	mainMod .. " + M",
	hl.dsp.layout("fit active"),
	{ description = "[LAYOUT:scrolling] Fit the active window to the screen" }
)
hl.bind(
	mainMod .. " + SHIFT + M",
	hl.dsp.layout("fit visible"),
	{ description = "[LAYOUT:scrolling] Fit visible windows to the screen" }
)
hl.bind(
	mainMod .. " + CTRL + A",
	hl.dsp.layout("fit all"),
	{ description = "[LAYOUT:scrolling] Fit all windows to the screen" }
)
hl.bind(
	mainMod .. " + SHIFT + HOME",
	hl.dsp.layout("fit tobeg"),
	{ description = "[LAYOUT:scrolling] Fit all windows from beginning to the screen" }
)
hl.bind(
	mainMod .. " + SHIFT + HOME",
	hl.dsp.layout("fit toend"),
	{ description = "[LAYOUT:scrolling] Fit all windows to end to the screen" }
)

hl.unbind(mainMod .. " SHIFT + L")
hl.unbind(mainMod .. " SHIFT + H")
hl.unbind(mainMod .. " SHIFT + K")
hl.unbind(mainMod .. " SHIFT + J")
hl.bind(
	mainMod .. " + SHIFT + L",
	hl.dsp.layout("focus r"),
	{ description = "[LAYOUT:scrolling] Move focus right and center layout" }
)
hl.bind(
	mainMod .. " + SHIFT + H",
	hl.dsp.layout("focus l"),
	{ description = "[LAYOUT:scrolling] Move focus left and center layout" }
)
hl.bind(
	mainMod .. " + SHIFT + K",
	hl.dsp.layout("focus u"),
	{ description = "[LAYOUT:scrolling] Move focus up and center layout" }
)
hl.bind(
	mainMod .. " + SHIFT + J",
	hl.dsp.layout("focus d"),
	{ description = "[LAYOUT:scrolling] Move focus down and center layout" }
)

hl.unbind(mainMod .. " SHIFT + N")
hl.bind(
	mainMod .. " + SHIFT + N",
	hl.dsp.layout("promote"),
	{ description = "[LAYOUT:scrolling] Move the to its own new column" }
)

hl.unbind(mainMod .. " CTRL + SHIFT + L")
hl.unbind(mainMod .. " CTRL + SHIFT + H")
hl.bind(
	mainMod .. " + CTRL + SHIFT + L",
	hl.dsp.layout("swapcol r"),
	{ description = "[LAYOUT:scrolling] Swap the current column with the right neighbor" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + H",
	hl.dsp.layout("swapcol l"),
	{ description = "[LAYOUT:scrolling] Swap the current column with the left neighbor" }
)

hl.unbind(mainMod .. " CTRL + SHIFT + ALT L")
hl.unbind(mainMod .. " CTRL + SHIFT + ALT H")
hl.bind(
	mainMod .. " + CTRL + SHIFT + ALT + L",
	hl.dsp.layout("movecoltoworkspace +1"),
	{ description = "[LAYOUT:scrolling] Move the entire column to the right workspace" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + ALT + H",
	hl.dsp.layout("movecoltoworkspace -1"),
	{ description = "[LAYOUT:scrolling] Move the entire column to the left workspace" }
)

hl.unbind(mainMod .. " + C")
hl.bind(mainMod .. " + C", hl.dsp.layout("togglefit"), { description = "[LAYOUT:scrolling] Toggle center fit method" })
