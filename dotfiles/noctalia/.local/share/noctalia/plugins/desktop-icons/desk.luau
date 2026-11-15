--!nonstrict
-- Desktop icons, Windows style with vim keys and macOS arranging (see plugin.toml).
--
-- One full-screen layer on the "bottom" layer, kept under noctalia's desktop
-- widgets (each widget is its own small surface above it, so they keep their
-- clicks). The icon grid covers the screen between the bar and the dock; cells
-- under a widget are blocked. The widgets' boxes come from noctalia's state file
-- (~/.local/state/noctalia/settings.toml, where it saves the fitted layout), read
-- again whenever it changes, so adding or moving a widget frees or takes cells.
--
-- Three stacked children:
--   grid    : the cells (icons, or transparent blanks)
--   overlay : floating things: drag ghosts, selection box, menus, prompts, help
--   pad     : a ui.pixelStream over everything, showing pad.py's transparent 1x1
--             frame. It is the only input target (press, drag, right click, wheel,
--             keys); the script hit-tests the cells itself.
--
-- Arranging, as on a Mac desktop (desktop menu or Ctrl+Alt+digit):
--   Sort By none keeps where you put things (positions saved as points of the
--   screen, so they survive icon sizes and widget moves); Name/Kind/Date/Size keeps
--   them arranged. Clean Up packs them; Clean Up By sorts once. Use Stacks groups
--   files by kind or date into stacks a click opens in place.
--
-- Icons are Nautilus' own (Adwaita-Matugen, Adwaita, its thumbnails); names have
-- no background, black or white from the wallpaper brightness behind each cell.
--
-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).


-- ── settings ────────────────────────────────────────────────────────────────

local function conf(key, default)
  local v = noctalia.getConfig(key)
  if v == nil then
    return default
  end
  return v
end

local function setting(key, default)
  local ok, v = pcall(noctalia.getSetting, key)
  if ok and v ~= nil then
    return v
  end
  return default
end

local folderSetting = conf("folder", "")
local showHome = conf("show_home", true)
local showTrash = conf("show_trash", true)
local apps = conf("apps", {})
local singleClick = conf("open_on", "double") == "single"
local thumbnails = conf("thumbnails", true)
local showHidden = conf("show_hidden", false)
local WIDGET_GAP = conf("widget_gap", 8)

local HOME = noctalia.expandPath("~")
local DATA_HOME = noctalia.getenv("XDG_DATA_HOME") or (HOME .. "/.local/share")
local CACHE_HOME = noctalia.getenv("XDG_CACHE_HOME") or (HOME .. "/.cache")
local STATE_HOME = noctalia.getenv("XDG_STATE_HOME") or (HOME .. "/.local/state")
local CONFIG_HOME = noctalia.getenv("XDG_CONFIG_HOME") or (HOME .. "/.config")
local DATA_DIR = noctalia.pluginDataDir() or (CACHE_HOME .. "/desktop-icons")
noctalia.mkdirAll(DATA_DIR)
local POSITIONS = DATA_DIR .. "/layout.json" -- points of the screen (positions.json held cells)
local VIEW_FILE = DATA_DIR .. "/view.json"
local SOCKET = DATA_DIR .. "/pad.sock"
local NAMESPACE = "noctalia-plugin:dotfiles/desktop-icons:desk"

-- pad.py serves the input pad its frame; without it no click or key arrives.
-- Started here and, should it ever die, again from update() (it exits when one runs).
local PAD_PY = noctalia.pluginDir() .. "/pad.py"
local function startPad()
  noctalia.runAsync({ "python3", PAD_PY, SOCKET })
end
startPad()

local L = require("./lib.luau")({ HOME = HOME, DATA_HOME = DATA_HOME, CACHE_HOME = CACHE_HOME,
  CONFIG_HOME = CONFIG_HOME, DATA_DIR = DATA_DIR, folderSetting = folderSetting })

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

local function fail(msg)
  noctalia.notifyError(tr("ui.error"), msg)
end

-- ── view options (the Mac "View Options" and "Sort By", remembered) ──────────

local SIZES = { small = 0.85, medium = 1.0, large = 1.2, huge = 1.45 }
local SIZE_ORDER = { "small", "medium", "large", "huge" }
local SPACINGS = { tight = 0.88, normal = 1.0, wide = 1.18 }
local TEXT_SIZES = { small = 0.9, normal = 1.0, large = 1.15 }

local view = {
  sortBy = "none", -- none | name | kind | date | size
  stacks = false,
  groupBy = "kind", -- kind | date
  iconSize = conf("icon_size", "medium"),
  spacing = "normal",
  textSize = "normal",
  showInfo = false,
  expanded = {}, -- stack key -> true
}

do
  local raw = noctalia.readFile(VIEW_FILE)
  local data = raw and noctalia.json.decode(raw)
  if type(data) == "table" then
    for k, v in pairs(data) do
      if view[k] ~= nil and type(v) == type(view[k]) then
        view[k] = v
      end
    end
  end
  if not SIZES[view.iconSize] then view.iconSize = "medium" end
  if not SPACINGS[view.spacing] then view.spacing = "normal" end
  if not TEXT_SIZES[view.textSize] then view.textSize = "normal" end
end

local function saveView()
  noctalia.writeFile(VIEW_FILE, noctalia.json.encode(view))
end

-- ── geometry ────────────────────────────────────────────────────────────────
-- All in this output's logical px; the layer covers the whole output.

local DESIGN_CW, DESIGN_CH = 86, 96 -- a medium cell at scale 1
local outW, outH = 0, 0
local S = 1 -- monitor scale against the 1536x864 canvas the widgets are designed on
local CW, CH, COLS, ROWS, OX, OY = 86, 96, 1, 1, 0, 0
local ICON, FONT, PAD = 48, 11, 2
local MENU_W, MENU_ROW, DRAG_THRESHOLD = 200, 26, 6
local geometryReady = false
local geometryKey = ""
local blocked = {} -- "c,r" -> true: under a widget
local widgetsMtime, widgetsSig = nil, nil -- state file mtime, and the widget boxes it held

local function cellId(c, r)
  return c .. "," .. r
end

-- Fitted desktop widget boxes for this output, from noctalia's state file (or the
-- config when nothing was fitted yet): { x0, y0, x1, y1 } in output px.
local function readWidgetRects(name)
  local rects = {}
  local function parse(path)
    local raw = noctalia.readFile(path)
    -- Only the [desktop_widgets...] tables (a few dozen of ~800 lines): parsing the
    -- whole file overran the tick's CPU budget.
    local first = raw and raw:find("%[desktop_widgets[%]%.]")
    if not first then
      return false
    end
    local last = #raw
    local at = first
    while true do
      local h = raw:find("\n%s*%[", at + 1)
      if not h then
        break
      end
      local name = raw:match("^%s*%[([%w_]+)", h + 1)
      if name ~= "desktop_widgets" then
        last = h
        break
      end
      at = h
    end
    raw = raw:sub(first, last)
    local enabled = true
    local found = false
    local cur = nil
    local function flush()
      if cur and cur.cx and cur.bw and (not cur.output or cur.output == name) then
        local sx = (cur.pw and cur.pw > 0) and outW / cur.pw or 1
        local sy = (cur.ph and cur.ph > 0) and outH / cur.ph or 1
        local cx, cy = cur.cx * sx, cur.cy * sy
        local hw, hh = cur.bw * sx / 2, cur.bh * sy / 2
        table.insert(rects, { cx - hw, cy - hh, cx + hw, cy + hh })
      end
      cur = nil
    end
    local section = ""
    for line in raw:gmatch("[^\n]+") do
      local l = line:gsub("^%s+", ""):gsub("%s*#.*$", "")
      local header = l:match("^%[([^%]]+)%]$")
      if header then
        flush()
        section = header
        local id = header:match("^desktop_widgets%.widget%.([^%.]+)$") or header:match('^desktop_widgets%.widget%."([^"]+)"$')
        if id then
          cur, found = {}, true
        end
      else
        local k, v = l:match("^([%w_]+)%s*=%s*(.-)$")
        if k and section == "desktop_widgets" and k == "enabled" then
          enabled = v == "true"
        elseif k and cur then
          local n = tonumber(v)
          if k == "cx" then cur.cx = n
          elseif k == "cy" then cur.cy = n
          elseif k == "box_width" then cur.bw = n
          elseif k == "box_height" then cur.bh = n
          elseif k == "placement_width" then cur.pw = n
          elseif k == "placement_height" then cur.ph = n
          elseif k == "output" then cur.output = v:match('^"(.*)"$')
          end
        end
      end
    end
    flush()
    if not enabled then
      rects = {}
    end
    return found
  end
  if not parse(STATE_HOME .. "/noctalia/settings.toml") then
    rects = {}
    parse(CONFIG_HOME .. "/noctalia/settings.toml")
  end
  return rects
end

-- Space the bar and the dock keep (they float above on the "top" layer).
local function reserves()
  local bar = tonumber(setting("bar.default.thickness", 28)) or 28
  local barPos = setting("bar.default.position", "top")
  local dockOn = setting("dock.enabled", true)
  local dock = dockOn and ((tonumber(setting("dock.icon_size", 36)) or 36) + 26) or 0
  local top, bottom, left, right = 8 * S, 8 * S, 12 * S, 12 * S
  if barPos == "bottom" then bottom += bar else top += bar end
  if barPos == "left" then left += bar elseif barPos == "right" then right += bar end
  bottom += dock
  return top, bottom, left, right
end

local function computeBlocked(rects)
  blocked = {}
  local gap = WIDGET_GAP * S
  for _, rc in ipairs(rects) do
    for c = 1, COLS do
      for r = 1, ROWS do
        local x0, y0 = OX + (c - 1) * CW, OY + (r - 1) * CH
        -- A cell is free when the widget (plus a gap) leaves its middle 80% alone,
        -- so icons can tuck close to a widget.
        local ix, iy = CW * 0.1, CH * 0.1
        if x0 + ix < rc[3] + gap and x0 + CW - ix > rc[1] - gap and y0 + iy < rc[4] + gap and y0 + CH - iy > rc[2] - gap then
          blocked[cellId(c, r)] = true
        end
      end
    end
  end
end

-- Returns true when anything that moves cells changed.
local function computeGeometry()
  local name = layer.outputName()
  local w, h = nil, nil
  for _, o in ipairs(noctalia.outputs()) do
    if (name and o.name == name) or (not name and o.focused) then
      w, h = o.width, o.height
    end
  end
  if not w or w <= 0 or h <= 0 then
    return false
  end
  -- The state file also changes for unrelated settings (a new wallpaper): re-read
  -- its widget boxes on a change, re-place only when they moved.
  local info = noctalia.fileInfo(STATE_HOME .. "/noctalia/settings.toml")
  local wm = info and info.mtime or -2
  local key = table.concat({ w, h, view.iconSize, view.spacing, view.textSize }, "|")
  if geometryReady and key == geometryKey and wm == widgetsMtime then
    return false
  end
  local sized = key ~= geometryKey
  geometryKey, widgetsMtime = key, wm
  if sized then
    outW, outH = w, h
    S = math.min(outW / 1536, outH / 864)
    local cs = S * SIZES[view.iconSize]
    local sp = SPACINGS[view.spacing]
    CW = math.floor(DESIGN_CW * cs * sp)
    CH = math.floor(DESIGN_CH * cs * (1 + (sp - 1) * 0.6) * TEXT_SIZES[view.textSize] ^ 0.5)
    ICON = math.floor(48 * cs)
    FONT = 11 * cs * TEXT_SIZES[view.textSize]
    PAD = math.max(1, math.floor(2 * cs))
    MENU_W, MENU_ROW = math.floor(210 * S), math.floor(26 * S)
    DRAG_THRESHOLD = 6 * S
    local top, bottom, left, right = reserves()
    COLS = math.max(1, math.floor((outW - left - right) / CW))
    ROWS = math.max(1, math.floor((outH - top - bottom) / CH))
    OX = math.floor(left + (outW - left - right - COLS * CW) / 2)
    OY = math.floor(top + (outH - top - bottom - ROWS * CH) / 2)
  end
  local rects = readWidgetRects(name)
  local sig = {}
  for i, rc in ipairs(rects) do
    sig[i] = string.format("%d,%d,%d,%d", rc[1], rc[2], rc[3], rc[4])
  end
  sig = table.concat(sig, ";")
  if not sized and sig == widgetsSig then
    return false
  end
  widgetsSig = sig
  computeBlocked(rects)
  geometryReady = true
  return true
end

-- Keeps this surface under the desktop widgets: umbriel stacks a layer's surfaces
-- by creation, so after the plugin is (re)enabled ours is on top. Re-creating the
-- widgets (hide, show) puts them back above. Only when widgets are showing.
local function keepUnderWidgets()
  noctalia.runAsync({ "umbriel", "layers" }, function(res)
    if res.exitCode ~= 0 then
      return
    end
    local mine, firstWidget, n = nil, nil, 0
    for line in res.stdout:gmatch("[^\n]+") do
      n += 1
      if line:find(NAMESPACE, 1, true) then
        mine = n
      elseif line:find("noctalia-desktop-widget-", 1, true) and line:match("^bottom") and not firstWidget then
        firstWidget = n
      end
    end
    if mine and firstWidget and mine > firstWidget then
      noctalia.runAsync({ "sh", "-c", "noctalia msg desktop-widgets-hide && sleep 0.2 && noctalia msg desktop-widgets-show" })
    end
  end)
end

-- ── model ───────────────────────────────────────────────────────────────────
-- item: { key, name, icon, image?, path?, uri?, isDir?, fixed?, kind, open = argv,
--         size, mtime, fileKind, info?, members? (stack), stack? (member of) }

local folder = nil
local folderMtime, thumbsMtime = -1, -1
local entries = {} -- the folder's items
local fixedItems = {}
local items = {} -- what is shown, in placement order
local byKey = {}
local pos = {} -- key -> { c, r }
local occ = {} -- "c,r" -> key
local overflow = 0
local moreAt = nil -- "c,r" of the "+N more" cell when not everything fits
local saved = {} -- folder -> key -> { fx, fy } (points of the screen, 0..1)

local function loadSaved()
  local raw = noctalia.readFile(POSITIONS)
  local data = raw and noctalia.json.decode(raw)
  saved = type(data) == "table" and data or {}
end

local function writeSaved()
  noctalia.writeFile(POSITIONS, noctalia.json.encode(saved))
end

local function fileItem(name)
  local path = folder .. "/" .. name
  local info = noctalia.fileInfo(path)
  if not info then
    return nil
  end
  local ext = (name:match("%.([^.]+)$") or ""):lower()
  local item = {
    key = "f:" .. name, name = name, path = path, uri = L.fileUri(path), isDir = info.isDir,
    kind = info.isDir and "dir" or "file", open = { "gio", "open", path },
    size = info.size or 0, mtime = info.mtime or 0,
  }
  if info.isDir then
    item.icon, item.fileKind = "folder", "Folders"
    if view.showInfo then
      local n = #(noctalia.listDir(path) or {})
      item.info = tr(n == 1 and "ui.info.item" or "ui.info.items", { count = n })
    end
    return item
  end
  item.fileKind = L.EXT_KIND[ext] or "Other"
  if name:match("^[Ss]creen[%s_-]?[Ss]hot") or name:match("^screenshot_") then
    item.fileKind = "Screenshots"
  end
  if ext == "desktop" then
    local entry = L.parseDesktopFile(path)
    if entry then
      item.name, item.icon = entry.name or name, entry.icon or "application-x-executable"
      item.open, item.fileKind = { "gio", "launch", path }, "Applications"
      return item
    end
  end
  item.icon = L.EXT_ICON[ext] or "text-x-generic"
  if thumbnails then
    item.image = L.cachedThumbnail(path, item.mtime)
    if not item.image and L.IMAGE_EXT[ext] and item.size <= 16 * 1024 * 1024 then
      item.image = path
    end
  end
  if view.showInfo then
    item.info = L.humanSize(item.size)
  end
  return item
end

local function readFolder()
  local list = {}
  for _, name in ipairs(noctalia.listDir(folder) or {}) do
    if showHidden or string.sub(name, 1, 1) ~= "." then
      local it = fileItem(name)
      if it then
        table.insert(list, it)
      end
    end
  end
  entries = list
end

local function buildFixed()
  local list = {}
  if showHome then
    table.insert(list, { key = "home", name = tr("ui.home"), icon = "user-home", fixed = true, kind = "home",
      path = HOME, uri = L.fileUri(HOME), isDir = true, open = { "gio", "open", HOME } })
  end
  if showTrash then
    local n = #(noctalia.listDir(DATA_HOME .. "/Trash/files") or {})
    table.insert(list, { key = "trash", name = tr("ui.trash"), icon = "user-trash", fixed = true, kind = "trash",
      uri = "trash:///", open = { "gio", "open", "trash:///" },
      info = view.showInfo and tr(n == 1 and "ui.info.item" or "ui.info.items", { count = n }) or nil })
  end
  for _, id in ipairs(apps) do
    local p = L.findDesktopEntry(id)
    local entry = p and L.parseDesktopFile(p)
    table.insert(list, { key = "app:" .. id, name = (entry and entry.name) or id, icon = (entry and entry.icon) or id,
      fixed = true, kind = "app", open = { "gtk-launch", id } })
  end
  fixedItems = list
end

-- Sort order for Sort By / Clean Up By; folders first, as Nautilus does.
local function comparator(by)
  local function byName(a, b)
    return a.name:lower() < b.name:lower()
  end
  return function(a, b)
    if (a.isDir or false) ~= (b.isDir or false) then
      return a.isDir or false
    end
    if by == "kind" then
      local ka, kb = L.KIND_RANK[a.fileKind] or 99, L.KIND_RANK[b.fileKind] or 99
      if ka ~= kb then
        return ka < kb
      end
    elseif by == "date" then
      if (a.mtime or 0) ~= (b.mtime or 0) then
        return (a.mtime or 0) > (b.mtime or 0)
      end
    elseif by == "size" then
      if (a.size or 0) ~= (b.size or 0) then
        return (a.size or 0) > (b.size or 0)
      end
    end
    return byName(a, b)
  end
end

local function dateGroup(mtime)
  local now = os.time()
  local today = os.time({ year = tonumber(os.date("%Y")), month = tonumber(os.date("%m")), day = tonumber(os.date("%d")), hour = 0 })
  if mtime >= today then return "Today" end
  if mtime >= today - 86400 then return "Yesterday" end
  if mtime >= now - 7 * 86400 then return "Previous 7 Days" end
  if mtime >= now - 30 * 86400 then return "Previous 30 Days" end
  return "Earlier"
end
local DATE_RANK = { Today = 1, Yesterday = 2, ["Previous 7 Days"] = 3, ["Previous 30 Days"] = 4, Earlier = 5 }

-- What is shown: fixed items, then the folder; with stacks, files grouped into
-- stacks (two or more alike), an open stack followed by its files.
local function buildItems()
  local list = {}
  for _, it in ipairs(fixedItems) do
    table.insert(list, it)
  end
  local files = table.clone(entries)
  local by = view.sortBy ~= "none" and view.sortBy or "name"
  table.sort(files, comparator(by))
  if view.stacks then
    local groups, order = {}, {}
    for _, it in ipairs(files) do
      if it.isDir then
        table.insert(list, it)
      else
        local g = view.groupBy == "date" and dateGroup(it.mtime) or it.fileKind
        if not groups[g] then
          groups[g] = {}
          table.insert(order, g)
        end
        table.insert(groups[g], it)
      end
    end
    table.sort(order, function(a, b)
      local ra = view.groupBy == "date" and DATE_RANK[a] or L.KIND_RANK[a] or 99
      local rb = view.groupBy == "date" and DATE_RANK[b] or L.KIND_RANK[b] or 99
      return ra < rb
    end)
    for _, g in ipairs(order) do
      local members = groups[g]
      if #members >= 2 then
        local key = "stack:" .. g
        local first = members[1]
        local stack = { key = key, name = g, kind = "stack", icon = first.icon, image = first.image, members = members,
          info = tr("ui.info.items", { count = #members }), count = #members }
        table.insert(list, stack)
        if view.expanded[key] then
          for _, m in ipairs(members) do
            m.stack = key
            table.insert(list, m)
          end
        end
      else
        table.insert(list, members[1])
      end
    end
  else
    for _, it in ipairs(files) do
      it.stack = nil
      table.insert(list, it)
    end
  end
  items, byKey = list, {}
  for _, it in ipairs(list) do
    byKey[it.key] = it
  end
end

local function freeCell(c, r)
  return c >= 1 and c <= COLS and r >= 1 and r <= ROWS and not blocked[cellId(c, r)] and not occ[cellId(c, r)]
end

-- Free cells in fill order: column by column from the left.
local function freeCells()
  local list = {}
  for c = 1, COLS do
    for r = 1, ROWS do
      if not blocked[cellId(c, r)] then
        table.insert(list, { c, r })
      end
    end
  end
  return list
end

local function cellPoint(c, r)
  return { (OX + (c - 0.5) * CW) / outW, (OY + (r - 0.5) * CH) / outH }
end

local function pointCell(p)
  local c = math.floor((p[1] * outW - OX) / CW) + 1
  local r = math.floor((p[2] * outH - OY) / CH) + 1
  return math.max(1, math.min(COLS, c)), math.max(1, math.min(ROWS, r))
end

local function nearestFree(c, r)
  local best, bestD = nil, math.huge
  for cc = 1, COLS do
    for rr = 1, ROWS do
      if freeCell(cc, rr) then
        local d = (cc - c) ^ 2 + (rr - r) ^ 2 * 1.2
        if d < bestD then
          best, bestD = { cc, rr }, d
        end
      end
    end
  end
  return best
end

local function setCell(key, c, r)
  pos[key] = { c, r }
  occ[cellId(c, r)] = key
end

-- Arranged (Sort By, stacks): in order over the free cells. Free: saved points,
-- each to its nearest free cell; new items take the first free cell.
local function place()
  local mine = saved[folder] or {}
  saved[folder] = mine
  pos, occ, overflow = {}, {}, 0
  local auto = view.stacks or view.sortBy ~= "none"
  local pending = {}
  if auto then
    pending = items
  else
    for _, it in ipairs(items) do
      local p = mine[it.key]
      if type(p) == "table" and type(p[1]) == "number" and p[1] <= 1 and p[2] <= 1 then
        local c, r = pointCell(p)
        if not freeCell(c, r) then
          local f = nearestFree(c, r)
          if f then c, r = f[1], f[2] else c = nil end
        end
        if c then setCell(it.key, c, r) else overflow += 1 end
      else
        table.insert(pending, it)
      end
    end
  end
  local cells = freeCells()
  local i = 1
  for _, it in ipairs(pending) do
    while cells[i] and occ[cellId(cells[i][1], cells[i][2])] do
      i += 1
    end
    if cells[i] then
      setCell(it.key, cells[i][1], cells[i][2])
    else
      overflow += 1
    end
  end
  -- Not everything fits: the last free cell becomes "+N more".
  moreAt = nil
  if overflow > 0 and #cells > 0 then
    local last = cells[#cells]
    moreAt = cellId(last[1], last[2])
    local key = occ[moreAt]
    if key then
      pos[key], occ[moreAt] = nil, nil
      overflow += 1
    end
  end
  -- Remember every point, so things stay put when others come and go (and where
  -- an arranged desktop left them when Sort By goes back to none).
  if not view.stacks then
    local fresh = {}
    for key, p in pairs(pos) do
      if not key:match("^stack:") then
        fresh[key] = cellPoint(p[1], p[2])
      end
    end
    saved[folder] = fresh
    writeSaved()
  end
end

local function ordered()
  local list = {}
  for _, it in ipairs(items) do
    if pos[it.key] then
      table.insert(list, it)
    end
  end
  table.sort(list, function(a, b)
    local pa, pb = pos[a.key], pos[b.key]
    if pa[1] ~= pb[1] then
      return pa[1] < pb[1]
    end
    return pa[2] < pb[2]
  end)
  return list
end

-- ── state ───────────────────────────────────────────────────────────────────

local selection = {}
local focusKey, anchorKey = nil, nil
local hoverKey = nil
local mode = "normal" -- normal | rename | search | confirm | menu | help
local visual = false
local pendingG = false
local ctrlDown, shiftDown = false, false
local lastKeyMs = 0

local press = nil
local drag = nil
local band = nil
local lastClick = { key = nil, ms = 0 }

local rename = nil
local search = { query = "", last = "" }
local confirm = nil
local menu = nil -- { x, y, entries, hover, h, sub = { x, y, entries, hover, h, parent }, level }

local lum = {}
local fx = { cut = {} } -- feedback: fx.toast (a short message), fx.cut (keys of cut icons, drawn faded)
local nodeCache = {} -- "c,r" -> { signature, node }, see grid()
local wallpaper = nil

local render -- forward
local refresh -- forward
local relayout -- forward

local function selectedKeys()
  local list = {}
  for _, it in ipairs(ordered()) do
    if selection[it.key] then
      table.insert(list, it.key)
    end
  end
  return list
end

-- Selected items, a stack standing for its files.
local function selectedItems(expandStacks)
  local list = {}
  for _, key in ipairs(selectedKeys()) do
    local it = byKey[key]
    if expandStacks and it.members then
      for _, m in ipairs(it.members) do
        table.insert(list, m)
      end
    else
      table.insert(list, it)
    end
  end
  return list
end

local function selectOnly(key)
  selection = {}
  if key then
    selection[key] = true
  end
  focusKey, anchorKey = key, key
end

local function selectRange(fromKey, toKey)
  local a, b = pos[fromKey], pos[toKey]
  if not (a and b) then
    return
  end
  selection = {}
  for key, p in pairs(pos) do
    if p[1] >= math.min(a[1], b[1]) and p[1] <= math.max(a[1], b[1])
      and p[2] >= math.min(a[2], b[2]) and p[2] <= math.max(a[2], b[2]) then
      selection[key] = true
    end
  end
end

local function selectEdge(last)
  local list = ordered()
  local it = list[last and #list or 1]
  selectOnly(it and it.key)
end

local function selectAll()
  for key in pairs(pos) do
    selection[key] = true
  end
end

local function toggleFocused()
  if focusKey then
    selection[focusKey] = not selection[focusKey] or nil
  end
end

-- ── actions ─────────────────────────────────────────────────────────────────

local function run(argv, done)
  local ok = noctalia.runAsync(argv, function(res)
    if res.exitCode ~= 0 then
      fail((res.stderr ~= "" and res.stderr) or (argv[1] .. " failed"))
    end
    if done then
      done(res)
    end
    refresh(true)
  end)
  if not ok then
    fail("could not start " .. argv[1])
  end
end

-- A message at the bottom of the desktop for ~1.5s, so an action shows it worked.
function fx.flash(text, glyph)
  local t = { text = text, glyph = glyph }
  fx.toast = t
  noctalia.runAsync({ "sleep", "1.6" }, function()
    if fx.toast == t then
      fx.toast = nil
      render()
    end
  end)
  render()
end

local function toggleStack(it)
  view.expanded[it.key] = not view.expanded[it.key] or nil
  saveView()
  relayout()
end

local function openItem(it)
  if it.kind == "stack" then
    toggleStack(it)
    return
  end
  if not noctalia.runAsync(it.open) then
    fail("could not open " .. it.name)
  end
end

local previewing = nil -- uri of the file our Sushi preview shows, nil when closed
local sushiHidden = false -- its window is open on a workspace not on screen (from umbriel)
local reopening = false -- we closed that window to reopen here: its Visible=false isn't a close

local function previewerCall(args, done)
  local argv = { "gdbus", "call", "--session", "--dest", "org.gnome.NautilusPreviewer",
    "--object-path", "/org/gnome/NautilusPreviewer", "--method" }
  for _, a in ipairs(args) do
    table.insert(argv, a)
  end
  noctalia.runAsync(argv, done and function(res) done(res.exitCode == 0) end or nil)
end

-- Shows a file in GNOME Sushi; Space again closes it (closeIfAlreadyShown), and
-- a new file replaces the one shown (arrow keys in the preview, below). Sushi
-- keeps one window: left open on another workspace, it would show the file there,
-- out of sight, so that one is closed first and the preview opens here.
local function preview(it, keepOpen)
  if not (it and it.uri) then
    return
  end
  previewing = it.uri
  -- Sushi may be quitting after the close: retry while it restarts.
  local function show(tries)
    previewerCall({ "org.gnome.NautilusPreviewer2.ShowFile", it.uri, "", keepOpen and "false" or "true", "" },
      function(ok)
        if not ok and tries > 0 then
          noctalia.runAsync({ "sleep", "0.3" }, function() show(tries - 1) end)
        end
      end)
  end
  if sushiHidden and not keepOpen then
    sushiHidden, reopening = false, true
    previewerCall({ "org.gnome.NautilusPreviewer2.Close" }, function() show(5) end)
  else
    show(5)
  end
end

local function filePaths(list)
  local out = {}
  for _, it in ipairs(list) do
    if it.path and not it.fixed then
      table.insert(out, it.path)
    end
  end
  return out
end

local function copySelection(cut)
  local uris, keys = {}, {}
  for _, it in ipairs(selectedItems(true)) do
    if it.path and not it.fixed then
      table.insert(uris, it.uri)
      keys[it.key] = true
    end
  end
  -- Copy as a uri list, as yazi does, so any app pastes the files (Nautilus, a
  -- browser upload, a chat); cut in Nautilus' format, so its Paste moves them.
  if #uris > 0 and cut then
    noctalia.copyToClipboard("cut\n" .. table.concat(uris, "\n"), "x-special/gnome-copied-files")
  elseif #uris > 0 then
    noctalia.copyToClipboard(table.concat(uris, "\r\n") .. "\r\n", "text/uri-list")
  end
  if #uris > 0 then
    fx.cut = cut and keys or {}
    fx.flash(tr(cut and "ui.toast.cut" or "ui.toast.copied", { count = #uris }), cut and "cut" or "copy")
  end
end

local function pasteInto(dir)
  noctalia.runAsync({ "wl-paste", "--no-newline", "--type", "x-special/gnome-copied-files" }, function(res)
    local action, uris = "copy", {}
    for line in (res.exitCode == 0 and res.stdout or ""):gmatch("[^\r\n]+") do
      if line == "cut" or line == "copy" then
        action = line
      elseif line:match("^%a[%w+.-]*://") then
        table.insert(uris, line)
      end
    end
    local function go()
      if #uris == 0 then
        fx.flash(tr("ui.toast.nothing"), "clipboard-off")
        return
      end
      fx.flash(tr("ui.toast.pasting", { count = #uris }), "clipboard")
      if action == "cut" then
        fx.cut = {}
      end
      local argv = { "gio", action == "cut" and "move" or "copy", "--" }
      for _, u in ipairs(uris) do
        table.insert(argv, u)
      end
      table.insert(argv, dir)
      run(argv)
    end
    if #uris > 0 then
      go()
      return
    end
    noctalia.runAsync({ "wl-paste", "--no-newline", "--type", "text/uri-list" }, function(r2)
      if r2.exitCode == 0 then
        for line in r2.stdout:gmatch("[^\r\n]+") do
          if line:match("^%a[%w+.-]*://") then
            table.insert(uris, line)
          end
        end
      end
      go()
    end)
  end)
end

local function trashSelection()
  local paths = filePaths(selectedItems(true))
  if #paths == 0 then
    return
  end
  local argv = { "gio", "trash", "--" }
  for _, p in ipairs(paths) do
    table.insert(argv, p)
  end
  selectOnly(nil)
  fx.flash(tr("ui.toast.trashed", { count = #paths }), "trash")
  run(argv)
end

local function deleteSelection()
  local paths = filePaths(selectedItems(true))
  if #paths == 0 then
    return
  end
  mode = "confirm"
  confirm = {
    text = tr("ui.confirm.delete", { count = #paths }),
    action = function()
      local argv = { "rm", "-rf", "--" }
      for _, p in ipairs(paths) do
        table.insert(argv, p)
      end
      selectOnly(nil)
      run(argv)
    end,
  }
end

local function emptyTrash()
  mode = "confirm"
  confirm = { text = tr("ui.confirm.empty_trash"), action = function() run({ "gio", "trash", "--empty" }) end }
end

local function freeName(base)
  local name, n = base, 1
  while noctalia.fileInfo(folder .. "/" .. name) do
    n += 1
    name = base .. " " .. n
  end
  return name
end

local function startRename(it)
  if not it or it.fixed or not it.path then
    return
  end
  local name = it.path:match("[^/]+$")
  local stem = it.isDir and #name or ((name:find("%.[^.]*$") or (#name + 1)) - 1)
  if stem == 0 then
    stem = #name
  end
  rename = { key = it.key, text = name, cursor = stem, stemSel = stem }
  mode = "rename"
end

local function createNew(isDir, c, r)
  local name = freeName(tr(isDir and "ui.new_folder" or "ui.new_document"))
  local path = folder .. "/" .. name
  local ok, err
  if isDir then
    ok, err = noctalia.mkdirAll(path)
  else
    ok, err = noctalia.writeFile(path, "")
  end
  if not ok then
    fail(err or ("could not create " .. name))
    return
  end
  local key = "f:" .. name
  if c and r and freeCell(c, r) then
    saved[folder][key] = cellPoint(c, r)
    writeSaved()
  end
  refresh(true)
  if byKey[key] then
    selectOnly(key)
    startRename(byKey[key])
  end
end

local function commitRename()
  local rn = rename
  rename, mode = nil, "normal"
  local it = rn and byKey[rn.key]
  if not it then
    return
  end
  local new = rn.text:gsub("^%s+", ""):gsub("%s+$", "")
  local old = it.path:match("[^/]+$")
  if new == "" or new == old or new:find("/") then
    return
  end
  local target = folder .. "/" .. new
  if noctalia.fileInfo(target) then
    fail(tr("ui.rename_exists", { name = new }))
    return
  end
  local ok, err = noctalia.renameFile(it.path, target)
  if not ok then
    fail(err or "rename failed")
    return
  end
  local p = pos[it.key]
  if p then
    saved[folder]["f:" .. new] = cellPoint(p[1], p[2])
    saved[folder][it.key] = nil
    writeSaved()
  end
  refresh(true)
  selectOnly("f:" .. new)
end

-- Clean Up: pack the icons into the first free cells, keeping their order.
-- Clean Up By: the same, sorted once.
local function cleanUp(by)
  local list = ordered()
  if by then
    local fixed, rest = {}, {}
    for _, it in ipairs(list) do
      table.insert(it.fixed and fixed or rest, it)
    end
    table.sort(rest, comparator(by))
    list = fixed
    for _, it in ipairs(rest) do
      table.insert(list, it)
    end
  end
  local cells = freeCells()
  local fresh = {}
  for i, it in ipairs(list) do
    if cells[i] then
      fresh[it.key] = cellPoint(cells[i][1], cells[i][2])
    end
  end
  saved[folder] = fresh
  view.sortBy, view.stacks = "none", false
  saveView()
  relayout()
end

local function setSort(by)
  view.sortBy = by
  saveView()
  relayout()
end

local function setStacks(on)
  view.stacks = on
  saveView()
  relayout()
end

local function setView(key, value)
  view[key] = value
  saveView()
  relayout()
end

local function zoom(step)
  local i = 2
  for n, name in ipairs(SIZE_ORDER) do
    if name == view.iconSize then
      i = n
    end
  end
  i = math.max(1, math.min(#SIZE_ORDER, i + step))
  setView("iconSize", SIZE_ORDER[i])
end

local function openTerminalHere()
  noctalia.runAsync({ "sh", "-c", 'cd "$1" && exec "${TERMINAL:-ghostty}"', "sh", folder })
end

-- Moving icons by hand turns an arranged desktop back into a free one (as Sort By
-- None), keeping where everything is now.
local function makeFree()
  if view.sortBy ~= "none" then
    view.sortBy = "none"
    saveView()
  end
end

local function nudge(dc, dr)
  if view.stacks then
    return
  end
  local keys = selectedKeys()
  if #keys == 0 then
    return
  end
  local moving = {}
  for _, k in ipairs(keys) do
    moving[k] = true
  end
  for _, k in ipairs(keys) do
    local p = pos[k]
    local c, r = p[1] + dc, p[2] + dr
    local o = occ[cellId(c, r)]
    if c < 1 or c > COLS or r < 1 or r > ROWS or blocked[cellId(c, r)] or (o and not moving[o]) then
      return
    end
  end
  makeFree()
  for _, k in ipairs(keys) do
    occ[cellId(pos[k][1], pos[k][2])] = nil
  end
  for _, k in ipairs(keys) do
    local p = pos[k]
    setCell(k, p[1] + dc, p[2] + dr)
    saved[folder][k] = cellPoint(p[1] + dc, p[2] + dr)
  end
  writeSaved()
end

-- Next item from `fromKey` (default: the focus) in a direction: nearest along that
-- axis, preferring the same row/column; `accept` filters the candidates.
local function neighbour(dc, dr, fromKey, accept)
  local from = pos[fromKey or focusKey or ""]
  if not from then
    local first = ordered()[1]
    return first and first.key
  end
  local best, bestD = nil, math.huge
  for key, p in pairs(pos) do
    if accept and not accept(byKey[key]) then
      continue
    end
    local ac, ar = p[1] - from[1], p[2] - from[2]
    local along, across = ac * dc + ar * dr, math.abs(ac * dr) + math.abs(ar * dc)
    if along > 0 then
      local d = along + across * 3
      if d < bestD then
        best, bestD = key, d
      end
    end
  end
  return best
end

local function moveFocus(dc, dr, how)
  local key = neighbour(dc, dr)
  if not key then
    return
  end
  if how == "extend" then
    focusKey = key
    selectRange(anchorKey or key, key)
  elseif how == "focus" then
    focusKey = key
  else
    selectOnly(key)
  end
end

local function findMatch(query, step)
  if query == "" then
    return
  end
  local list = ordered()
  local start = 0
  for i, it in ipairs(list) do
    if it.key == focusKey then
      start = i
    end
  end
  local q = query:lower()
  for n = (step == 0 and 0 or 1), #list do
    local i = ((start - 1 + n * (step == -1 and -1 or 1)) % #list) + 1
    if list[i].name:lower():find(q, 1, true) then
      selectOnly(list[i].key)
      return
    end
  end
end

-- ── preview navigation (as in Nautilus) ─────────────────────────────────────
-- Sushi doesn't move through files itself: on an arrow key it signals
-- SelectionEvent(direction) and the app that opened it selects the neighbour and
-- shows that. F2, Delete and "open in Files" come back as Rename, Trash and
-- NavigateTo. Only for previews we opened: Nautilus' have its window as parent.

local GTK_DIRS = { ["2"] = { 0, -1 }, ["3"] = { 0, 1 }, ["4"] = { -1, 0 }, ["5"] = { 1, 0 } } -- GtkDirectionType

local function itemByUri(uri)
  for _, it in ipairs(items) do
    if it.uri == uri and pos[it.key] then
      return it
    end
  end
  return nil
end

-- Shows the neighbour of the previewed file in the preview, and selects it.
local function previewStep(dc, dr)
  local from = previewing and itemByUri(previewing)
  local key = from and neighbour(dc, dr, from.key, function(it) return it and it.uri ~= nil and it.kind ~= "stack" end)
  if key then
    selectOnly(key)
    preview(byKey[key], true)
    render()
  end
end

-- Where Sushi's window is, from umbriel's window events (read only): open on a
-- workspace not on screen, the next preview reopens it here (see preview()).
local onFocus -- set below: onFocus(windowFocused); takes the keyboard when none is left

local function onWindowsLine(line)
  onFocus(line:find('"active":true', 1, true) ~= nil) -- "active": the window with the keyboard
  if not line:find("NautilusPreviewer", 1, true) then
    sushiHidden = false -- no Sushi window: skip decoding the whole window list
    return
  end
  local ok, ev = pcall(noctalia.json.decode, line)
  local list = ok and type(ev) == "table" and ev.data
  if type(list) ~= "table" then
    return
  end
  local hidden = false
  for _, w in ipairs(list) do
    if w.app_id == "org.gnome.NautilusPreviewer" and w.visible == false then
      hidden = true
    end
  end
  sushiHidden = hidden
end

local function onPreviewerLine(line)
  if line:find("ParentHandle", 1, true) and not line:find("'ParentHandle': <''>", 1, true) then
    previewing = nil -- Nautilus took the previewer over
  elseif line:find("'Visible': <false>", 1, true) then
    if reopening then
      reopening = false
    else
      previewing = nil
    end
  end
  if not previewing then
    return
  end
  local dir = line:match("%.SelectionEvent %(uint32 (%d+),?%)")
  local uri = line:match("%.%a+ %('(.-)',%)")
  if dir and GTK_DIRS[dir] then
    previewStep(GTK_DIRS[dir][1], GTK_DIRS[dir][2])
  elseif uri and line:find("%.Rename %(") then
    previewing = nil
    local it = itemByUri(uri)
    if it then
      selectOnly(it.key)
      startRename(it)
      render()
    end
  elseif uri and line:find("%.Trash %(") then
    previewing = nil
    local it = itemByUri(uri)
    if it then
      selectOnly(it.key)
      trashSelection()
      render()
    end
  elseif uri and line:find("%.NavigateTo %(") then
    previewing = nil
    local it = itemByUri(uri)
    if it and it.path then
      noctalia.runAsync({ "nautilus", "--select", it.path })
    end
  end
end

-- stdbuf: piped, gdbus would hold its lines in a block buffer.
noctalia.runStream("exec stdbuf -oL gdbus monitor --session --dest org.gnome.NautilusPreviewer --object-path /org/gnome/NautilusPreviewer",
  onPreviewerLine)
noctalia.runStream("exec stdbuf -oL umbriel subscribe windows", onWindowsLine)

-- Tab on an empty desktop: keys only reach a surface that holds the keyboard, and
-- umbriel gives a layer focus only as it appears or is clicked. So when the last
-- focused window goes (a switch to an empty workspace, the last window closed),
-- the desktop takes the keyboard: briefly "exclusive", then back to "on_demand",
-- which keeps it until a window is clicked or focused. Not while a noctalia panel
-- (the launcher) is open, and only on that transition, never from a window.
do
  local hadWindow = true
  local function grab()
    noctalia.layer.configure("desk", { keyboard = "exclusive" })
    noctalia.runAsync({ "sleep", "0.15" }, function()
      noctalia.layer.configure("desk", { keyboard = "on_demand" })
    end)
  end
  onFocus = function(focused)
    if focused or not hadWindow then
      hadWindow = focused
      return
    end
    hadWindow = false
    noctalia.runAsync({ "noctalia", "msg", "status" }, function(res)
      if not (res.stdout or ""):find('"panelOpen": true', 1, true) then
        grab()
      end
    end)
  end
  -- A workspace switch doesn't refresh the window list: ask umbriel then.
  noctalia.runStream("exec stdbuf -oL umbriel subscribe workspaces", function()
    noctalia.runAsync({ "umbriel", "focused-window" }, function(res)
      onFocus(res.exitCode == 0 and not (res.stdout or ""):find("no focused window", 1, true))
    end)
  end)
end





-- ── context menu (with one level of submenus) ───────────────────────────────

local HEADER_H, SEP_H = 0, 0

local function entryHeight(en)
  if en.sep then
    return SEP_H
  elseif en.header then
    return HEADER_H
  end
  return MENU_ROW
end

local function menuHeight(entries)
  local h = PAD * 6
  for _, en in ipairs(entries) do
    h += entryHeight(en)
  end
  return h
end

local function radio(label, current, value, fn)
  return { label = label, radio = true, checked = current == value, fn = fn }
end

local function sortMenu(fnFor)
  return {
    radio(tr("ui.menu.sort.none"), view.sortBy, "none", fnFor("none")),
    { sep = true },
    radio(tr("ui.menu.sort.name"), view.sortBy, "name", fnFor("name")),
    radio(tr("ui.menu.sort.kind"), view.sortBy, "kind", fnFor("kind")),
    radio(tr("ui.menu.sort.date"), view.sortBy, "date", fnFor("date")),
    radio(tr("ui.menu.sort.size"), view.sortBy, "size", fnFor("size")),
  }
end

local function viewMenu()
  local e = { { header = true, label = tr("ui.menu.view.icon_size") } }
  for _, s in ipairs(SIZE_ORDER) do
    table.insert(e, radio(tr("ui.menu.view." .. s), view.iconSize, s, function() setView("iconSize", s) end))
  end
  table.insert(e, { header = true, label = tr("ui.menu.view.spacing") })
  for _, s in ipairs({ "tight", "normal", "wide" }) do
    table.insert(e, radio(tr("ui.menu.view." .. s), view.spacing, s, function() setView("spacing", s) end))
  end
  table.insert(e, { header = true, label = tr("ui.menu.view.text_size") })
  for _, s in ipairs({ "small", "normal", "large" }) do
    table.insert(e, radio(tr("ui.menu.view.text_" .. s), view.textSize, s, function() setView("textSize", s) end))
  end
  table.insert(e, { sep = true })
  table.insert(e, { label = tr("ui.menu.view.show_info"), check = true, checked = view.showInfo,
    fn = function() setView("showInfo", not view.showInfo) end })
  return e
end

local function menuFor(it, c, r)
  local e = {}
  local function add(label, hint, fn)
    table.insert(e, { label = label, hint = hint, fn = fn })
  end
  local function sep()
    table.insert(e, { sep = true })
  end
  if it and it.kind == "stack" then
    add(tr(view.expanded[it.key] and "ui.menu.collapse" or "ui.menu.expand"), "Enter", function() toggleStack(it) end)
    sep()
    add(tr("ui.menu.copy"), "y", function() copySelection(false) end)
    add(tr("ui.menu.cut"), "x", function() copySelection(true) end)
    add(tr("ui.menu.trash"), "Del", trashSelection)
    sep()
    add(tr("ui.menu.stacks_off"), "", function() setStacks(false) end)
  elseif it then
    local sel = selectedItems(true)
    local files = #filePaths(sel) > 0
    add(tr("ui.menu.open"), "Enter", function()
      for _, s in ipairs(selectedItems(false)) do
        openItem(s)
      end
    end)
    if it.uri then
      add(tr("ui.menu.preview"), "Space", function() preview(it) end)
    end
    if it.kind == "trash" then
      sep()
      add(tr("ui.menu.empty_trash"), "", emptyTrash)
    end
    if files then
      sep()
      add(tr("ui.menu.cut"), "x", function() copySelection(true) end)
      add(tr("ui.menu.copy"), "y", function() copySelection(false) end)
      if #sel == 1 and it.isDir and not it.fixed then
        add(tr("ui.menu.paste"), "p", function() pasteInto(it.path) end)
      end
      sep()
      if #sel == 1 then
        add(tr("ui.menu.rename"), "F2", function() startRename(it) end)
      end
      add(tr("ui.menu.trash"), "Del", trashSelection)
      add(tr("ui.menu.delete"), "D", deleteSelection)
      sep()
      add(tr("ui.menu.copy_path"), "", function()
        noctalia.copyToClipboard(table.concat(filePaths(sel), "\n"), "text/plain")
      end)
      add(tr("ui.menu.show_in_files"), "", function()
        noctalia.runAsync({ "nautilus", "--select", it.path })
      end)
    end
  else
    add(tr("ui.menu.new_folder"), "a", function() createNew(true, c, r) end)
    add(tr("ui.menu.new_document"), "A", function() createNew(false, c, r) end)
    add(tr("ui.menu.paste"), "p", function() pasteInto(folder) end)
    sep()
    table.insert(e, { label = tr("ui.menu.use_stacks"), hint = "C-A-0", check = true, checked = view.stacks,
      fn = function() setStacks(not view.stacks) end })
    if view.stacks then
      table.insert(e, { label = tr("ui.menu.group_by"), sub = {
        radio(tr("ui.menu.sort.kind"), view.groupBy, "kind", function() setView("groupBy", "kind") end),
        radio(tr("ui.menu.sort.date"), view.groupBy, "date", function() setView("groupBy", "date") end),
      } })
    end
    table.insert(e, { label = tr("ui.menu.sort_by"), sub = sortMenu(function(by) return function() setSort(by) end end) })
    if not view.stacks then
      add(tr("ui.menu.clean_up"), "C-A-c", function() cleanUp(nil) end)
      table.insert(e, { label = tr("ui.menu.clean_up_by"), sub = {
        { label = tr("ui.menu.sort.name"), fn = function() cleanUp("name") end },
        { label = tr("ui.menu.sort.kind"), fn = function() cleanUp("kind") end },
        { label = tr("ui.menu.sort.date"), fn = function() cleanUp("date") end },
        { label = tr("ui.menu.sort.size"), fn = function() cleanUp("size") end },
      } })
    end
    table.insert(e, { label = tr("ui.menu.view_options"), sub = viewMenu() })
    sep()
    add(tr("ui.menu.select_all"), "C-a", selectAll)
    add(tr("ui.menu.refresh"), "F5", function() refresh(true) end)
    sep()
    add(tr("ui.menu.open_folder"), "", function() noctalia.runAsync({ "gio", "open", folder }) end)
    add(tr("ui.menu.terminal"), "", openTerminalHere)
    add(tr("ui.menu.help"), "?", function() mode = "help" end)
  end
  return e
end

local function openMenu(x, y, it, c, r)
  HEADER_H, SEP_H = math.floor(22 * S), math.floor(9 * S)
  local entries = menuFor(it, c, r)
  local h = menuHeight(entries)
  menu = { x = math.max(0, math.min(x, outW - MENU_W)), y = math.max(0, math.min(y, outH - h)),
    entries = entries, hover = nil, h = h, sub = nil, level = 1 }
  mode = "menu"
end

local function entryTop(m, i)
  local y = m.y + PAD * 3
  for n = 1, i - 1 do
    y += entryHeight(m.entries[n])
  end
  return y
end

local function openSub(i)
  local en = menu.entries[i]
  if not en or not en.sub then
    menu.sub = nil
    return
  end
  if menu.sub and menu.sub.parent == i then
    return
  end
  local h = menuHeight(en.sub)
  local x = menu.x + MENU_W - PAD * 2
  if x + MENU_W > outW then
    x = menu.x - MENU_W + PAD * 2
  end
  local y = math.max(0, math.min(entryTop(menu, i) - PAD * 3, outH - h))
  menu.sub = { x = x, y = y, entries = en.sub, hover = nil, h = h, parent = i }
end

-- (level, index) of the entry at (x, y): index nil outside, false on a non-entry.
local function menuHit(x, y)
  for _, lv in ipairs({ { menu.sub, 2 }, { menu, 1 } }) do
    local m = lv[1]
    if m and x >= m.x and x <= m.x + MENU_W and y >= m.y and y <= m.y + m.h then
      local cy = m.y + PAD * 3
      for i, en in ipairs(m.entries) do
        local h = entryHeight(en)
        if y >= cy and y < cy + h then
          return lv[2], (not en.sep and not en.header) and i or false
        end
        cy += h
      end
      return lv[2], false
    end
  end
  return nil, nil
end

local function activate(level, i)
  local m = level == 2 and menu.sub or menu
  local en = m and m.entries[i]
  if not en then
    return
  end
  if en.sub then
    openSub(i)
    menu.level = 2
    menu.sub.hover = 1
    while menu.sub.entries[menu.sub.hover] and (menu.sub.entries[menu.sub.hover].sep or menu.sub.entries[menu.sub.hover].header) do
      menu.sub.hover += 1
    end
    return
  end
  menu, mode = nil, "normal"
  if en.fn then
    en.fn()
  end
end

local function menuStep(step)
  local m = (menu.level == 2 and menu.sub) or menu
  local n = #m.entries
  local i = m.hover or (step > 0 and 0 or n + 1)
  for _ = 1, n do
    i = ((i - 1 + step) % n) + 1
    if not m.entries[i].sep and not m.entries[i].header then
      m.hover = i
      if m == menu then
        openSub(i)
      end
      return
    end
  end
end

-- ── pointer ─────────────────────────────────────────────────────────────────

local DOUBLE_CLICK_MS = 450

local function px(nx, ny)
  return tonumber(nx) * outW, tonumber(ny) * outH
end

local function cellAt(x, y)
  local c, r = math.floor((x - OX) / CW) + 1, math.floor((y - OY) / CH) + 1
  return math.max(1, math.min(COLS, c)), math.max(1, math.min(ROWS, r))
end

local function keyAt(x, y)
  if x < OX or y < OY or x >= OX + COLS * CW or y >= OY + ROWS * CH then
    return nil, cellAt(x, y)
  end
  local c, r = cellAt(x, y)
  return occ[cellId(c, r)], c, r
end

local function onDown(nx, ny)
  local x, y = px(nx, ny)
  if noctalia.nowMs() - lastKeyMs > 5000 then
    ctrlDown, shiftDown = false, false
  end
  if mode == "menu" then
    local level, i = menuHit(x, y)
    if i then
      activate(level, i)
    elseif level == nil then
      menu, mode = nil, "normal"
    end
    render()
    return
  end
  if mode == "rename" then
    commitRename()
  elseif mode ~= "normal" then
    mode, confirm = "normal", nil
  end
  local key = keyAt(x, y)
  press = { x = x, y = y, key = key, ms = noctalia.nowMs(), moved = false }
  render()
end

local function onMove(nx, ny)
  local x, y = px(nx, ny)
  if mode == "menu" then
    local level, i = menuHit(x, y)
    local changed = false
    if level == 1 and i ~= menu.hover then
      menu.hover = i or nil
      menu.level = 1
      if i then
        openSub(i)
      end
      changed = true
    elseif level == 2 and menu.sub and i ~= menu.sub.hover then
      menu.sub.hover = i or nil
      menu.level = 2
      changed = true
    end
    if changed then
      render()
    end
    return
  end
  if press then
    if not press.moved and math.abs(x - press.x) + math.abs(y - press.y) > DRAG_THRESHOLD then
      press.moved = true
      if press.key then
        if not selection[press.key] then
          selectOnly(press.key)
        end
        drag = { keys = selectedKeys(), dx = 0, dy = 0 }
      else
        local base = {}
        if ctrlDown then
          for k in pairs(selection) do
            base[k] = true
          end
        end
        band = { x0 = press.x, y0 = press.y, base = base }
      end
    end
    if drag then
      drag.dx, drag.dy = x - press.x, y - press.y
      render()
    elseif band then
      band.x1, band.y1 = x, y
      local x0, x1 = math.min(band.x0, x), math.max(band.x0, x)
      local y0, y1 = math.min(band.y0, y), math.max(band.y0, y)
      selection = table.clone(band.base)
      for key, p in pairs(pos) do
        local cx0, cy0 = OX + (p[1] - 1) * CW, OY + (p[2] - 1) * CH
        if cx0 < x1 and cx0 + CW > x0 and cy0 < y1 and cy0 + CH > y0 then
          selection[key] = true
        end
      end
      render()
    end
    return
  end
  local key = keyAt(x, y)
  if key ~= hoverKey then
    hoverKey = key
    render()
  end
end

local function dropTarget(key, moving)
  local t = key and not moving[key] and byKey[key]
  if t and (t.kind == "dir" or t.kind == "home" or t.kind == "trash") then
    return t
  end
  return nil
end

local function drop(x, y, pr)
  local d = drag
  drag = nil
  local target, tc, trow = keyAt(x, y)
  local moving = {}
  for _, k in ipairs(d.keys) do
    moving[k] = true
  end
  local t = dropTarget(target, moving)
  if t then
    local paths = filePaths(selectedItems(true))
    if #paths > 0 then
      local argv = t.kind == "trash" and { "gio", "trash", "--" } or { "gio", "move", "--" }
      for _, p in ipairs(paths) do
        table.insert(argv, p)
      end
      if t.kind ~= "trash" then
        table.insert(argv, t.path)
      end
      selectOnly(nil)
      fx.flash(t.kind == "trash" and tr("ui.toast.trashed", { count = #paths })
        or tr("ui.toast.moved", { count = #paths, name = t.name }), t.kind == "trash" and "trash" or "folder")
      run(argv)
    end
    return
  end
  if view.stacks then
    return -- stacks keep the desktop arranged
  end
  local pc, prow = cellAt(pr.x, pr.y)
  local dc, dr = tc - pc, trow - prow
  if dc == 0 and dr == 0 then
    return
  end
  makeFree()
  for _, k in ipairs(d.keys) do
    occ[cellId(pos[k][1], pos[k][2])] = nil
  end
  local targets = {}
  for _, k in ipairs(d.keys) do
    local p = pos[k]
    local c = math.max(1, math.min(COLS, p[1] + dc))
    local r = math.max(1, math.min(ROWS, p[2] + dr))
    if not freeCell(c, r) then
      local f = nearestFree(c, r)
      c, r = f and f[1] or p[1], f and f[2] or p[2]
    end
    targets[k] = { c, r }
    occ[cellId(c, r)] = k
  end
  for k, p in pairs(targets) do
    pos[k] = p
    saved[folder][k] = cellPoint(p[1], p[2])
  end
  writeSaved()
end

local function onUp(nx, ny)
  local x, y = px(nx, ny)
  local pr = press
  press = nil
  if not pr then
    return
  end
  if drag then
    drop(x, y, pr)
  elseif band then
    band = nil
  elseif pr.key then
    local key = pr.key
    local it = byKey[key]
    local now = noctalia.nowMs()
    if ctrlDown then
      selection[key] = not selection[key] or nil
      focusKey, anchorKey = key, key
    elseif shiftDown and anchorKey then
      focusKey = key
      selectRange(anchorKey, key)
    elseif it and it.kind == "stack" then
      selectOnly(key) -- a stack opens on one click, as on a Mac
      toggleStack(it)
    elseif singleClick or (lastClick.key == key and now - lastClick.ms <= DOUBLE_CLICK_MS) then
      lastClick.key = nil
      selectOnly(key)
      openItem(it)
      render()
      return
    else
      selectOnly(key)
    end
    lastClick.key, lastClick.ms = key, now
  elseif not ctrlDown then
    selectOnly(nil)
  end
  render()
end

local function onCancel()
  press, drag, band = nil, nil, nil
  render()
end

local function onRight(nx, ny)
  local x, y = px(nx, ny)
  if mode == "rename" then
    commitRename()
  end
  local key, c, r = keyAt(x, y)
  if key and not selection[key] then
    selectOnly(key)
  elseif not key then
    selectOnly(nil)
  end
  if not key and blocked[cellId(c, r)] then
    c, r = nil, nil
  end
  openMenu(x, y, key and byKey[key], c, r)
  render()
end

-- Ctrl+wheel zooms, as in a file manager.
local function onScroll(_, dy)
  if ctrlDown and noctalia.nowMs() - lastKeyMs < 5000 then
    local d = tonumber(dy) or 0
    if d ~= 0 then
      zoom(d < 0 and 1 or -1)
    end
  end
end

-- ── keyboard ────────────────────────────────────────────────────────────────

local function focusItem()
  return focusKey and byKey[focusKey]
end

local function openSelection()
  for _, it in ipairs(selectedItems(false)) do
    openItem(it)
  end
end

local DIRS = {
  h = { -1, 0 }, j = { 0, 1 }, k = { 0, -1 }, l = { 1, 0 },
  Left = { -1, 0 }, Down = { 0, 1 }, Up = { 0, -1 }, Right = { 1, 0 },
}

local function renameKey(chord)
  local rn = rename
  local t = rn.text
  if chord == "Return" or chord == "KP_Enter" then
    commitRename()
  elseif chord == "Escape" then
    rename, mode = nil, "normal"
  elseif chord == "BackSpace" or chord == "Delete" then
    if rn.stemSel then
      rn.text, rn.cursor = t:sub(rn.stemSel + 1), 0
    elseif chord == "BackSpace" and rn.cursor > 0 then
      rn.text = t:sub(1, rn.cursor - 1) .. t:sub(rn.cursor + 1)
      rn.cursor -= 1
    elseif chord == "Delete" then
      rn.text = t:sub(1, rn.cursor) .. t:sub(rn.cursor + 2)
    end
    rn.stemSel = nil
  elseif chord == "Left" then
    rn.cursor = rn.stemSel and 0 or math.max(0, rn.cursor - 1)
    rn.stemSel = nil
  elseif chord == "Right" then
    rn.cursor = rn.stemSel and rn.stemSel or math.min(#t, rn.cursor + 1)
    rn.stemSel = nil
  elseif chord == "Home" then
    rn.cursor, rn.stemSel = 0, nil
  elseif chord == "End" then
    rn.cursor, rn.stemSel = #t, nil
  elseif chord == "Ctrl+a" then
    rn.stemSel, rn.cursor = #t, #t
  end
end

local function renameText(s)
  local rn = rename
  if rn.stemSel then
    rn.text = s .. rn.text:sub(rn.stemSel + 1)
    rn.cursor, rn.stemSel = #s, nil
  else
    rn.text = rn.text:sub(1, rn.cursor) .. s .. rn.text:sub(rn.cursor + 1)
    rn.cursor += #s
  end
end

local function menuKey(base, s)
  if base == "Escape" or s == "q" then
    if menu.level == 2 and menu.sub then
      menu.level = 1
      menu.sub.hover = nil
    else
      menu, mode = nil, "normal"
    end
  elseif base == "Down" or s == "j" then
    menuStep(1)
  elseif base == "Up" or s == "k" then
    menuStep(-1)
  elseif base == "Right" or s == "l" then
    if menu.level == 1 and menu.hover and menu.entries[menu.hover].sub then
      activate(1, menu.hover)
    end
  elseif base == "Left" or s == "h" then
    if menu.level == 2 then
      menu.level = 1
      if menu.sub then menu.sub.hover = nil end
    end
  elseif base == "Return" or base == "KP_Enter" or s == " " then
    local m = menu.level == 2 and menu.sub or menu
    if m and m.hover then
      activate(menu.level, m.hover)
    end
  end
end

local KEYS
do
local function tabStep(step)
  local list = ordered()
  if #list == 0 then
    return
  end
  local i = 0
  for n, it in ipairs(list) do
    if it.key == focusKey then
      i = n
    end
  end
  i = i == 0 and (step > 0 and 1 or #list) or ((i - 1 + step) % #list) + 1
  selectOnly(list[i].key)
end
local function keyMenu()
  local p = focusKey and pos[focusKey]
  if p then
    openMenu(OX + p[1] * CW - CW / 2, OY + p[2] * CH - CH / 3, byKey[focusKey], p[1], p[2])
  else
    openMenu(outW / 2 - MENU_W / 2, outH / 3)
  end
end

local function rename1() startRename(focusItem()) end
local function copy() copySelection(false) end
local function cut() copySelection(true) end
local function zoomIn() zoom(1) end
local function zoomOut() zoom(-1) end
local function help() mode = "help" end
local function newFolder() createNew(true) end

-- Normal mode: typed text (vim) and key chords (Windows) in one table.
KEYS = {
  o = openSelection, Return = openSelection, KP_Enter = openSelection,
  r = rename1, F2 = rename1,
  y = copy, ["Ctrl+c"] = copy, x = cut, ["Ctrl+x"] = cut,
  p = function()
    local it = focusItem()
    pasteInto((it and it.kind == "dir" and #selectedKeys() == 1) and it.path or folder)
  end,
  ["Ctrl+v"] = function() pasteInto(folder) end,
  d = trashSelection, Delete = trashSelection, D = deleteSelection, ["Shift+Delete"] = deleteSelection,
  a = newFolder, ["Ctrl+Shift+N"] = newFolder, ["Ctrl+Shift+n"] = newFolder,
  A = function() createNew(false) end,
  ["/"] = function() mode, search.query = "search", "" end,
  n = function() findMatch(search.last, 1) end,
  N = function() findMatch(search.last, -1) end,
  G = function() selectEdge(true) end, End = function() selectEdge(true) end,
  Home = function() selectEdge(false) end,
  v = function() visual, anchorKey = not visual, focusKey end,
  Escape = function() visual = false; selectOnly(nil) end,
  ["+"] = zoomIn, ["="] = zoomIn, ["Ctrl+plus"] = zoomIn, ["Ctrl+equal"] = zoomIn, ["Ctrl+KP_Add"] = zoomIn,
  ["-"] = zoomOut, ["Ctrl+minus"] = zoomOut, ["Ctrl+KP_Subtract"] = zoomOut,
  ["Ctrl+0"] = function() setView("iconSize", "medium") end,
  ["?"] = help, F1 = help,
  F5 = function() refresh(true) end,
  ["Ctrl+a"] = selectAll, ["Ctrl+space"] = toggleFocused,
  ["Ctrl+j"] = function() openMenu(outW / 2 - MENU_W / 2, outH / 3) end,
  Menu = keyMenu, ["Shift+F10"] = keyMenu,
  -- Tab enters the icons (the first), then steps through them; Shift+Tab back.
  Tab = function() tabStep(1) end,
  ["Shift+ISO_Left_Tab"] = function() tabStep(-1) end, ["Shift+Tab"] = function() tabStep(-1) end,
  -- The Mac's Ctrl+Cmd+0..4 (Super never reaches the desktop).
  ["Ctrl+Alt+0"] = function() setStacks(not view.stacks) end,
  ["Ctrl+Alt+1"] = function() setSort("name") end, ["Ctrl+Alt+2"] = function() setSort("kind") end,
  ["Ctrl+Alt+3"] = function() setSort("date") end, ["Ctrl+Alt+4"] = function() setSort("size") end,
  ["Ctrl+Alt+9"] = function() setSort("none") end, ["Ctrl+Alt+c"] = function() cleanUp(nil) end,
  [" "] = function()
    local it = focusItem()
    if ctrlDown then
      toggleFocused()
    elseif it and it.kind == "stack" then
      toggleStack(it)
    else
      preview(it)
    end
  end,
}
end

local ARROW_HOW = { [""] = false, ["Shift+"] = "extend", ["Ctrl+"] = "focus", ["Alt+"] = "nudge" }

-- One key: typed text (`text`) or a chord such as "Ctrl+c" or "Shift+Down".
local function handle(k, text)
  local base = text and k or k:match("([^+]+)$")
  if mode == "rename" then
    if text then renameText(k) else renameKey(k) end
  elseif mode == "search" then
    if text then
      search.query ..= k
      findMatch(search.query, 0)
    elseif base == "BackSpace" then
      search.query = search.query:sub(1, -2)
      findMatch(search.query, 0)
    elseif base == "Return" or base == "KP_Enter" or base == "Escape" then
      search.last = base ~= "Escape" and search.query or search.last
      mode = "normal"
    end
  elseif mode == "menu" then
    menuKey(not text and base or nil, text and k or nil)
  elseif mode == "confirm" or mode == "help" then
    local act = mode == "confirm" and confirm and confirm.action
    if text or base == "Escape" or base == "Return" then
      mode, confirm = "normal", nil
      if act and (k == "y" or k == "Y" or base == "Return") then
        act()
      end
    end
  else
    local g = pendingG
    pendingG = false
    local d = DIRS[base]
    local how = d and (text and (k:upper() == k and "nudge" or (visual and "extend" or false))
      or ARROW_HOW[k:sub(1, #k - #base)])
    if text and not d and DIRS[k:lower()] then
      d, how = DIRS[k:lower()], "nudge" -- H J K L
    end
    if d and how ~= nil then
      if how == "nudge" then
        nudge(d[1], d[2])
      else
        moveFocus(d[1], d[2], how or ((visual or shiftDown) and "extend" or nil))
      end
    elseif k == "g" then
      if g then selectEdge(false) else pendingG = true end
    elseif KEYS[k] then
      KEYS[k]()
    end
  end
  render()
end

local function onText(s)
  handle(s, true)
end

local function onKey(chord, pressed)
  lastKeyMs = noctalia.nowMs()
  local mod = chord:match("^Control_") and "ctrl" or chord:match("^Shift_") and "shift"
  if mod then
    if mod == "ctrl" then ctrlDown = pressed == "true" else shiftDown = pressed == "true" end
    return
  end
  -- noctalia keeps Tab presses (its own focus cycling) and passes the release: act on it.
  local tab = chord == "Tab" or chord == "Shift+ISO_Left_Tab" or chord == "Shift+Tab"
  if pressed ~= (tab and "false" or "true") then
    return
  end
  ctrlDown = chord:find("Ctrl+", 1, true) ~= nil
  shiftDown = chord:find("Shift+", 1, true) ~= nil
  handle(chord, false)
end

-- ── wallpaper brightness ────────────────────────────────────────────────────

local function sampleWallpaper(path)
  local gw, gh = COLS * CW, ROWS * CH
  noctalia.runAsync({
    "magick", path .. "[0]", "-resize", outW .. "x" .. outH .. "^", "-gravity", "center",
    "-extent", outW .. "x" .. outH, "+gravity", "-crop", gw .. "x" .. gh .. "+" .. OX .. "+" .. OY, "+repage",
    "-resize", COLS .. "x" .. (ROWS * 2) .. "!", "-colorspace", "Gray", "-depth", "8", "txt:-",
  }, function(res)
    if res.exitCode ~= 0 then
      return
    end
    local fresh = {}
    for line in res.stdout:gmatch("[^\n]+") do
      local x, y, g = line:match("^(%d+),(%d+):%s*%(%s*([%d%.]+)")
      if x and tonumber(y) % 2 == 1 then
        fresh[cellId(tonumber(x) + 1, (tonumber(y) - 1) // 2 + 1)] = tonumber(g) / 255
      end
    end
    lum, nodeCache = fresh, {}
    render()
  end, 20000)
end

local function textStyle(c, r)
  local l = lum[cellId(c, r)]
  if l and l > 0.6 then
    return "#161616", false, "#16161699"
  end
  return "#ffffff", true, "#ffffffbb"
end

-- ── drawing ─────────────────────────────────────────────────────────────────

local CLEAR = "#00000000"

local function iconNode(it, size)
  size = size or ICON
  if it.image then
    return ui.image({ path = it.image, width = size, height = size, radius = 4, fit = "contain" })
  end
  local path = L.iconPath(it.icon) or L.iconPath("text-x-generic")
  if path then
    return ui.image({ path = path, width = size, height = size, fit = "contain" })
  end
  return ui.glyph({ name = "file", size = size - 8, color = "on_surface" })
end

-- A stack: its first file inside two translucent frames, like a pile of cards.
local function stackIcon(it)
  local f = math.max(2, math.floor(3 * S))
  local inner = ICON - 4 * f
  return ui.column({ width = ICON, height = ICON, minWidth = ICON, minHeight = ICON, padding = f,
    radius = math.floor(9 * S), fill = "surface/0.35", align = "center", justify = "center" }, {
    ui.column({ width = ICON - 2 * f, height = ICON - 2 * f, minHeight = ICON - 2 * f, padding = f,
      radius = math.floor(7 * S), fill = "surface/0.6", align = "center", justify = "center" }, {
      iconNode(it, inner),
    }),
  })
end

local function label(text, color, shadow, props)
  local p = props or {}
  p.text, p.color, p.shadow = text, color, shadow
  p.fontSize = p.fontSize or FONT
  p.maxLines = p.maxLines or 2
  p.maxWidth = p.maxWidth or (CW - 6 * PAD)
  p.textAlign = p.textAlign or "center"
  return ui.label(p)
end

local function renameNode()
  local rn = rename
  local t = rn.text
  local shown = rn.stemSel and t or (t:sub(1, rn.cursor) .. "│" .. t:sub(rn.cursor + 1))
  return ui.row({ fill = "surface", radius = math.floor(5 * S), paddingH = PAD * 2, paddingV = PAD,
    justify = "center" }, {
    label(shown, rn.stemSel and "primary" or "on_surface", false,
      { maxLines = 4, fontWeight = rn.stemSel and "semibold" or nil }),
  })
end

local function cell(it, c, r, ghost)
  local isSel = selection[it.key] and not ghost
  local isFocus = focusKey == it.key and not isSel and not ghost
  local dragging = drag and selection[it.key] and not ghost
  local frame, fill = CLEAR, CLEAR
  if isSel then
    frame, fill = "primary", "primary_container"
  elseif isFocus then
    frame = "primary/0.7"
  elseif hoverKey == it.key and not drag then
    fill = "on_surface/0.14"
  elseif it.stack then
    fill = "primary/0.10" -- files of an open stack
  end
  local children = { it.kind == "stack" and stackIcon(it) or iconNode(it) }
  if rename and rename.key == it.key then
    table.insert(children, renameNode())
  else
    local color, shadow, sub
    if isSel then
      color, shadow, sub = "on_primary_container", false, "on_primary_container"
    else
      color, shadow, sub = textStyle(c, r)
    end
    local name = it.name
    if it.kind == "stack" then
      name = (view.expanded[it.key] and "▾ " or "▸ ") .. name
    end
    table.insert(children, label(name, color, shadow, { fontWeight = (isSel or it.kind == "stack") and "semibold" or nil,
      maxLines = it.info and 1 or 2 }))
    if it.info then
      table.insert(children, label(it.info, sub, shadow and not isSel,
        { maxLines = 1, fontSize = FONT * 0.88 }))
    end
  end
  return ui.column({
    key = "cell" .. it.key .. (ghost and "-ghost" or ""),
    width = CW, minWidth = CW, height = CH, minHeight = CH,
    padding = PAD, radius = math.floor(12 * S), fill = frame, align = "stretch",
    opacity = dragging and 0.35 or (ghost and 0.85 or (fx.cut[it.key] and 0.5 or 1)),
  }, {
    ui.column({ flexGrow = 1, padding = PAD, gap = math.floor(3 * S), radius = math.floor(10 * S),
      fill = fill, align = "center", justify = "start" }, children),
  })
end

local function moreCell()
  return ui.column({ width = CW, minWidth = CW, height = CH, minHeight = CH, align = "center", justify = "center",
    gap = PAD * 2 }, {
    iconNode({ icon = "folder" }),
    label(tr("ui.more", { count = overflow }), "#ffffff", true),
  })
end

-- Cell nodes kept between renders (plain tables, no callbacks: input is the pad's),
-- so a hover or a drag step rebuilds only the cells whose look changed. Cleared by
-- relayout (items, geometry) and a new wallpaper sample (name colours).

local function grid()
  local rows = {}
  for r = 1, ROWS do
    local cells = {}
    for c = 1, COLS do
      local id = cellId(c, r)
      local key = occ[id]
      local sig
      if key then
        sig = not (rename and rename.key == key) and table.concat({ key, selection[key] and 1 or 0,
          focusKey == key and 1 or 0, hoverKey == key and not drag and 1 or 0, drag and selection[key] and 1 or 0,
          view.expanded[key] and 1 or 0, fx.cut[key] and 1 or 0 }, "|") or nil
      else
        sig = id == moreAt and ("+" .. overflow) or ""
      end
      local hit = nodeCache[id]
      if not (sig and hit and hit[1] == sig) then
        local node = key and cell(byKey[key], c, r) or (id == moreAt and moreCell())
          or ui.box({ key = "e" .. id, width = CW, height = CH, fill = CLEAR }) -- unfilled boxes paint black
        hit = { sig, node }
        nodeCache[id] = sig and hit or nil
      end
      cells[c] = hit[2]
    end
    table.insert(rows, ui.row({ key = "r" .. r, height = CH, minHeight = CH, align = "start" }, cells))
  end
  return ui.column({ key = "grid", width = outW, minWidth = outW, height = outH, minHeight = outH, align = "start" }, {
    ui.column({ width = COLS * CW, height = ROWS * CH, minHeight = ROWS * CH, translateX = OX, translateY = OY,
      align = "start" }, rows),
  })
end

local function menuBox(m, active)
  local rowsN = {}
  for i, en in ipairs(m.entries) do
    if en.sep then
      table.insert(rowsN, ui.column({ key = "s" .. i, height = SEP_H, minHeight = SEP_H, justify = "center" }, {
        ui.box({ height = 1, fill = "outline_variant/0.6", width = MENU_W - PAD * 6 }),
      }))
    elseif en.header then
      table.insert(rowsN, ui.row({ key = "hd" .. i, height = HEADER_H, minHeight = HEADER_H, paddingH = PAD * 4,
        align = "end" }, {
        ui.label({ text = en.label, fontSize = FONT * 0.9, fontWeight = "semibold", color = "on_surface_variant" }),
      }))
    else
      local hot = m.hover == i
      local fg = hot and (active and "on_primary" or "on_surface") or "on_surface"
      local mark = ""
      if en.checked then
        mark = en.radio and "●" or "✓"
      end
      table.insert(rowsN, ui.row({ key = "m" .. i, height = MENU_ROW, minHeight = MENU_ROW, paddingH = PAD * 3,
        radius = math.floor(7 * S), align = "center", gap = PAD * 2,
        fill = hot and (active and "primary" or "on_surface/0.10") or CLEAR }, {
        ui.label({ text = mark, fontSize = FONT * 0.95, color = hot and active and "on_primary" or "primary",
          width = 12 * S, minWidth = 12 * S }),
        ui.label({ text = en.label, fontSize = FONT * 1.1, color = fg, flexGrow = 1 }),
        ui.label({ text = en.sub and "›" or (en.hint or ""), fontSize = FONT * (en.sub and 1.3 or 0.95),
          color = hot and active and "on_primary" or "on_surface_variant" }),
      }))
    end
  end
  return ui.column({ width = MENU_W, minWidth = MENU_W, height = m.h, minHeight = m.h, padding = PAD * 3,
    radius = math.floor(12 * S), fill = "surface/0.97", border = "outline_variant/0.6", borderWidth = 1,
    align = "stretch" }, rowsN)
end

local function overlay()
  local nodes, used = {}, 0
  local function put(node, x, y, h)
    table.insert(nodes, ui.column({ height = h, minHeight = h, translateX = x, translateY = y - used, align = "start" }, { node }))
    used += h
  end

  if drag then
    for _, k in ipairs(drag.keys) do
      local p = pos[k]
      if p then
        put(cell(byKey[k], p[1], p[2], true), OX + (p[1] - 1) * CW + drag.dx, OY + (p[2] - 1) * CH + drag.dy, CH)
      end
    end
    local tx, ty = press.x + drag.dx, press.y + drag.dy
    local target, tc, trow = keyAt(tx, ty)
    local moving = {}
    for _, k in ipairs(drag.keys) do
      moving[k] = true
    end
    local into = dropTarget(target, moving) ~= nil
    if into or not view.stacks then
      local ok = into or not blocked[cellId(tc, trow)]
      put(ui.box({ width = CW, height = CH, radius = math.floor(12 * S),
        fill = into and "primary/0.35" or (ok and "on_surface/0.10" or "error/0.15"), border = ok and "primary" or "error",
        borderWidth = 2 }), OX + (tc - 1) * CW, OY + (trow - 1) * CH, CH)
    end
  end

  if band and band.x1 then
    local x0, y0 = math.min(band.x0, band.x1), math.min(band.y0, band.y1)
    local bw, bh = math.abs(band.x1 - band.x0), math.abs(band.y1 - band.y0)
    put(ui.box({ width = bw, height = bh, radius = math.floor(4 * S), fill = "primary/0.18",
      border = "primary/0.8", borderWidth = 1 }), x0, y0, bh)
  end

  local function pill(text, glyph)
    local kids = { ui.label({ text = text, fontSize = 12.5 * S, color = "on_surface" }) }
    if glyph then
      table.insert(kids, 1, ui.glyph({ name = glyph, size = 14 * S, color = "primary" }))
    end
    return ui.row({ fill = "surface/0.95", radius = math.floor(10 * S), paddingH = math.floor(12 * S),
      paddingV = math.floor(6 * S), gap = math.floor(6 * S), align = "center" }, kids)
  end
  local pillH = math.floor(34 * S)
  if fx.toast then
    put(ui.row({ width = outW, minWidth = outW, justify = "center" }, { pill(fx.toast.text, fx.toast.glyph) }),
      0, OY + ROWS * CH - pillH - 8 * S, pillH)
  end
  if mode == "search" then
    put(pill("/" .. search.query .. "│", "search"), OX + 8 * S, OY + 8 * S, pillH)
  elseif visual then
    put(pill("-- VISUAL --"), OX + 8 * S, OY + 8 * S, pillH)
  end
  if mode == "confirm" and confirm then
    put(pill(confirm.text, "alert-triangle"), outW / 2 - 170 * S, outH / 2 - pillH / 2, pillH)
  end

  if mode == "menu" and menu then
    put(menuBox(menu, menu.level == 1), menu.x, menu.y, menu.h)
    if menu.sub then
      put(menuBox(menu.sub, menu.level == 2), menu.sub.x, menu.sub.y, menu.sub.h)
    end
  end

  if mode == "help" then
    -- Keys as keycaps: groups split by spaces, a chord's keys by "+".
    local HELP = {
      { "Mouse", "mouse", {
        { "Click", "Select" }, { "Ctrl+Click", "Toggle" }, { "Shift+Click", "Extend" },
        { "Double-click", "Open (a stack: one click)" }, { "Drag", "Move, or into a folder or Trash" },
        { "Right-click", "Menu" }, { "Ctrl+Wheel", "Icon size" } } },
      { "Navigate", "arrows-move", {
        { "Tab", "Enter the icons, next (Shift: back)" },
      { "h j k l", "Move (or the arrows)" }, { "gg G", "First, last" },
        { "/", "Search" }, { "n N", "Next, previous match" } } },
      { "Select", "select", {
        { "Shift+Arrows v", "Extend, visual mode" }, { "Ctrl+Arrows", "Move the focus only" },
        { "Ctrl+Space", "Toggle the focused icon" }, { "Ctrl+A Esc", "Select all, clear" } } },
      { "Files", "files", {
        { "Enter o", "Open" }, { "Space", "Preview (arrows: next file)" }, { "F2 r", "Rename" },
        { "y x p", "Copy, cut, paste" }, { "d Del", "Move to Trash" }, { "D", "Delete for good" },
        { "a A", "New folder, document" } } },
      { "Arrange", "layout-grid", {
        { "H J K L", "Move the icons" }, { "Ctrl+Alt+0", "Use stacks" },
        { "Ctrl+Alt+1-4", "Sort by name, kind, date, size" }, { "Ctrl+Alt+C", "Clean up" },
        { "+ -", "Icon size" }, { "Ctrl+J F5", "View menu, refresh" } } },
    }
    local fs, rowH, headH, gapS = 11.5 * S, math.floor(24 * S), math.floor(26 * S), math.floor(10 * S)
    local keyW, colW, pad = math.floor(140 * S), math.floor(360 * S), math.floor(18 * S)
    local function cap(t)
      return ui.row({ fill = "surface_container_highest", border = "outline_variant", borderWidth = 1,
        radius = math.floor(5 * S), paddingH = math.floor(6 * S), height = math.floor(19 * S), align = "center" }, {
        ui.label({ text = t, fontSize = fs * 0.92, fontWeight = "semibold", color = "on_surface" }),
      })
    end
    local function keys(spec)
      local nodes = {}
      for group in spec:gmatch("%S+") do
        local parts = {}
        for k in (group == "+" and group or group:gsub("%+", " ")):gmatch(group == "+" and ".+" or "%S+") do
          if #parts > 0 then
            table.insert(parts, ui.label({ text = "+", fontSize = fs * 0.85, color = "on_surface_variant" }))
          end
          table.insert(parts, cap(k))
        end
        table.insert(nodes, ui.row({ gap = math.floor(2 * S), align = "center" }, parts))
      end
      return ui.row({ width = keyW, minWidth = keyW, gap = math.floor(5 * S), align = "center" }, nodes)
    end
    local function section(sec)
      local rows = { ui.row({ height = headH, minHeight = headH, gap = math.floor(7 * S), align = "center" }, {
        ui.glyph({ name = sec[2], size = fs * 1.3, color = "primary" }),
        ui.label({ text = sec[1], fontSize = fs * 1.05, fontWeight = "bold", color = "primary" }),
      }) }
      for i, r in ipairs(sec[3]) do
        table.insert(rows, ui.row({ key = sec[1] .. i, height = rowH, minHeight = rowH, gap = math.floor(10 * S),
          align = "center" }, {
          keys(r[1]),
          ui.label({ text = r[2], fontSize = fs, color = "on_surface_variant", maxLines = 1, maxWidth = colW - keyW - 10 * S }),
        }))
      end
      return ui.column({ key = "sec" .. sec[1], width = colW, minWidth = colW }, rows), headH + #sec[3] * rowH
    end
    -- Two columns, sections in order, the split that best balances their heights.
    local cols, heights = { {}, {} }, { 0, 0 }
    local total = 0
    local built = {}
    for i, sec in ipairs(HELP) do
      local node, h = section(sec)
      built[i] = { node, h }
      total += h + gapS
    end
    local c = 1
    for _, b in ipairs(built) do
      if c == 1 and heights[1] + b[2] / 2 > total / 2 then
        c = 2
      end
      if #cols[c] > 0 then
        table.insert(cols[c], ui.box({ height = gapS, width = 1, fill = CLEAR }))
      end
      table.insert(cols[c], b[1])
      heights[c] += b[2] + (#cols[c] > 1 and gapS or 0)
    end
    local bodyH = math.max(heights[1], heights[2])
    local titleH = math.floor(34 * S)
    local hw = 2 * colW + math.floor(28 * S) + 2 * pad
    local hh = titleH + math.floor(12 * S) + bodyH + 2 * pad
    put(ui.column({ width = hw, minWidth = hw, height = hh, minHeight = hh, padding = pad, gap = math.floor(6 * S),
      radius = math.floor(16 * S), fill = "surface/0.97", border = "outline_variant/0.6", borderWidth = 1 }, {
      ui.row({ height = titleH, minHeight = titleH, gap = math.floor(9 * S), align = "center" }, {
        ui.glyph({ name = "keyboard", size = fs * 1.7, color = "primary" }),
        ui.label({ text = "Desktop shortcuts", fontSize = fs * 1.4, fontWeight = "bold", color = "on_surface" }),
        ui.spacer({ flexGrow = 1 }),
        ui.label({ text = "press any key to close", fontSize = fs * 0.9, color = "on_surface_variant" }),
      }),
      ui.box({ height = 1, fill = "outline_variant/0.6", width = hw - 2 * pad }),
      ui.row({ gap = math.floor(28 * S), align = "start" }, {
        ui.column({ width = colW, minWidth = colW, align = "start" }, cols[1]),
        ui.column({ width = colW, minWidth = colW, align = "start" }, cols[2]),
      }),
    }), math.max(0, outW / 2 - hw / 2), math.max(0, outH / 2 - hh / 2), hh)
  end

  return ui.column({ key = "overlay", width = outW, minWidth = outW, height = outH, minHeight = outH,
    translateY = -outH, align = "start" }, nodes)
end

render = function()
  if not geometryReady then
    return
  end
  layer.render(ui.column({ width = outW, height = outH, clip = true, align = "start" }, {
    grid(),
    overlay(),
    ui.pixelStream({
      key = "pad", path = SOCKET, width = outW, height = outH, fit = "stretch", translateY = -2 * outH,
      onPointerDown = onDown,
      onPointerMove = onMove,
      onPointerUp = onUp,
      onPointerCancel = onCancel,
      onRightClick = onRight,
      onScroll = onScroll,
      onTextInput = onText,
      onKeyEvent = onKey,
    }),
  }))
end

-- ── refresh ─────────────────────────────────────────────────────────────────

-- Rebuilds what is shown and where, keeping selection and focus by key.
relayout = function()
  nodeCache = {}
  if computeGeometry() then
    wallpaper = nil -- resample for the new cells
  end
  buildFixed()
  buildItems()
  place()
  for key in pairs(selection) do
    if not byKey[key] then
      selection[key] = nil
    end
  end
  if focusKey and not byKey[focusKey] then
    focusKey = nil
  end
  if rename and not byKey[rename.key] then
    rename, mode = nil, "normal"
  end
  render()
end

refresh = function(force)
  local dir = (force or not folder) and L.desktopDir() or folder -- user-dirs.dirs: at start and F5
  local info = noctalia.fileInfo(dir)
  local mtime = info and info.mtime or -2
  local thumbs = noctalia.fileInfo(CACHE_HOME .. "/thumbnails/large")
  local tmtime = thumbs and thumbs.mtime or -2
  local iconsChanged = L.syncMatugenIcons()
  local geomChanged = computeGeometry()
  if geomChanged then
    wallpaper = nil
  end
  if force or iconsChanged or geomChanged or dir ~= folder or mtime ~= folderMtime or tmtime ~= thumbsMtime then
    folder, folderMtime, thumbsMtime = dir, mtime, tmtime
    readFolder()
    relayout()
  end
  local wp = noctalia.wallpaperPath(layer.outputName() or "")
  if wp and wp ~= wallpaper then
    wallpaper = wp
    sampleWallpaper(wp)
  end
end

local ticks = 0

function update()
  if not geometryReady then
    if computeGeometry() then
      refresh(true)
      keepUnderWidgets()
    end
    noctalia.setUpdateInterval(geometryReady and 2000 or 250)
    return
  end
  if ticks == 0 then
    keepUnderWidgets() -- again, once noctalia has settled
  end
  noctalia.setUpdateInterval(2000)
  ticks += 1
  if ticks % 15 == 0 then -- every 30s
    noctalia.processMatches(function(running)
      if not running then startPad() end
    end, "python3", PAD_PY)
  end
  if not press and mode ~= "rename" and mode ~= "menu" then
    refresh(false)
  end
end

loadSaved()
update()
