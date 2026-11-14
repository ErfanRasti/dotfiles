--!nonstrict
-- Minimal weather for the desktop and the lockscreen, drawn from the forecast
-- noctalia's weather service already caches (same location, units and refresh).
--
--   card :  00:37            ☾ 5°      week :  Now  01  02  03  04  05
--           Sat, Nov 14  Clear · 3°/11°         5°   5°  4°  4°  3°  3°
--                                              ──────────────────────────
--   time and temperature share a row,                       min  avg  max
--   so do date and condition                Today ☁         3°   6°  11°
--                                              Sun   ☂         5°  10°  14°
--
-- A day's average is the mean of its hourly temperatures (the cache holds 7 days
-- of hours); it is bold, lows are dimmed. Every cell has a fixed size, so the
-- content never resizes with the numbers and the tile's fitted text size stays put.
--
-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

local CACHE = "~/.cache/noctalia/weather.json"

local mode = noctalia.getConfig("mode")
local width = noctalia.getConfig("width")
local height = noctalia.getConfig("height")
local days = noctalia.getConfig("days")
local hours = noctalia.getConfig("hours")

local FG = "on_surface"
local DIM = "on_surface_variant"

local snapshot = nil
local cacheMtime = -1
local imperial = false

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

local function temp(celsius)
  if celsius == nil then
    return "--"
  end
  return math.floor((imperial and 32 + celsius * 1.8 or celsius) + 0.5) .. "°"
end

-- Re-parses the cache only when noctalia rewrote it.
local function load()
  local info = noctalia.fileInfo(CACHE)
  if not info then
    snapshot = nil
  elseif info.mtime ~= cacheMtime then
    local raw = noctalia.readFile(CACHE)
    local data = raw and noctalia.json.decode(raw)
    if data and data.snapshot and data.snapshot.valid then
      snapshot = data.snapshot
      cacheMtime = info.mtime
    end
  end
end

local function text(t, size, color, props)
  local p = props or {}
  p.text, p.fontSize, p.color, p.maxLines = t, size, color or FG, 1
  return ui.label(p)
end

local function bold(t, size)
  return text(t, size, FG, { fontWeight = "bold" })
end

-- A fixed-size cell: a label's own width doesn't pin its size (it hugs its text).
local function cell(w, justify, child)
  return ui.row({ width = w, minWidth = w, justify = justify, align = "center" }, { child })
end

-- Today's entry in the daily list (the cache starts at today).
local function todayIndex()
  local today = os.date("%Y-%m-%d")
  for i, day in ipairs(snapshot.forecast_days) do
    if day.date_iso == today then
      return i
    end
  end
  return 1
end

-- ── card: the desktop's top-left card ──────────────────────────────────────────
-- Time over date on the left, icon and temperature over "condition · low/high"
-- on the right, each caption centered under its line, on the same two rows
-- (heights and font sizes), so they line up.
local TIME_ROW, DATE_ROW = 44, 20

local function card()
  local left = {
    ui.row({ height = TIME_ROW, align = "center" }, { bold(os.date("%H:%M"), 36) }),
    ui.row({ height = DATE_ROW, align = "center" }, { text(os.date("%a, %b ") .. tonumber(os.date("%d")), 13) }),
  }
  local right = {}
  if snapshot then
    local now = snapshot.current
    local today = snapshot.forecast_days[todayIndex()]
    right = {
      ui.row({ height = TIME_ROW, gap = 8, align = "center" }, {
        ui.glyph({ name = glyphFor(now.weather_code, now.is_day), size = 30, color = FG }),
        bold(temp(now.temperature_c), 36),
      }),
      ui.row({ height = DATE_ROW, align = "center" }, {
        text((WMO[now.weather_code] or UNKNOWN)[1] .. " · "
          .. temp(today.temperature_min_c) .. "/" .. temp(today.temperature_max_c), 13),
      }),
    }
  end
  -- A pinned height too: unpinned, noctalia measures the row taller than its rows,
  -- and the tile then barely scales the text up on a bigger box.
  local h = TIME_ROW + DATE_ROW
  return ui.row({ width = width, minWidth = width, height = h, minHeight = h }, {
    ui.column({ align = "center" }, left),
    ui.spacer({ flexGrow = 1 }),
    ui.column({ align = "center" }, right),
  })
end

-- ── week: hours from now, then today and the next days ────────────────────────
local TEMP_W, TEMP_GAP = 32, 10

-- The min/avg/max columns, numbers right-aligned so the degree signs line up.
local function temps(min, avg, max)
  return ui.row({ gap = TEMP_GAP, align = "center" }, { cell(TEMP_W, "end", min), cell(TEMP_W, "end", avg), cell(TEMP_W, "end", max) })
end

-- Mean of a day's hourly temperatures, the low/high midpoint when it has no hours.
local function average(day)
  local sum, n = 0, 0
  for _, h in ipairs(snapshot.forecast_hours) do
    if string.sub(h.time_iso, 1, 10) == day.date_iso then
      sum += h.temperature_c
      n += 1
    end
  end
  return n > 0 and sum / n or (day.temperature_min_c + day.temperature_max_c) / 2
end

local function hourStrip()
  local list = snapshot.forecast_hours
  local hour = os.date("%Y-%m-%dT%H")
  local first = 1
  for i, h in ipairs(list) do
    if string.sub(h.time_iso, 1, 13) == hour then
      first = i
      break
    end
  end
  local w = math.floor(width / hours) -- equal cells across the width
  local cols = {}
  for i = first, math.min(#list, first + hours - 1) do
    local now = i == first
    table.insert(cols, ui.column({ key = "h" .. i, gap = 2, align = "center", width = w }, {
      text(now and noctalia.tr("ui.now") or string.sub(list[i].time_iso, 12, 13), 11, DIM),
      bold(temp(now and snapshot.current.temperature_c or list[i].temperature_c), 13),
    }))
  end
  return ui.row({ justify = "center", height = 34 }, cols)
end

local function dayRows()
  local list = snapshot.forecast_days
  local first = todayIndex()
  local rows = {
    ui.row({ align = "center", height = 12 }, {
      ui.spacer({ flexGrow = 1 }),
      temps(text("min", 10, DIM), text("avg", 10, DIM), text("max", 10, DIM)),
    }),
  }
  for i = first, math.min(#list, first + days) do
    local day = list[i]
    local name = i == first and noctalia.tr("ui.today")
      or os.date("%a", os.time({ year = tonumber(day.date_iso:sub(1, 4)), month = tonumber(day.date_iso:sub(6, 7)),
        day = tonumber(day.date_iso:sub(9, 10)), hour = 12 }))
    table.insert(rows, ui.row({ key = "d" .. i, gap = 6, align = "center", height = 18 }, {
      cell(44, "start", text(name, 12)),
      cell(16, "center", ui.glyph({ name = glyphFor(day.weather_code), size = 14, color = DIM })),
      ui.spacer({ flexGrow = 1 }),
      temps(text(temp(day.temperature_min_c), 12, DIM), bold(temp(average(day)), 12), text(temp(day.temperature_max_c), 12)),
    }))
  end
  -- With a set height the day list takes the room left over and spreads its rows.
  local fill = height > 0
  return ui.column({ gap = 4, flexGrow = fill and 1 or nil, justify = fill and "space_between" or nil }, rows)
end

local function week()
  local children = { text(noctalia.tr("ui.waiting"), 11, DIM) }
  if snapshot then
    children = { hourStrip(), ui.box({ fill = "outline_variant/0.5", height = 1 }), dayRows() }
  end
  local h = height > 0 and height or nil
  return ui.column({ gap = 10, width = width, minWidth = width, height = h, minHeight = h }, children)
end

function update()
  -- The card shows the time, so it ticks every second (load() then only stats the
  -- cache file); the week ticks once a minute, for the hour and day to roll over.
  noctalia.setUpdateInterval(mode == "card" and 1000 or 60000)
  imperial = noctalia.getSetting("weather.unit") == "imperial"
  load()
  desktopWidget.render(mode == "card" and card() or week())
end
