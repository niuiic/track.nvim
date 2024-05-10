local static = require("track.static")
local core = require("core")

-- # global vars
local sign_group = "TrackSigns"
local sign_name = "TrackSign"
local hl = "TrackColor"
local id_count = 0
---@type {[string]: {[string]: track.Mark}}
-- {file: {id: track.Mark}}
local mark_list = {}

-- # define sign
local define_sign = function()
	pcall(vim.fn.sign_undefine, sign_name)
	vim.api.nvim_set_hl(0, hl, {
		fg = static.config.sign.text_color,
	})
	vim.fn.sign_define(sign_name, {
		text = static.config.sign.text,
		texthl = hl,
	})
end

-- # get mark
---@param bufnr number
local get_buf_marks = function(bufnr)
	---@diagnostic disable-next-line: param-type-mismatch
	local res = vim.fn.sign_getplaced(vim.api.nvim_buf_get_name(bufnr), {
		group = sign_group,
	})
	if res[1] then
		return res[1].signs or {}
	end
	return {}
end

---@param bufnr number
---@param lnum number
local get_target_mark = function(bufnr, lnum)
	return core.lua.list.find(get_buf_marks(bufnr), function(x)
		return x.lnum == lnum
	end)
end

-- # mark
---@param bufnr number | nil
---@param lnum number | nil
---@param id number | nil
local mark = function(bufnr, lnum, id)
	if not id then
		id_count = id_count + 1
		id = id_count
	end
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]

	vim.fn.sign_place(id, sign_group, sign_name, bufnr, {
		lnum = lnum,
		priority = static.config.sign.priority,
	})

	---@type track.Mark
	local cur_mark = {
		id = id,
		file = vim.api.nvim_buf_get_name(bufnr),
		lnum = lnum,
	}

	if not mark_list[cur_mark.file] then
		mark_list[cur_mark.file] = {}
	end
	mark_list[cur_mark.file][cur_mark.id] = cur_mark
end

-- # unmark
---@param bufnr number | nil
---@param lnum number | nil
local unmark = function(bufnr, lnum)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]

	local target_mark = get_target_mark(bufnr, lnum)
	if not target_mark then
		return
	end

	vim.fn.sign_unplace(sign_group, { id = target_mark.id })

	local file = vim.api.nvim_buf_get_name(bufnr)
	mark_list[file][target_mark.id] = nil
	if #(core.lua.table.keys(mark_list[file])) == 0 then
		mark_list[file] = nil
	end
end

-- # toggle
---@param bufnr number | nil
---@param lnum number | nil
local toggle = function(bufnr, lnum)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]

	local target_mark = get_target_mark(bufnr, lnum)
	if target_mark then
		unmark(bufnr, lnum)
	else
		mark(bufnr, lnum)
	end
end

-- # store
--- get directory from file path
---@param path string
---@return string
local get_directory = function(path)
	local index = string.find(string.reverse(path), "/", 1, true)
	return string.sub(path, 1, string.len(path) - index)
end

---@param path string
local store = function(path)
	local directory = get_directory(path)
	if not core.file.file_or_dir_exists(directory) then
		core.file.mkdir(directory)
	end

	local file = io.open(path, "w+")
	if not file then
		return
	end
	local marks = {}
	core.lua.table.each(mark_list, function(_, value)
		core.lua.table.each(value, function(_, v)
			table.insert(marks, v)
		end)
	end)
	local text = vim.fn.json_encode({
		marks = marks,
		id_count = id_count,
	})
	file:write(text)
	file:close()
end

-- # restore
---@param bufnr number
local mark_for_buffer = function(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local file = vim.api.nvim_buf_get_name(bufnr)
	if not file or not mark_list[file] then
		return
	end

	core.lua.table.each(mark_list[file], function(_, x)
		if not x.file == file then
			return
		end

		mark(bufnr, x.lnum, x.id)
	end)
end

---@param path string
local restore = function(path)
	local file = io.open(path, "r")
	if not file then
		return
	end
	local text = file:read("*a")
	local data = vim.fn.json_decode(text)
	if not data or not data.marks then
		return
	end

	id_count = data.id_count
	mark_list = {}
	core.lua.list.each(data.marks, function(x)
		if not mark_list[x.file] then
			mark_list[x.file] = {}
		end
		mark_list[x.file][x.id] = x
	end)

	core.lua.list.each(vim.api.nvim_list_bufs(), function(bufnr)
		mark_for_buffer(bufnr)
	end)
end

-- # remove
local remove = function()
	local marks = {}
	core.lua.table.each(mark_list, function(_, value)
		core.lua.table.each(value, function(_, v)
			table.insert(marks, {
				id = v.id,
				group = sign_group,
			})
		end)
	end)
	vim.fn.sign_unplacelist(marks)
	mark_list = {}
end

-- # sync mark list
-- ## create buffer
vim.api.nvim_create_autocmd("BufAdd", {
	callback = function(args)
		mark_for_buffer(args.buf)
	end,
})

-- ## close buffer
vim.api.nvim_create_autocmd({ "BufDelete", "BufUnload" }, {
	callback = function(args)
		local bufnr = args.buf
		local file = vim.api.nvim_buf_get_name(bufnr)
		if not file or not mark_list[file] then
			return
		end

		core.lua.list.each(get_buf_marks(bufnr), function(x)
			mark_list[file][x.id].lnum = x.lnum
		end)
	end,
})

return {
	define_sign = define_sign,
	mark = mark,
	unmark = unmark,
	toggle = toggle,
	store = store,
	restore = restore,
	remove = remove,
}
