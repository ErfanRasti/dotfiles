---------------------------
---- WORKSPACE LAYOUTS ----
---------------------------
-- Per-workspace layouts, like umbriel's scripts/set_layout.py:
--   SUPER+F1 scrolling, F2 floating ("stacking" on umbriel), F3 dwindle, F4 master,
--   F5 toggle scrolling <-> dwindle; add SHIFT to set it for every workspace.
-- The choice is kept in a state file and re-applied on every config pass, so it survives
-- reloads. Loaded after config/scrolling.lua (which sets the default layout).

local STATE = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr/workspace-layouts"
local LAYOUTS = { scrolling = true, floating = true, dwindle = true, master = true }

-- { ["*"] = default layout, ["<workspace id>"] = layout }
local function read_state()
	local state = {}
	local f = io.open(STATE, "r")
	if f then
		for line in f:lines() do
			local key, layout = line:match("^([%w*%-]+)=(%a+)$")
			if key and LAYOUTS[layout] then
				state[key] = layout
			end
		end
		f:close()
	end
	return state
end

local function write_state(state)
	local f = io.open(STATE, "w")
	if not f then -- first use: create the directory (spawns mkdir only then)
		os.execute('mkdir -p "' .. STATE:match("^(.*)/[^/]+$") .. '"')
		f = io.open(STATE, "w")
	end
	if not f then
		return
	end
	for key, layout in pairs(state) do
		f:write(key, "=", layout, "\n")
	end
	f:close()
end

-- Apply the saved layouts (runs on every config pass)
local state = read_state()
local default = state["*"]
if default then
	hl.config({ general = { layout = default == "floating" and "dwindle" or default } })
end
for key, layout in pairs(state) do
	if key ~= "*" then
		hl.workspace_rule({ workspace = key, layout = layout == "floating" and "dwindle" or layout })
	end
end
local function floating_here(id)
	local l = state[tostring(id)] or default
	return l == "floating"
end
-- New windows float on floating workspaces
for key, layout in pairs(state) do
	if key ~= "*" and layout == "floating" then
		hl.window_rule({ name = "floating-ws-" .. key, match = { workspace = key }, float = true })
	end
end

-- Float or tile the windows already on a workspace when entering/leaving "floating"
local function set_floating(ws_id, on)
	for _, w in ipairs(hl.get_windows()) do
		if w.workspace and w.workspace.id == ws_id and w.floating ~= on then
			hl.dispatch(hl.dsp.window.float({ action = on and "enable" or "disable", window = w }))
		end
	end
end

-- Set the layout of the active workspace (or of all workspaces), save it, reload the config
function SET_LAYOUT(layout, all)
	local ws = hl.get_active_workspace()
	if not ws or not ws.id then
		return
	end
	local s = read_state()
	local key = tostring(ws.id)
	if layout == "toggle" then
		layout = ((all and s["*"]) or s[key] or s["*"] or "scrolling") == "scrolling" and "dwindle" or "scrolling"
	end
	local was_floating = floating_here(ws.id)
	if all then
		s = { ["*"] = layout }
	else
		s[key] = layout
	end
	write_state(s)
	if all then
		for _, w in ipairs(hl.get_workspaces()) do
			if w.id and w.id > 0 then
				set_floating(w.id, layout == "floating")
			end
		end
	elseif (layout == "floating") ~= was_floating then
		set_floating(ws.id, layout == "floating")
	end
	NOTIFY((all and "All workspaces: " or ("Workspace " .. key .. ": ")) .. layout)
	hl.dispatch(hl.dsp.reload_config())
end
