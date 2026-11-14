--!nonstrict
-- Minimal weekly weather tile. Reads the forecast noctalia's weather service
-- already caches, so it follows the shell's location, units and refresh.
--
--   hourly :  Now  01  02  03  04  05      daily :  5°               Clear
--             5°   5°  4°  4°  3°  3°               ───────────────  3° · 11°
--            ──────────────────────────             (days as in hourly,
--                          min  avg  max             from tomorrow on)
--            Today ☁        3°   7°  11°
--            Sun   ☂        5°  10°  14°     now :         ☾ 5°
--            …                                         Clear · 3°/11°
--
-- Lows are dimmed (on_surface_variant), averages bold (the day in one number). A day's average is the mean
-- of its hourly temperatures (the cache holds 7 days of hours). Every row has
-- fixed column widths, so the content's size never changes with the numbers and
-- the tile's fitted text size stays put.

-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

local CACHE = "~/.cache/noctalia/weather.json"

local mode = noctalia.getConfig("mode")
local width = noctalia.getConfig("width")
local days = noctalia.getConfig("days")
local hours = noctalia.getConfig("hours")

local FG = "on_surface"
local DIM = "on_surface_variant"
local LINE = "outline_variant/0.5"

local snapshot = nil
local cacheMtime = -1

-- WMO weather interpretation codes (WMO 4677), the "weather_code" Open-Meteo
-- reports (https://open-meteo.com/en/docs): each code's short name and icon.
-- Icons are names from noctalia's glyph set; a { day, night } pair varies with
-- the sun.
local WMO = {
  [0] = { "Clear", { "weather-sun", "weather-moon" } },
  [1] = { "Mainly clear", { "weather-cloud-sun", "weather-moon-stars" } },
  [2] = { "Partly cloudy", { "weather-cloud-sun", "weather-moon-stars" } },
  [3] = { "Overcast", "weather-cloud" },
  [45] = { "Fog", "weather-cloud-haze" },
  [48] = { "Rime fog", "weather-cloud-haze" },
  [51] = { "Light drizzle", "weather-cloud-rain" },
  [53] = { "Drizzle", "weather-cloud-rain" },
  [55] = { "Heavy drizzle", "weather-cloud-rain" },
  [56] = { "Icy drizzle", "weather-cloud-rain" },
  [57] = { "Icy drizzle", "weather-cloud-rain" },
  [61] = { "Light rain", "weather-cloud-rain" },
  [63] = { "Rain", "weather-cloud-rain" },
  [65] = { "Heavy rain", "weather-cloud-rain" },
  [66] = { "Icy rain", "weather-cloud-rain" },
  [67] = { "Icy rain", "weather-cloud-rain" },
  [71] = { "Light snow", "weather-cloud-snow" },
  [73] = { "Snow", "weather-cloud-snow" },
  [75] = { "Heavy snow", "weather-cloud-snow" },
  [77] = { "Snow grains", "weather-cloud-snow" },
  [80] = { "Showers", "weather-cloud-rain" },
  [81] = { "Showers", "weather-cloud-rain" },
  [82] = { "Heavy showers", "weather-cloud-rain" },
  [85] = { "Snow showers", "weather-cloud-snow" },
  [86] = { "Snow showers", "weather-cloud-snow" },
  [95] = { "Thunderstorm", "weather-cloud-lightning" },
  [96] = { "Thunderstorm", "weather-cloud-lightning" },
  [99] = { "Thunderstorm", "weather-cloud-lightning" },
}
local UNKNOWN = { "Weather", "weather-cloud" }

local function glyphFor(code, isDay)
  local icon = (WMO[code] or UNKNOWN)[2]
  if type(icon) == "table" then
    return isDay == false and icon[2] or icon[1]
  end
  return icon
end

local function conditionFor(code)
  return (WMO[code] or UNKNOWN)[1]
end

local function temp(celsius)
  if celsius == nil then
    return "--"
  end
  local v = celsius
  if noctalia.getSetting("weather.unit") == "imperial" then
    v = 32 + celsius * 1.8
  end
  return tostring(math.floor(v + 0.5)) .. "°"
end

local function weekday(iso)
  local y, m, d = string.match(iso or "", "^(%d+)-(%d+)-(%d+)")
  if not y then
    return iso or ""
  end
  return os.date("%a", os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }))
end

-- Re-parses the cache only when noctalia rewrote it.
local function load()
  local info = noctalia.fileInfo(CACHE)
  if not info then
    snapshot = nil
    return
  end
  if info.mtime == cacheMtime and snapshot then
    return
  end
  local raw = noctalia.readFile(CACHE)
  local data = raw and noctalia.json.decode(raw)
  if data and data.snapshot and data.snapshot.valid then
    snapshot = data.snapshot
    cacheMtime = info.mtime
  end
end

local function caption(text, color, w, align)
  return ui.label({ text = text, fontSize = 11, color = color, width = w, maxLines = 1, textAlign = align or "start" })
end

local function body(text, color, w, align)
  return ui.label({ text = text, fontSize = 12, color = color, width = w, maxLines = 1, textAlign = align or "start" })
end

local function separator()
  return ui.box({ fill = LINE, height = 1 })
end

-- Mean of a day's hourly temperatures, the low/high midpoint when it has no hours.
local function average(day)
  local sum, n = 0, 0
  for _, h in ipairs(snapshot.forecast_hours or {}) do
    if h.temperature_c and string.sub(h.time_iso or "", 1, 10) == day.date_iso then
      sum += h.temperature_c
      n += 1
    end
  end
  if n > 0 then
    return sum / n
  end
  if day.temperature_min_c and day.temperature_max_c then
    return (day.temperature_min_c + day.temperature_max_c) / 2
  end
  return nil
end

-- The three temperature columns: fixed width, numbers right-aligned so the
-- degree signs line up, and a clear gap between columns.
local TEMP_W = 32
local TEMP_GAP = 10

-- Each number sits right-aligned in its own fixed-width cell.
local function cell(child)
  return ui.row({ width = TEMP_W, minWidth = TEMP_W, justify = "end" }, { child })
end

local function temps(children)
  local cells = {}
  for _, child in ipairs(children) do
    table.insert(cells, cell(child))
  end
  return ui.row({ gap = TEMP_GAP, align = "center" }, cells)
end

-- One "day  glyph ……… min  avg  max" row.
local function dayRow(key, name, day)
  -- A label's width doesn't pin its size (it hugs its text), so the name and the
  -- glyph sit in fixed-width cells: every row's glyph starts at the same x.
  return ui.row({ key = key, gap = 6, align = "center", height = 18 }, {
    ui.row({ width = 44, minWidth = 44 }, { body(name, FG) }),
    ui.row({ width = 16, minWidth = 16, justify = "center" }, {
      ui.glyph({ name = glyphFor(day.weather_code or 3, true), size = 14, color = DIM }),
    }),
    ui.spacer({ flexGrow = 1 }),
    temps({
      body(temp(day.temperature_min_c), DIM, TEMP_W, "end"),
      ui.label({ text = temp(average(day)), fontSize = 12, fontWeight = "bold", color = FG,
        width = TEMP_W, maxLines = 1, textAlign = "end" }),
      body(temp(day.temperature_max_c), FG, TEMP_W, "end"),
    }),
  })
end

-- Column titles over the day rows' temperatures, right-aligned like the numbers.
local function dayHeader()
  local function title(text)
    return ui.label({ text = text, fontSize = 10, color = DIM, width = TEMP_W, maxLines = 1, textAlign = "end" })
  end
  return ui.row({ align = "center", height = 12 }, {
    ui.spacer({ flexGrow = 1 }), temps({ title("min"), title("avg"), title("max") }),
  })
end

-- Index of the first daily entry for today (the cache starts at today).
local function todayIndex(list)
  local today = os.date("%Y-%m-%d")
  for i, day in ipairs(list) do
    if day.date_iso == today then
      return i
    end
  end
  return 1
end

local function dayRows(fromToday)
  local list = snapshot.forecast_days or {}
  local first = todayIndex(list)
  local rows = { dayHeader() }
  local start = fromToday and first or first + 1
  for i = start, math.min(#list, first + days) do
    local name = (i == first) and noctalia.tr("ui.today") or weekday(list[i].date_iso)
    table.insert(rows, dayRow("d" .. i, name, list[i]))
  end
  return ui.column({ gap = 4 }, rows)
end

local function dailyHeader()
  local current = snapshot.current or {}
  local list = snapshot.forecast_days or {}
  local today = list[todayIndex(list)] or {}
  return ui.row({ align = "center", height = 34 }, {
    ui.label({ text = temp(current.temperature_c), fontSize = 26, fontWeight = "bold", color = FG }),
    ui.spacer({ flexGrow = 1 }),
    ui.column({ gap = 2, align = "end" }, {
      caption(conditionFor(current.weather_code or 3), FG, 110, "end"),
      caption(temp(today.temperature_min_c) .. " · " .. temp(today.temperature_max_c), DIM, 110, "end"),
    }),
  })
end

-- Current temperature over "condition · low/high", right-aligned: the weather
-- beside the clock on the desktop card, mirroring its time-over-date.
local function nowBlock()
  local current = snapshot.current or {}
  local list = snapshot.forecast_days or {}
  local today = list[todayIndex(list)] or {}
  local line = conditionFor(current.weather_code or 3) .. " · "
    .. temp(today.temperature_min_c) .. "/" .. temp(today.temperature_max_c)
  return ui.column({ gap = 0, align = "end", width = width }, {
    ui.row({ gap = 8, align = "center", justify = "end" }, {
      ui.glyph({ name = glyphFor(current.weather_code or 3, current.is_day), size = 30, color = FG }),
      ui.label({ text = temp(current.temperature_c), fontSize = 36, fontWeight = "bold", color = FG, maxLines = 1 }),
    }),
    ui.label({ text = line, fontSize = 12, color = FG, width = width, maxLines = 1, textAlign = "end" }),
  })
end

local function hourlyStrip()
  local list = snapshot.forecast_hours or {}
  local now = os.date("%Y-%m-%dT%H")
  local first = 1
  for i, h in ipairs(list) do
    if string.sub(h.time_iso or "", 1, 13) == now then
      first = i
      break
    end
  end
  -- Equal-width cells across the whole width, label and temperature centred in each.
  local cell = math.floor(width / hours)
  local cols = {}
  for i = first, math.min(#list, first + hours - 1) do
    local h = list[i]
    local label = (i == first) and noctalia.tr("ui.now") or string.sub(h.time_iso, 12, 13)
    local value = (i == first and snapshot.current) and snapshot.current.temperature_c or h.temperature_c
    table.insert(cols, ui.column({ key = "h" .. i, gap = 2, align = "center", width = cell }, {
      caption(label, DIM, cell, "center"),
      ui.label({ text = temp(value), fontSize = 13, fontWeight = "bold", color = FG, width = cell, textAlign = "center" }),
    }))
  end
  return ui.row({ gap = 0, justify = "center", height = 34 }, cols)
end

local function render()
  load()
  local children
  if not snapshot then
    children = { caption(noctalia.tr("ui.waiting"), DIM) }
  elseif mode == "now" then
    children = { nowBlock() }
  elseif mode == "hourly" then
    children = { hourlyStrip(), separator(), dayRows(true) }
  else
    children = { dailyHeader(), separator(), dayRows(false) }
  end
  desktopWidget.render(ui.column({ gap = 10, width = width, minWidth = width }, children))
end

function update()
  noctalia.setUpdateInterval(60000) -- the hour and the day roll over; the cache refreshes on its own schedule
  render()
end
