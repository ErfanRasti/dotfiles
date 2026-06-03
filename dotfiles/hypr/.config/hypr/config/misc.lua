----------------
----  MISC  ----
----------------
-- https://wiki.hyprland.org/Configuring/Basics/Variables/#misc

hl.config({
	misc = {
		focus_on_activate = true, -- Focus an app that requests to be focused
		allow_session_lock_restore = true, -- Allow you to restart a lockscreen app in case it crashes
		force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers. -1 means "random"
		disable_hyprland_logo = true, -- If true disables the random Hyprland logo / anime girl background. :(
		disable_splash_rendering = true,
		-- Global default font to render the text including debug fps/notification, config error messages and etc.
		font_family = "CaskaydiaCove Nerd Font Mono",
		animate_mouse_windowdragging = true,
		animate_manual_resizes = true,
		enable_swallow = false,
	},
})
