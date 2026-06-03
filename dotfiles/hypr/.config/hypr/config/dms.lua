-- --- dms shell bindings ---

-- Autostarts
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/reload_config.sh")
	hl.exec_cmd("dsearch serve")
end)

-- Permissions
hl.permission({ binary = "/usr/bin/dms", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/bin/quickshell", type = "screencopy", mode = "allow" })

-- Hard-override any earlier bindings for these combos
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.unbind("ALT + SPACE")
hl.unbind(mainMod .. " + COMMA")
hl.unbind("XF86AudioRaiseVolume")
hl.unbind("XF86AudioLowerVolume")
hl.unbind("XF86AudioMute")
hl.unbind("XF86AudioMicMute")
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.unbind(mainMod .. " + N")
hl.unbind(mainMod .. " + CTRL + SHIFT + B")
hl.unbind(mainMod .. " + ALT + W")
hl.unbind(mainMod .. " + A")
hl.unbind(mainMod .. " + V")
hl.unbind(mainMod .. " + ESCAPE")
hl.unbind(mainMod .. " + PERIOD")
hl.unbind("ALT + F4")
hl.unbind(mainMod .. " + SLASH")
hl.unbind("PRINT")
hl.unbind("SHIFT + PRINT")
hl.unbind(mainMod .. " + SHIFT + CTRL + P")
hl.unbind("CTRL + ALT + DELETE")
hl.unbind("CTRL + SHIFT + F5")
hl.unbind(mainMod .. " + SLASH") -- Second occurrence-- spotlight

-- Spotlight
hl.bind(
	"ALT + SPACE",
	hl.dsp.exec_cmd("dms ipc call spotlight toggle"),
	{ description = "[SHELL:dms] Toggle spotlight menu" }
)

-- Shell settings
hl.bind(
	mainMod .. " + COMMA",
	hl.dsp.exec_cmd("dms ipc call settings toggle"),
	{ description = "[SHELL:dms] Toggle shell settings" }
)

-- Audio (allow-when-locked=true -> use bindl)
-- e at the end: allows the binding to repeat while you hold the key down
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("dms ipc call audio increment 5"),
	{ locked = true, repeating = true, description = "[SHELL:dms] Raise the volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("dms ipc call audio decrement 5"),
	{ locked = true, repeating = true, description = "[SHELL:dms] Lower the volume" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("dms ipc call audio mute"),
	{ locked = true, repeating = true, description = "[SHELL:dms] Toggle mute audio" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("dms ipc call audio micmute"),
	{ locked = true, repeating = true, description = "[SHELL:dms] Toggle mute microphone" }
)

-- Backlight (allow-when-locked=true -> use bindl)
-- e at the end: allows the binding to repeat while you hold the key down
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("dms ipc call brightness increment 5 backlight:intel_backlight"),
	{ locked = true, repeating = true, description = "[SHELL:dms] Turn the brightness up" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("dms ipc call brightness decrement 5 backlight:intel_backlight"),
	{ locked = true, repeating = true, description = "[SHELL:dms] Turn the brightness down" }
)

-- dms toggles
hl.bind(
	mainMod .. " + N",
	hl.dsp.exec_cmd("dms ipc call notifications toggle"),
	{ description = "[SHELL:dms] Toggle notifications panel" }
)
hl.bind(
	mainMod .. " + CTRL + SHIFT + B",
	hl.dsp.exec_cmd("dms ipc call dock toggleAutoHide"),
	{ description = "[SHELL:dms] Toggle dock auto-hide" }
)
hl.bind(
	mainMod .. " + ALT + W",
	hl.dsp.exec_cmd("dms ipc call dash toggle wallpaper"),
	{ description = "[SHELL:dms] Toggle wallpaper dashboard" }
)
hl.bind(
	mainMod .. " + A",
	hl.dsp.exec_cmd("dms ipc call control-center toggle"),
	{ description = "[SHELL:dms] Toggle control center" }
)
hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd("dms ipc call clipboard toggle"),
	{ description = "[SHELL:dms] Toggle clipboard manager" }
)
hl.bind(
	mainMod .. " + ESCAPE",
	hl.dsp.exec_cmd("dms ipc call lock lock"),
	{ description = "[SHELL:dms] Lock the session" }
)
hl.bind(
	mainMod .. " + PERIOD",
	hl.dsp.exec_cmd("dms ipc call spotlight toggleQuery :"),
	{ description = "[SHELL:dms] Open spotlight emoji panel" }
)
hl.bind("ALT + F4", hl.dsp.exec_cmd("dms ipc call powermenu toggle"), { description = "[SHELL:dms] Toggle power menu" })
-- bind = $mainMod, SLASH, exec, dms ipc call keybinds toggle hyprland # [SHELL:dms] Toggle keybindings overlay

-- Screenshot
hl.bind("PRINT", hl.dsp.exec_cmd("dms screenshot"), { description = "[SHELL:dms] Take area screenshot" })
hl.bind(
	"SHIFT + PRINT",
	hl.dsp.exec_cmd("dms screenshot full"),
	{ description = "[SHELL:dms] Take full screen screenshot" }
)

-- Color picker
hl.bind(
	mainMod .. " + SHIFT + CTRL + P",
	hl.dsp.exec_cmd("dms color pick -a"),
	{ description = "[SHELL:dms] Pick color from screen (auto copy)" }
)

-- Task Manager
hl.bind(
	"CTRL + ALT + DELETE",
	hl.dsp.exec_cmd("dms ipc call processlist toggle"),
	{ description = "[SHELL:dms] Toggle task manager" }
)

-- toggle_app.sh
hl.bind(
	"CTRL + SHIFT + F5",
	hl.dsp.exec_cmd(
		'~/.config/hypr/scripts/toggle_app.sh "dgop" "kitty --override confirm_os_window_close=0 --class dgop --title dgop dgop"'
	),
	{ description = "[SHELL:dms] Toggle dgop system monitor" }
)

-- Windowrules for dgop
local dgop_class = "^(dgop)$"
hl.window_rule({
	name = "dgop",
	match = {
		class = dgop_class,
	},
	center = true,
	float = true,
	size = "(monitor_w*0.8) (monitor_h*0.8)",
})

-- Windowrules for dms settings
hl.window_rule({
	name = "dms-settings",
	match = {
		class = "org.quickshell",
		title = "Settings",
	},
	center = true,
	float = true,
	size = "(monitor_w*0.6) (monitor_h*0.8)",
})

-- Layerrules
hl.layer_rule({
	name = "dms",
	match = {
		namespace = "dms:.*",
	},
	blur = true,
	ignore_alpha = 0.2,
})

hl.layer_rule({
	name = "dms-exception",
	match = {
		namespace = "dms:workspace-overview",
	},
	-- TODO: manual review — disable "blur" has no layer_rule directive analog
	ignore_alpha = 0.0,
})
