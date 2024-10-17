local Outline = {}

-- % new %
-- TODO: new
function Outline:new(config, marks)
	local instance = {
		_config = config,
		_marks = marks,
		_line_marks = {},
	}

	setmetatable(instance, { __index = Outline })

	return instance
end

-- % set_config %
-- TODO: set_config
function Outline:set_config(config)
	self._config = config
	if self:_is_open() then
		self:close()
		self:open(self._flow)
	end
end

-- % open %
-- TODO: open
function Outline:open(flow)
	if self:_is_open() then
		if self._flow == flow then
			return
		end

		self._flow = flow
		self._outline_window:clean()
		self:draw_marks()
		return
	end

	self._flow = flow
	self._prev_winnr = vim.api.nvim_get_current_win()
	self._outline_window = require("track.window"):new_split(self._config.win_pos, self._config.win_size, false)
	self._outline_window:set_keymap({
		[self._config.keymap_move_mark_up] = function()
			self:_move_mark_up()
		end,
		[self._config.keymap_move_mark_down] = function()
			self:_move_mark_down()
		end,
		[self._config.keymap_navigate_to_mark] = function()
			self:_navigate_to_mark()
		end,
		[self._config.keymap_delete_mark] = function()
			self:_delete_mark()
		end,
		[self._config.keymap_update_mark] = function()
			self:_update_mark(self._config.set_default_when_update_mark)
		end,
		[self._config.keymap_preview_mark] = function()
			self:_preview_mark()
		end,
	})
	self:draw_marks()
end

-- % close %
-- TODO: close
function Outline:close()
	if not self:_is_open() then
		return
	end

	self._outline_window:close()
	if self._preview_window then
		self._preview_window:close()
	end
end

-- % is_open %
function Outline:_is_open()
	return self._outline_window and self._outline_window:is_valid()
end

-- % draw_marks %
-- TODO: draw_marks
function Outline:draw_marks()
	if not self:_is_open() then
		return
	end

	self._line_marks = {}

	local start_lnum = 1
	if self._flow then
		self:_draw_flow_marks(self._flow, start_lnum)
	else
		vim.iter(self._marks:get_flows()):each(function(flow)
			self:_draw_flow_marks(flow, start_lnum)
			start_lnum = start_lnum + #self._marks:get_marks(flow) + 2
		end)
	end

	self._outline_window:clean(start_lnum - 2)
end

function Outline:_draw_flow_marks(flow, start_lnum)
	local marks = self._marks:get_marks(flow)
	if not marks then
		return
	end

	self._outline_window:write_line(start_lnum, flow, self._config.flow_hl_group)
	for index, mark in ipairs(marks) do
		self._outline_window:write_line(
			start_lnum + index,
			self._config.get_mark_line_text(mark:get_file_path(), mark:get_lnum(), mark:get_text()),
			self._config.mark_hl_group
		)
		self._line_marks[start_lnum + index] = mark
	end
	self._outline_window:write_line(start_lnum + #marks + 1, "")
end

-- % move_mark_up %
function Outline:_move_mark_up()
	local mark = self:_get_cursor_mark()
	if not mark then
		return
	end

	local moved = self._marks:change_mark_order(mark:get_id(), "backward")
	if moved then
		self:draw_marks()
		self._outline_window:set_cursor_lnum(self._outline_window:get_cursor_lnum() - 1)
	end
end

-- % move_mark_down %
function Outline:_move_mark_down()
	local mark = self:_get_cursor_mark()
	if not mark then
		return
	end

	local moved = self._marks:change_mark_order(mark:get_id(), "forward")
	if moved then
		self:draw_marks()
		self._outline_window:set_cursor_lnum(self._outline_window:get_cursor_lnum() + 1)
	end
end

-- % navigate_to_mark %
-- TODO: navigate_to_mark
function Outline:_navigate_to_mark()
	local mark = self:_get_cursor_mark()
	if not mark then
		return
	end

	local bufnr = vim.iter(vim.api.nvim_list_bufs()):find(function(bufnr)
		return vim.api.nvim_buf_get_name(bufnr) == mark:get_file_path()
	end)
	-- FIXME: previous win could be destroyed
	vim.api.nvim_set_current_win(self._prev_winnr)
	if not bufnr then
		vim.cmd("file " .. mark:get_file_path())
	else
		vim.api.nvim_set_current_buf(bufnr)
	end

	vim.api.nvim_win_set_cursor(0, { mark:get_lnum(), 0 })
end

-- % delete_mark %
-- TODO: delete_mark
function Outline:_delete_mark()
	local mark = self:_get_cursor_mark()
	if not mark then
		return
	end

	self._marks:delete_mark(mark:get_id())
	self:draw_marks()
end

-- % update_mark %
-- TODO: update_mark
function Outline:_update_mark(set_default)
	local mark = self:_get_cursor_mark()
	if not mark then
		return
	end

	vim.ui.input({
		prompt = "input mark text",
		default = set_default and mark:get_text() or nil,
	}, function(input)
		if not input then
			return
		end

		self._marks:update_mark_text(mark:get_id(), input)
		self:draw_marks()
	end)
end

-- % preview_mark %
-- TODO: preview_mark
function Outline:_preview_mark() end

-- % get_cursor_mark %
-- TODO: _get_cursor_mark
function Outline:_get_cursor_mark()
	local lnum = self._outline_window:get_cursor_lnum()
	return self._line_marks[lnum]
end

return Outline
