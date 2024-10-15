local config = require("track.config")

local M = {
	_config = config,
}

-- TODO: setup
function M:setup(new_config)
	config:set(new_config or {})
end

return M
