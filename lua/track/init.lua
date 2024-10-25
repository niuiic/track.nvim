local _config = require("track.config")
local _marks = require("track.marks"):new(_config:get().mark)

local M = {
	_config = _config,
	_marks = _marks,
	_outline = require("track.outline"):new(_config:get().outline, _marks),
}

-- % setup %
function M.setup(new_config)
	M._config:set(new_config or {})
	M._marks:set_config(M._config:get().mark)
	M._outline:set_config(M._config:get().outline)
end

-- % open_outline %
function M.open_outline(show_all)
	if show_all then
		M._outline:open()
	else
		M._select_flow(function(flow)
			M._outline:open(flow)
		end)
	end
end

-- % close_outline %
function M.close_outline()
	M._outline:close()
end

-- % add_flow %
function M.add_flow()
	vim.ui.input({ prompt = "input flow name" }, function(input)
		if input then
			M._marks:add_flow(input)
			M._outline:draw_marks()
		end
	end)
end

-- % delete_flow %
function M.delete_flow()
	M._select_flow(function(flow)
		M._marks:delete_flow(flow)
		M._outline:draw_marks()
	end)
end

-- % update_flow %
function M.update_flow()
	M._select_flow(function(flow)
		vim.ui.input({ prompt = "input flow name" }, function(input)
			if input then
				M._marks:update_flow(flow, input)
				M._outline:draw_marks()
			end
		end)
	end)
end

-- % add_mark %
function M.add_mark()
	M._select_flow(function(flow)
		local file_path = vim.api.nvim_buf_get_name(0)
		local lnum = vim.api.nvim_win_get_cursor(0)[1]

		if not file_path then
			require("track.notify").notify_err("file is invalid")
			return
		end

		vim.ui.input({ prompt = "input mark text" }, function(input)
			if input then
				M._marks:add_mark(file_path, lnum, input, flow)
				M._outline:draw_marks()
			end
		end)
	end)
end

-- % delete_mark %
function M.delete_mark()
	local file_path = vim.api.nvim_buf_get_name(0)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local marks = M._marks:get_marks_by_pos(file_path, lnum)

	if #marks == 0 then
		require("track.notify").notify_warn("no mark exists at this line")
		return
	end

	if #marks == 1 then
		M._marks:delete_mark(marks[1]:get_id())
		M._outline:draw_marks()
		return
	end

	M._select_mark(marks, function(mark)
		M._marks:delete_mark(mark:get_id())
		M._outline:draw_marks()
	end)
end

-- % delete_marks %
function M.delete_marks(delete_all)
	if delete_all then
		for _, flow in ipairs(M._marks:get_flows()) do
			M._marks:delete_flow(flow)
		end
		M._outline:draw_marks()
	else
		M._select_flow(function(flow)
			M._marks:delete_flow(flow)
			M._outline:draw_marks()
		end)
	end
end

-- % update_mark %
function M.update_mark(set_default)
	local file_path = vim.api.nvim_buf_get_name(0)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local marks = M._marks:get_marks_by_pos(file_path, lnum)

	if #marks == 0 then
		require("track.notify").notify_warn("no mark exists at this line")
		return
	end

	if #marks == 1 then
		M._update_mark_text(marks[1], set_default)
	else
		M._select_mark(marks, function(mark)
			M._update_mark_text(mark, set_default)
		end)
	end
end

function M._update_mark_text(mark, set_default)
	vim.ui.input({
		prompt = "input mark text",
		default = set_default and mark:get_text() or nil,
	}, function(input)
		if input then
			M._marks:update_mark_text(mark:get_id(), input)
			M._outline:draw_marks()
		end
	end)
end

-- % store_marks %
function M.store_marks(file_path)
	M._marks:store_marks(file_path)
end

-- % restore_marks %
function M.restore_marks(file_path)
	M._marks:restore_marks(file_path)
end

-- % notify_file_path_change %
function M.notify_file_path_change(old, new)
	if new then
		M._marks:update_mark_file_path(old, new)
	else
		M._marks:delete_marks_by_file_path(old)
	end
	M._outline:draw_marks()
end

-- % notify_dir_path_change %
function M.notify_dir_path_change(old, new)
	if new then
		M._marks:update_mark_file_path_dir(old, new)
	else
		M._marks:delete_marks_by_file_path_dir(old)
	end
	M._outline:draw_marks()
end

-- % notify_file_change %
function M.notify_file_change(file_path)
	M._marks:update_mark_lnum(file_path)
	M._outline:draw_marks()
end

-- % _select_flow %
function M._select_flow(fn)
	local flows = M._marks:get_flows()

	if #flows == 0 then
		require("track.notify").notify_err("no flow exists")
		return
	end

	vim.ui.select(flows, { prompt = "select flow" }, function(choice)
		if choice then
			fn(choice)
		end
	end)
end

-- % _select_mark %
function M._select_mark(marks, fn)
	vim.ui.select(
		vim.iter(marks):map(function(mark)
			return mark:get_text()
		end),
		{ prompt = "select mark" },
		function(choice)
			if not choice then
				return
			end

			local mark = vim.iter(marks):find(function(mark)
				return mark:get_text() == choice
			end)
			if mark then
				fn(mark)
			end
		end
	)
end

-- % decorate_marks_on_file %
function M.decorate_marks_on_file(file_path)
	vim.iter(M._marks:get_marks_by_pos(file_path)):each(function(mark)
		M._marks:decorate_mark(mark)
	end)
end

-- % is_enabled %
function M.is_enabled(bufnr, winnr)
	return not require("track.window"):is_track_win(bufnr) and M._config:get().is_enabled(bufnr, winnr)
end

-- % navigate_to_outline %
function M.navigate_to_outline()
	local file_path = vim.api.nvim_buf_get_name(0)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local marks = M._marks:get_marks_by_pos(file_path, lnum)

	if #marks == 0 then
		require("track.notify").notify_warn("no mark exists at this line")
		return
	end

	if #marks == 1 then
		M._outline:focus_on_outline_mark(marks[1])
		return
	end

	M._select_mark(marks, function(mark)
		M._outline:focus_on_outline_mark(mark)
	end)
end

-- % highlight_cursor_marks_on_outline %
function M.highlight_cursor_marks_on_outline(file_path, lnum)
	local marks = M._marks:get_marks_by_pos(file_path, lnum)
	M._outline:highlight_ontline_marks(marks)
end

return M
