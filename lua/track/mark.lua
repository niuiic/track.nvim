local static = require("track.static")
local core = require("core")

local sign_group = "TrackSigns"
local sign_name = "TrackSign"
local hl = "TrackColor"
local id_count = 0

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

---@param bufnr number
local get_marks = function(bufnr)
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
	return core.lua.list.find(get_marks(bufnr), function(x)
		return x.lnum == lnum
	end)
end

---@param bufnr number | nil
---@param lnum number | nil
local mark = function(bufnr, lnum)
	id_count = id_count + 1
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]

	vim.fn.sign_place(id_count, sign_group, sign_name, bufnr, {
		lnum = lnum,
		priority = static.config.sign.priority,
	})
end

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
end

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

return {
	define_sign = define_sign,
	mark = mark,
	unmark = unmark,
	toggle = toggle,
}
