local Marks = {}

-- % new %
function Marks:new(config)
	local instance = {
		_config = {},
		_marks = {},
		_ns_id = vim.api.nvim_create_namespace("track_marks"),
		_sign_group = "TrackSigns",
		_sign_name = "TrackSign",
		_id_count = 0,
	}

	setmetatable(instance, { __index = Marks })

	instance:set_config(config)

	return instance
end

-- % set_config %
-- TODO: set_config
function Marks:set_config(config)
	if config.mark_hl_group ~= self._config.mark_hl_group or config.mark_icon ~= self._config.mark_icon then
		pcall(vim.fn.sign_undefine, self._sign_name)
		vim.fn.sign_define(self._sign_name, {
			text = config.mark_icon,
			texthl = config.mark_hl_group,
		})

		for _, marks in pairs(self._marks) do
			for _, mark in ipairs(marks) do
				self:_undecorate_mark(mark)
				self:_decorate_mark(mark)
			end
		end
	end

	self._config = config
end

-- % add_flow %
function Marks:add_flow(name)
	if self._marks[name] then
		require("track.notify").notify_err("flow already exists")
		return
	end

	self._marks[name] = {}
end

-- % delete_flow %
function Marks:delete_flow(name)
	self:delete_marks(name)
	self._marks[name] = nil
end

-- % update_flow %
function Marks:update_flow(old, new)
	if not self._marks[old] then
		require("track.notify").notify_err(string.format("flow %s doesn't exist", old))
		return
	end

	if self._marks[new] then
		require("track.notify").notify_err(string.format("flow %s exists", new))
		return
	end

	self._marks[new], self._marks[old] = self._marks[old], nil
end

-- % get_flows %
function Marks:get_flows()
	return vim.tbl_keys(self._marks)
end

-- % has_flow %
function Marks:has_flow(name)
	return self._marks[name] ~= nil
end

-- % add_mark %
function Marks:add_mark(file_path, lnum, text, flow)
	if not self._marks[flow] then
		require("track.notify").notify_err("flow doesn't exist")
		return
	end

	if
		vim.iter(self._marks[flow]):any(function(mark)
			return mark.file_path == file_path and mark.lnum == lnum
		end)
	then
		require("track.notify").notify_err("mark already exists")
		return
	end

	self._id_count = self._id_count + 1
	local mark = require("track.mark"):new(self._id_count, file_path, lnum, text)
	table.insert(self._marks[flow], mark)

	self:_decorate_mark(mark)
end

-- % delete_mark %
function Marks:delete_mark(id)
	for _, marks in pairs(self._marks) do
		for index, mark in ipairs(marks) do
			if mark.id == id then
				self:_undecorate_mark(mark)
				table.remove(marks, index)
				return
			end
		end
	end
end

-- % update_mark_text %
function Marks:update_mark_text(id, text)
	local mark = self:_find_mark(id)
	if not mark then
		require("track.notify").notify_err("mark doesn't exist")
		return
	end

	self:_undecorate_mark(mark)
	mark:set_text(text)
	self:_decorate_mark(mark)
end

-- % delete_marks %
function Marks:delete_marks(flow)
	local marks = self._marks
	if flow then
		marks = marks[flow]
	end

	if marks then
		return
	end

	vim.iter(marks):each(function(mark)
		self:delete_mark(mark.id)
	end)
end

-- % get_marks %
function Marks:get_marks(flow)
	if flow then
		return self._marks[flow] or {}
	end

	return self._marks
end

-- % get_marks_by_pos %
-- TODO: get_marks_by_pos
function Marks:get_marks_by_pos(file_path, lnum) end

-- % store_marks %
-- TODO:store_marks
function Marks:store_marks(file_path) end

-- % restore_marks %
-- TODO:restore_marks
function Marks:restore_marks(file_path) end

-- % change_mark_order %
function Marks:change_mark_order(id, direction)
	for _, marks in pairs(self._marks) do
		for index, mark in ipairs(marks) do
			if mark.id == id then
				return self:_move_mark(marks, index, direction)
			end
		end
	end
end

function Marks:_move_mark(marks, index, direction)
	if direction == "forward" then
		if index == 1 then
			return false
		end

		marks[index - 1], marks[index] = marks[index], marks[index - 1]
		return true
	end

	if direction == "backward" then
		if index == #marks then
			return false
		end

		marks[index + 1], marks[index] = marks[index], marks[index + 1]
		return true
	end

	error("invalid direction")
end

-- % update_mark_file_path %
function Marks:update_file_path(old, new) end

-- % update_mark_lnum %

-- % decorate_mark %
-- TODO:decorate_mark
function Marks:_decorate_mark(mark)
	local bufnr = self:_get_file_bufnr(mark:get_file_path())
	if not bufnr then
		return
	end

	vim.fn.sign_place(mark:get_id(), self._sign_group, self._sign_name, bufnr, {
		lnum = mark:get_lnum(),
		priority = self._config.sign_priority,
	})

	vim.api.nvim_buf_set_extmark(bufnr, self._ns_id, mark:get_lnum() - 1, 0, {
		id = mark:get_id(),
		virt_text = { {
			string.rep(" ", 8) .. mark:get_text(),
			self._config.mark_hl_group,
		} },
		virt_text_pos = "eol",
	})
end

function Marks:_get_file_bufnr(file_path)
	return vim.iter(vim.api.nvim_list_bufs()):find(function(bufnr)
		return vim.api.nvim_buf_get_name(bufnr) == file_path
	end)
end

-- % undecorate_mark %
-- TODO:undecorate_mark
function Marks:_undecorate_mark(mark) end

-- % get_mark %
function Marks:_get_mark(id)
	for _, marks in pairs(self._marks) do
		for _, mark in ipairs(marks) do
			if mark.id == id then
				return mark
			end
		end
	end
end

return Marks
