-- % Config %
local Config = {}
function Config:new(config)
	local instance = {
		_config = config,
	}

	setmetatable(instance, { __index = Config })

	return instance
end

function Config:set(new_config)
	self._config = vim.tbl_deep_extend("force", self._config, new_config)
end

function Config:get()
	return self._config
end

-- % default_config %
local screen_w = vim.opt.columns:get()
local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
local preview_win_width = math.floor(screen_w * 0.6)
local preview_win_height = math.floor(screen_h * 0.6)

local default_config = {
	is_enabled = function()
		return true
	end,
	mark = {
		mark_hl_group = "WarningMsg",
		mark_icon = "󰍒",
		sign_priority = 10,
		get_root_dir = function()
			return vim.fs.root(0, ".git") or vim.fn.getcwd()
		end,
	},
	outline = {
		flow_hl_group = "FloatBorder",
		mark_hl_group = "WarningMsg",
		win_pos = "left",
		win_size = 30,
		preview_win_width = preview_win_width,
		preview_win_height = preview_win_height,
		preview_on_hover = true,
		cursor_line_hl_group = "CursorLine",
		set_default_when_update_mark = false,
		keymap_move_mark_up = "<A-k>",
		keymap_move_mark_down = "<A-j>",
		keymap_navigate_to_mark = "<cr>",
		keymap_delete_mark = "d",
		keymap_update_mark = "e",
		keymap_preview_mark = "p",
		keymap_close_preview_win = "q",
		get_mark_line_text = function(_, _, text)
			return text
		end,
		select_window = function() end,
	},
}

return Config:new(default_config)
