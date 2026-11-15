--!nonstrict
-- Keeps the desktop icons' layer on screen. The layer is shown on the focused
-- output; at shell startup there can be none yet, and after a monitor is plugged
-- or unplugged it should move to the focused one (desk.luau fits itself to its
-- output). Showing again re-picks the output.
--
-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

noctalia.layer.show("desk")

local tries = 0
function update()
  tries += 1
  noctalia.layer.show("desk") -- idempotent
  noctalia.setUpdateInterval(tries >= 5 and 600000 or 2000)
end

function onOutputsChanged()
  noctalia.layer.hide("desk")
  noctalia.layer.show("desk")
end

