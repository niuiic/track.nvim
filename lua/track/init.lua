local config = require("track.config")

local M = {
	_config = config,
	_marks = require("track.marks"):new(config:get().mark),
}

-- % setup %
-- TODO: setup
function M:setup(new_config)
	config:set(new_config or {})
	M._marks:set_config(config:get().mark)
end

-- % open_outline %
-- TODO: open_outline
function M.open_outline(show_all) end

-- % close_outline %
-- TODO: close_outline
function M.close_outline() end

-- % add_flow %
-- TODO: add_flow
function M.add_flow()
	vim.ui.input({ prompt = "input flow name" }, function(input)
		if input then
			M._marks:add_flow(input)
		end
	end)
end

-- % delete_flow %
-- TODO: delete_flow
function M.delete_flow()
	M._select_flow(function(flow)
		M._marks:delete_flow(flow)
	end)
end

-- % update_flow %
-- TODO: update_flow
function M.update_flow()
	M._select_flow(function(flow)
		vim.ui.input({ prompt = "input flow name" }, function(input)
			if input then
				M._marks:update_flow(flow, input)
			end
		end)
	end)
end

-- % add_mark %
-- TODO: add_mark
function M.add_mark()
	M._select_flow(function(flow)
		local file_path = vim.api.nvim_buf_get_name(0)
		local lnum = vim.api.nvim_win_get_cursor(0)[1]

		vim.ui.input({ prompt = "input mark text" }, function(input)
			if input then
				M._marks:add_mark(file_path, lnum, input, flow)
			end
		end)
	end)
end

-- % delete_mark %
-- TODO: delete_mark
function M.delete_mark()
	local file_path = vim.api.nvim_buf_get_name(0)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local marks = M._marks:get_marks_by_pos(file_path, lnum)

	if #marks == 0 then
		require("track.notify").notify_err("no mark exists at this line")
		return
	end

	if #marks == 1 then
		M._marks:delete_mark(marks[1]:get_id())
		return
	end

	M._select_mark(marks, function(mark)
		M._marks:delete_mark(mark:get_id())
	end)
end

-- % delete_marks %
function M.delete_marks(delete_all)
	if delete_all then
		for _, flow in ipairs(M._marks:get_flows()) do
			M._marks:delete_flow(flow)
		end
	else
		M._select_flow(function(flow)
			M._marks:delete_flow(flow)
		end)
	end
end

-- % update_mark %
-- TODO: update_mark
function M.update_mark(set_default)
	local file_path = vim.api.nvim_buf_get_name(0)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local marks = M._marks:get_marks_by_pos(file_path, lnum)

	if #marks == 0 then
		require("track.notify").notify_err("no mark exists at this line")
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
		end
	end)
end

-- % store_marks %
-- TODO: store_marks
function M.store_marks(file_path)
	M._marks:store_marks(file_path)
end

-- % restore_marks %
-- TODO: restore_marks
function M.restore_marks(file_path)
	M._marks:restore_marks(file_path)
end

-- % notify_file_path_change %
-- TODO: notify_file_path_change
function M.notify_file_path_change(old, new)
	M._marks:update_mark_file_path(old, new)
end

-- % notify_file_change %
-- TODO: notify_file_change
function M.notify_file_change(file_path)
	M._marks:update_mark_lnum(file_path)
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

return M
