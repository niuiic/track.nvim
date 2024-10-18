# track.nvim

- Enhanced mark with description.
- Track the thought process of analyzing code.

[More neovim plugins](https://github.com/niuiic/awesome-neovim-plugins)

## Features

- flow
  - multiple flows
  - multiple marks in different flows on same line
- outline
  - list flows and marks
    - filter with flow
  - move mark up/down
  - navigate to mark
  - preview mark
  - edit mark
  - delete mark
- mark
  - decorate
  - edit text
  - delete
    - batch delete
  - store/restore

## Usage

<img src="https://github.com/niuiic/assets/blob/main/track.nvim/usage.gif" />

Available functions.

```mermaid
classDiagram
    class App {
        %% config
        +setup(config: Config)
        %% enable
        +is_enabled(bufnr: number, winnr: number) boolean
        %% outline
        +open_outline(show_all?: boolean)
        +close_outline()
        %% flow
        +add_flow()
        +delete_flow()
        +update_flow()
        %% mark
        +add_mark()
        +delete_mark()
        +delete_marks(delete_all?: string)
        +update_mark(set_default?: boolean)
        +store_marks(file_path: string)
        +restore_marks(file_path: string)
        +notify_file_path_change(old: string, new: string)
        +notify_file_change(file_path: string)
        +decorate_marks_on_file(file_path: string)
    }
```

You may need a session plugin for storing/restoring marks. Check [niuiic/multiple-session.nvim](https://github.com/niuiic/multiple-session.nvim).

If there is no highlight on your preview window, try to set filetype.

```lua
vim.filetype.add({
	extension = {
		ts = "typescript",
	},
})
```

## Config

- default config

```lua
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
		preview_cursor_line_hl_group = "CursorLine",
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
		select_window = function() end,
	},
}
```

- config type

```mermaid
classDiagram
    Config --* OutlineConfig
    Config --* MarkConfig
    class Config {
        +outline: OutlineConfig
        +mark: MarkConfig
        +is_enabled(bufnr: number, winnr: number) boolean
    }

    class OutlineConfig {
        +flow_hl_group: string
        +mark_hl_group: string
        +win_pos: 'left' | 'right' | 'top' | 'bottom'
        +win_size: number
        +preview_win_width: number
        +preview_win_height: number
        +preview_cursor_line_hl_group: string
        +preview_on_hover: boolean
        +set_default_when_update_mark: boolean
        +keymap_move_mark_up: string
        +keymap_move_mark_down: string
        +keymap_navigate_to_mark: string
        +keymap_delete_mark: string
        +keymap_update_mark: string
        +keymap_preview_mark: string

        +get_mark_line_text(file_path: string, lnum: string, text: string) string
        +select_window(fn: (winnr: number) => void)
    }

    class MarkConfig {
        +mark_hl_group: string
        +mark_icon: string
        +get_root_dir: () => string | nil
        +sign_priority: number
    }
```
