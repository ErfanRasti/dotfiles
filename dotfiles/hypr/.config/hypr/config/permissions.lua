-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

hl.config({
	ecosystem = {
		enforce_permissions = true,
	},
})

-- NixOS: binaries live in /nix/store/<hash>-<name>-<version>/..., never /usr/bin, so the
-- stock /usr rules never matched. These follow the store path across updates.
local store = "/nix/store/[a-z0-9]+-"
hl.permission({ binary = store .. "grim-[^/]+/bin/grim", type = "screencopy", mode = "allow" })
hl.permission({ binary = store .. "hyprpicker-[^/]+/bin/hyprpicker", type = "screencopy", mode = "allow" })
hl.permission({
	binary = store .. "xdg-desktop-portal-hyprland-[^/]+/libexec/xdg-desktop-portal-hyprland",
	type = "screencopy",
	mode = "allow",
})
-- permissions to prevent black screen after lock
hl.permission({ binary = store .. "hyprlock-[^/]+/bin/hyprlock", type = "screencopy", mode = "allow" })
-- Plugins: for "plugin" rules Hyprland matches the regex against the plugin's *path* (the
-- "key"), not a program binary. Allow the NixOS-built plugins from config/plugins.lua, by
-- their /etc link and by the store path it resolves to; nothing else gets loaded silently.
hl.permission({ binary = "/etc/hypr/plugins/[^/]+\\.so", type = "plugin", mode = "allow" })
hl.permission({ binary = store .. "[^/]+/lib/lib[^/]+\\.so", type = "plugin", mode = "allow" })
-- `hyprctl plugin load` (matched by binary)
hl.permission({ binary = store .. "hyprland-[^/]+/bin/hyprctl", type = "plugin", mode = "allow" })
