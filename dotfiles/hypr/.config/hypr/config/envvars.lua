-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Set cursor
-- See https://wiki.hypr.land/Hypr-Ecosystem/hyprcursor/
-- Apps that do not support server-side cursors
-- and hyprcursor will still fall back to XCursor.
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")

-- Set GDK apps scale
hl.env("GDK_SCALE", "1.0")

-- Set default terminal app
hl.env("TERMINAL", TERMINAL)
hl.env("XDG_CONFIG_HOME", os.getenv("HOME") .. "/.config")

-- To apply themes correctly on qt apps
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
