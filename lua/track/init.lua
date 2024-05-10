local static = require("track.static")
local mark = require("track.mark")

local setup = function(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
	mark.define_sign()
end

return {
	setup = setup,
	mark = mark.mark,
	unmark = mark.unmark,
	toggle = mark.toggle,
	store = mark.store,
	restore = mark.restore,
	remove = mark.remove,
}
