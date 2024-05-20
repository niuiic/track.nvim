local static = require("track.static")
local mark = require("track.mark")
local search = require("track.search")
local jump = require("track.jump")

local setup = function(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
	mark.define_sign()
end

return {
	setup = setup,
	mark = mark.mark,
	is_marked = mark.is_marked,
	unmark = mark.unmark,
	toggle = mark.toggle,
	store = mark.store,
	restore = mark.restore,
	remove = mark.remove,
	edit = mark.edit,
	search = search.search,
	jump_to_next = jump.jump_to_next,
	jump_to_prev = jump.jump_to_prev,
}
