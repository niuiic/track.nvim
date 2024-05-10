local config = {
	sign = {
		text = "󰍒",
		text_color = "#00ff00",
		priority = 10,
	},
	search = {
		---@param mark track.Mark
		entry_label = function(mark)
			return string.format("[%s] %s | %s:%s", mark.id, mark.desc, mark.file, mark.lnum)
		end,
		---@param marks track.Mark[]
		---@return track.Mark[]
		sort_entry = function(marks)
			return require("core").lua.list.sort(marks, function(prev, cur)
				return prev.id < cur.id
			end)
		end,
	},
}

return {
	config = config,
}
