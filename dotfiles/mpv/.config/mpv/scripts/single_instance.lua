-- Special thanks to https://github.com/mpv-player/mpv/issues/43#issuecomment-2496083283
local mp = require("mp")
local utils = require("mp.utils")

function close_other_instances()
	local current_pid = utils.getpid()

	local process_list = utils.subprocess({
		args = { "pgrep", "-x", "mpv" },
		cancellable = false,
	})

	if process_list.status == 0 then
		for pid in process_list.stdout:gmatch("%d+") do
			pid = tonumber(pid)
			if pid and pid ~= current_pid then
				utils.subprocess({
					args = { "kill", tostring(pid) },
					cancellable = false,
				})
			end
		end
	end
end

mp.register_event("start-file", close_other_instances)
