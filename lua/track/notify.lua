local M = {}

function M.notify(msg)
	vim.fn.notify(msg, vim.log.levels.INFO, {
		title = "track.nvim",
	})
end

function M.notify_err(msg)
	vim.fn.notify(msg, vim.log.levels.ERROR, {
		title = "track.nvim",
	})
end

function M.notify_warn(msg)
	vim.fn.notify(msg, vim.log.levels.WARN, {
		title = "track.nvim",
	})
end

return M
