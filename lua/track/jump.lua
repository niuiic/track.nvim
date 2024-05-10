local core = require("core")
local mark = require("track.mark")

local jump_to_next = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local cur_line = vim.api.nvim_win_get_cursor(0)[1]
	local target_line

	core.lua.list.each(mark.get_buf_marks(bufnr), function(x)
		if not target_line and x.lnum > cur_line then
			target_line = x.lnum
		end
	end)

	if not target_line then
		vim.notify("No next mark in this buffer", vim.log.levels.WARN, {
			title = "Track",
		})
		return
	end

	vim.api.nvim_win_set_cursor(0, {
		target_line,
		0,
	})
end

local jump_to_prev = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local cur_line = vim.api.nvim_win_get_cursor(0)[1]
	local target_line

	core.lua.list.each(mark.get_buf_marks(bufnr), function(x)
		if x.lnum < cur_line then
			target_line = x.lnum
		end
	end)

	if not target_line then
		vim.notify("No prev mark in this buffer", vim.log.levels.WARN, {
			title = "Track",
		})
		return
	end

	vim.api.nvim_win_set_cursor(0, {
		target_line,
		0,
	})
end

return {
	jump_to_next = jump_to_next,
	jump_to_prev = jump_to_prev,
}
