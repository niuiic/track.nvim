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
	vim.api.nvim_buf_set_var(instance._bufnr, "disable_track", true)
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
	vim.api.nvim_buf_set_var(instance._bufnr, "disable_track", true)
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
function Window:write_file(file_path, focus_lnum, hl_group)
	if not vim.uv.fs_stat(file_path) then
		return
	end

	local cur_winnr = vim.api.nvim_get_current_win()
	local cur_cursor_pos = vim.api.nvim_win_get_cursor(cur_winnr)

	vim.api.nvim_set_current_win(self._winnr)

	local lines = vim.fn.readfile(file_path)
	vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("filetype", vim.filetype.match({ filename = file_path }), {
		buf = self._bufnr,
	})

	if focus_lnum then
		vim.api.nvim_win_set_cursor(self._winnr, { focus_lnum, 0 })
		vim.cmd("normal zz")
	end

	if focus_lnum and hl_group then
		vim.api.nvim_buf_add_highlight(self._bufnr, self._ns_id, hl_group, focus_lnum - 1, 0, -1)
	end

	vim.api.nvim_set_current_win(cur_winnr)
	vim.api.nvim_win_set_cursor(cur_winnr, cur_cursor_pos)
end

-- % set_keymap %
-- TODO: set_keymap
function Window:set_keymap(keymap)
	for key, callback in pairs(keymap) do
		vim.keymap.set("n", key, callback, {
			buffer = self._bufnr,
		})
	end
end

-- % set_autocmd %
function Window:set_autocmd(events, fn)
	vim.api.nvim_create_autocmd(events, {
		buffer = self._bufnr,
		callback = function()
			fn()
		end,
	})
end

-- % get_cursor_lnum %
function Window:get_cursor_lnum()
	return vim.api.nvim_win_get_cursor(self._winnr)[1]
end

-- % set_cursor_lnum %
function Window:set_cursor_lnum(lnum)
	vim.api.nvim_win_set_cursor(self._winnr, { lnum, 0 })
end

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
function Window:clean(after_lnum)
	vim.api.nvim_buf_set_lines(self._bufnr, after_lnum or 0, -1, false, {})
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

-- % get_winnr %
function Window:get_winnr()
	return self._winnr
end

-- % enable_edit %
function Window:enable_edit()
	vim.api.nvim_set_option_value("modifiable", true, {
		buf = self._bufnr,
	})
end

-- % disable_edit %
function Window:disable_edit()
	vim.api.nvim_set_option_value("modifiable", false, {
		buf = self._bufnr,
	})
end

return Window
