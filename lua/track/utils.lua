local core = require("core")

local get_buf_list = function()
	return core.lua.list.filter(vim.api.nvim_list_bufs(), function(bufnr)
		return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
	end)
end

return {
	get_buf_list = get_buf_list,
}
