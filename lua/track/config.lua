-- % Config %
local Config = {}
function Config:new(config)
	local instance = {
		_config = config,
	}

	setmetatable(instance, {
		__index = Config,
	})

	return instance
end

function Config:set(new_config)
	self._config = vim.tbl_deep_extend("force", self._config, new_config)
end

function Config:get()
	return self._config
end

-- % default config %
local default_config = {
	mark = {
		mark_hl_group = "CurSearch",
		mark_icon = "󰍒",
		get_root_dir = function()
			return vim.fs.root(0, ".git") or vim.fn.getcwd()
		end,
	},
	outline = {
		flow_hl_group = "FloatBorder",
		win_pos = "left",
		win_size = 30,
		get_mark_line_text = function(file_path, lnum, text)
			return string.format("[%s:%d] %s", file_path, lnum, text)
		end,
	},
}

return Config:new(default_config)
