local Marks = {}

-- % new %
function Marks:new(config)
	local instance = {
		_config = {},
		_marks = {},
		_flows = {},
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
				self:decorate_mark(mark)
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
	table.insert(self._flows, name)
end

-- % delete_flow %
function Marks:delete_flow(name)
	if not self._marks[name] then
		return
	end

	vim.iter(self._marks[name]):each(function(mark)
		self:delete_mark(mark:get_id())
	end)
	self._marks[name] = nil
	self:_delete_flow_from_flows(name)
end

function Marks:_delete_flow_from_flows(name)
	self._flows = vim.iter(self._flows)
		:filter(function(flow)
			return flow ~= name
		end)
		:totable()
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
	for index, flow in ipairs(self._flows) do
		if flow == old then
			self._flows[index] = new
			return
		end
	end
end

-- % get_flows %
function Marks:get_flows()
	return self._flows
end

-- % has_flow %
function Marks:has_flow(name)
	return self._marks[name] ~= nil
end

-- % change_flow_order %
function Marks:change_flow_order(name, direction)
	for index, flow in ipairs(self._flows) do
		if flow == name then
			if direction == "backward" then
				if index == 1 then
					return false
				end

				self._flows[index - 1], self._flows[index] = self._flows[index], self._flows[index - 1]
				return true
			end

			if direction == "forward" then
				if index == #self._flows then
					return false
				end

				self._flows[index + 1], self._flows[index] = self._flows[index], self._flows[index + 1]
				return true
			end

			error("invalid direction")
		end
	end
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

	self:decorate_mark(mark)
end

-- % _add_mark %
function Marks:_add_mark(flow, mark)
	if not self._marks[flow] then
		self._marks[flow] = {}
	end

	table.insert(self._marks[flow], mark)
	self:decorate_mark(mark)
end

-- % delete_mark %
function Marks:delete_mark(id)
	for _, marks in pairs(self._marks) do
		for index, mark in ipairs(marks) do
			if mark:get_id() == id then
				self:_undecorate_mark(mark)
				table.remove(marks, index)
				return
			end
		end
	end
end

-- % update_mark_text %
function Marks:update_mark_text(id, text)
	local mark = self:_get_mark(id)
	if not mark then
		require("track.notify").notify_err("mark doesn't exist")
		return
	end

	self:_undecorate_mark(mark)
	mark:set_text(text)
	self:decorate_mark(mark)
end

-- % get_marks %
function Marks:get_marks(flow)
	if flow then
		return self._marks[flow] or {}
	end

	return self._marks
end

-- % get_marks_by_pos %
function Marks:get_marks_by_pos(file_path, lnum)
	local target_marks = {}

	for _, marks in pairs(self._marks) do
		for _, mark in ipairs(marks) do
			if mark:get_file_path() == file_path then
				if not lnum or mark:get_lnum() == lnum then
					table.insert(target_marks, mark)
				end
			end
		end
	end

	return target_marks
end

-- % store_marks %
function Marks:store_marks(file_path)
	local marks = {}
	local root_dir = self._config.get_root_dir()
	for flow, mark_list in pairs(self._marks) do
		marks[flow] = vim.iter(mark_list)
			:map(function(mark)
				return mark:to_string(root_dir)
			end)
			:totable()
	end
	local text = vim.json.encode({
		id_count = self._id_count,
		marks = marks,
		flows = self._flows,
	})

	local ok = pcall(vim.fn.writefile, { text }, file_path)
	if not ok then
		require("track.notify").notify_err("failed to write marks to file")
	end
end

-- % restore_marks %
function Marks:restore_marks(file_path)
	if not vim.uv.fs_stat(file_path) or vim.fn.isdirectory(file_path) == 1 then
		require("track.notify").notify_err("file doesn't exist")
		return
	end

	vim.iter(self:get_flows()):each(function(flow)
		self:delete_flow(flow)
	end)
	local data = vim.json.decode(vim.fn.readfile(file_path)[1])
	self._id_count = data.id_count
	self._flows = data.flows or {}
	local root_dir = self._config.get_root_dir()
	for flow, marks in pairs(data.marks or {}) do
		self._marks[flow] = {}
		for _, str in ipairs(marks) do
			self:_add_mark(flow, require("track.mark"):from_string(str, root_dir))
		end
	end
end

-- % change_mark_order %
function Marks:change_mark_order(id, direction)
	for _, marks in pairs(self._marks) do
		for index, mark in ipairs(marks) do
			if mark:get_id() == id then
				return self:_move_mark(marks, index, direction)
			end
		end
	end
end

function Marks:_move_mark(marks, index, direction)
	if direction == "backward" then
		if index == 1 then
			return false
		end

		marks[index - 1], marks[index] = marks[index], marks[index - 1]
		return true
	end

	if direction == "forward" then
		if index == #marks then
			return false
		end

		marks[index + 1], marks[index] = marks[index], marks[index + 1]
		return true
	end

	error("invalid direction")
end

-- % update_mark_file_path %
function Marks:update_mark_file_path(old, new)
	for _, marks in pairs(self._marks) do
		for _, mark in ipairs(marks) do
			if mark:get_file_path() == old then
				mark:set_file_path(new)
			end
		end
	end
end

-- % update_mark_file_path_dir %
function Marks:update_mark_file_path_dir(old, new)
	for _, marks in pairs(self._marks) do
		for _, mark in ipairs(marks) do
			if string.match(mark:get_file_path(), old .. "/.*") then
				mark:set_file_path(string.gsub(mark:get_file_path(), old, new))
			end
		end
	end
end

-- % update_mark_lnum %
function Marks:update_mark_lnum(file_path)
	local signs = self:_get_signs(file_path)
	if not signs then
		return
	end

	for _, marks in pairs(self._marks) do
		for _, mark in ipairs(marks) do
			if signs[mark:get_id()] then
				mark:set_lnum(signs[mark:get_id()])
			end
		end
	end
end

function Marks:_get_signs(file_path)
	local signs = (vim.fn.sign_getplaced(file_path, {
		group = self._sign_group,
	})[1] or {}).signs
	if not signs then
		return
	end

	local results = {}
	for _, sign in ipairs(signs) do
		if sign.name == self._sign_name then
			results[sign.id] = sign.lnum
		end
	end

	return results
end

-- % decorate_mark %
function Marks:decorate_mark(mark)
	local bufnr = self:_get_file_bufnr(mark:get_file_path())
	if not bufnr then
		return
	end

	pcall(function()
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
	end)
end

-- % undecorate_mark %
function Marks:_undecorate_mark(mark)
	local bufnr = self:_get_file_bufnr(mark:get_file_path())
	if not bufnr then
		return
	end

	vim.fn.sign_unplace(self._sign_group, { id = mark:get_id() })
	vim.api.nvim_buf_del_extmark(bufnr, self._ns_id, mark:get_id())
end

-- % get_mark %
function Marks:_get_mark(id)
	for _, marks in pairs(self._marks) do
		for _, mark in ipairs(marks) do
			if mark:get_id() == id then
				return mark
			end
		end
	end
end

-- % get_file_bufnr %
function Marks:_get_file_bufnr(file_path)
	return vim.iter(vim.api.nvim_list_bufs()):find(function(bufnr)
		return vim.api.nvim_buf_get_name(bufnr) == file_path
	end)
end

-- % delete_marks_by_file_path %
function Marks:delete_marks_by_file_path(file_path)
	for _, marks in pairs(self._marks) do
		vim.iter(marks):each(function(mark)
			if mark:get_file_path() == file_path then
				self:delete_mark(mark:get_id())
			end
		end)
	end
end

-- % delete_marks_by_file_path_dir %
function Marks:delete_marks_by_file_path_dir(dir_path)
	for _, marks in pairs(self._marks) do
		vim.iter(marks):each(function(mark)
			if string.match(mark:get_file_path(), dir_path .. "/.*") then
				self:delete_mark(mark:get_id())
			end
		end)
	end
end

return Marks
