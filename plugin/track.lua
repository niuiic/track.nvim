vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function(args)
		if require("track").is_enabled(args.buf, vim.api.nvim_get_current_win()) then
			local file_path = vim.api.nvim_buf_get_name(args.buf)
			require("track").notify_file_change(file_path)
		end
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		if require("track").is_enabled(args.buf, vim.api.nvim_get_current_win()) then
			local file_path = vim.api.nvim_buf_get_name(args.buf)
			require("track").decorate_marks_on_file(file_path)
		end
	end,
})

local prev_lnum
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	callback = function(args)
		if not require("track").is_outline_open() then
			return
		end

		local winnr = vim.api.nvim_get_current_win()
		if not require("track").is_enabled(args.buf, winnr) then
			return
		end

		local lnum = vim.api.nvim_win_get_cursor(winnr)[1]
		if lnum == prev_lnum then
			return
		end

		local file_path = vim.api.nvim_buf_get_name(args.buf)
		require("track").highlight_cursor_marks_on_outline(file_path, lnum)
		prev_lnum = lnum
	end,
})
