vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function(args)
		local file_path = vim.api.nvim_buf_get_name(args.buf)
		require("track").notify_file_change(file_path)
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		local file_path = vim.api.nvim_buf_get_name(args.buf)
		require("track").decorate_marks_on_file(file_path)
	end,
})
