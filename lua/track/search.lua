local mark = require("track.mark")
local core = require("core")
local utils = require("track.utils")
local static = require("track.static")

local search = function(opts)
	---@type track.Mark[]
	local marks = {}
	local bufs = {}
	core.lua.list.each(utils.get_buf_list(), function(bufnr)
		local file = vim.api.nvim_buf_get_name(bufnr)
		if not file then
			return
		end
		bufs[file] = bufnr
	end)
	core.lua.table.each(mark.get_mark_list(), function(file, mark_list)
		if bufs[file] then
			core.lua.list.each(mark.get_buf_marks(bufs[file]), function(x)
				table.insert(marks, {
					id = x.id,
					file = file,
					lnum = x.lnum,
					desc = mark_list[x.id].desc,
				})
			end)
			return
		end

		core.lua.table.each(mark_list, function(_, x)
			table.insert(marks, x)
		end)
	end)
	if #marks == 0 then
		vim.notify("No mark setted", vim.log.levels.WARN, {
			title = "Track",
		})
		return
	end
	marks = static.config.search.sort_entry(marks)

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local previewers = require("telescope.previewers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local winnr = vim.api.nvim_get_current_win()
	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = "track.nvim: marks",
			finder = finders.new_table(core.lua.list.map(marks, function(x)
				return static.config.search.entry_label(x)
			end)),
			sorter = conf.generic_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry)
					local target_mark = core.lua.list.find(marks, function(x)
						return static.config.search.entry_label(x) == entry[1]
					end)
					if not target_mark then
						return
					end

					local offset = math.floor(vim.api.nvim_win_get_height(self.state.winid) / 2)
					local start_line
					if target_mark.lnum - offset >= 0 then
						start_line = target_mark.lnum - offset
					else
						start_line = 0
					end
					local end_line = target_mark.lnum + offset

					local lines = core.lua.list.filter(vim.fn.readfile(target_mark.file), function(_, i)
						return i >= start_line and i <= end_line
					end)
					local filetype = vim.filetype.match({ filename = target_mark.file })
					vim.api.nvim_set_option_value("filetype", filetype, {
						buf = self.state.bufnr,
					})
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_add_highlight(
						self.state.bufnr,
						0,
						"TelescopeSelection",
						target_mark.lnum - start_line - 1,
						0,
						-1
					)
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local target_mark = core.lua.list.find(marks, function(x)
						return static.config.search.entry_label(x) == selection[1]
					end)
					if not target_mark then
						return
					end

					vim.api.nvim_set_current_win(winnr)
					if bufs[target_mark.file] then
						vim.api.nvim_win_set_buf(winnr, bufs[target_mark.file])
					else
						vim.cmd("e " .. target_mark.file)
					end
					vim.api.nvim_win_set_cursor(winnr, {
						target_mark.lnum,
						0,
					})
				end)
				return true
			end,
		})
		:find()
end

return {
	search = search,
}
