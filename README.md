# track.nvim

- Enhanced mark with description.
- Track the thought process of reading source code.

## Dependencies

- [niuiic/core.nvim](https://github.com/niuiic/core.nvim)
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Usage

<img src="https://github.com/niuiic/assets/blob/main/track.nvim/usage.gif" />

Available functions.

| function                          | desc                                 |
| --------------------------------- | ------------------------------------ |
| `setup(config)`                   | set config                           |
| `mark(bufnr?, lnum?, id?, desc?)` | mark line                            |
| `unmark(bufnr?, lnum?)`           | unmark line                          |
| `toggle(bufnr?, lnum?)`           | mark/unmark line                     |
| `store(path)`                     | store marks                          |
| `restore(path)`                   | restore marks                        |
| `remove()`                        | remove all marks                     |
| `edit(bufnr?, lnum?)`             | edit mark                            |
| `search(opts)`                    | search marks                         |
| `jump_to_next()`                  | jump to next mark in this buffer     |
| `jump_to_prev()`                  | jump to previous mark in this buffer |

## Config

Default config.

```lua
require("track").setup({
	sign = {
		text = "󰍒",
		text_color = "#00ff00",
		priority = 10,
	},
	search = {
		---@param mark track.Mark
		entry_label = function(mark)
			return string.format("[%s] %s | %s:%s", mark.id, mark.desc, mark.file, mark.lnum)
		end,
		---@param marks track.Mark[]
		---@return track.Mark[]
		sort_entry = function(marks)
			return require("core").lua.list.sort(marks, function(prev, cur)
				return prev.id < cur.id
			end)
		end,
	},
})
```

Keymap example.

```lua
local keys = {
	{
		"mm",
		function()
			require("track").toggle()
		end,
		desc = "toggle mark",
	},
	{
		"mc",
		function()
			require("track").remove()
		end,
		desc = "remove all marks",
	},
	{
		"mj",
		function()
			require("track").jump_to_next()
		end,
		desc = "jump to next mark",
	},
	{
		"mk",
		function()
			require("track").jump_to_prev()
		end,
		desc = "jump to prev mark",
	},
	{
		"me",
		function()
			require("track").edit()
		end,
		desc = "edit mark",
	},
	{
		"<space>om",
		function()
			require("track").search()
		end,
		desc = "search marks",
	},
}
```
