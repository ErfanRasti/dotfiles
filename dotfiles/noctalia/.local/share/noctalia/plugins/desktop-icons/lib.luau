--!nonstrict
-- Paths, icons and kinds for desk.luau: the desktop folder, Nautilus' icons
-- (Adwaita-Matugen, refreshed per matugen build; Adwaita), its thumbnails, desktop
-- entries and file kinds. A module so desk.luau stays under Luau's local limit.
--
-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

local md5 = require("./md5.luau")

return function(env)
local HOME, DATA_HOME, CACHE_HOME, CONFIG_HOME, DATA_DIR = env.HOME, env.DATA_HOME, env.CACHE_HOME, env.CONFIG_HOME, env.DATA_DIR
local folderSetting = env.folderSetting


local function dataDirs()
  local dirs = { DATA_HOME }
  for dir in (noctalia.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"):gmatch("[^:]+") do
    table.insert(dirs, dir)
  end
  return dirs
end

local function desktopDir()
  if folderSetting ~= "" then
    return noctalia.expandPath(folderSetting)
  end
  local raw = noctalia.readFile(CONFIG_HOME .. "/user-dirs.dirs")
  local dir = raw and raw:match('XDG_DESKTOP_DIR="([^"]*)"')
  if dir and dir ~= "" then
    dir = dir:gsub("^%$HOME", HOME)
    if dir ~= HOME then
      return dir
    end
  end
  return HOME .. "/Desktop"
end

local function fileUri(path)
  return "file://" .. path:gsub("[^%w/!$&'()*+,%-.:=@_~]", function(ch)
    return string.format("%%%02X", string.byte(ch))
  end)
end

local MATUGEN_SRC = DATA_HOME .. "/icons/Adwaita-Matugen/scalable/"
local matugenDir = nil
local matugenMtime = -1
local ADWAITA_CONTEXTS = { "places", "mimetypes", "status", "devices", "legacy" }
local adwaita = nil
for _, dir in ipairs(dataDirs()) do
  if noctalia.fileInfo(dir .. "/icons/Adwaita/scalable/places/folder.svg") then
    adwaita = dir .. "/icons/Adwaita/scalable/"
    break
  end
end
local iconCache = {}

-- Copies the matugen icons to a directory named after their build time: noctalia
-- keeps one loaded image per path, so a rebuild has to be a new path.
local function syncMatugenIcons()
  local info = noctalia.fileInfo(DATA_HOME .. "/icons/Adwaita-Matugen")
  local mtime = info and info.mtime or -2
  if mtime == matugenMtime then
    return false
  end
  matugenDir = nil
  local version = tostring(mtime)
  local names = info and noctalia.listDir(MATUGEN_SRC)
  if names then
    local dir = DATA_DIR .. "/icons/" .. version .. "/"
    noctalia.mkdirAll(dir)
    for _, name in ipairs(names) do
      local svg = noctalia.readFile(MATUGEN_SRC .. name)
      if svg then
        noctalia.writeFile(dir .. name, svg)
      end
    end
    matugenDir = dir
  end
  matugenMtime = mtime -- only now: a sync cut short is redone on the next pass
  for _, v in ipairs(noctalia.listDir(DATA_DIR .. "/icons") or {}) do
    if v ~= version then
      noctalia.runAsync({ "rm", "-rf", "--", DATA_DIR .. "/icons/" .. v })
    end
  end
  iconCache = {}
  return true
end

local function iconPath(name)
  local hit = iconCache[name]
  if hit ~= nil then
    return hit or nil
  end
  local path = nil
  if matugenDir and noctalia.fileInfo(matugenDir .. name .. ".svg") then
    path = matugenDir .. name .. ".svg"
  elseif adwaita then
    for _, ctx in ipairs(ADWAITA_CONTEXTS) do
      local p = adwaita .. ctx .. "/" .. name .. ".svg"
      if noctalia.fileInfo(p) then
        path = p
        break
      end
    end
  end
  path = path or noctalia.appIconPath(name, 96)
  iconCache[name] = path or false
  return path
end

-- Kinds (stacks, Sort By Kind) and Adwaita icons by extension.
local KIND_ORDER = { "Applications", "Documents", "PDF Documents", "Spreadsheets", "Presentations", "Images",
  "Screenshots", "Movies", "Music", "Archives", "Developer", "Fonts", "Disk Images", "Other" }
local KIND_RANK = {}
for i, k in ipairs(KIND_ORDER) do
  KIND_RANK[k] = i
end
local EXT_KIND, EXT_ICON = {}, {}
for _, spec in ipairs({
  { "Documents", "x-office-document", "doc docx odt rtf txt md epub pages tex" },
  { "PDF Documents", "x-office-document", "pdf" },
  { "Spreadsheets", "x-office-spreadsheet", "xls xlsx ods csv numbers" },
  { "Presentations", "x-office-presentation", "ppt pptx odp key" },
  { "Images", "image-x-generic", "png jpg jpeg gif webp svg bmp heic avif jxl tiff" },
  { "Movies", "video-x-generic", "mp4 mkv webm mov avi" },
  { "Music", "audio-x-generic", "mp3 flac ogg opus wav m4a" },
  { "Archives", "package-x-generic", "zip tar gz xz zst bz2 7z rar deb rpm" },
  { "Developer", "text-x-script", "sh py lua luau js ts c h cpp rs go nix json toml yaml yml html htm css" },
  { "Fonts", "font-x-generic", "ttf otf woff2" },
  { "Disk Images", "application-x-firmware", "iso img" },
  { "Applications", "application-x-executable", "appimage" },
}) do
  for ext in spec[3]:gmatch("%S+") do
    EXT_KIND[ext], EXT_ICON[ext] = spec[1], spec[2]
  end
end
EXT_ICON.html, EXT_ICON.htm = "text-html", "text-html"
EXT_ICON.txt, EXT_ICON.md = "text-x-generic", "text-x-generic"
local IMAGE_EXT = { png = true, jpg = true, jpeg = true, gif = true, webp = true, svg = true, bmp = true }
local THUMB_SIZES = { "large", "x-large", "normal", "xx-large" }

local hashes = {} -- path -> MD5 of its URI (the thumbnail's name)

local function cachedThumbnail(path, mtime)
  local hash = hashes[path]
  if not hash then
    hash = md5(fileUri(path))
    hashes[path] = hash
  end
  for _, size in ipairs(THUMB_SIZES) do
    local thumb = CACHE_HOME .. "/thumbnails/" .. size .. "/" .. hash .. ".png"
    local info = noctalia.fileInfo(thumb)
    if info and info.mtime >= mtime then
      return thumb
    end
  end
  return nil
end

local function parseDesktopFile(path)
  local raw = noctalia.readFile(path)
  if not raw then
    return nil
  end
  local lang = noctalia.getSetting("shell.lang")
  local localized = lang and ("Name[" .. lang .. "]") or nil
  local out, inEntry = {}, false
  for line in raw:gmatch("[^\r\n]+") do
    local section = line:match("^%s*%[(.-)%]%s*$")
    if section then
      if inEntry then
        break
      end
      inEntry = section == "Desktop Entry"
    elseif inEntry then
      local k, v = line:match("^%s*([^=]-)%s*=%s*(.-)%s*$")
      if k == "Name" then
        out.name = out.name or v
      elseif localized and k == localized then
        out.name = v
      elseif k == "Icon" then
        out.icon = v
      end
    end
  end
  return out
end

local function findDesktopEntry(id)
  for _, dir in ipairs(dataDirs()) do
    local path = dir .. "/applications/" .. id .. ".desktop"
    if noctalia.fileInfo(path) then
      return path
    end
  end
  return nil
end

local function humanSize(n)
  local units = { "B", "KB", "MB", "GB", "TB" }
  local i = 1
  while n >= 1000 and i < #units do
    n /= 1000
    i += 1
  end
  return (i == 1 and string.format("%d %s", n, units[i])) or string.format(n < 10 and "%.1f %s" or "%.0f %s", n, units[i])
end


return {
  desktopDir = desktopDir,
  fileUri = fileUri,
  syncMatugenIcons = syncMatugenIcons,
  iconPath = iconPath,
  KIND_RANK = KIND_RANK,
  EXT_KIND = EXT_KIND,
  EXT_ICON = EXT_ICON,
  IMAGE_EXT = IMAGE_EXT,
  cachedThumbnail = cachedThumbnail,
  parseDesktopFile = parseDesktopFile,
  findDesktopEntry = findDesktopEntry,
  humanSize = humanSize,
}
end
