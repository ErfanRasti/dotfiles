-----------------------
---- LOOK AND FEEL ----
-----------------------
-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/# https://wiki.hyprland.org/Configuring/Variables/#general

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 2,

		border_size = 2,

		-- https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
		col = {
			active_border = { colors = { primary, tertiary }, angle = 45 },
			inactive_border = secondary_container,
		},
		-- Set to true enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = true,

		-- Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
		allow_tearing = true,

		-- layout = dwindle
		layout = "dwindle",
	},
	-- https://wiki.hyprland.org/Configuring/Variables/#decoration
	decoration = {
		rounding = 10,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 0.9, -- Opacity of the active window
		inactive_opacity = 0.85, -- Opacity of inactive opacity
		dim_inactive = true, -- Make the inactive window a little dim
		dim_strength = 0.3,

		-- To minimize power usage of Hyprland disable both shadow and blur
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = shadow,
		},

		-- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
		blur = {
			enabled = true,
			size = 5, -- Blur distance
			passes = 3, -- Number of passes to perform blur filter
			ignore_opacity = true, -- Make the blur layer ignore the opacity of the window.
			new_optimizations = true, -- pre-requirement of xray
			xray = true, -- The blur doesn't sum up when two windows are on top of each other.
			vibrancy = 0.1696, -- Increase saturation of blurred colors. [0.0 - 1.0]
			special = true, -- Blur behind the special workspace
			popups = true, -- Blur popups like waybar tooltips
		},
	},
	animations = {
		enabled = true,
	},
})

-- https://wiki.hyprland.org/Configuring/Variables/#animations
-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Default springs
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 1.94,
	bezier = "almostLinear",
	style = "slidefadevert",
})
hl.animation({
	leaf = "specialWorkspaceIn",
	enabled = true,
	speed = 1.21,
	bezier = "almostLinear",
	style = "slidefadevert",
})
hl.animation({
	leaf = "specialWorkspaceOut",
	enabled = true,
	speed = 1.94,
	bezier = "almostLinear",
	style = "slidefadevert",
})
hl.animation({ leaf = "hyprfocusIn", enabled = true, speed = 1.7, bezier = "linear" })
hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 1.7, bezier = "almostLinear" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
	name = "no-gaps-wtv1",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})
hl.window_rule({
	name = "no-gaps-f1",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

-- See https://wiki.hypr.land/Configuring/Basics/Variables/#groupbar
-- and https://wiki.hypr.land/Configuring/Basics/Variables/#group
hl.config({
	group = {
		drag_into_group = 2, -- Add window to the group when dragged to the groupbar
		merge_groups_on_drag = false, -- Merge groups when dragged to eachother
		merge_groups_on_groupbar = true, -- Merge groups when dragged to groupbar
		merge_floated_into_tiled_on_groupbar = true, -- Merge floated window when dragged to the groupbar
		col = {
			border_active = { colors = { primary, tertiary }, angle = 45 },
			border_inactive = secondary_container,
		},
		groupbar = {
			gradients = true,
			font_family = "CaskaydiaCove Nerd Font Propo",
			font_weight_active = "bold",
			font_size = 14, -- Set groupbar font size
			indicator_height = 0, -- No indicator
			indicator_gap = 1, -- Gap between window and indicator
			gradient_rounding = 10,
			gradient_rounding_power = 4.0,
			gradient_round_only_edges = false,
			round_only_edges = false,
			keep_upper_gap = false,
			col = {
				-- active = primary_transparent,
				-- inactive = secondary_container_transparent
				active = { colors = { primary, tertiary }, angle = 45 },
				inactive = secondary_container,
			},
			text_color = on_primary,
			text_color_inactive = on_secondary_container,
		},
	},
})
