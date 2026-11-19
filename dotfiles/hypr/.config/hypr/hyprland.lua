-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")

-- Desktop shell, the same setup as umbriel (bar, notifications, OSD, launcher, lock, wallpaper):
--   "noctalia"   noctalia (default, like umbriel)            -> config/noctalia.lua
--   "dms"        DankMaterialShell                           -> config/dms.lua
--   "standalone" waybar + swaync + swayosd + hyprpaper + hypridle + rofi
-- Change it, then SUPER+SHIFT+R (scripts/reload_config.sh swaps the running programs).
DESKTOP_SHELL = "dms"

-- Add matugen colors
require("config.colors")

require("config.permissions") -- before plugins: plugin loads are checked against these rules
require("config.plugins")
require("config.monitors")
require("config.programs")
require("config.autostart")
require("config.envvars")
require("config.appearance")
require("config.misc")
require("config.input")
require("config.rules")
require("config.binds")
require("config.features")
require("config.scrolling")
require("config.workspace_layouts") -- per-workspace layouts (SUPER+F1..F5), after scrolling
require("config.noctalia") -- active only when DESKTOP_SHELL == "noctalia"
require("config.dms") -- active only when DESKTOP_SHELL == "dms"
