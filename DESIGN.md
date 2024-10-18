# track.nvim

## Features

- multiple flows
  - allow multiple marks in different flows on same line
- list marks in a tree view
  - change mark order
  - support level
  - navigate to mark
  - preview mark
  - filter with flow
- mark
  - select flow, write content
  - reset flow and content
  - decorate
  - decorate marks when enter new buffer
  - update mark lnum when buffer text changed
  - update mark file_path when buffer name changed
- flow
  - create flow
  - edit flow
  - delete flow

## Architecture

### App

```mermaid
classDiagram
    App --* Outline
    App --* Marks
    App --* Config
    class App {
        <<Singleton>>

        -outline: Outline
        -marks: Marks
        -config: Config

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

- App.setup

```mermaid
flowchart LR
    start([start]) --> n1

    n1[set config] --> n2

    n2[notify marks and outline] --> finish

    finish([finish])
```

- App.open_outline

```mermaid
flowchart LR
    start([start]) --> n1

    n1{to show all}
    n1 --Y--> n2
    n1 --N--> n3

    n2[open outline] --> finish

    n3[select flow] --> n4

    n4[open outline with flow] --> finish

    finish([finish])
```

- App.add_flow

```mermaid
flowchart LR
    start([start]) --> n1

    n1[input flow name] --> n2

    n2[notify marks] --> n3

    n3[notify outline] --> finish

    finish([finish])
```

- App.delete_flow

```mermaid
flowchart LR
    start([start]) --> n1

    n1[select flow] --> n2

    n2[notify marks] --> n3

    n3[notify outline] --> finish

    finish([finish])
```

- App.update_flow

```mermaid
flowchart LR
    start([start]) --> n1

    n1[select flow] --> n4

    n4[input flow name] --> n2

    n2[notify marks] --> n3

    n3[notify outline] --> finish

    finish([finish])
```

- App.add_mark

```mermaid
flowchart LR
    start([start]) --> n7

    n7{has flow}
    n7 --Y--> n2
    n7 --N--> error

    n2[select flow] --> n4

    n4[get file_path and lnum] --> n5

    n5[notify marks] --> n6

    n6[notify outline] --> finish

    error[notify error] --> finish
    finish([finish])
```

- App.delete_mark

```mermaid
flowchart LR
    start([start]) --> n1

    n1[get cursor marks] --> n2

    n2{has marks}
    n2 --Y--> n6
    n2 --N--> error

    n6{just one mark}
    n6 --Y--> n4
    n6 --N--> n3

    n3[select mark] --> n4

    n4[notify marks] --> n5

    n5[notify outline] --> finish

    error[notify error] --> finish
    finish([finish])
```

- App.delete_marks

```mermaid
flowchart LR
    start([start]) --> n1

    n1{delete all}
    n1 --Y--> n2
    n1 --N--> n3

    n2[delete all flows] --> n4

    n4[notify outline] --> finish

    n3[select flow] --> n5

    n5[delete flow] --> n4

    finish([finish])
```

### Marks

```mermaid
classDiagram
    note for Marks "use flow as key of marks"
    Marks --* Mark
    Marks --o MarkConfig
    class Marks {
        <<Singleton>>

        -config: MarkConfig
        -marks: Map~string, Mark[]~
        -ns_id: number
        -sign_group: string
        -sign_name: string
        -id_count: number

        %% new
        +new(config: MarkConfig)$ Marks
        %% config
        +set_config(config: MarkConfig)
        %% flow
        +add_flow(name: string)
        +delete_flow(name: string)
        +update_flow(old: string, new: string)
        +get_flows() string[]
        +has_flow(name: string) boolean
        %% mark
        +add_mark(file_path: string, lnum: number, text: string, flow: string)
        -add_mark(mark: Mark, flow: string)
        +delete_mark(id: number)
        +update_mark_text(id: number, text: string)
        +update_mark_file_path(old: string, new: string)
        +update_mark_lnum(file_path: string)
        +change_mark_order(id: number, direction: 'forward' | 'backward') boolean
        +get_marks(flow?: string) Mark[]
        +get_marks_by_pos(file_path: string, lnum?: number) Mark[]
        +store_marks(file_path: string)
        +restore_marks(file_path: string)
        +decorate_mark(mark: Mark)
        -undecorate_mark(mark: Mark)
        -get_mark(id: number) Mark | nil
    }

    class Mark {
        -id: number
        -text: string
        -file_path: string
        -lnum: number

        +new(id:number, file_path: string, lnum: number, text: string)$ Mark
        +get_id() number
        +get_lnum() number
        +set_lnum(lnum: number)
        +get_file_path() string
        +set_file_path(file_path: string)
        +get_text() string
        +set_text(text: string)
        +to_string(root_dir?: string) string
        +from_string(str: string, root_dir?: string)$ Mark
    }
```

- Marks.add_flow

```mermaid
flowchart LR
    start([start]) --> n1

    n1{flow exists}
    n1 --Y--> error(notify error) --> finish
    n1 --N--> n2

    n2[add new field to marks] --> finish

    finish([finish])
```

- Marks.delete_flow

```mermaid
flowchart LR
    start([start]) --> n1

    n1{flow exists}
    n1 --Y--> n2
    n1 --N--> finish

    n2[delete field from marks] --> n3

    n3[delete flow marks] --> finish

    finish([finish])
```

- Marks.update_flow

```mermaid
flowchart LR
    start([start]) --> n1

    n1{old flow exists}
    n1 --Y--> n2
    n1 --N--> error(notify error) --> finish

    n2{new flow exists}
    n2 --Y--> error
    n2 --N--> n3

    n3[add new flow and move marks to it] --> n4

    n4[delete old flow] --> finish

    finish([finish])
```

- Marks.set_config

```mermaid
flowchart LR
    start([start]) --> n1

    n1[set config] --> n4

    n4{decorate config changed}
    n4 --Y-->n5
    n4 --N-->finish

    n5[redefine sign] --> n2

    n2[undecorate all marks] --> n3

    n3[decorate all marks] --> finish

    finish([finish])
```

- Marks.add_mark

```mermaid
flowchart LR
    start([start]) --> n1

    n1{mark exists}
    n1 --Y--> error(notify error) --> finish
    n1 --N--> n5

    n5[increase id count] --> n2

    n2[create new mark] --> n3

    n3[decorate mark] --> n4

    n4[add mark to marks] --> finish

    finish([finish])
```

- Marks.delete_mark

```mermaid
flowchart LR
    start([start]) --> n1

    n1{mark exists}
    n1 --N--> error(notify error) --> finish
    n1 --Y--> n2

    n2[undecorate mark] --> n3

    n3[remove mark from marks] --> finish

    finish([finish])
```

- Marks.update_mark_text

```mermaid
flowchart LR
    start([start]) --> n4

    n4{mark exists}
    n4 --N--> error(notify error) --> finish
    n4 --Y--> n5

    n5[find mark] --> n1

    n1[undecorate mark] --> n2

    n2[set mark text] --> n3

    n3[decorate mark] --> finish

    finish([finish])
```

- Marks.decorate_mark

```mermaid
flowchart LR
    start([start]) --> n3

    n3{file is open}
    n3 --N--> finish
    n3 --Y--> n4

    n4[get bufnr] --> n1

    n1[place a sign] --> n2

    n2[set virtual text] --> finish

    finish([finish])
```

### Outline

```mermaid
classDiagram
    Outline --o OutlineConfig
    Outline --o Marks
    Outline --* Window
    class Outline {
        <<Singleton>>

        -config: OutlineConfig
        -marks: Marks
        -outline_window: Window | nil
        -preview_window: Window | nil
        -flow: string | nil
        -line_marks: Map~number, Mark~
        -prev_winnr: number

        %% new
        +new(config: OutlineConfig, marks: Marks)$ Outline
        %% config
        +set_config(config: OutlineConfig)
        %% outline
        +open(flow?: string)
        +close()
        -is_open() boolean
        %% mark
        +draw_marks()
        -move_mark_up()
        -move_mark_down()
        -navigate_to_mark()
        -delete_mark()
        -update_mark(set_default?: boolean)
        -preview_mark()
        -get_cursor_mark() Mark | nil
    }

    class Window {
        -ns_id: number
        -pos: 'left' | 'right' | 'top' | 'bottom' | 'float'
        -bufnr: number
        -winnr: number

        +new_split(pos: 'left' | 'right' | 'top' | 'bottom', size: number, enter?: boolean)$ Window
        +new_float(relative_winnr: number, row: number, col: number, width: number, height: number, enter?: boolean)$ Window
        +is_valid() boolean
        +write_line(lnum: number, text: string, hl_group?: string)
        +write_file(file_path: string, focus_lnum?: number, hl_group?: string)
        +clean(after_lnum?: number)
        +set_keymap(keymap: Map~string, function~)
        +set_autocmd(events: string[], fn: () => void)
        +get_cursor_lnum() number
        +set_cursor_lnum(lnum: number)
        +get_pos() 'left' | 'right' | 'top' | 'bottom' | 'float'
        +close()
        +get_winnr() number
        +enable_edit()
        +disable_edit()
    }
```

- Outline.open

```mermaid
flowchart LR
    start([start]) --> n1

    n1{outline is open}
    n1 --Y--> n2
    n1 --N--> n3

    n2{flow is same}
    n2 --Y--> finish
    n2 --N--> n4

    n4[clean buffer] --> n7

    n5[draw marks] --> finish

    n3[open window] --> n6

    n6[set keymap] --> n7

    n7[set flow] --> n5

    finish([finish])
```

- Outline.set_config

```mermaid
flowchart LR
    start([start]) --> n1

    n1[set config] --> n2

    n2{outline is open}
    n2 --Y--> n3
    n2 --N--> finish

    n3[close outline] --> n4

    n4[open outline with previous filter] --> finish

    finish([finish])
```

- Outline.draw_marks

```mermaid
flowchart LR
    start([start]) --> n1

    n1[get flows and marks with current filter] --> n2

    n2[draw flows and marks] --> n3

    n3[reset line_marks] --> finish

    finish([finish])
```

- Outline.move_mark_up

```mermaid
flowchart LR
    start([start]) --> n1

    n1[get cursor mark] --> n2

    n2[try to change mark order] --> n3

    n3{is successful}
    n3 --Y--> n4
    n3 --N--> finish

    n4[redraw marks] --> n5

    n5[move cursor up] --> finish

    finish([finish])
```

- App flow/mark method

```mermaid
flowchart LR
    start([start]) --> n1

    n1[notify marks] --> n2

    n2{outline is open}
    n2 --Y--> n3
    n2 --N--> finish

    n3[notify outline to redraw marks]

    finish([finish])
```

### Config

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
