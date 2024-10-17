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
local default_config = {
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
		preview_on_hover = true,
		set_default_when_update_mark = false,
		keymap_move_mark_up = "<A-k>",
		keymap_move_mark_down = "<A-j>",
		keymap_navigate_to_mark = "<cr>",
		keymap_delete_mark = "d",
		keymap_update_mark = "e",
		keymap_preview_mark = "p",
		get_mark_line_text = function(_, _, text)
			return text
		end,
	},
}

return Config:new(default_config)
