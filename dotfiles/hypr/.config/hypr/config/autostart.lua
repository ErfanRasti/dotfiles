-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- hl.on("hyprland.start", function ()
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)
-- hl.exec_cmd() will spawn an asynchronous process, so there is no need for & disown at the end.
-- hl.exec_raw(cmd)	execute a raw command. While exec_cmd will do sh -c, this won’t.

hl.on("hyprland.start", function()
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 20")
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 20")
	-- To set cursor on all gtk apps check gtk-3.0 and gtk-4.0 config folders
	-- or you can use nwg-look.

	-- hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1") -- To activate gnome polkit

	hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
	hl.exec_cmd("systemctl --user start hypridle-runner.service")
	hl.exec_cmd("systemctl --user start hyprsunset.service")

	hl.exec_cmd("hyprpaper")
	-- hl.exec_cmd("swww-daemon")
	-- hl.exec_cmd("hyprpanel")

	-- To make sure that xdg-desktop-portal-hyprland can get the required variables on startup:
	-- See https://wiki.hypr.land/Useful-Utilities/Screen-Sharing/
	-- Also check https://wiki.archlinux.org/title/XDG_Desktop_Portal#Portal_does_not_start
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Have plugins loaded at startup and send a notification for fail events only
	hl.exec_cmd("hyprpm reload -n")

	-- Prevent logind from handling power key presses
	hl.exec_cmd(
		'systemd-inhibit --who="Hyprland config" --why="suspend keybind" --what=handle-power-key --mode=block sleep infinity & echo $! > /tmp/.hyprland-systemd-inhibit'
	)

	hl.exec_cmd("waybar")
	-- hl.exec_cmd("ashell")
	-- hl.exec_cmd("hypr-dock")
	-- hl.exec_cmd("systemctl --user start vicinae.service")

	hl.exec_cmd("swaync")
	hl.exec_cmd("swayosd-server")

	-- Restore device states
	hl.exec_cmd("~/.config/hypr/scripts/hypr_resume.sh restore")

	-- udiskie
	hl.exec_cmd("udiskie")

	-- pyprland
	-- hl.exec_cmd("/usr/bin/pypr")

	hl.exec_cmd("wl-paste --type text --watch cliphist store") -- Stores only text data
	hl.exec_cmd("wl-paste --type image --watch cliphist store") -- Stores only image data

	-- Make clipboard persist even if the related app is closed
	hl.exec_cmd("wl-clip-persist --clipboard regular")

	-- clipse
	-- hl.exec_cmd("clipse -listen")

	-- Battery notify
	hl.exec_cmd("~/.config/hypr/scripts/battery_watcher.sh")

	-- Welcome sound
	hl.exec_cmd("paplay /usr/share/sounds/ocean/stereo/desktop-login.oga")

	-- KDEConnect
	hl.exec_cmd("/usr/bin/kdeconnectd &")

	-- ydotool
	hl.exec_cmd("systemctl --user start ydotoold.service")

	-- hl.exec_cmd("paplay /usr/share/sounds/ocean/stereo/completion-rotation.oga")
end)

hl.on("hyprland.shutdown", function()
	hl.exec_cmd('kill -9 "$(cat /tmp/.hyprland-systemd-inhibit)"')
	hl.exec_cmd("~/.config/hypr/scripts/hypr_resume.sh save")
	hl.exec_cmd("paplay /usr/share/sounds/ocean/stereo/desktop-logout.oga")
end)
