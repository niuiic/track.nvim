local Window = {}

-- % new_split %
function Window:new_split(pos, size, enter)
	local instance = {
		_pos = pos,
		_ns_id = vim.api.nvim_create_namespace("track window"),
	}
	setmetatable(instance, { __index = Window })

	local cur_winnr = vim.api.nvim_get_current_win()
	instance._bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("filetype", "track", { buf = instance._bufnr })
	if pos == "left" then
		vim.cmd("topleft " .. size .. "vs")
	elseif pos == "right" then
		vim.cmd(size .. "vs")
	elseif pos == "top" then
		vim.cmd("top " .. size .. "sp")
	elseif pos == "bottom" then
		vim.cmd(size .. "sp")
	else
		error("pos is not supported")
	end
	instance._winnr = vim.api.nvim_get_current_win()
	instance:_set_window_options()
	vim.api.nvim_win_set_buf(instance._winnr, instance._bufnr)

	if not enter then
		vim.api.nvim_set_current_win(cur_winnr)
	end

	return instance
end

-- % new_float %
function Window:new_float(relative_winnr, row, col, width, height, enter)
	local instance = {
		_pos = "float",
		_ns_id = vim.api.nvim_create_namespace("track window"),
	}
	setmetatable(instance, { __index = Window })

	instance._bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("filetype", "track", { buf = instance._bufnr })
	local cur_zindex = vim.api.nvim_win_get_config(0).zindex or 0
	instance._winnr = vim.api.nvim_open_win(instance._bufnr, false, {
		relative = "win",
		win = relative_winnr,
		width = width,
		height = height,
		row = row,
		col = col,
		zindex = cur_zindex + 1,
		style = "minimal",
		border = "rounded",
	})
	instance:_set_window_options()

	if enter then
		vim.api.nvim_set_current_win(instance._winnr)
	end

	return instance
end

-- % is_valid %
function Window:is_valid()
	return vim.api.nvim_buf_is_valid(self._bufnr) and vim.api.nvim_win_is_valid(self._winnr)
end

-- % write_line %
-- TODO: write_line
function Window:write_line(lnum, text, hl_group)
	vim.api.nvim_buf_set_lines(self._bufnr, lnum - 1, lnum, false, { text })
	if hl_group then
		vim.api.nvim_buf_add_highlight(self._bufnr, self._ns_id, hl_group, lnum - 1, 0, -1)
	end
end

-- % write_file %
-- TODO: write_file
function Window:write_file(file_path) end

-- % set_keymap %
-- TODO: set_keymap
function Window:set_keymap(keymap) end

-- % get_cursor_lnum %
-- TODO: get_cursor_lnum
function Window:get_cursor_lnum() end

-- % get_pos %
function Window:get_pos()
	return self._pos
end

-- % close %
function Window:close()
	pcall(function()
		vim.api.nvim_buf_delete(self._bufnr, { force = true })
		vim.api.nvim_win_close(self._winnr, true)
	end)
end

-- % clean %
function Window:clean()
	vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, {})
end

-- % set_window_options %
function Window:_set_window_options()
	vim.api.nvim_set_option_value("number", false, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("relativenumber", false, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("winfixwidth", true, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("list", false, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("wrap", true, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("linebreak", true, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("breakindent", true, {
		win = self._winnr,
	})
	vim.api.nvim_set_option_value("showbreak", "      ", {
		win = self._winnr,
	})
end

return Window
