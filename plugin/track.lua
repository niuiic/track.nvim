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
