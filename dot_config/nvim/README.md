# nvim-config

## Updating plugins

Plugins are managed with `vim.pack`. To update them all:

1. Run `:PackUpdate` (defined in `lua/plugins/init.lua`; it calls `vim.pack.update()`).
2. A buffer opens showing the pending changes. Type `:write` to apply them, or `:quit` to cancel.

You can also call it directly with `:lua vim.pack.update()`.

## Status line

The status line is configured with lualine in `lua/configs/lualine.lua`. Its minimal style is inspired by [jakmaz/dotfiles](https://github.com/jakmaz/dotfiles).

```
 main +3 ~1  lua/options.lua                       󰒋  NORMAL  󱑆 1h25m
```

**Left side**

- **Git:** the current branch, the diff (added / changed / removed lines) and the diagnostic counts.
- **File:** the file name, with its path from the project root.

**Right side**

- **`󰒋` LSP:** lit when a language server (e.g. `lua_ls`) is attached to the current file, so completion, go-to-definition and error checking work. Dimmed when none is attached.
- **Mode:** the current Vim mode as plain text (`NORMAL`, `INSERT`, `VISUAL`...).
- **`󱑆` Session time:** how long Neovim has been open, in hours and minutes. It starts at `0h00m` each time you open Neovim.

The status line is hidden on the dashboard and in inactive windows.
