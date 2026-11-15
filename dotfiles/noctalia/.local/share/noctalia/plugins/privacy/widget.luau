--!nonstrict
-- Privacy indicators, mac style: a little filled circle per thing in use, in its
-- colour, with the glyph in the matching "on" tone (on_green on green, ...).
--
--   (screen-share) (camera) (microphone) (map-pin)
--        red         green      orange      blue
--
-- probe.sh reports what is in use (and by which apps); it runs every second, one
-- at a time, and the bar redraws only when the answer or the colours change.
-- Hidden while nothing is in use (hide_inactive), so the capsule group around it
-- shrinks back to the volume widgets, as with noctalia's own privacy widget.
--
-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

local POLL_MS = 1000
-- A page asking once ("where am I") holds GeoClue only for a moment, which a poll
-- can miss or flash for a single frame: location stays lit this long after it was
-- last seen in use.
local LOCATION_HOLD_MS = 3000
local COLORS = "~/.cache/noctalia/privacy-colors.json" -- the privacy_colors template
local PROBE = noctalia.pluginDir() .. "/probe.sh"
-- Circle diameter and glyph size in logical px; fits the 28px bar's capsule.
local DOT = 18
local GLYPH = 12
-- With hide_inactive off, idle indicators are faint circles.
local INACTIVE_FILL = "outline_variant/0.5"
local INACTIVE_INK = "on_surface_variant"

-- Order on the bar; `fallback` is the palette role used when a custom colour name
-- can't be resolved (the template hasn't run yet).
local KINDS = {
  { key = "screen", glyph = "screen-share", fallback = "error" },
  { key = "camera", glyph = "camera", fallback = "tertiary" },
  { key = "mic", glyph = "microphone", fallback = "secondary" },
  { key = "location", glyph = "map-pin", fallback = "primary" },
}

local palette = {}
local paletteMtime = -1
local state = { screen = {}, camera = {}, mic = {}, location = {} }
local busy = false
local locationSeenMs = nil
local locationApps = {}
local drawnKey = nil

local function loadPalette()
  local info = noctalia.fileInfo(COLORS)
  local mtime = info and info.mtime or -2
  if mtime == paletteMtime then
    return false
  end
  paletteMtime = mtime
  local raw = info and noctalia.readFile(COLORS)
  local data = raw and noctalia.json.decode(raw)
  palette = type(data) == "table" and data or {}
  return true
end

-- The circle's fill and its glyph's ink: a custom colour from the template with its
-- on_ tone, a palette role with its on_ role, or #RRGGBB with black or white.
local CUSTOM = {
  red = true, orange = true, yellow = true, green = true, mint = true, teal = true,
  cyan = true, blue = true, indigo = true, purple = true, pink = true, brown = true,
}

local function contrast(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)")
  if not r then
    return "on_surface"
  end
  local y = 0.299 * tonumber(r, 16) + 0.587 * tonumber(g, 16) + 0.114 * tonumber(b, 16)
  return y > 150 and "#000000" or "#ffffff"
end

local function colorsFor(kind)
  local want = string.lower(noctalia.getConfig(kind.key .. "_color") or "")
  if palette[want] then
    return palette[want], palette["on_" .. want] or contrast(palette[want])
  end
  if want == "" or CUSTOM[want] then
    want = kind.fallback
  end
  if string.sub(want, 1, 1) == "#" then
    return want, contrast(want)
  end
  return want, "on_" .. want
end

local function tooltip()
  local lines = {}
  for _, kind in ipairs(KINDS) do
    local apps = state[kind.key]
    if #apps > 0 then
      table.insert(lines, noctalia.tr("ui." .. kind.key) .. ": " .. table.concat(apps, ", "))
    end
  end
  return #lines > 0 and table.concat(lines, "\n") or noctalia.tr("ui.idle")
end

-- Redraws only when what's shown changes: the key is built first, the tree after.
local function draw()
  local hide = noctalia.getConfig("hide_inactive")
  local gap = noctalia.getConfig("gap") or 4
  local vertical = barWidget.isVertical()
  local shown, parts = {}, {}
  for _, kind in ipairs(KINDS) do
    local on = #state[kind.key] > 0
    if on or not hide then
      local fill, ink = INACTIVE_FILL, INACTIVE_INK
      if on then
        fill, ink = colorsFor(kind)
      end
      table.insert(shown, { kind, fill, ink })
      table.insert(parts, kind.key .. "=" .. fill .. "/" .. ink)
    end
  end
  local tip = tooltip()
  local key = table.concat(parts, ",") .. "|" .. tip .. "|" .. gap .. "|" .. tostring(vertical)
  if key == drawnKey then
    return
  end
  drawnKey = key

  if #shown == 0 then
    barWidget.setVisible(false)
    return
  end
  local dots = {}
  for i, s in ipairs(shown) do
    dots[i] = ui.row({
      key = s[1].key, width = DOT, height = DOT, minWidth = DOT, minHeight = DOT,
      radius = DOT / 2, fill = s[2], justify = "center", align = "center",
    }, { ui.glyph({ name = s[1].glyph, size = GLYPH, color = s[3] }) })
  end
  barWidget.render((vertical and ui.column or ui.row)({ gap = gap, align = "center", tooltip = tip }, dots))
  barWidget.setVisible(true)
end

local function probe()
  if busy then
    return
  end
  busy = true
  noctalia.runAsync({
    PROBE,
    noctalia.getSetting("shell.privacy.mic_filter_regex") or "",
    noctalia.getSetting("shell.privacy.cam_filter_regex") or "",
    noctalia.getSetting("shell.privacy.screen_filter_regex") or "",
  }, function(result)
    busy = false
    local data = result.exitCode == 0 and noctalia.json.decode(result.stdout or "")
    if type(data) == "table" then
      local now = noctalia.nowMs()
      local loc = data.location or {}
      if #loc > 0 then
        locationSeenMs = now
        locationApps = {}
        for i, id in ipairs(loc) do
          locationApps[i] = (string.gsub(id, "^%l", string.upper)) -- bare DesktopIds ("chromium")
        end
      end
      state = {
        screen = data.screen or {},
        camera = data.camera or {},
        mic = data.mic or {},
        location = (locationSeenMs and now - locationSeenMs < LOCATION_HOLD_MS) and locationApps or {},
      }
    end
    draw()
  end)
end

function update()
  noctalia.setUpdateInterval(POLL_MS)
  if loadPalette() then
    drawnKey = nil
  end
  probe()
end

function onConfigChanged()
  drawnKey = nil
  draw()
end

loadPalette()
draw()
