------------------
---- NOCTALIA ----
------------------
-- The same noctalia setup as umbriel (~/.config/umbriel/config/noctalia.toml), on Hyprland.
-- Active when DESKTOP_SHELL == "noctalia" in hyprland.lua.
-- Commands: `noctalia msg --help`. Docs: https://docs.noctalia.dev
if DESKTOP_SHELL ~= "noctalia" then
	return
end

local mainMod = "SUPER"

-- Screenshots, screen toolkit and annotate capture the screen (enforce_permissions is on)
hl.permission({
	binary = "/nix/store/[a-z0-9]+-noctalia-[^/]+/bin/\\.?noctalia(-wrapped)?",
	type = "screencopy",
	mode = "allow",
})

-- Start the shell (bar, notifications, OSD, launcher, lock screen, wallpaper, polkit agent).
-- Idle/lock timers and the rest of the session come from config/autostart.lua.
hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")
end)

-- Replace the standalone binding of a key with a noctalia one.
local function nbind(keys, msg, opts)
	opts = opts or {}
	opts.description = "[SHELL:noctalia] " .. (opts.description or msg)
	hl.unbind(keys)
	hl.bind(keys, hl.dsp.exec_cmd("noctalia msg " .. msg), opts)
end

local locked = function(desc, repeating)
	return { locked = true, repeating = repeating ~= false, description = desc }
end

-- Launcher & settings
nbind("ALT + SPACE", "panel-toggle launcher", { description = "Toggle app launcher" })
nbind(mainMod .. " + COMMA", "settings-toggle", { description = "Toggle shell settings" })

-- Audio / media (work while locked)
nbind("XF86AudioRaiseVolume", "volume-up", locked("Raise the volume"))
nbind("XF86AudioLowerVolume", "volume-down", locked("Lower the volume"))
nbind("XF86AudioMute", "volume-mute", locked("Toggle mute audio", false))
nbind("XF86AudioMicMute", "mic-mute", locked("Toggle mute microphone", false))
nbind("XF86AudioPlay", "media toggle", locked("Play/pause", false))
nbind("XF86AudioPause", "media toggle", locked("Play/pause", false))
nbind("XF86AudioNext", "media next", locked("Next track"))
nbind("XF86AudioPrev", "media previous", locked("Previous track"))

-- Brightness
nbind("XF86MonBrightnessUp", "brightness-up", locked("Turn the brightness up"))
nbind("XF86MonBrightnessDown", "brightness-down", locked("Turn the brightness down"))

-- Panels & plugins (the same keys as umbriel)
nbind(mainMod .. " + N", "panel-toggle control-center notifications", { description = "Toggle notifications" })
nbind(mainMod .. " + ALT + N", "notification-dnd-toggle", { description = "Toggle Do Not Disturb" })
nbind(mainMod .. " + ALT + W", "panel-toggle wallpaper", { description = "Toggle wallpaper panel" })
nbind(mainMod .. " + ESCAPE", "session lock", { description = "Lock the session" })
nbind(mainMod .. " + S", "panel-toggle control-center", { description = "Toggle control center" })
nbind(mainMod .. " + V", "panel-toggle clipboard", { description = "Toggle clipboard history" })
nbind(mainMod .. " + B", "dock-toggle", { description = "Toggle the dock" })
nbind(mainMod .. " + PERIOD", "panel-toggle launcher /emo", { description = "Open emoji picker" })
nbind(mainMod .. " + ALT + PERIOD", "panel-toggle plugin:kaomoji", { description = "Open kaomoji picker" })
-- Shell cheatsheet on SUPER+SLASH like niri/umbriel; the rofi menus stay on SUPER+SHIFT+SLASH and
-- SUPER+CTRL(+SHIFT)+SLASH (binds.lua).
nbind(mainMod .. " + SLASH", "panel-toggle plugin:keybind-cheatsheet", { description = "Toggle keybind cheatsheet" })
nbind(mainMod .. " + CTRL + ALT + SHIFT + K", "panel-toggle plugin:show-keys", { description = "Show pressed keys" })
nbind(mainMod .. " + SHIFT + N", "panel-toggle plugin:sticky-notes", { description = "Toggle sticky notes" })
nbind(mainMod .. " + CTRL + SHIFT + S", "panel-toggle plugin:screen-toolkit", { description = "Open screen toolkit" })
nbind("ALT + F4", "panel-toggle session", { description = "Toggle session menu" })
hl.unbind(mainMod .. " + CTRL + SHIFT + C")
hl.bind(
	mainMod .. " + CTRL + SHIFT + C",
	hl.dsp.exec_cmd("~/.config/noctalia/plugins/keep-awake-plus/scripts/system-awake"),
	{ description = "[SHELL:noctalia] Toggle keep-awake" }
)

-- Recent windows: hold Alt, tap Tab (noctalia's window switcher, as on umbriel)
nbind("ALT + TAB", "window-switcher hold", { description = "Window switcher" })
nbind("ALT + SHIFT + TAB", "window-switcher hold", { description = "Window switcher" })

-- Screenshots (Shift+Print also works on the lock screen)
nbind("PRINT", "screenshot-region", { description = "Screenshot a region" })
nbind(
	"SHIFT + PRINT",
	"screenshot-fullscreen --no-freeze-screen --no-annotate",
	locked("Screenshot the monitor", false)
)
nbind(mainMod .. " + PRINT", "screenshot-window --no-freeze-screen --no-annotate", { description = "Screenshot the window" })

-- Layer rules: blur noctalia's bar, panels, dock, notifications and OSD (same set as umbriel)
hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|desktop-widget-.*)$",
	},
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})
-- Desktop icons: blur the frosted selection and menus, not fainter tints
hl.layer_rule({
	name = "noctalia-desktop-icons",
	match = { namespace = "^noctalia-plugin:dotfiles/desktop-icons:desk$" },
	blur = true,
	ignore_alpha = 0.22,
})

-- Noctalia's settings window floats, like on umbriel
hl.window_rule({
	name = "noctalia-settings",
	match = { class = "^(dev.noctalia.Noctalia)$" },
	float = true,
	center = true,
	size = "1020 900",
})
