-- --- Noctalia shell bindings (ported from niri) ---

-- Autostarts
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/reload_config.sh")
end)

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
hl.unbind(mainMod .. " + ALT + W")
hl.unbind(mainMod .. " + ESCAPE")
hl.unbind(mainMod .. " + A")
hl.unbind(mainMod .. " + V")
hl.unbind(mainMod .. " + PERIOD")
hl.unbind("ALT + F4")

-- Launcher
hl.bind(
	"ALT + SPACE",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call launcher toggle"),
	{ description = "[SHELL:noctalia] Toggle app launcher" }
)

-- Shell settings
hl.bind(
	mainMod .. " + COMMA",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call settings toggle"),
	{ description = "[SHELL:noctalia] Toggle shell settings" }
)

-- Audio (allow-when-locked=true -> use bindl)
-- e at the end: allows the binding to repeat while you hold the key down
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(
		'sh -lc "qs -c noctalia-shell ipc call volume increase; paplay /usr/share/sounds/ocean/stereo/audio-volume-change.oga"'
	),
	{ locked = true, repeating = true, description = "[SHELL:noctalia] Increase volume with feedback sound" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(
		'sh -lc "qs -c noctalia-shell ipc call volume decrease; paplay /usr/share/sounds/ocean/stereo/audio-volume-change.oga"'
	),
	{ locked = true, repeating = true, description = "[SHELL:noctalia] Decrease volume with feedback sound" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume muteOutput"),
	{ locked = true, repeating = true, description = "[SHELL:noctalia] Toggle output mute" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume muteInput"),
	{ locked = true, repeating = true, description = "[SHELL:noctalia] Toggle microphone mute" }
)

-- Backlight (allow-when-locked=true -> use bindl)
-- e at the end: allows the binding to repeat while you hold the key down
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness increase"),
	{ locked = true, repeating = true, description = "[SHELL:noctalia] Increase screen brightness" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness decrease"),
	{ locked = true, repeating = true, description = "[SHELL:noctalia] Decrease screen brightness" }
)

-- Noctalia panels
hl.bind(
	mainMod .. " + N",
	hl.dsp.exec_cmd('sh -lc "qs -c noctalia-shell ipc call notifications toggleHistory"'),
	{ description = "[SHELL:noctalia] Toggle notification history" }
)
hl.bind(
	mainMod .. " + ALT + W",
	hl.dsp.exec_cmd('sh -lc "qs -c noctalia-shell ipc call wallpaper toggle"'),
	{ description = "[SHELL:noctalia] Toggle wallpaper panel" }
)
hl.bind(
	mainMod .. " + ESCAPE",
	hl.dsp.exec_cmd('sh -lc "qs -c noctalia-shell ipc call lockScreen lock"'),
	{ description = "[SHELL:noctalia] Lock the session" }
)
hl.bind(
	mainMod .. " + A",
	hl.dsp.exec_cmd('sh -lc "qs -c noctalia-shell ipc call controlCenter toggle"'),
	{ description = "[SHELL:noctalia] Toggle control center" }
)
hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call launcher clipboard"),
	{ description = "[SHELL:noctalia] Open clipboard launcher" }
)
hl.bind(
	mainMod .. " + PERIOD",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call launcher emoji"),
	{ description = "[SHELL:noctalia] Open emoji picker" }
)
hl.bind(
	"ALT + F4",
	hl.dsp.exec_cmd("qs -c noctalia-shell ipc call sessionMenu toggle"),
	{ description = "[SHELL:noctalia] Toggle session menu" }
)

-- Layerrules
hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "noctalia.*",
	},
	blur = true,
	ignore_alpha = 0.2,
})
